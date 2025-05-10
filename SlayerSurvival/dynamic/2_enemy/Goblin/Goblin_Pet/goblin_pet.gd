extends EnemyPetBase

func _initialize():
	enemy_pet_name         = "goblin_pet"
	animation_speed        = 1.5
	attack_animation_speed = 2.5
	move_speed             = 120
	attack_damage          = 15
	attack_distance        = 30 	#! FIXME : 이후 _on_attack_timer_timeout 작업 후 추가 필요 

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timer_timeout():
	#? 공격 모션 수정 예정 (원거리 공격 예정)
	pass
