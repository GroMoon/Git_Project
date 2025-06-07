extends CharacterShadowBase

func _initialize():
	move_speed      = 130 * 0.8
	attack_damage   = 13
	animation_speed = 1.5 

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func cast_lightning():
	var target = get_closest_enemy()
	var lightning = preload("res://dynamic/1_player/characters/Wizard/Shadow/lightning_shadow.tscn").instantiate()
	lightning.global_position = target.global_position
	get_parent().add_child(lightning)

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
	is_attacking = true
	# shadow에 대해서 공격 애니메이션 반대로 실행
	var original_flip = animated_sprite.flip_h
	animated_sprite.flip_h = not original_flip
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
