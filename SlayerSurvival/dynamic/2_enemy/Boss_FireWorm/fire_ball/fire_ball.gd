extends Area2D

@onready var animation_player = $AnimationPlayer

var direction        = Vector2.ZERO
var fire_ball_speed  = 400
var fire_ball_damage = 20
var explosion_damage = 15
var player

var target_explode = false
var target = Vector2.ZERO		# FIXME 타겟 폭발

func _ready():
	player = get_parent().get_parent().get_node("player")
	animation_player.play("Idle")
	
	target = player.global_position			# FIXME 타겟 폭발

func _process(delta):
	position += direction * fire_ball_speed * delta
	if target_explode:
		explode_2()

func explode():
	fire_ball_damage = explosion_damage
	animation_player.play("Explosion")			# 폭발 애니메이션
	fire_ball_speed = 0								# 이동 정지
	await animation_player.animation_finished
	queue_free()

# FIXME 타겟 폭발
func explode_2():
	# 목표 위치에 도달했는지 확인
	if position.distance_to(target) < 1.0:
		fire_ball_damage = explosion_damage
		fire_ball_speed = 0
		animation_player.play("Explosion")
		await animation_player.animation_finished
		queue_free()

func _on_body_entered(body):
	player.process_collision_enemy(fire_ball_damage)
	if target_explode:
		explode_2()			# FIXME 타겟 폭발
	else:
		explode()
	
func _on_explosion_timer_timeout():
	if target_explode == false:
		explode()
	else:
		print("버전 1이므로 타이머 돌지 않음")
		pass
