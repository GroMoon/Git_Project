extends CharacterShadowBase

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3

func _initialize():
	move_speed      = 150 * 0.8
	attack_damage   = 10
	animation_speed = 1.5 

func _ready():
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	is_attacking = true
	# shadow에 대해서 공격 애니메이션 반대로 실행
	var original_flip = animated_sprite.flip_h
	animated_sprite.flip_h = not original_flip
	animated_sprite.speed_scale = animation_speed
	# print("attack timer timeout!")
	# 방향에 따라 area 변경
	if animated_sprite.flip_h:
		attack_area_1.position.x = -37
		attack_area_2.position.x = -7
		attack_area_3.position.x = -33
	else:
		attack_area_1.position.x = 37
		attack_area_2.position.x = 7
		attack_area_3.position.x = 33
	
	if attack_times == 2:
		animation_player.play("attack_1")
		await animation_player.animation_finished
		animation_player.play("attack_2")
		await animation_player.animation_finished
	elif attack_times == 3:
		animation_player.play("attack_1")
		await animation_player.animation_finished
		animation_player.play("attack_2")
		await animation_player.animation_finished
		animation_player.play("attack_3")
		await animation_player.animation_finished
	else:
		# 공격 1
		animation_player.play("attack_1")
		await animation_player.animation_finished

	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
