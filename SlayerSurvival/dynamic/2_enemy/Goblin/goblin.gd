extends EnemyBase

func _initialize():
	# 적 특성
	enemy_name      = "goblin"
	health          = 35
	move_speed      = 100
	damage          = 8
	spawn_radius    = 700
	animation_speed = 1.6
	pet_chance      = 0.9

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)