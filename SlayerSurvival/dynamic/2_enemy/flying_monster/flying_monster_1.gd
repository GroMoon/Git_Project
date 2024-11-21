extends CharacterBody2D

var health = 10				# 적 체력
var move_speed = 100		# 적 이동 속도
var player					# slime (플레이어) 노드에 대한 참조
var damage = 5				# 적 데미지
var touch_flag = false		# 적과 맞닿아 있는지 flag

func _ready():
	# player 노드 찾기
	player = get_parent().get_parent().get_parent().get_node("player")  # 경로는 상황에 맞게 변경

func _physics_process(_delta):
	# 플레이어가 존재하면 그 위치로 움직임
	if player:
		var direction = (player.position - position).normalized()		# 플레이어와 적 사이의 방향 계산
		velocity = direction * move_speed		# 그 방향으로 이동
		move_and_slide()		# 이동 적용

	# 애니메이션 처리
	if velocity.length() > 0:
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	
	# 접촉 상태인 경우 damage
	if touch_flag == true:
		player.process_collision_enemy(damage)

# 접촉 상태가 되었을 때
func _on_interaction_sensor_body_entered(_body:Node2D):
	touch_flag = true

# 접촉 상태에서 벗어날 때
func _on_interaction_sensor_body_exited(_body:Node2D):
	touch_flag = false

func _on_interaction_sensor_area_entered(area:Area2D):
	if area.is_in_group("attack"):
		health -= area.damage			# TODO area.damage가 무기 추가 후 각 공격에 맞는 damage가 들어오는지 확인할 필요가 있음
		if health <= 0:
			queue_free()
		#print("enemyHP : ", health)		# Enemy 체력 디버깅



