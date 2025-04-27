extends CharacterBase

var lightning = preload("res://dynamic/1_player/characters/Wizard/Lightning/lightning.tscn")

func _initialize():
	# 캐릭터 특성
	character_name      = "wizard"
	move_speed          = 130
	attack_damage       = 15
	magnetic_area_scale = 100
	animation_speed     = 1.5
	start_hp            = 40

func _ready():
	_initialize()
	super._ready()

func _physics_process(_delta):
	super._physics_process(_delta)


func cast_lightning():
	var target = get_closest_enemy()
	var ligtning_instance = lightning.instantiate()
	ligtning_instance.global_position = target.global_position
	get_parent().add_child(ligtning_instance)

func get_closest_enemy():
	var closest_enemy = null
	var closest_distance = 300
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	return closest_enemy if closest_enemy else self

func _on_attack_timer_timeout():
	# 사망 시 공격 모션 비활성화를 위한 조건
	if is_dead:
		return
	is_attacking = true
	animated_sprite.speed_scale = animation_speed
	# print("attack timer timeout!")
	
	if attack_times == 2:
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
	elif attack_times == 3:
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
	else:
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()

	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()

func _on_damage_timer_timeout():
	damage_flag = false
