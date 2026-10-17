extends WeaponBase

## 그림자 분신: 기존 그림자 시스템(test.gd 에서 소환)을 레벨로 제어

func on_level_changed():
	player.shadow_partner_level = level
	player.shadow_attack = true

func _physics_process(_delta):
	pass
