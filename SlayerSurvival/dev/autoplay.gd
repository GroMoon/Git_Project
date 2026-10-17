extends Node

## 자동 플레이 스모크 테스트 하네스
## 사용법 (프로젝트 폴더에서):
##   Godot --headless --fixed-fps 60 res://dev/autoplay.tscn -- --char=warrior --map=cave --seconds=180
##   (스크린샷이 필요하면 --headless 제외) -- --shots=10,60,120 --shot_dir=/tmp/shots
## 옵션
##   --char=warrior|king|wizard   --map=cave|dungeon   --seconds=게임 내 초
##   --log_every=로그 간격(초)     --shots=스크린샷 찍을 게임 시간(초, 쉼표 구분)
##   --shot_dir=스크린샷 저장 경로  --god=1 (무적)    --start_minute=시작 분(디렉터 테스트용)

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
	print("[autoplay] start char=%s map=%s seconds=%s" % [opts["char"], opts["map"], opts["seconds"]])

func _process(delta):
	if player == null or not is_instance_valid(player):
		return
	var base_ui = player.get_node("UI_Layer/BaseUI")

	_handle_blocking_ui(base_ui)

	if get_tree().paused:
		return

	elapsed += delta
	if opts["god"] == "1":
		player.current_hp = player.max_hp
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

	if player.is_dead or base_ui.death_pause_flag:
		_finish("player died")
	elif elapsed >= float(opts["seconds"]):
		_finish("time limit")

# 레벨업/다이얼로그 등 입력이 필요한 UI 자동 처리
func _handle_blocking_ui(base_ui):
	if base_ui.lvlup_pause_flag:
		var select_ui = player.get_node("UI_Layer/SelectUI")
		if select_ui.has_method("autopick"):
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
	if crowd >= 3:
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
	var path = "%s/%s_%07.2f.png" % [dir_path, opts["char"], elapsed]
	img.save_png(path)
	print("[autoplay] shot ", path)

func _finish(reason: String):
	print("[autoplay] END reason=%s t=%.1f lv=%d kills=%d levelups=%d max_enemies=%d min_fps=%d" % [
		reason, elapsed, player.character_level, player.kill_count, levelups, max_enemies, min_fps])
	set_process(false)
	get_tree().quit()
