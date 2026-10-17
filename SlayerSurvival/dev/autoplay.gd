extends Node

## 자동 플레이 스모크 테스트 하네스
## 사용법 (프로젝트 폴더에서):
##   Godot --headless --fixed-fps 60 res://dev/autoplay.tscn -- --char=warrior --map=cave --seconds=180
##   (스크린샷이 필요하면 --headless 제외) -- --shots=10,60,120 --shot_dir=/tmp/shots
## 옵션
##   --char=warrior|king|wizard   --map=cave|dungeon   --seconds=게임 내 초
##   --log_every=로그 간격(초)     --shots=스크린샷 찍을 게임 시간(초, 쉼표 구분)
##   --shot_dir=스크린샷 저장 경로  --god=1 (무적)    --start_minute=시작 분(디렉터 테스트용)
##   --give=fireball,bomb:3 (시작 시 업그레이드 지급, :n = n레벨)  --pick=first|random
##   --shot_levelup=1 (첫 레벨업 화면 스크린샷)  --shot_chest=1 (첫 보물상자 화면 스크린샷)
##   --pets=goblin,mushroom,skeleton,flyingeye (시작 시 몬스터 펫 지급)
##   --chest_at=초 (해당 시각에 플레이어 위치에 보물상자, --chest_count=5 면 보상 5개 상자를 바로 열기)
##   --shot_chest=0.4,1.0 (상자 연출 중 여러 시점 스크린샷)  --die_at=초 (강제 사망)  --shot_death=1 (결과 화면 스크린샷)  --shot_pause=초 (해당 시각에 일시정지 화면 스크린샷)

const GAME_SCENE = "res://test.tscn"

var opts = {
	"char": "warrior",
	"map": "cave",
	"seconds": "120",
	"log_every": "10",
	"shots": "",
	"shot_dir": "user://autoplay_shots",
	"god": "0",
	"start_minute": "0",
	"give": "",
	"pick": "random",
	"shot_levelup": "0",
	"shot_pause": "-1",
	"shot_chest": "0",
	"pets": "",
	"chest_at": "-1",
	"chest_count": "0",
	"die_at": "-1",
	"shot_death": "0",
}

var game: Node = null
var player: Node = null
var elapsed := 0.0
var next_log := 0.0
var shots: Array = []
var wander_dir := Vector2.RIGHT
var wander_timer := 0.0
var max_enemies := 0
var min_fps := 1000.0
var levelups := 0
var levelup_wait := 0.0
var levelup_shot_done := false
var chest_spawned := false
var shot_index := 0
var death_wait := 0.0
var chests := 0
var chest_wait := 0.0
var chest_shot_done := false
var pause_shot_state := 0
var pause_shot_wait := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv = arg.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	for s in String(opts["shots"]).split(",", false):
		shots.append(float(s))
	shots.sort()
	next_log = float(opts["log_every"])
	randomize()
	call_deferred("_start_game")

func _start_game():
	game = load(GAME_SCENE).instantiate()
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await get_tree().process_frame
	if opts["map"] == "dungeon":
		game._on_dungeon_button_pressed()
	else:
		game._on_cave_button_pressed()
	await get_tree().process_frame
	match opts["char"]:
		"king":
			game._on_select_king_pressed()
		"wizard":
			game._on_wizard_pressed()
		_:
			game._on_select_warrior_pressed()
	await get_tree().process_frame
	player = game.get_node_or_null("player")
	var start_minute = int(opts["start_minute"])
	if start_minute > 0:
		player.get_node("UI_Layer/BaseUI").minute = start_minute
	for spec in String(opts["give"]).split(",", false):
		var parts = spec.split(":")
		var count = int(parts[1]) if parts.size() > 1 else 1
		for i in count:
			player.add_upgrade(parts[0])
	for pet in String(opts["pets"]).split(",", false):
		Dialogic.VAR.set(pet + "_pet_diag", true)
	print("[autoplay] start char=%s map=%s seconds=%s" % [opts["char"], opts["map"], opts["seconds"]])

func _process(delta):
	if player == null or not is_instance_valid(player):
		return
	var base_ui = player.get_node("UI_Layer/BaseUI")

	# 보스 처치 → 엔딩 연출이 시작되면 잠시 후 종료
	if base_ui.ending_pause_flag:
		death_wait += delta
		if death_wait > 3.0:
			_take_shot()
			_finish("ending")
		return

	# 결과 화면 스크린샷 (사망 후 잠시 대기)
	if base_ui.death_pause_flag and opts["shot_death"] == "1":
		death_wait += delta
		if death_wait > 1.0:
			_take_shot()
			_finish("player died")
		return

	_handle_blocking_ui(base_ui)

	# 일시정지 화면 스크린샷
	var pause_at = float(opts["shot_pause"])
	if pause_at >= 0.0 and pause_shot_state == 0 and elapsed >= pause_at:
		pause_shot_state = 1
		base_ui.globl_pause_flag = true
		base_ui.update_info()
	elif pause_shot_state == 1:
		pause_shot_wait += delta
		if pause_shot_wait > 0.5:
			_take_shot()
			base_ui.globl_pause_flag = false
			pause_shot_state = 2
		return

	if get_tree().paused:
		return

	elapsed += delta
	if opts["god"] == "1":
		player.current_hp = player.max_hp
	if float(opts["chest_at"]) >= 0.0 and not chest_spawned and elapsed >= float(opts["chest_at"]) and int(opts["chest_count"]) > 0:
		# 보상 개수를 지정해 바로 열기
		chest_spawned = true
		player.get_node("UI_Layer/SelectUI").open_chest(int(opts["chest_count"]))
	if float(opts["chest_at"]) >= 0.0 and not chest_spawned and elapsed >= float(opts["chest_at"]):
		chest_spawned = true
		var chest = ChestPickup.create()
		chest.global_position = player.global_position + Vector2(40, 0)
		game.get_node("EnemySpwaner").add_child(chest)
	if float(opts["die_at"]) >= 0.0 and elapsed >= float(opts["die_at"]) and not player.is_dead:
		opts["god"] = "0"
		player.respawn_times = 0
		player.damage_flag = false
		player.process_collision_enemy(99999)
	_steer()

	var fps = Engine.get_frames_per_second()
	if elapsed > 3.0:
		min_fps = min(min_fps, fps)
	var enemy_count = get_tree().get_nodes_in_group("enemy").size()
	max_enemies = max(max_enemies, enemy_count)

	if elapsed >= next_log:
		next_log += float(opts["log_every"])
		print("[autoplay] t=%5.1f clock=%s fps=%d enemies=%d lv=%d hp=%.0f/%.0f kills=%d nodes=%d" % [
			elapsed, base_ui.stopwatch.text, fps, enemy_count, player.character_level,
			player.current_hp, player.max_hp, player.kill_count, get_tree().get_node_count()])

	if shots.size() > 0 and elapsed >= shots[0]:
		shots.pop_front()
		_take_shot()

	if (player.is_dead or base_ui.death_pause_flag) and opts["shot_death"] != "1":
		_finish("player died")
	elif elapsed >= float(opts["seconds"]):
		_finish("time limit")

# 레벨업/다이얼로그 등 입력이 필요한 UI 자동 처리
func _handle_blocking_ui(base_ui):
	if base_ui.lvlup_pause_flag:
		var select_ui = player.get_node("UI_Layer/SelectUI")
		if "chest_open" in select_ui and select_ui.chest_open:
			if opts["shot_chest"] != "0" and not chest_shot_done:
				# --shot_chest=1 → 1.6초 뒤 한 장, --shot_chest=0.4,0.9,... → 여러 시점
				var times = [1.6] if opts["shot_chest"] == "1" else Array(String(opts["shot_chest"]).split(",")).map(func(x): return float(x))
				var before = chest_wait
				chest_wait += get_process_delta_time()
				for t in times:
					if before < t and chest_wait >= t:
						_take_shot()
				if chest_wait < times.max() + 0.1:
					return
				chest_shot_done = true
			chests += 1
			select_ui.autoclose_chest()
			return
		# 첫 레벨업 화면은 잠깐 띄워두고 스크린샷
		if opts["shot_levelup"] == "1" and not levelup_shot_done:
			levelup_wait += get_process_delta_time()
			if levelup_wait < 0.6:
				return
			levelup_shot_done = true
			_take_shot()
		if select_ui.has_method("autopick"):
			if opts["pick"] != "first" and "current_choices" in select_ui and not select_ui.current_choices.is_empty():
				var choice = select_ui.current_choices.pick_random()
				if opts["pick"] == "smart":
					choice = _smart_pick(select_ui.current_choices)
				select_ui.accept_input_at = 0.0
				select_ui._on_upgrade_button_pressed(choice)
			else:
				select_ui.autopick()
		else:
			var container = select_ui.get_node("select_panel/upgrade_container")
			for child in container.get_children():
				if child is BaseButton and not child.is_queued_for_deletion():
					child.emit_signal("pressed")
					break
		levelups += 1
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
		Dialogic.VAR.diag_pause_flag = false

# 무기 우선(새 무기 > 무기 강화 > 패시브) 선택
func _smart_pick(choices: Array) -> String:
	var best = choices[0]
	var best_score = -1.0
	for id in choices:
		var score = randf()
		if UpgradeDB.is_weapon(id):
			score += 3.0 if player.get_upgrade_level(id) == 0 else 2.0
		elif UpgradeDB.is_passive(id):
			score += 1.5 if id in ["might", "max_hp", "armor", "cooldown", "area"] else 1.0
		if score > best_score:
			best_score = score
			best = id
	return best

# 간단한 카이팅 봇: 너무 가까운 적 무리는 피하고(접선 이동), 멀면 가장 가까운 적에게 접근
func _steer():
	var away := Vector2.ZERO
	var crowd := 0
	var closest: Node2D = null
	var closest_dist := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		var d: Vector2 = player.global_position - e.global_position
		var dist = d.length()
		if dist < closest_dist:
			closest_dist = dist
			closest = e
		if dist < 90.0 and dist > 0.01:
			away += d / dist * (90.0 - dist)
			crowd += 1
	var dir: Vector2
	var preferred = 170.0 if opts["char"] == "wizard" else 60.0
	# 보물상자가 가까이 있으면 주우러 감
	var chest: Node2D = null
	for c in get_tree().get_nodes_in_group("Chest"):
		if player.global_position.distance_to(c.global_position) < 700.0:
			chest = c
			break
	if chest and crowd < 5:
		dir = (chest.global_position - player.global_position).normalized()
	elif crowd >= 3:
		dir = (away.normalized() + away.normalized().orthogonal() * 0.8).normalized()
	elif closest != null and closest_dist < 600.0:
		var to_enemy = (closest.global_position - player.global_position).normalized()
		if closest_dist > preferred * 1.3:
			dir = to_enemy
		elif closest_dist < preferred * 0.8:
			dir = (-to_enemy + to_enemy.orthogonal() * 0.5).normalized()
		else:
			dir = to_enemy.orthogonal()
	else:
		wander_timer -= get_process_delta_time()
		if wander_timer <= 0.0:
			wander_timer = randf_range(0.8, 2.0)
			wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
		dir = wander_dir
	# 맵 경계 근처면 중앙 쪽으로
	if player.global_position.length() > 1200.0:
		dir = (dir - player.global_position.normalized() * 1.5).normalized()
	for action in ["left", "right", "up", "down"]:
		Input.action_release(action)
	if dir.x > 0.3:
		Input.action_press("right")
	elif dir.x < -0.3:
		Input.action_press("left")
	if dir.y > 0.3:
		Input.action_press("down")
	elif dir.y < -0.3:
		Input.action_press("up")

func _take_shot():
	if DisplayServer.get_name() == "headless":
		return
	var dir_path = String(opts["shot_dir"])
	DirAccess.make_dir_recursive_absolute(dir_path)
	var img = get_viewport().get_texture().get_image()
	shot_index += 1
	var path = "%s/%s_%07.2f_%02d.png" % [dir_path, opts["char"], elapsed, shot_index]
	img.save_png(path)
	print("[autoplay] shot ", path)

func _finish(reason: String):
	print("[autoplay] END reason=%s t=%.1f lv=%d kills=%d levelups=%d max_enemies=%d min_fps=%d ending=%s" % [
		reason, elapsed, player.character_level, player.kill_count, levelups, max_enemies, min_fps,
		player.get_node("UI_Layer/BaseUI").ending_pause_flag])
	# 노드 누수 확인용: 게임 루트 자식 종류별 개수
	var counts = {}
	for child in game.get_children():
		var key = child.get_class() + ":" + String(child.name).rstrip("0123456789@")
		counts[key] = counts.get(key, 0) + 1
	for child in game.get_node("EnemySpwaner").get_children():
		var key = "spawner/" + child.get_class() + ":" + String(child.name).rstrip("0123456789@")
		counts[key] = counts.get(key, 0) + 1
	print("[autoplay] nodes ", counts)
	if "weapons" in player:
		var build = {}
		for id in player.weapons.keys():
			build[id] = player.weapons[id].level
		print("[autoplay] build weapons=", build, " passives=", player.passives)
		print("[autoplay] damage ", RunStats.damage_by_source)
		var evolved = player.weapons.keys().filter(func(k): return player.weapons[k].evolved)
		print("[autoplay] chests=%d evolved=%s" % [chests, evolved])
	set_process(false)
	get_tree().quit()
