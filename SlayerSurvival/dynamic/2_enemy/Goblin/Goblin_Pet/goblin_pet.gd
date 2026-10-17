extends EnemyPetBase

var bomb = preload("res://dynamic/2_enemy/Goblin/Goblin_Pet/goblin_bomb.tscn")

func _initialize():
	enemy_pet_name         = "goblin_pet"
	animation_speed        = 1.5
	attack_animation_speed = 2.5
	move_speed             = 120
	attack_damage          = 30
	attack_distance        = 30

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	# 타겟 없으면 다음 타이머에 다시 시도 (공격 중 상태로 멈추지 않도록)
	if target_enemy == null or !is_instance_valid(target_enemy):
		$AttackTimer.start()
		return
	is_attacking = true
	animation_player.speed_scale = attack_animation_speed
	var target_pos = target_enemy.global_position

	var bomb_instance = bomb.instantiate()

	animation_player.play("attack")
	await animation_player.animation_finished
	# 공격 모션 동안 대상이 다른 공격에 죽어 사라졌을 수 있음 → 마지막 위치로 던짐
	if is_instance_valid(target_enemy):
		target_pos = target_enemy.global_position
	bomb_instance.global_position = global_position
	bomb_instance.target = target_pos
	# 노드 좌표계를 부모 노드와 분리(이렇게 하지 않으면 position의 좌표계 기준을 로컬(goblin_pet)로 잡기 때문에 부정확함)
	bomb_instance.set_as_top_level(true)
	add_child(bomb_instance)
	
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
