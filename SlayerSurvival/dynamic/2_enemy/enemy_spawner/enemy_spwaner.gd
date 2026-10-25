extends Node2D

## 웨이브 디렉터 (기존 타이머 스포너 대체)
## - 시간(분)에 따라 초당 스폰 수 / 동시 최대 수 / 적 체력이 증가
## - 화면 밖 사각 링에서 스폰, 너무 멀어진 적은 화면 밖 가까운 곳으로 재배치
## - 이벤트: 대량 스폰, 박쥐 떼 돌진(직선), 포위 링, 엘리트, 10분 보스
## - 무한 모드 (RunMode): 보스를 잡아도 계속. 이전 웨이브를 잡은 뒤 10분마다 보스 웨이브(n번째 = n마리, 최대 3),
##   10분 이후 이벤트 반복(규모 증가), 엘리트 계속 등장, 적 이동 속도 증가

const MONSTER = 0
const ELITE   = 1
const BOSS    = 2

const MAP_LIMIT       = 1500.0	# 맵 경계 (스폰 좌표 제한)
const SPAWN_MARGIN    = 70.0	# 화면 바깥 여유
const MAX_ENEMIES     = 260		# 동시 최대 적 수 (성능 한도)
const RECYCLE_FACTOR  = 1.7		# 화면 반대각선 * 이 값보다 멀면 재배치
const BOSS_MINUTE     = 10
const MAX_BOSSES      = 3		# 무한 모드 한 웨이브 최대 보스 수
const BOSS_SPLIT_HP   = [1.0, 0.7, 0.6]	# 보스가 여러 마리일 때 한 마리당 체력 비율
const MIN_BOSS_GAP    = 2.0		# 무한 모드: 웨이브를 늦게 잡아도 다음 보스까지 최소 2분 쉬는 시간

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
var boss_nodes: Array = []				# 살아 있는 보스 (현재 웨이브)
var boss_wave := 0						# 지금까지 등장한 보스 웨이브 수
var next_boss_time := float(BOSS_MINUTE)	# 다음 보스 웨이브 시각(분)

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
	if not boss_nodes.is_empty():
		rate *= 0.35		# 보스전에는 잡몹을 줄임
	spawn_budget = min(spawn_budget + rate * delta, 20.0 if RunMode.is_endless() else 10.0)
	while spawn_budget >= 1.0:
		spawn_budget -= 1.0
		if alive < max_alive(t):
			spawn_enemy(pick_enemy(t), MONSTER)
			alive += 1

	# 이벤트 (무한 모드 한계 돌파 이후에는 10분 단위로 반복, 회차마다 규모 +50%)
	var loops = int(t / BOSS_MINUTE) if RunMode.overcap_unlocked() else 0
	for loop in range(loops + 1):
		for ev in events:
			var ev_time = ev[0] + loop * BOSS_MINUTE
			var key = str(ev_time) + ev[1]
			if t >= ev_time and not events_done.has(key):
				events_done[key] = true
				# 반복 회차에서 이미 지나간 이벤트(보스를 늦게 잡은 경우)는 한꺼번에 몰리지 않게 건너뜀
				if loop == 0 or t - ev_time <= 0.5:
					run_event(ev[1], ev[2], 1.0 + 0.5 * loop)

	# 엘리트 (1분마다, 사이클이 돌수록 한 번에 나오는 수가 늘어남). 보스전 중에는 쉼, 무한 모드는 10분 이후에도 계속
	if t >= next_elite_time:
		next_elite_time += 1.0
		if boss_nodes.is_empty() and (t < BOSS_MINUTE or RunMode.is_endless()):
			spawn_elite_wave()

	# 멀어진 적 재배치 (1초마다)
	recycle_timer -= delta
	if recycle_timer <= 0.0:
		recycle_timer = 1.0
		recycle_far_enemies()

	# 보스 스폰 (클래식: 10:00 한 번 / 무한: 이전 웨이브를 잡은 뒤 next_boss_time 마다)
	if t >= next_boss_time and boss_nodes.is_empty() and (boss_wave == 0 or RunMode.is_endless()):
		spawn_boss_wave()

# ================= 보스 =================
# n번째 웨이브는 보스 n마리 (최대 3). 맵 보스부터, 두 번째 마리는 다른 맵의 보스
func spawn_boss_wave():
	boss_wave += 1
	boss_spawn_flag = true
	next_boss_time = INF
	if get_parent().instance_map:
		map_name = get_parent().instance_map.name
	# 맵에 따른 보스 선택
	var main_boss = fire_worm if map_name == "cave" else bring_of_death
	var other_boss = bring_of_death if main_boss == fire_worm else fire_worm
	var count = mini(boss_wave, MAX_BOSSES)
	for i in count:
		var boss_node = spawn_enemy(main_boss if i % 2 == 0 else other_boss, BOSS)
		if boss_node == null:
			continue
		if count > 1:
			boss_node.health *= BOSS_SPLIT_HP[count - 1]
			boss_node.max_health = boss_node.health
		boss_nodes.append(boss_node)
	if not boss_nodes.is_empty() and base_ui.boss_bar:
		base_ui.boss_bar.track(boss_nodes[0])
	GameFeel.shake(0.6)
	GameFeel.flash_screen(Color(0.6, 0.0, 0.0, 0.35), 0.8)
	if RunMode.is_endless() and boss_wave > 1:
		base_ui.show_banner(GameUI.t("보스 웨이브 %d", "BOSS WAVE %d") % boss_wave,
			GameUI.t("보스 %d마리 출현!", "%d bosses incoming!") % count, GameUI.RED, 2.5)

# 보스 처치 (무한 모드에서만 BaseUI 를 통해 호출). 웨이브의 보스를 모두 잡으면 다음 단계
func on_boss_defeated(boss):
	RunMode.bosses_killed += 1
	boss_nodes.erase(boss)
	boss_nodes = boss_nodes.filter(func(b): return is_instance_valid(b) and not b.is_dead)
	if not boss_nodes.is_empty():
		if base_ui.boss_bar:
			base_ui.boss_bar.track(boss_nodes[0])		# 남은 보스를 체력바로
		return
	var first_clear = RunMode.waves_cleared == 0
	RunMode.waves_cleared += 1
	var t = minute + sec / 60.0
	next_boss_time = max(float(BOSS_MINUTE * (RunMode.waves_cleared + 1)), t + MIN_BOSS_GAP)
	# 웨이브 보상: 보상 5개 보물상자
	var chest = ChestPickup.create()
	chest.fixed_count = 5
	chest.global_position = clamp_to_map(boss.global_position)
	call_deferred("add_child", chest)
	var next_count = mini(boss_wave + 1, MAX_BOSSES)
	var next_text = GameUI.t("다음 보스 웨이브 %s  ·  보스 %d마리", "Next boss wave %s  ·  %d bosses") % [GameUI.format_time(next_boss_time * 60.0), next_count]
	if first_clear:
		base_ui.show_banner(GameUI.t("★ 한계 돌파 ★", "★ LIMIT BREAK ★"),
			GameUI.t("이제 최대 레벨을 넘어 강화할 수 있습니다", "Upgrades can now go beyond MAX") + "\n" + next_text, GameUI.STAR, 4.0)
	else:
		base_ui.show_banner(GameUI.t("%d단계 돌파!", "STAGE %d CLEAR!") % RunMode.waves_cleared, next_text, GameUI.STAR, 3.0)

# ================= 엘리트 =================
# 엘리트 4종(플라잉 아이 → 스켈레톤 → 머쉬룸 → 고블린)이 한 사이클
# - 1번째 사이클 (0:45 ~ 3:45): 순서대로 1마리씩
# - 2번째 사이클 (4:45 ~ 7:45): 서로 다른 종류 무작위 2마리 동시
# - 3번째 사이클 (8:45 ~ 9:45): 서로 다른 종류 무작위 3마리 동시 (10:00 보스 전까지)
func spawn_elite_wave():
	var cycle = int(floor(elite_index / float(elite_cycle.size())))
	var count = mini(cycle + 1, elite_cycle.size())
	var picks: Array
	if count == 1:
		picks = [elite_cycle[elite_index % elite_cycle.size()]]
	else:
		picks = elite_cycle.duplicate()
		picks.shuffle()
		picks = picks.slice(0, count)
	elite_index += 1
	for scene in picks:
		spawn_enemy(scene, ELITE)		# 위치는 각자 화면 밖 무작위 (여러 방향에서 동시에 옴)
	return picks

# ================= 난이도 곡선 =================
# 초당 스폰 수 (무한 모드 10분 이후 1분마다 +5%, 최대 2배: 한계 돌파로 강해진 빌드에 맞춰 화면을 채움)
func spawn_rate(t: float) -> float:
	return (0.9 + 0.95 * t) * endless_mult(t, 0.05, 2.0)

# 동시 최대 적 수
func max_alive(t: float) -> int:
	return mini(int(40 + 22 * t), MAX_ENEMIES)

# 적 체력 배율 (무한 모드 10분 이후 1분마다 +6% 추가, 제한 없음)
func hp_mult(t: float) -> float:
	return (1.0 + 0.12 * t + 0.025 * t * t) * endless_mult(t, 0.06, INF)

# 무한 모드 10분 이후 추가 배율: 1 + per_minute * (t - 10), 최대 cap. 클래식 / 10분 전은 1
func endless_mult(t: float, per_minute: float, cap: float) -> float:
	if not RunMode.is_endless() or t <= BOSS_MINUTE:
		return 1.0
	return min(1.0 + per_minute * (t - BOSS_MINUTE), cap)

# 적 공격력 배율
func damage_mult(t: float) -> float:
	return 1.0 + 0.06 * t

# 적 이동 속도 배율 (무한 모드 10분 이후 1분마다 +2%, 최대 +40%)
func speed_mult(t: float) -> float:
	return endless_mult(t, 0.02, 1.4)

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
func run_event(kind: String, args: Array, count_mult: float = 1.0):
	var scene = scene_by_name(args[0])
	var count: int = int(args[1] * count_mult)
	match kind:
		"mass":
			for i in count:
				spawn_enemy(scene, MONSTER)
		"swarm":
			spawn_swarm(scene, count)
		"ring":
			spawn_ring(scene, count)

# 박쥐 떼: 화면 한쪽에서 몰려와 플레이어에게 빠르게 달려듦
func spawn_swarm(scene: PackedScene, count: int):
	var half = visible_half_extents()
	var dir = Vector2.RIGHT.rotated(randf() * TAU)
	var center = player.global_position - dir * (half.length() + SPAWN_MARGIN)
	var side = dir.orthogonal()
	for i in count:
		var offset = side * randf_range(-160, 160) - dir * randf_range(0, 220)
		var e = spawn_enemy(scene, MONSTER, clamp_to_map(center + offset), false)
		if e:
			e.move_speed *= 1.35		# 일반 개체보다 빠르게 덮쳐옴

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
	if monster_type != BOSS and "move_speed" in enemy_instance:
		enemy_instance.move_speed *= speed_mult(t)
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
