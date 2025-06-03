extends EnemyBase

func _initialize():
	# 적 특성
	enemy_name      = "mushroom_elite"
	health          = 370
	move_speed      = 80
	damage          = 15
	spawn_radius    = 500
	animation_speed = 1.5
	pet_chance      = 0.0

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)