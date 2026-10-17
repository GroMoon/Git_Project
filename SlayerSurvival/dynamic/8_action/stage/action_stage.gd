extends Node2D
## 던전 진행 : 방(Room)마다 웨이브를 처치 → 포털로 다음 방 → 마지막 방 보스 → 결과(랭크/골드)
##   바닥 영역(깊이 이동 범위) : FLOOR_TOP ~ FLOOR_BOTTOM

const ActionInput = preload("res://dynamic/8_action/core/action_input.gd")
const CombatFX    = preload("res://dynamic/8_action/core/combat_fx.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")
const Backdrop    = preload("res://dynamic/8_action/stage/dungeon_backdrop.gd")
const DungeonData = preload("res://dynamic/8_action/stage/dungeon_data.gd")
const ExitPortal  = preload("res://dynamic/8_action/stage/exit_portal.gd")
const ActionHUD   = preload("res://dynamic/8_action/ui/action_hud.gd")
const Warrior     = preload("res://dynamic/8_action/player/warrior_action.gd")
const Enemy       = preload("res://dynamic/8_action/enemy/action_enemy.gd")
const BossEnemy   = preload("res://dynamic/8_action/enemy/boss_enemy.gd")
const AllyMonster = preload("res://dynamic/8_action/enemy/ally_monster.gd")

const MENU_SCENE    := "res://dynamic/5_title_screen/menu.tscn"
const FLOOR_TOP     := 440.0
const FLOOR_BOTTOM  := 690.0
const SIDE_PADDING  := 50.0
const MAX_ATTACKERS := 2		# 동시에 공격할 수 있는 적 수
const NEXT_WAVE_DELAY := 1.2
const PLAYER_ENTRY  := Vector2(220, 560)
const MAX_PARTY     := 4		# 동료 최대 수 (종류별 1마리)

## 테스트에서 false로 두면 결과 골드를 세이브 파일에 저장하지 않음
var save_rewards := true
## 쓰러뜨린 몬스터가 동료가 될 확률 (일반 / 엘리트)
var recruit_chance := 0.12
var elite_recruit_chance := 0.4

var player : Node2D
var actors : Node2D
var fx     : Node2D
var camera : Camera2D
var hud    : CanvasLayer
var backdrop : Node2D
var portal : Node2D

var room_width := 2200.0
var room_index := 0
var wave_index := 0
var kills := 0
var gold  := 0
var elapsed := 0.0
var boss : Node2D = null
var party : Array = []		# 몬스터 동료

var _attack_tokens: Array = []
var _enemy_count := 0
var _next_wave_timer := -1.0
var _room_cleared := false
var _transitioning := false
var _game_over := false
var _dungeon_clear := false

func _ready():
	ActionInput.ensure_actions()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Engine.time_scale = 1.0
	Audiomanager.play_music_for_scene("ingame")

	backdrop = Backdrop.new()
	backdrop.z_index = -10
	add_child(backdrop)

	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)

	fx = CombatFX.new()
	fx.name = "CombatFX"
	add_child(fx)

	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	camera.make_current()
	fx.camera = camera

	player = Warrior.new()
	player.name = "Player"
	player.stage = self
	player.position = PLAYER_ENTRY
	actors.add_child(player)
	player.died.connect(_on_player_died)

	portal = ExitPortal.new()
	actors.add_child(portal)

	hud = ActionHUD.new()
	add_child(hud)
	hud.bind(player, fx)
	hud.setup_minimap(DungeonData.ROOMS)

	load_room(0, false)

func _exit_tree():
	Engine.time_scale = 1.0
	SpriteSheet.clear_cache()

func _process(delta):
	_follow_camera(delta)
	if Input.is_action_just_pressed("act_menu"):
		get_tree().change_scene_to_file(MENU_SCENE)
		return
	if (_game_over or _dungeon_clear) and Input.is_action_just_pressed("act_restart"):
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("act_respawn"):		# 디버그 : 현재 웨이브 다시 소환
		start_wave(wave_index)
	elif Input.is_action_just_pressed("act_debug_skip") and not _transitioning:	# 디버그 : 다음 방
		load_room(mini(room_index + 1, DungeonData.ROOMS.size() - 1))

	if not _game_over and not _dungeon_clear:
		elapsed += delta
	if _next_wave_timer > 0.0:
		_next_wave_timer -= delta
		if _next_wave_timer <= 0.0:
			start_wave(wave_index + 1)
	if _room_cleared and not _transitioning and portal.is_player_inside(player):
		load_room(room_index + 1)

func _follow_camera(delta: float):
	if player == null:
		return
	var half_w := 640.0
	var target_x := clampf(player.position.x + player.facing * 90.0, half_w, maxf(half_w, room_width - half_w))
	camera.position.x = lerpf(camera.position.x, target_x, 1.0 - exp(-5.0 * delta))

## 바닥 영역 안으로 위치 제한
func clamp_to_floor(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, SIDE_PADDING, room_width - SIDE_PADDING),
		clampf(pos.y, FLOOR_TOP, FLOOR_BOTTOM))

# ───────────────────────────── 방 / 웨이브 ─────────────────────────────

func load_room(index: int, with_fade := true):
	_transitioning = true
	if with_fade:
		await hud.fade(1.0, 0.3)
	room_index = index
	var room: Dictionary = DungeonData.ROOMS[index]
	room_width = room.width
	backdrop.room_width = room_width
	backdrop.queue_redraw()
	_clear_room_objects()
	player.position = PLAYER_ENTRY
	player.facing = 1
	player.reset_pose()
	for ally in party:
		ally.position = clamp_to_floor(PLAYER_ENTRY + Vector2(ally.slot_offset.x, ally.slot_offset.y))
		ally.state = 0
	camera.position.x = 640.0
	_room_cleared = false
	portal.position = Vector2(room_width - 170.0, FLOOR_TOP + 25.0)
	portal.set_open(false)
	hud.set_room(index)
	hud.show_go_arrow(false)
	start_wave(0)
	if with_fade:
		await hud.fade(0.0, 0.3)
	hud.show_banner(("BOSS - " if room.get("boss", false) else "") + room.name)
	_transitioning = false

func _clear_room_objects():
	for node in actors.get_children():
		if node != player and node != portal and not party.has(node):
			node.queue_free()
	_attack_tokens.clear()
	_enemy_count = 0
	_next_wave_timer = -1.0
	boss = null

func start_wave(index: int):
	var waves: Array = DungeonData.ROOMS[room_index].waves
	wave_index = clampi(index, 0, waves.size() - 1)
	_next_wave_timer = -1.0
	for entry in waves[wave_index]:
		var pos := Vector2(entry[1], entry[2])
		# 플레이어 바로 옆에 생기지 않도록
		if absf(pos.x - player.position.x) < 420.0:
			pos.x = player.position.x + (420.0 if pos.x >= player.position.x else -420.0)
			if pos.x > room_width - SIDE_PADDING or pos.x < SIDE_PADDING:
				pos.x = player.position.x - (pos.x - player.position.x)
		spawn_enemy(entry[0], pos, entry.size() > 3 and entry[3])

func spawn_enemy(kind: String, pos: Vector2, elite := false) -> Node2D:
	var is_boss := kind == "bringer"
	var enemy = BossEnemy.new() if is_boss else Enemy.new()
	enemy.setup(kind, elite)
	enemy.stage = self
	enemy.position = clamp_to_floor(pos)
	enemy.facing = 1 if pos.x < player.position.x else -1
	actors.add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	_enemy_count += 1
	hud.set_enemy_count(_enemy_count)
	if is_boss:
		boss = enemy
		hud.set_boss(enemy)
	return enemy

func _on_enemy_died(enemy: Node):
	kills += 1
	gold += int(enemy.gold * (1.0 + player.gold_bonus))
	_enemy_count = maxi(0, _enemy_count - 1)
	hud.set_enemy_count(_enemy_count)
	if enemy == boss:
		_on_boss_defeated()
		return
	_try_recruit(enemy)
	if _enemy_count > 0 or _game_over:
		return
	var waves: Array = DungeonData.ROOMS[room_index].waves
	if wave_index + 1 < waves.size():
		_next_wave_timer = NEXT_WAVE_DELAY
	else:
		_on_room_cleared()

## 노션 컨셉 : 쓰러뜨린 몬스터가 확률로 동료가 됨 (종류별 1마리, 최대 4)
func _try_recruit(enemy: Node):
	if party.size() >= MAX_PARTY or party.any(func(a): return a.kind == enemy.kind):
		return
	if randf() < (elite_recruit_chance if enemy.elite else recruit_chance):
		recruit(enemy.kind, enemy.position)

func recruit(kind: String, pos: Vector2) -> Node2D:
	var ally := AllyMonster.new()
	ally.setup(kind, party.size())
	ally.stage = self
	ally.position = clamp_to_floor(pos)
	actors.add_child(ally)
	party.append(ally)
	ally.flash(0.3, Color(0.5, 1.0, 0.6))
	fx.spawn_shockwave(ally.position, 140.0, Color(0.5, 1.0, 0.6))
	fx.spawn_text("동료 획득!", ally.position + Vector2(0, -150), Color(0.55, 1.0, 0.6), 26)
	hud.show_banner("%s 이(가) 동료가 되었다!" % ally.display_name)
	hud.set_party(party.map(func(a): return a.display_name))
	return ally

func _on_room_cleared():
	_room_cleared = true
	hud.mark_room_cleared(room_index)
	if room_index + 1 < DungeonData.ROOMS.size():
		portal.set_open(true)
		hud.show_banner("ROOM CLEAR")
		hud.show_go_arrow(true)

func _on_boss_defeated():
	hud.mark_room_cleared(room_index)
	# 슬로우 모션이 끝난 뒤 결과 (실시간 기준 타이머)
	await get_tree().create_timer(2.4, true, false, true).timeout
	_show_result()

func _show_result():
	if _dungeon_clear or _game_over:
		return
	_dungeon_clear = true
	var rank := DungeonData.calc_rank(elapsed, fx.max_combo, player.hits_taken)
	var rank_bonus: float = {"SSS": 2.0, "SS": 1.7, "S": 1.5, "A": 1.3, "B": 1.15}.get(rank, 1.0)
	var total_gold := int(gold * rank_bonus)
	if save_rewards and Global.character_data.has("GOLD"):
		Global.character_data["GOLD"]["gold"] += total_gold
		Global.save_character_data()
	hud.show_result({
		"dungeon": DungeonData.DUNGEON_NAME, "rank": rank, "time": elapsed,
		"max_combo": fx.max_combo, "total_hits": fx.total_hits, "hits_taken": player.hits_taken,
		"kills": kills, "gold": total_gold,
	})

# ───────────────────────────── 공격 토큰 ─────────────────────────────

## 동시 공격 인원 제한 (둘러싸여 한꺼번에 맞는 상황 방지)
func request_attack_token(enemy: Node) -> bool:
	if enemy in _attack_tokens:
		return true
	_attack_tokens = _attack_tokens.filter(func(e): return is_instance_valid(e))
	if _attack_tokens.size() >= MAX_ATTACKERS:
		return false
	_attack_tokens.append(enemy)
	return true

func can_take_attack_token(enemy: Node) -> bool:
	return enemy in _attack_tokens or _attack_tokens.size() < MAX_ATTACKERS

func release_attack_token(enemy: Node):
	_attack_tokens.erase(enemy)

func _on_player_died(_player: Node):
	_game_over = true
	hud.show_center("GAME OVER\nR : 다시 도전    ESC : 메뉴")
