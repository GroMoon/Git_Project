extends SceneTree
## 캐릭터 로스터(King / Wizard) + 캐릭터 선택 화면 헤드리스 테스트
## 실행 (프로젝트 폴더에서):
##   Godot_v4.2.1-stable_win64_console.exe --headless --path . --script res://dynamic/8_action/tests/roster_smoke_test.gd

const STAGE_SCENE  := "res://dynamic/8_action/stage/action_stage.tscn"
const SELECT_SCENE := "res://dynamic/8_action/ui/character_select.tscn"
const ATTACK_STATE := 5

## 오토로드 등록 후에 컴파일되도록 preload 대신 _initialize에서 load
var ActionStage : GDScript
var stage
var player
var results := []
var _step := 0
var _frame := 0
var _data := {}

func _initialize():
	ActionStage = load("res://dynamic/8_action/stage/action_stage.gd")
	_load_stage("king")

func _load_stage(character: String):
	if stage:
		stage.queue_free()
	ActionStage.selected_character = character
	stage = load(STAGE_SCENE).instantiate()
	stage.save_rewards = false
	stage.recruit_chance = 0.0
	stage.elite_recruit_chance = 0.0
	root.add_child(stage)
	player = null

func _physics_process(_delta):
	if stage != null and not is_instance_valid(player):
		player = stage.player
		return false
	_frame += 1
	_run_step()
	return false

func check(name: String, ok: bool, detail := ""):
	results.append([name, ok])
	print(("PASS  " if ok else "FAIL  ") + name + ("" if detail == "" else "  (" + detail + ")"))

func enemies() -> Array:
	return get_nodes_in_group("action_enemy")

## 적 정리 후 플레이어 주변에 고정(AI 정지) 적 배치
func setup(offsets: Array, kind := "goblin"):
	for e in enemies():
		e.remove_from_group("action_enemy")
		e.queue_free()
	stage._enemy_count = 0
	stage._next_wave_timer = -1.0
	player.reset_pose()
	player.position = Vector2(1000, 560)
	player.facing = 1
	player.hp = player.max_hp
	player.mp = player.max_mp
	player.cooldowns.clear()
	player.invuln_timer = 0.0
	for offset in offsets:
		var e = stage.spawn_enemy(kind, Vector2(1000, 560) + offset)
		e.guard_chance = 0.0

func freeze_enemies():
	for e in enemies():
		if e.state <= 1:
			e._think = 1.0
			e._attack_cd = 99.0

func tap(action: String, at: int, hold := 2):
	if _frame == at:
		Input.action_press(action)
	elif _frame == at + hold:
		Input.action_release(action)

func mash_attack():
	if _frame % 8 == 3:
		Input.action_press("act_attack")
	elif _frame % 8 == 5:
		Input.action_release("act_attack")

func avg_dist() -> float:
	var list := enemies()
	if list.is_empty():
		return 0.0
	var total := 0.0
	for e in list:
		total += absf(e.position.x - player.position.x) + absf(e.position.y - player.position.y)
	return total / list.size()

func damaged_count() -> int:
	return enemies().filter(func(e): return e.hp < e.max_hp).size()

func next_step():
	Input.action_release("act_attack")
	_step += 1
	_frame = 0
	_data.clear()

func _run_step():
	match _step:
		0:	# ── King : 콤보 체인 ──
			if _frame == 1:
				check("king spawned", player.sheet_key == "medieval_king", player.sheet_key)
				setup([Vector2(90, 0), Vector2(120, 50)])
				_data.moves = []
			freeze_enemies()
			mash_attack()
			if player.state == ATTACK_STATE and (_data.moves.is_empty() or _data.moves[-1] != player.move_name):
				_data.moves.append(player.move_name)
			if _frame == 90:
				check("king combo chain", str(_data.moves).begins_with('["atk1", "atk2", "atk3"'), str(_data.moves))
				next_step()
		1:	# ── King S : 왕의 부름 (넓게 빨아들이기) ──
			if _frame == 1:
				setup([Vector2(-330, -100), Vector2(360, 110), Vector2(-250, 120), Vector2(300, -90)])
				_data.start = avg_dist()
				_data.min = 9999.0
			freeze_enemies()
			tap("act_skill_2", 4)
			if _frame > 6:
				_data.min = minf(_data.min, avg_dist())
			if _frame == 80:
				check("king royal call gathers", _data.min < _data.start * 0.45, "avg %.0f -> %.0f" % [_data.start, _data.min])
				check("king royal call hits all", damaged_count() == 4, "hit %d" % damaged_count())
				next_step()
		2:	# ── Wizard 로 교체 ──
			if _frame == 1:
				_load_stage("wizard")
			if _frame == 3:
				next_step()
		3:	# ── Wizard : 마력탄이 멀리 있는 적을 맞힘 ──
			if _frame == 1:
				check("wizard spawned", player.sheet_key == "wizard", player.sheet_key)
				setup([Vector2(380, 0)])
				_data.hp = enemies()[0].hp
			freeze_enemies()
			tap("act_attack", 4)
			if _frame == 60:
				check("wizard bolt hits far enemy", enemies()[0].hp < _data.hp, "dist 380")
				next_step()
		4:	# ── Wizard S : 그라비티 홀 (마법사 몰이) ──
			if _frame == 1:
				setup([Vector2(80, -100), Vector2(470, 100), Vector2(150, 110), Vector2(430, -90)])
				_data.max_spread = 0.0
			freeze_enemies()
			tap("act_skill_2", 4)
			if _frame == 6:
				var xs := enemies().map(func(e): return e.position.x)
				_data.start_spread = xs.max() - xs.min()
			if _frame == 80:
				var xs := enemies().map(func(e): return e.position.x)
				var spread: float = xs.max() - xs.min()
				check("wizard gravity hole gathers", spread < _data.start_spread * 0.5, "x spread %.0f -> %.0f" % [_data.start_spread, spread])
			if _frame == 150:
				check("gravity hole burst launches", enemies().any(func(e): return e.z > 60.0 or e.state == 4))
				next_step()
		5:	# ── Wizard A : 체인 라이트닝 (3명) ──
			if _frame == 1:
				setup([Vector2(200, -60), Vector2(-250, 80), Vector2(320, 90), Vector2(900, 0)])
			freeze_enemies()
			tap("act_skill_1", 4)
			if _frame == 60:
				check("chain lightning hits 3 nearest", damaged_count() == 3, "hit %d" % damaged_count())
				next_step()
		6:	# ── Wizard D : 블링크 (무적 이동) ──
			if _frame == 1:
				setup([])
				_data.x = player.position.x
				_data.invuln = false
			tap("act_skill_3", 4)
			if player.move_name == "blink" and not player.can_be_hit():
				_data.invuln = true
			if _frame == 40:
				check("blink teleports far", player.position.x - _data.x > 200.0, "moved %.0f" % (player.position.x - _data.x))
				check("blink is invulnerable", _data.invuln)
				next_step()
		7:	# ── Wizard F : 메테오 스톰 ──
			if _frame == 1:
				setup([Vector2(150, 0), Vector2(260, -70), Vector2(350, 70), Vector2(420, 0)], "mushroom")
			freeze_enemies()
			tap("act_skill_4", 4)
			if _frame == 160:
				check("meteor storm hits enemies", damaged_count() >= 3, "hit %d" % damaged_count())
				next_step()
		8:	# ── 일시정지 메뉴 + 키 변경 (사용자 키 설정 파일은 백업 후 복원) ──
			if _frame == 1:
				var ActionInput = load("res://dynamic/8_action/core/action_input.gd")
				_data.input = ActionInput
				_data.backup = FileAccess.get_file_as_string(ActionInput.CONFIG_PATH) if FileAccess.file_exists(ActionInput.CONFIG_PATH) else ""
				ActionInput.reset_defaults()
				stage.open_pause_menu()
			if _frame == 3:
				check("ESC opens pause menu (paused)", stage.pause_menu != null and paused)
				stage.pause_menu.activate(1)		# 조작 설정
				check("pause menu opens key settings", stage.pause_menu.page == "keys")
				var input = _data.input
				input.rebind("act_attack", KEY_J)
				check("rebind attack -> J", input.get_key("act_attack") == KEY_J, input.key_name("act_attack"))
				input.rebind("act_jump", KEY_J)
				check("rebind swaps conflicting key", input.get_key("act_jump") == KEY_J and input.get_key("act_attack") == KEY_C,
					"attack=%s jump=%s" % [input.key_name("act_attack"), input.key_name("act_jump")])
				check("key settings saved to file", FileAccess.file_exists(input.CONFIG_PATH))
				input.reset_defaults()
				check("reset restores defaults", input.get_key("act_attack") == KEY_X and input.get_key("act_jump") == KEY_C)
				if _data.backup != "":
					var file := FileAccess.open(input.CONFIG_PATH, FileAccess.WRITE)
					file.store_string(_data.backup)
					file.close()
				stage.pause_menu.close()
			if _frame == 5:
				check("closing menu unpauses", not paused and stage.pause_menu == null)
				next_step()
		9:	# ── 캐릭터 선택 화면 ──
			if _frame == 1:
				stage.queue_free()
				stage = null
				ActionStage.selected_character = "warrior"
				_data.select = load(SELECT_SCENE).instantiate()
				root.add_child(_data.select)
			if _frame == 3:
				check("select screen builds 3 cards", _data.select._cards.size() == 3)
				var press := InputEventAction.new()
				press.action = "act_right"
				press.pressed = true
				_data.select._unhandled_input(press)	# 헤드리스에서는 입력 이벤트가 뷰포트로 전달되지 않아 직접 호출
			if _frame == 5:
				check("right arrow selects next", _data.select.selected == 1, "selected %d" % _data.select.selected)
				_data.select._start()
				check("start sets character", ActionStage.selected_character == "king", ActionStage.selected_character)
				_data.select.queue_free()
			if _frame == 8:
				var failed := results.filter(func(r): return not r[1]).size()
				print("RESULT  %d/%d passed" % [results.size() - failed, results.size()])
				quit(1 if failed > 0 else 0)
