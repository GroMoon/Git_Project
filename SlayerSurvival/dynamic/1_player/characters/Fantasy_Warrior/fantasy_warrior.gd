extends CharacterBase

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3

func _initialize():
	# 캐릭터 특성
	character_name      = "fantasy_warrior"
	move_speed          = 200
	attack_damage       = 7
	magnetic_area_scale = 100
	animation_speed     = 2.0
	start_hp            = 50.0

func _ready():
	_initialize()
	super._ready()

func _physics_process(_delta):
	super._physics_process(_delta)


func _on_attack_timer_timeout():
	# 사망 시 공격 모션 비활성화를 위한 조건
	if is_dead:
		return	
	is_attacking = true
	animated_sprite.speed_scale = animation_speed
	# print("attack timer timeout!")
	# 방향에 따라 area 변경
	if animated_sprite.flip_h:
		attack_area_1.position.x = -29
		attack_area_2.position.x = -4
		attack_area_3.position.x = -30
	else:
		attack_area_1.position.x = 29
		attack_area_2.position.x = 4
		attack_area_3.position.x = 30
	
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
