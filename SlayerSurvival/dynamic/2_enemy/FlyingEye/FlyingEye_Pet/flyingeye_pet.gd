extends EnemyPetBase

func _initialize():
	enemy_pet_name         = "flyingeye_pet"
	animation_speed        = 2.5
	attack_animation_speed = 2.5
	move_speed             = 100
	attack_damage          = 10
	attack_distance        = 20

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	is_attacking = true
	animated_sprite.speed_scale = attack_animation_speed
	# 공격 1
	attack_area.set_deferred("disabled", false)
	if animated_sprite.flip_h:		# 왼쪽 공격
		attack_area.position = Vector2(-11, -2)
	else: 							# 오른쪽 공격
		attack_area.position = Vector2(11, -2)
	animated_sprite.play("attack_2")
	await animated_sprite.animation_finished
	attack_area.set_deferred("disabled", true)	
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
