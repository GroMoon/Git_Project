extends CharacterBase

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3

func _initialize():
	# 캐릭터 특성
	character_name      = "medieval_king"
	move_speed          = 150
	attack_damage       = 10
	magnetic_area_scale = 100
	animation_speed     = 1.5
	start_hp            = 75.0

func _ready():
	_initialize()
	super._ready()

func _physics_process(_delta):
	super._physics_process(_delta)


func _on_attack_timer_timeout():
	attack_timer.wait_time = attack_wait_time - cooldown
	# 사망 시 공격 모션 비활성화를 위한 조건
	if is_dead:
		return	
	is_attacking = true
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
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_1")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_2")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
	elif attack_times == 3:
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_1")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_2")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_3")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
	else:
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		# 공격 1
		animation_player.play("attack_1")
		await animation_player.animation_finished
		# pause 해제 대기
		if not await wait_for_pause_resume():
			is_attacking = false
			return

	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
