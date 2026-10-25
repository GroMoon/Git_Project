extends WeaponBase

## 캐릭터 고유 무기 (전사/왕: 콤보 베기, 마법사: 번개)
## 실제 공격은 각 캐릭터 스크립트가 처리하고, 여기서는 레벨에 따른 스탯만 플레이어에 반영

func on_level_changed():
	var times_key = "times_wizard" if player.character_name == "wizard" else "times"
	player.attack_times          = int(stat(times_key, 1))
	player.attack_times_level    = level - 1
	player.signature_damage_mult = float(stat("damage", 1.0)) * overcap_mult()
	player.signature_cd_mult     = float(stat("cooldown", 1.0))
	player.signature_area_mult   = float(stat("area", 1.0))
	player.crit_bonus            = 0.15 if evolved else 0.0
	player.recalc_stats()

func _physics_process(_delta):
	pass
