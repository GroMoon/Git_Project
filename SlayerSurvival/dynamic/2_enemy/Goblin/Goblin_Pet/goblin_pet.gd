extends EnemyPetBase

var bomb = preload("res://dynamic/2_enemy/Goblin/Goblin_Pet/goblin_bomb.tscn")

func _initialize():
	enemy_pet_name         = "goblin_pet"
	animation_speed        = 1.5
	attack_animation_speed = 2.5
	move_speed             = 120
	attack_damage          = 10
	attack_distance        = 30 	#! FIXME : 이후 _on_attack_timer_timeout 작업 후 추가 필요 

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	is_attacking = true
	animation_player.speed_scale = attack_animation_speed
	# 타겟 없으면 return
	if target_enemy == null or !is_instance_valid(target_enemy):
		return
	
	var bomb_instance = bomb.instantiate()
	bomb_instance.global_position = global_position
	bomb_instance.target = target_enemy.global_position
	
	animation_player.play("attack")
	await animation_player.animation_finished
	
	# 노드 좌표계를 부모 노드와 분리(이렇게 하지 않으면 position의 좌표계 기준을 로컬(goblin_pet)로 잡기 때문에 부정확함)
	bomb_instance.set_as_top_level(true)
	add_child(bomb_instance)
	
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
