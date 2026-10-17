extends CharacterBase

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3

func _initialize():
	# 캐릭터 특성
	character_name      = "medieval_king"
	move_speed          = 150
	attack_damage       = 14
	magnetic_area_scale = 100
	animation_speed     = 1.5
	start_hp            = 75.0
	attack_wait_time    = 1.1
	attack_anim_speed   = 1.4

func _ready():
	_initialize()
	super._ready()

func _physics_process(_delta):
	super._physics_process(_delta)


func _on_attack_timer_timeout():
	# 오른쪽을 볼 때 공격 범위 x 위치 (왼쪽은 자동 반전)
	run_melee_combo([attack_area_1, attack_area_2, attack_area_3], [37, 7, 33])
