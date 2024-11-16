extends CharacterBody2D

var health = 10				# 적 체력
var move_speed = 100		# 적 이동 속도
var player					# slime (플레이어) 노드에 대한 참조
var damage = 5				# 적 데미지

func _ready():
	# slime 노드 찾기 (예: 플레이어 노드가 "Slime"이라고 가정)
	player = get_parent().get_parent().get_parent().get_node("Slime")  # 경로는 상황에 맞게 변경

func _physics_process(_delta):
	# 플레이어가 존재하면 그 위치로 움직임
	if player:
		# 플레이어와 적 사이의 방향 계산
		var direction = (player.position - position).normalized()		
		# 그 방향으로 이동
		velocity = direction * move_speed		
		# 이동 적용
		move_and_slide()

	# 애니메이션 처리
	if velocity.length() > 0:
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.flip_h = velocity.x < 0


func _on_interaction_sensor_body_entered(body:Node2D):
	body.process_collision_enemy(damage)

func _on_interaction_sensor_area_entered(area:Area2D):
	if area.is_in_group("attack"):
		health -= area.damage			# TODO area.damage가 무기 추가 후 각 공격에 맞는 damage가 들어오는지 확인할 필요가 있음
		if health <= 0:
			queue_free()
		print("enemyHP : ", health)		# Enemy 체력 디버깅

# Enemy 충돌 처리
func process_collision_enemy(_damage):
	pass