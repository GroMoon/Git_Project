extends EnemyPetBase

func _initialize():
	enemy_pet_name         = "skeleton_pet"
	animation_speed        = 1.2
	attack_animation_speed = 2.5
	move_speed             = 100
	attack_damage          = 10
	attack_distance        = 30

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	is_attacking = true
	animation_player.speed_scale = attack_animation_speed
	# 공격 1
	if animated_sprite.flip_h:		# 왼쪽 공격
		attack_area.position = Vector2(-66, -5)
	else: 							# 오른쪽 공격
		attack_area.position = Vector2(66, -5)
	animation_player.play("attack")
	await animation_player.animation_finished
	
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
