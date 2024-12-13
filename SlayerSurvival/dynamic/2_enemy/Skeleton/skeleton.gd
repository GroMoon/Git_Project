extends CharacterBody2D

@onready var collision_shape    = $CollisionShape2D
@onready var animated_sprite    = $AnimatedSprite2D
@onready var interaction_sensor = $interaction_sensor 

# 코인
var coin = preload("res://dynamic/6_utillity/Items/coin.tscn")
var coins = 10
# 적 특성
var health       = 10 	# 적 체력
var move_speed   = 100 	# 적 이동 속도
var damage       = 3  		# 적 데미지
var spawn_radius = 300  # 스폰 범위
# 전역 변수
var player 
var touch_flag = false 
var is_dead    = false

func _ready():
	# player 노드 찾기
	player = get_parent().get_parent().get_node("player")
	
func _physics_process(_delta):
	# 사망 상태에서 아무것도 처리 아지 않도록
	if is_dead:
		return

	# 플레이어가 존재하면 그 위치로 움직임
	if player:
		var direction = (player.position - position).normalized()        # 플레이어와 적 사이의 방향 계산
		velocity = direction * move_speed        # 그 방향으로 이동
		move_and_slide()        # 이동 적용

	# 애니메이션 처리
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = velocity.x < 0

	if touch_flag:
		player.process_collision_enemy(damage)

# 접촉 상태가 되었을 때
func _on_interaction_sensor_body_entered(_body:Node2D):
	if _body == player and not touch_flag:
		player.process_collision_enemy(damage)
		touch_flag = true
		print(touch_flag)

# 접촉 상태에서 벗어날 때
func _on_interaction_sensor_body_exited(_body:Node2D):
	if _body == player:
		touch_flag = false
	
func _on_interaction_sensor_area_entered(area:Area2D):
	if area.is_in_group("attack"):
		health -= area.get_parent().attack_damage            # TODO area.damage가 무기 추가 후 각 공격에 맞는 damage가 들어오는지 확인할 필요가 있음
		if health <= 0:
			# queue_free()
			enemy_die()
		print("enemyHP(뼈다구) : ", health)        # Enemy 체력 디버깅

# 사망 처리 함수
func enemy_die():
	is_dead = true 							# 사망 상태 활성화
	drop_item()
	collision_shape.disabled = true			# CollisionShape2D 비활성화
	interaction_sensor.queue_free()			# interaction_sensor 삭제
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()							# 적 노드 삭제
	
func drop_item():
	var coin_chance = randf()
	if coin_chance <= 0.5:
		print("코인 드랍")
		var new_coin = coin.instantiate()
		new_coin.coin = coins
		new_coin.global_position = global_position
		get_parent().call_deferred("add_child", new_coin)
