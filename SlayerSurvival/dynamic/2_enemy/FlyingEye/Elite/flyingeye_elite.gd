extends EnemyBase

func _initialize():
	# 적 특성
	enemy_name      = "flyingeye_elite"
	health          = 210
	move_speed      = 105
	damage          = 15
	spawn_radius    = 500
	animation_speed = 2.0
	pet_chance      = 0.0

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)