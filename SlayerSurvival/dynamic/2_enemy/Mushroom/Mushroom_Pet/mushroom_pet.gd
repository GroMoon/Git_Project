extends CharacterBody2D

const STOP_DISTANCE          = 50.0 		# 플레이어와의 거리가 해당 값 이하일 땐 멈춤
const ATTACK_DISTANCE        = 50.0			# 공격을 시작하는 거리
const ANIMATION_SPEED        = 1.5			# 기본 애니메이션 속도
const ATTACK_ANIMATION_SPEED = 2.0 			# 공격 애니메이션 속도

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area     = $Attack/attack_1

var move_speed    = 80  			# 펫 이동 속도
var attack_damage = 5
var is_attacking  = false

var target_enemy: Node2D = null     # 현재 목표로 하는 적
var player               = null

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
		if distance_to_target <= ATTACK_DISTANCE:
			velocity = Vector2.ZERO
			animated_sprite.speed_scale = ANIMATION_SPEED
			animated_sprite.play("idle")
		else:
			velocity = direction * move_speed
		move_and_slide()
	else:
		# 목표 적이 없으면 플레이어를 따라 이동
		if player:
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player <= STOP_DISTANCE:
				velocity = Vector2.ZERO
				animated_sprite.speed_scale = ANIMATION_SPEED
				animated_sprite.play("idle")
			else:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * move_speed
				move_and_slide()
			
			# enemy 그룹에서 가장 가까운 적을 탐색해서 target_enemy로 설정
			target_enemy = find_closest_enemy()
	
	# 애니메이션 처리: 이동 중이면 "walk", 그렇지 않으면 "idle"
	if velocity.length() > 0:
		animated_sprite.speed_scale = ANIMATION_SPEED
		animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.speed_scale = ANIMATION_SPEED
		animated_sprite.play("idle")


# "enemy" 그룹에 속한 적들 중 가장 가까운 노드를 찾는 함수
func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0 :
		return null
	
	var closest: Node2D = null
	var min_dist = INF
	for enemy in enemies:
		if enemy is Node2D:
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				closest = enemy
	return closest

# func _on_attack_timer_timeout():
# 	# 만약 목표 적이 존재하고 유효하며, 그 거리가 공격 범위 내라면 공격 실행
# 	if target_enemy != null and is_instance_valid(target_enemy) and global_position.distance_to(target_enemy.global_position) <= ATTACK_DISTANCE:
# 		is_attacking = true
# 		animated_sprite.speed_scale = ATTACK_ANIMATION_SPEED
# 		# 공격 범위 활성화
# 		attack_area.set_deferred("disabled", false)
# 		# 공격 방향에 따라 공격 영역 위치 설정
# 		if animated_sprite.flip_h:		# 왼쪽 공격
# 			attack_area.position = Vector2(-21, 9)
# 		else: 							# 오른쪽 공격
# 			attack_area.position = Vector2(21, 9)
# 		animated_sprite.play("attack")
# 		await animated_sprite.animation_finished
# 		attack_area.set_deferred("disabled", true)
# 		is_attacking = false
	
# 	# 공격 여부와 상관없이 타이머 재시작
# 	$AttackTimer.start()

func _on_attack_timer_timeout():
	is_attacking = true
	animated_sprite.speed_scale = ATTACK_ANIMATION_SPEED
	# 공격 1
	attack_area.set_deferred("disabled", false)
	if animated_sprite.flip_h:		# 왼쪽 공격
		attack_area.position = Vector2(-21, 9)
	else: 							# 오른쪽 공격
		attack_area.position = Vector2(21, 9)
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	attack_area.set_deferred("disabled", true)	
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()