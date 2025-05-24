extends EnemyBase

func _initialize():
	# 적 특성
	enemy_name      = "skeleton"
	health          = 33
	move_speed      = 75
	damage          = 5
	spawn_radius    = 500
	animation_speed = 1.2
	pet_chance      = 0.1

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)