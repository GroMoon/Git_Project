extends EnemyBase

func _initialize():
	# 적 특성
	enemy_name      = "goblin_elite"
	health          = 350
	move_speed      = 100
	damage          = 24
	spawn_radius    = 700
	animation_speed = 1.6
	pet_chance      = 0.0
	is_elite        = true

func _ready():
	_initialize()
	super._ready()

func _physics_process(delta):
	super._physics_process(delta)