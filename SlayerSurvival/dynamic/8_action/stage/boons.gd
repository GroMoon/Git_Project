extends RefCounted
## 방 클리어 보상 : 강화 3개 중 1개 선택
## (노션 컨셉 "레벨업 : 파티(몬스터) + Player 의 강화 요소" 를 방 단위 보상으로 재해석)
##   party = true 인 강화는 몬스터 동료가 있을 때만 등장

const BOONS := [
	{"id": "power",       "name": "투지",      "desc": "공격력 +12%",              "icon": Vector2i(1, 9)},
	{"id": "vitality",    "name": "강철 체력", "desc": "최대 HP +15%\nHP 30% 회복", "icon": Vector2i(0, 9)},
	{"id": "haste",       "name": "신속",      "desc": "스킬 쿨타임 -12%",         "icon": Vector2i(10, 9)},
	{"id": "mana",        "name": "마나 순환", "desc": "MP 회복 속도 +40%",        "icon": Vector2i(5, 10)},
	{"id": "vampire",     "name": "흡혈",      "desc": "준 피해의 3% 회복",        "icon": Vector2i(11, 9)},
	{"id": "swift",       "name": "질풍",      "desc": "이동 속도 +8%",            "icon": Vector2i(7, 9)},
	{"id": "guard",       "name": "수호",      "desc": "받는 피해 -8%",            "icon": Vector2i(6, 9)},
	{"id": "critical",    "name": "급소 공격", "desc": "15% 확률로\n1.5배 피해",   "icon": Vector2i(7, 10)},
	{"id": "focus",       "name": "집중",      "desc": "적중할 때마다 MP +4",      "icon": Vector2i(8, 9)},
	{"id": "party_power", "name": "동료 강화", "desc": "몬스터 동료\n공격력 +50%", "icon": Vector2i(9, 10), "party": true},
	{"id": "party_haste", "name": "동료 지휘", "desc": "몬스터 동료\n공격 속도 +35%", "icon": Vector2i(9, 9), "party": true},
]

static func get_boon(id: String) -> Dictionary:
	for boon in BOONS:
		if boon.id == id:
			return boon
	return {}

## 서로 다른 강화 count개 (동료가 없으면 동료 강화 제외)
static func roll(count: int, party_size: int) -> Array:
	var pool := BOONS.filter(func(b): return party_size > 0 or not b.get("party", false))
	pool.shuffle()
	return pool.slice(0, count)

static func apply(id: String, player: Node, _stage: Node):
	match id:
		"power":
			player.attack_power *= 1.12
		"vitality":
			player.max_hp *= 1.15
			player.heal(player.max_hp * 0.3)
		"haste":
			player.cooldown_scale *= 0.88
		"mana":
			player.mp_regen *= 1.4
		"vampire":
			player.lifesteal += 0.03
		"swift":
			player.walk_speed *= 1.08
			player.run_speed *= 1.08
		"guard":
			player.damage_reduction = minf(0.7, player.damage_reduction + 0.08)
		"critical":
			player.crit_chance += 0.15
		"focus":
			player.mp_on_hit += 4.0
		"party_power":
			player.party_power_scale *= 1.5
		"party_haste":
			player.party_cooldown_scale *= 0.65
	player.boons.append(id)
	player.hp_changed.emit(player.hp, player.max_hp)
