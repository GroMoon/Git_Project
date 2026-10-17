extends SceneTree
## 밸런스 측정 (헤드리스 자동 플레이 봇) — 캐릭터별 DPS / 받는 피해 측정
## 실행 (프로젝트 폴더에서):
##   Godot_v4.2.1-stable_win64_console.exe --headless --path . --script res://dynamic/8_action/tests/balance_report.gd [-- warrior]
## (캐릭터 이름을 주면 그 캐릭터만 측정 → 여러 프로세스로 병렬 실행 가능)
## 시나리오마다 TRIALS회 반복(시드 고정) 후 평균
## 봇 : 가장 가까운 적에게 라인을 맞추고 다가가 스킬(쿨 되면 즉시) → 평타 연타
## 시간은 실시간 기준(물리 60프레임 = 1초, 히트스탑 포함)

const STAGE_SCENE := "res://dynamic/8_action/stage/action_stage.tscn"
const SECONDS := 12
const TRIALS  := 3
var CHARACTERS := ["warrior", "king", "wizard"]
const PREFERRED_RANGE := {"warrior": 95.0, "king": 115.0, "wizard": 170.0}
const SCENARIOS := ["single", "mob", "wave"]
const BOSS_HP := 400000.0

var ActionStage : GDScript
var stage
var player
var results := {}
var _char_index := 0
var _scenario_index := 0
var _trial := 0
var _frame := 0
var _held : Array = []
var _start_hp := 0.0

func _initialize():
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		CHARACTERS = [args[0]]
	ActionStage = load("res://dynamic/8_action/stage/action_stage.gd")
	_begin()

func _begin():
	if stage:
		stage.queue_free()
	ActionStage.selected_character = CHARACTERS[_char_index]
	stage = load(STAGE_SCENE).instantiate()
	stage.save_rewards = false
	stage.recruit_chance = 0.0
	stage.elite_recruit_chance = 0.0
	root.add_child(stage)
	player = null
	_frame = 0

func _setup_scenario():
	for e in get_nodes_in_group("action_enemy"):
		e.remove_from_group("action_enemy")
		e.queue_free()
	stage._enemy_count = 0
	stage._next_wave_timer = -1.0
	seed(_trial * 7919 + _scenario_index * 101 + 17)
	player.position = Vector2(700, 560)
	player.facing = 1
	player.max_hp = 1e9
	player.hp = player.max_hp
	_start_hp = player.hp
	match SCENARIOS[_scenario_index]:
		"single":
			_dummy("skeleton", Vector2(900, 560))
		"mob":
			for offset in [Vector2(200, -60), Vector2(260, 60), Vector2(320, 0), Vector2(380, -40)]:
				_dummy("goblin", player.position + offset)
		"wave":
			for entry in [["goblin", 1000, 500], ["goblin", 1050, 620], ["skeleton", 1150, 560], ["mushroom", 1250, 500]]:
				var e = stage.spawn_enemy(entry[0], Vector2(entry[1], entry[2]))
				e.hp = 1e9
				e.max_hp = 1e9

func _dummy(kind: String, pos: Vector2):
	var e = stage.spawn_enemy(kind, pos)
	e.hp = 1e9
	e.max_hp = 1e9
	e.guard_chance = 0.0

func _physics_process(_delta):
	if player == null:
		if stage.player:
			player = stage.player
			_setup_scenario()
		return false
	_frame += 1
	if SCENARIOS[_scenario_index] != "wave":
		for e in get_nodes_in_group("action_enemy"):
			if e.state <= 1:
				e._think = 1.0
				e._attack_cd = 99.0
	_bot()
	if _frame >= SECONDS * 60:
		_record()
		_next()
	return false

func _press(action: String):
	Input.action_press(action)
	_held.append(action)

func _bot():
	for action in _held:
		Input.action_release(action)
	_held.clear()
	var target = null
	var best := 1e9
	for e in get_nodes_in_group("action_enemy"):
		var d: float = absf(e.position.x - player.position.x) + absf(e.position.y - player.position.y) * 2.0
		if d < best:
			best = d
			target = e
	if target == null:
		return
	var dx: float = target.position.x - player.position.x
	var dy: float = target.position.y - player.position.y
	var want: float = PREFERRED_RANGE[CHARACTERS[_char_index]]
	if player.state == 0 or player.state == 1 or player.state == 5:
		for slot in player.skill_slots:
			if player.can_use_skill(slot.move) and absf(dx) < want + 160.0 and absf(dy) < 40.0 and _frame % 2 == 0:
				_press(slot.action)
				return
	if absf(dy) > 14.0 and player.state != 5:
		_press("act_down" if dy > 0.0 else "act_up")
	if absf(dx) > want + 30.0 and player.state != 5:
		_press("act_right" if dx > 0.0 else "act_left")
	elif signf(dx) != player.facing and absf(dx) > 20.0 and player.state != 5:
		_press("act_right" if dx > 0.0 else "act_left")
	elif _frame % 4 == 0:
		_press("act_attack")

func _record():
	var dealt := 0.0
	for e in get_nodes_in_group("action_enemy"):
		dealt += e.max_hp - e.hp
	var seconds := float(SECONDS)
	var key: String = CHARACTERS[_char_index]
	if not results.has(key):
		results[key] = {}
	var scenario: String = SCENARIOS[_scenario_index]
	if not results[key].has(scenario):
		results[key][scenario] = {"dps": 0.0, "taken_per_sec": 0.0, "max_combo": 0}
	var r: Dictionary = results[key][scenario]
	r.dps += dealt / seconds / TRIALS
	r.taken_per_sec += (_start_hp - player.hp) / seconds / TRIALS
	r.max_combo = maxi(r.max_combo, stage.fx.max_combo)

func _next():
	for action in _held:
		Input.action_release(action)
	_held.clear()
	_trial += 1
	if _trial < TRIALS:
		_begin()
		return
	_trial = 0
	_scenario_index += 1
	if _scenario_index >= SCENARIOS.size():
		_scenario_index = 0
		_char_index += 1
		if _char_index >= CHARACTERS.size():
			_print_report()
			quit()
			return
	_begin()

func _print_report():
	print("BALANCE  character | single DPS | boss TTK(s) | mob DPS(4) | wave DPS | taken/s in wave | max HP | max combo")
	for key in CHARACTERS:
		var r: Dictionary = results[key]
		var probe = load("res://dynamic/8_action/player/%s_action.gd" % key).new()
		probe._setup_character()
		var base_hp: float = probe.max_hp
		probe.free()
		print("BALANCE  %-8s | %9.0f | %10.1f | %9.0f | %8.0f | %14.0f | %6.0f | %d" % [
			key, r.single.dps, BOSS_HP / maxf(1.0, r.single.dps), r.mob.dps, r.wave.dps,
			r.wave.taken_per_sec, base_hp, r.wave.max_combo])
