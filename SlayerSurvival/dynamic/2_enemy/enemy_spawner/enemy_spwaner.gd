extends Node2D

const MONSTER = 0
const ELITE   = 1
const BOSS    = 2

var player
var base_ui
var minute
var sec
var map_name = ""

# 적 대량 스폰 플래그
var has_spawned_flyingeye_mass = false
var has_spawned_skeleton_mass  = false
var has_spawned_mushroom_mass  = false
# 엘리트 스폰 여부 플래그
var has_spawned_flyingeye_elite = false
var has_spawned_skeleton_elite  = false
var has_spawned_mushroom_elite  = false
var has_spawned_goblin_elite    = false
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

func _ready():
	pass

func _process(_delta):
	player  = get_parent().get_node_or_null("player")
	base_ui = player.get_node("UI_Layer/BaseUI")
	minute  = base_ui.minute
	sec     = base_ui.sec

	# 몬스터 등장 구간 제어
	# 0 ~ 1분: flyingeye만 소환
	if minute == 0:
		$FlyingEyeTimer.set_paused(false)
		$FlyingEyeTimer.wait_time = 1.6
		$SkeletonTimer.set_paused(true)
		$MushroomTimer.set_paused(true)
		$GoblinTimer.set_paused(true)
		
		# 대량 스폰 알고리즘
		if sec > 30 and not has_spawned_flyingeye_mass:
			for i in range(10):
				print("flyingeye 대량 스폰")
				spawn_enemy(flyingeye, MONSTER)
			has_spawned_flyingeye_mass = true

		# flyingeye 엘리트 몬스터 소환
		if sec > 45 and not has_spawned_flyingeye_elite:
			spawn_enemy(flyingeye_elite, ELITE)
			has_spawned_flyingeye_elite = true	

	# 1 ~ 5분: flyingeye와 skeleton 소환
	elif minute >= 1 and minute <= 5:
		$FlyingEyeTimer.set_paused(false)
		$FlyingEyeTimer.wait_time = 3.3
		$SkeletonTimer.set_paused(false)
		$SkeletonTimer.wait_time = 2.5
		$MushroomTimer.set_paused(true)
		$GoblinTimer.set_paused(true)

		# skeleton 엘리트 몬스터 소환
		if minute == 3 and sec > 30 and not has_spawned_skeleton_elite:
			spawn_enemy(skeleton_elite,ELITE)
			has_spawned_skeleton_elite = true
			
	# 5 ~ 8분: flyingeye, skeleton, mushroom 소환
	elif minute >= 5 and minute <= 8:
		$FlyingEyeTimer.set_paused(false)
		$SkeletonTimer.set_paused(false)
		$SkeletonTimer.wait_time = 5
		$MushroomTimer.set_paused(false)
		$MushroomTimer.wait_time = 3.3
		$GoblinTimer.set_paused(true)

		# mushroom 엘리트 몬스터 소환
		if minute == 6 and sec > 30 and not has_spawned_mushroom_elite:
			spawn_enemy(mushroom_elite,ELITE)
			has_spawned_mushroom_elite = true

	# 8 ~ 10분: flyingeye, skeleton, mushroom, goblin 소환
	elif minute >= 8 and minute < 10:
		$FlyingEyeTimer.set_paused(false)
		$SkeletonTimer.set_paused(false)
		$MushroomTimer.set_paused(false)
		$MushroomTimer.wait_time = 5
		$GoblinTimer.set_paused(false)
	# 10분 이상: 모든 몬스터 타이머 정지 (보스만 등장)
	elif minute >= 10:
		$FlyingEyeTimer.set_paused(true)
		$SkeletonTimer.set_paused(true)
		$MushroomTimer.set_paused(true)
		$GoblinTimer.set_paused(true)

	# 보스 스폰
	if (!boss_spawn_flag) && (minute==10):
		if get_parent().instance_map:
			map_name = get_parent().instance_map.name
		print(map_name)
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

func spawn_enemy(enemy_tscn, monster_type: int):
	var enemy = enemy_tscn
	if enemy:
		var enemy_instance = enemy.instantiate()
		var spawn_radius   = enemy_instance.spawn_radius

		# 몬스터 타입에 따른 스케일 설정
		match monster_type:
			BOSS:
				enemy_instance.scale = Vector2(3, 3)
			ELITE:
				enemy_instance.scale = Vector2(1.5, 1.5)

		var spawn_pos: Vector2
		# 재시도 횟수 설정 (10회)
		var attempts := 0
		var max_attempts := 10

		# 최대 10번 시도해서 충돌 없는 위치 찾기
		while attempts < max_attempts:
			attempts += 1
			# 캐릭터 주변 반경에서 랜덤 위치 생성
			var angle = randf() * PI * 2	# 0부터 360도 사이의 랜덤 각도
			var distance = spawn_radius
			var offset = Vector2(cos(angle), sin(angle)) * distance

			# 적의 위치를 캐릭터 위치 + 랜덤 오프셋으로 설정
			spawn_pos = player.global_position + offset
			
			spawn_pos.x = clamp(spawn_pos.x, -1500, 1500)
			spawn_pos.y = clamp(spawn_pos.y, -1500, 1500)

			# 스폰 충돌 검사 함수 실행
			if is_spawn_position_clear(spawn_pos, enemy_instance):
				break

		# 최종 위치 적용 후 씬에 추가
		enemy_instance.global_position = spawn_pos
		add_child(enemy_instance)
	# 씬 로드 실패시 오류
	else:
		print("Error: Failed to load enemy scene.")


# 스폰 위치 충돌 검사 함수
func is_spawn_position_clear(position: Vector2, enemy_instance: Node2D) -> bool:
	var shape = enemy_instance.get_node_or_null("CollisionShape2D")		# enemy 노드의 콜리젼 모양 가져오기
	var query_shape = shape.shape										# shape.shape -> Shape2D의 리소스
	var query = PhysicsShapeQueryParameters2D.new()						# 검사용 query 생성
	query.shape = query_shape											# query 기준 -> 생성된 enemy의 Shape2D 리소스
	query.transform = Transform2D.IDENTITY.translated(position)			# query의 포지션을 생성된 enemy위치로 이동
	# 필요한 충돌 레이어만 마스크로 설정
	query.collision_mask = 1 											# cave의 경우 layer 1번인 (lava), dungeon의 경우 레이어 1번이 없음  
	#print("충돌검사")

	var space_state = get_world_2d().direct_space_state					# 2D World 받아오며 객체 확인
	var result = space_state.intersect_shape(query, 1)					# 가져온 Shape2D 리소스와 충돌하는 갯수(인자 1개) 확인 / 0개면 스폰 1이면 재시도

	return result.is_empty()

# Skeleton 소환
func _on_skeleton_timer_timeout():
	spawn_enemy(skeleton, MONSTER)
	
# Mushroom 소환
func _on_mushroom_timer_timeout():
	spawn_enemy(mushroom, MONSTER)
	
# FlyingEye 소환
func _on_flying_eye_timer_timeout():
	spawn_enemy(flyingeye, MONSTER)

# Goblin 소환
func _on_goblin_timer_timeout():
	spawn_enemy(goblin, MONSTER)
