extends Node2D

## 웨이브 디렉터 (기존 타이머 스포너 대체)
## - 시간(분)에 따라 초당 스폰 수 / 동시 최대 수 / 적 체력이 증가
## - 화면 밖 사각 링에서 스폰, 너무 멀어진 적은 화면 밖 가까운 곳으로 재배치
## - 이벤트: 대량 스폰, 박쥐 떼 돌진(직선), 포위 링, 엘리트, 10분 보스

const MONSTER = 0
const ELITE   = 1
const BOSS    = 2

const MAP_LIMIT       = 1500.0	# 맵 경계 (스폰 좌표 제한)
const SPAWN_MARGIN    = 70.0	# 화면 바깥 여유
const MAX_ENEMIES     = 260		# 동시 최대 적 수 (성능 한도)
const RECYCLE_FACTOR  = 1.7		# 화면 반대각선 * 이 값보다 멀면 재배치
const BOSS_MINUTE     = 10

var player
var base_ui
var minute
var sec
var map_name = ""

var spawn_budget := 0.0			# 누적된 스폰 가능 수
var recycle_timer := 0.0
var events_done := {}			# 실행된 이벤트 키
var next_elite_time := 0.75		# 다음 엘리트 등장 시각(분)
var elite_index := 0
# 보스 스폰 여부 플래그
var boss_spawn_flag = false

# 일반 몬스터
var skeleton  = preload("res://dynamic/2_enemy/Skeleton/skeleton.tscn")
var mushroom  = preload("res://dynamic/2_enemy/Mushroom/mushroom.tscn")
var goblin    = preload("res://dynamic/2_enemy/Goblin/goblin.tscn")
var flyingeye = preload("res://dynamic/2_enemy/FlyingEye/flyingeye.tscn")
# 엘리트 몬스터
var flyingeye_elite = preload("res://dynamic/2_enemy/FlyingEye/Elite/flyingeye_elite.tscn")
var skeleton_elite  = preload("res://dynamic/2_enemy/Skeleton/Elite/skeleton_elite.tscn")
var mushroom_elite  = preload("res://dynamic/2_enemy/Mushroom/Elite/mushroom_elite.tscn")
var goblin_elite    = preload("res://dynamic/2_enemy/Goblin/Elite/goblin_elite.tscn")
# 보스 몬스터
var fire_worm      = preload("res://dynamic/2_enemy/Boss_FireWorm/fireworm.tscn")
var bring_of_death = preload("res://dynamic/2_enemy/Boss_BringOfDeath/bringofdeath.tscn")

# 시간대별 등장 몬스터 가중치 [시작 분, {씬: 가중치}]
var spawn_table = []
# 이벤트 [분, 종류, 인자]
var events = [
	[0.5,  "mass",  ["flyingeye", 10]],
	[1.5,  "swarm", ["flyingeye", 22]],
	[2.5,  "ring",  ["skeleton", 22]],
	[3.5,  "mass",  ["skeleton", 18]],
	[4.25, "swarm", ["flyingeye", 30]],
	[5.5,  "ring",  ["mushroom", 26]],
	[6.5,  "mass",  ["mushroom", 22]],
	[7.25, "swarm", ["flyingeye", 40]],
	[8.25, "ring",  ["goblin", 30]],
	[9.25, "mass",  ["goblin", 26]],
]
# 엘리트 등장 순서
var elite_cycle = []

func _ready():
	spawn_table = [
		[0.0, {flyingeye: 100}],
		[1.0, {flyingeye: 60, skeleton: 40}],
		[3.0, {flyingeye: 30, skeleton: 50, mushroom: 20}],
		[5.0, {flyingeye: 15, skeleton: 35, mushroom: 40, goblin: 10}],
		[8.0, {flyingeye: 10, skeleton: 25, mushroom: 30, goblin: 35}],
	]
	elite_cycle = [flyingeye_elite, skeleton_elite, mushroom_elite, goblin_elite]

func _process(delta):
	player = get_parent().get_node_or_null("player")
	if player == null:
		return
	base_ui = player.get_node("UI_Layer/BaseUI")
	minute  = base_ui.minute
	sec     = base_ui.sec
	var t = minute + sec / 60.0

	# 일반 스폰 (초당 스폰 수만큼 예산 누적)
	var alive = get_tree().get_nodes_in_group("enemy").size()
	var rate = spawn_rate(t)
	if t >= BOSS_MINUTE:
		rate *= 0.35		# 보스전에는 잡몹을 줄임
	spawn_budget = min(spawn_budget + rate * delta, 10.0)
	while spawn_budget >= 1.0:
		spawn_budget -= 1.0
		if alive < max_alive(t):
			spawn_enemy(pick_enemy(t), MONSTER)
			alive += 1

	# 이벤트
	for ev in events:
		var key = str(ev[0]) + ev[1]
		if t >= ev[0] and not events_done.has(key):
			events_done[key] = true
			run_event(ev[1], ev[2])

	# 엘리트
	if t >= next_elite_time and t < BOSS_MINUTE:
		next_elite_time += 1.0
		var elite = elite_cycle[elite_index % elite_cycle.size()]
		elite_index += 1
		spawn_enemy(elite, ELITE)

	# 멀어진 적 재배치 (1초마다)
	recycle_timer -= delta
	if recycle_timer <= 0.0:
		recycle_timer = 1.0
		recycle_far_enemies()

	# 보스 스폰
	if (!boss_spawn_flag) && (minute >= BOSS_MINUTE):
		if get_parent().instance_map:
			map_name = get_parent().instance_map.name
		var boss
		# 맵에 따른 보스 선택
		match map_name:
			"cave":
				boss = fire_worm
			"dungeon_B1F":
				boss = bring_of_death
			_:
				boss = bring_of_death
		spawn_enemy(boss, BOSS)
		boss_spawn_flag = true
		GameFeel.shake(0.6)
		GameFeel.flash_screen(Color(0.6, 0.0, 0.0, 0.35), 0.8)

# ================= 난이도 곡선 =================
# 초당 스폰 수
func spawn_rate(t: float) -> float:
	return 0.9 + 0.95 * t

# 동시 최대 적 수
func max_alive(t: float) -> int:
	return mini(int(40 + 22 * t), MAX_ENEMIES)

# 적 체력 배율
func hp_mult(t: float) -> float:
	return 1.0 + 0.12 * t + 0.025 * t * t

# 적 공격력 배율
func damage_mult(t: float) -> float:
	return 1.0 + 0.06 * t

func pick_enemy(t: float) -> PackedScene:
	var weights = spawn_table[0][1]
	for row in spawn_table:
		if t >= row[0]:
			weights = row[1]
	var total = 0
	for k in weights:
		total += weights[k]
	var r = randf() * total
	for k in weights:
		r -= weights[k]
		if r <= 0.0:
			return k
	return weights.keys()[0]

func scene_by_name(enemy_name: String) -> PackedScene:
	match enemy_name:
		"skeleton":
			return skeleton
		"mushroom":
			return mushroom
		"goblin":
			return goblin
	return flyingeye

# ================= 이벤트 =================
func run_event(kind: String, args: Array):
	var scene = scene_by_name(args[0])
	var count: int = args[1]
	match kind:
		"mass":
			for i in count:
				spawn_enemy(scene, MONSTER)
		"swarm":
			spawn_swarm(scene, count)
		"ring":
			spawn_ring(scene, count)

# 박쥐 떼: 화면 한쪽에서 반대쪽으로 직선 돌진
func spawn_swarm(scene: PackedScene, count: int):
	var half = visible_half_extents()
	var dir = Vector2.RIGHT.rotated(randf() * TAU)
	var center = player.global_position - dir * (half.length() + SPAWN_MARGIN)
	var side = dir.orthogonal()
	for i in count:
		var offset = side * randf_range(-160, 160) - dir * randf_range(0, 220)
		var e = spawn_enemy(scene, MONSTER, clamp_to_map(center + offset), false)
		if e:
			e.move_override = dir * e.move_speed * 1.8
			e.despawn_far = true

# 포위 링: 플레이어를 둘러싸고 조여옴
func spawn_ring(scene: PackedScene, count: int):
	var half = visible_half_extents()
	var radius = half.length() * 0.85
	for i in count:
		var pos = player.global_position + Vector2.RIGHT.rotated(TAU * i / count) * radius
		spawn_enemy(scene, MONSTER, clamp_to_map(pos), false)

# ================= 스폰 =================
func visible_half_extents() -> Vector2:
	var size = get_viewport().get_visible_rect().size
	var cam = get_viewport().get_camera_2d()
	var zoom = cam.zoom if cam else Vector2.ONE
	return size / zoom / 2.0

func view_center() -> Vector2:
	var cam = get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam else player.global_position

# 화면 바깥 사각 링 위의 임의의 점
func random_offscreen_position() -> Vector2:
	var half = visible_half_extents() + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var perimeter = 4.0 * (half.x + half.y)
	var r = randf() * perimeter
	var local: Vector2
	if r < 2.0 * half.x:
		local = Vector2(r - half.x, -half.y)
	elif r < 2.0 * half.x + 2.0 * half.y:
		local = Vector2(half.x, r - 2.0 * half.x - half.y)
	elif r < 4.0 * half.x + 2.0 * half.y:
		local = Vector2(r - 3.0 * half.x - 2.0 * half.y, half.y)
	else:
		local = Vector2(-half.x, r - 4.0 * half.x - 3.0 * half.y)
	return clamp_to_map(view_center() + local)

func clamp_to_map(pos: Vector2) -> Vector2:
	return Vector2(clamp(pos.x, -MAP_LIMIT, MAP_LIMIT), clamp(pos.y, -MAP_LIMIT, MAP_LIMIT))

func spawn_enemy(enemy_tscn, monster_type: int, fixed_pos = null, check_clear := true) -> Node:
	if enemy_tscn == null:
		return null
	var enemy_instance = enemy_tscn.instantiate()

	# 몬스터 타입에 따른 스케일 설정
	match monster_type:
		BOSS:
			enemy_instance.scale = Vector2(3, 3)
		ELITE:
			enemy_instance.scale = Vector2(1.5, 1.5)

	var spawn_pos: Vector2 = fixed_pos if fixed_pos != null else random_offscreen_position()
	if fixed_pos == null or check_clear:
		# 최대 10번 시도해서 충돌 없는 위치 찾기
		var attempts := 0
		while attempts < 10 and not is_spawn_position_clear(spawn_pos, enemy_instance):
			attempts += 1
			spawn_pos = random_offscreen_position()

	# 최종 위치 적용 후 씬에 추가
	enemy_instance.global_position = spawn_pos
	add_child(enemy_instance)
	# 시간에 따른 강화
	var t = minute + sec / 60.0 if minute != null else 0.0
	if enemy_instance.has_method("apply_scaling"):
		enemy_instance.apply_scaling(hp_mult(t), damage_mult(t))
	return enemy_instance

# 너무 멀어진 적은 화면 밖 가까운 곳으로 재배치 (뱀서 방식)
func recycle_far_enemies():
	var limit = visible_half_extents().length() * RECYCLE_FACTOR
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not ("move_override" in enemy):
			continue		# 보스 등은 제외
		if enemy.global_position.distance_to(player.global_position) > limit:
			if enemy.despawn_far:
				enemy.queue_free()
			else:
				enemy.global_position = random_offscreen_position()

# 스폰 위치 충돌 검사 함수
func is_spawn_position_clear(position: Vector2, enemy_instance: Node2D) -> bool:
	var shape = enemy_instance.get_node_or_null("CollisionShape2D")		# enemy 노드의 콜리젼 모양 가져오기
	if shape == null:
		return true
	var query = PhysicsShapeQueryParameters2D.new()						# 검사용 query 생성
	query.shape = shape.shape											# query 기준 -> 생성된 enemy의 Shape2D 리소스
	query.transform = Transform2D.IDENTITY.translated(position)			# query의 포지션을 생성된 enemy위치로 이동
	# 필요한 충돌 레이어만 마스크로 설정
	query.collision_mask = 1 											# cave의 경우 layer 1번인 (lava), dungeon의 경우 레이어 1번이 없음
	var space_state = get_world_2d().direct_space_state					# 2D World 받아오며 객체 확인
	var result = space_state.intersect_shape(query, 1)					# 가져온 Shape2D 리소스와 충돌하는 갯수(인자 1개) 확인 / 0개면 스폰 1이면 재시도
	return result.is_empty()
