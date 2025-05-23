extends CharacterBody2D

class_name  EnemyPetBase

@onready var animated_sprite  = $AnimatedSprite2D
@onready var attack_area      = $Attack/attack_1
@onready var animation_player = $AnimationPlayer

# default enemy pet characteristics
var enemy_pet_name         = "EnemyPetBase"     # 몬스터펫 이름
var stop_distance          = 50.0               # 몬스터펫 플레이어와의 유지 거리
var attack_distance        = 10.0               # 몬스터펫 공격 시작 거리
var animation_speed        = 1.5                # 몬스터펫 기본 애니메이션 속도
var attack_animation_speed = 2.0                # 몬스터펫 공격 애니메이션 속도
var move_speed             = 100                # 몬스터펫 이동 속도
var attack_damage          = 5                  # 몬스터펫 공격 데미지

# flags
var is_attacking           = false  # 몬스터펫 공격 진행 중 플래그

# global variable
var target_enemy:Node2D = null      # 몬스터펫 공격 타겟
var player              = null 

func _ready():
	attack_area.set_deferred("disabled", true)

func _physics_process(_delta):
	# player 세팅
	if player == null:
		player = get_parent().get_node("player")
	# 공격 중에는 이동하지 않음
	if is_attacking:
		return

	# 적(target_enemy)이 유효하면 적을 따라 이동, 아니면 플레이어를 따라 이동
	if target_enemy != null and is_instance_valid(target_enemy):
		# 목표 적이 있을 때: 적 방향으로 이동
		var direction = (target_enemy.global_position - global_position).normalized()
		var distance_to_target = global_position.distance_to(target_enemy.global_position)
		# 공격 거리 안에 있으면 공격
		if distance_to_target <= attack_distance:
			if (enemy_pet_name != "flyingeye_pet"): 	# 날아다니는 몬스터의 경우 움직이면서 공격
				velocity = Vector2.ZERO
			else:
				velocity = direction * move_speed
			animated_sprite.speed_scale = animation_speed
			animated_sprite.play("idle")
		else:
			velocity = direction * move_speed
		move_and_slide()
	else:
		# 목표 적이 없으면 플레이어를 따라 이동
		if player:
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player <= stop_distance:
				velocity = Vector2.ZERO
				animated_sprite.speed_scale = animation_speed
				animated_sprite.play("idle")
			else:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * move_speed
				move_and_slide()
			
			# enemy 그룹에서 가장 가까운 적을 탐색해서 target_enemy로 설정
			target_enemy = find_closest_enemy()
	
	# 애니메이션 처리: 이동 중이면 "walk", 그렇지 않으면 "idle"
	if velocity.length() > 0:
		animated_sprite.speed_scale = animation_speed
		animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.speed_scale = animation_speed
		animated_sprite.play("idle")

# "enemy" 그룹에 속한 적들 중 가장 가까운 노드를 찾는 함수
func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0 :
		return null
	
	var closest: Node2D = null
	var min_dist = INF
	for enemy in enemies:
		if enemy is Node2D and enemy.targeted_flag == false:
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				closest = enemy
				closest.targeted_flag = true
	return closest
