extends Node2D

const BOSS_MONSTER = true
const MONSTER      = false

var player
var base_ui
var minute
var sec
var map_name = ""

var boss_spawn_flag = false # 보스 스폰 여부 플래그

# 일반 몬스터
var skeleton  = preload("res://dynamic/2_enemy/Skeleton/skeleton.tscn")
var mushroom  = preload("res://dynamic/2_enemy/Mushroom/mushroom.tscn")
var goblin    = preload("res://dynamic/2_enemy/Goblin/goblin.tscn")
var flyingeye = preload("res://dynamic/2_enemy/FlyingEye/flyingeye.tscn")
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
	if (!boss_spawn_flag) && (minute==10):	#! FIXME : test용으로 현재 보스 스폰 시간 1분 
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
		spawn_enemy(boss, BOSS_MONSTER)
		boss_spawn_flag = true
	

# 적을 스폰하는 함수
func spawn_enemy(enemy_tscn, is_boss):
	# 경로로부터 적 프리팹을 로드
	var enemy = enemy_tscn
	# 씬이 제대로 로드되었는지 확인
	if enemy:
		var enemy_instance = enemy.instantiate()
		var spawn_radius   = enemy_instance.spawn_radius
		if is_boss:
			enemy_instance.scale = Vector2(3,3)
		# 캐릭터 주변 반경에서 랜덤 위치 생성
		var angle = randf() * PI * 2  # 0부터 360도 사이의 랜덤 각도
		var distance = spawn_radius
		var offset = Vector2(cos(angle), sin(angle)) * distance

		# 적의 위치를 캐릭터 위치 + 랜덤 오프셋으로 설정
		var spawn_pos = player.global_position + offset

		# x, y가 -1550 ~ 1550 범위로 제한
		spawn_pos.x = clamp(spawn_pos.x, -1550, 1550)
		spawn_pos.y = clamp(spawn_pos.y, -1550, 1550)
		enemy_instance.global_position = spawn_pos

		# 씬에 적 인스턴스를 추가
		add_child(enemy_instance)
	else:
		print("Error: Failed to load enemy scene.")

# Skeleton 소환
func _on_skeleton_timer_timeout():
	spawn_enemy(skeleton, MONSTER)
	
# Mushrrom 소환
func _on_mushroom_timer_timeout():
	spawn_enemy(mushroom, MONSTER)
	
# FlyingEye 소환
func _on_flying_eye_timer_timeout():
	spawn_enemy(flyingeye, MONSTER)

# Goblin 소환
func _on_goblin_timer_timeout():
	spawn_enemy(goblin, MONSTER)