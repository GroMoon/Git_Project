class_name UpgradeDB

## 무기/패시브 데이터 정의
## - stats: 레벨별 값 배열 (index 0 = Lv1)
## - desc: 레벨별 설명 (Lv1 = 무기 소개, 이후 = 해당 레벨에서 바뀌는 점)
## - 텍스트는 {ko, en} 딕셔너리, text() 로 현재 언어에 맞게 꺼냄

const WEAPON_SLOTS  = 6
const PASSIVE_SLOTS = 6

const ICON_SHEET = preload("res://static/png/icon/spritesheet.png")
const ICON_SIZE  = 16

# 레벨업 선택지 가중치
const WEIGHT_OWNED_WEAPON  = 45
const WEIGHT_NEW_WEAPON    = 30
const WEIGHT_OWNED_PASSIVE = 30
const WEIGHT_NEW_PASSIVE   = 20

static var _data := {}
static var _icon_cache := {}

# ================= 조회 =================
static func data() -> Dictionary:
	if _data.is_empty():
		_data = _build()
	return _data

static func has(id: String) -> bool:
	return data().has(id)

static func get_entry(id: String) -> Dictionary:
	return data().get(id, {})

static func is_weapon(id: String) -> bool:
	return get_entry(id).get("type", "") == "weapon"

static func is_passive(id: String) -> bool:
	return get_entry(id).get("type", "") == "passive"

static func max_level(id: String) -> int:
	return get_entry(id).get("max_level", 1)

static func weapon_ids() -> Array:
	return data().keys().filter(func(k): return is_weapon(k))

static func passive_ids() -> Array:
	return data().keys().filter(func(k): return is_passive(k))

# 레벨별 스탯 (level은 1부터)
static func stat(id: String, level: int, key: String, default_value = 0.0):
	var stats = get_entry(id).get("stats", {})
	if not stats.has(key):
		return default_value
	var arr: Array = stats[key]
	return arr[clampi(level - 1, 0, arr.size() - 1)]

# 현재 언어에 맞는 텍스트
static func text(t) -> String:
	if t is String:
		return t
	var locale = TranslationServer.get_locale()
	if locale.begins_with("ko") and t.has("ko"):
		return t["ko"]
	return t.get("en", t.get("ko", ""))

# 캐릭터별로 이름/설명/아이콘이 다른 항목(시그니처 무기) 처리
static func display_name(id: String, character_name: String = "") -> String:
	var e = get_entry(id)
	if e.has("names_by_character") and e["names_by_character"].has(character_name):
		return text(e["names_by_character"][character_name])
	return text(e.get("name", id))

static func level_desc(id: String, level: int, character_name: String = "") -> String:
	var e = get_entry(id)
	var descs: Array = e.get("desc", [])
	if e.has("desc_by_character") and e["desc_by_character"].has(character_name):
		descs = e["desc_by_character"][character_name]
	if descs.is_empty():
		return ""
	return text(descs[clampi(level - 1, 0, descs.size() - 1)])

static func icon(id: String, character_name: String = "") -> Texture2D:
	var key = id + "/" + character_name
	if _icon_cache.has(key):
		return _icon_cache[key]
	var e = get_entry(id)
	var spec = e.get("icon")
	if e.has("icon_by_character") and e["icon_by_character"].has(character_name):
		spec = e["icon_by_character"][character_name]
	var tex: Texture2D = null
	if spec is Vector2i:
		tex = sheet_icon(spec.x, spec.y)
	elif spec is Dictionary:
		var atlas = AtlasTexture.new()
		atlas.atlas = load(spec["path"])
		atlas.region = spec["region"]
		tex = atlas
	elif spec is String:
		tex = load(spec)
	_icon_cache[key] = tex
	return tex

# 아이콘 시트(12x12, 16px)에서 (열, 행) 위치의 아이콘
static func sheet_icon(col: int, row: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = ICON_SHEET
	atlas.region = Rect2(col * ICON_SIZE, row * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	return atlas

# ================= 데이터 =================
static func _build() -> Dictionary:
	return {
		# ---------- 무기 ----------
		"signature": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/signature_weapon.gd",
			"name": {"ko": "고유 무기", "en": "Signature"},
			"names_by_character": {
				"fantasy_warrior": {"ko": "전사의 검", "en": "Warrior's Blade"},
				"medieval_king":   {"ko": "왕의 대검", "en": "Royal Greatsword"},
				"wizard":          {"ko": "번개 마법", "en": "Lightning"},
			},
			"icon": "res://dynamic/5_title_screen/store/store_sprites/double_slash.png",
			"icon_by_character": {"wizard": "res://dynamic/5_title_screen/store/store_sprites/double_lightening.png"},
			"desc": [
				{"ko": "가까운 적을 향해 검을 휘두른다.", "en": "Slashes toward the nearest enemy."},
				{"ko": "2연속 베기", "en": "Double slash"},
				{"ko": "피해 +25%", "en": "Damage +25%"},
				{"ko": "3연속 베기", "en": "Triple slash"},
				{"ko": "피해 +25%, 쿨타임 -15%", "en": "Damage +25%, cooldown -15%"},
				{"ko": "공격 범위 +30%", "en": "Attack area +30%"},
			],
			"desc_by_character": {
				"wizard": [
					{"ko": "가까운 적에게 번개를 내리친다.", "en": "Strikes the nearest enemy with lightning."},
					{"ko": "번개 +1", "en": "+1 bolt"},
					{"ko": "피해 +25%", "en": "Damage +25%"},
					{"ko": "번개 +1", "en": "+1 bolt"},
					{"ko": "피해 +25%, 쿨타임 -15%", "en": "Damage +25%, cooldown -15%"},
					{"ko": "번개 +1, 범위 +30%", "en": "+1 bolt, area +30%"},
				],
			},
			"stats": {
				"times":    [1, 2, 2, 3, 3, 3],
				"times_wizard": [1, 2, 2, 3, 3, 4],
				"damage":   [1.0, 1.0, 1.25, 1.25, 1.56, 1.56],
				"cooldown": [1.0, 1.0, 1.0, 1.0, 0.85, 0.85],
				"area":     [1.0, 1.0, 1.0, 1.0, 1.0, 1.3],
			},
		},
		"fireball": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/fireball_weapon.gd",
			"name": {"ko": "화염구", "en": "Fireball"},
			"icon": {"path": "res://dynamic/2_enemy/Boss_FireWorm/Sprites/Fire Ball/Move.png", "region": Rect2(4, 8, 32, 32)},
			"desc": [
				{"ko": "가까운 적에게 화염구를 날려 폭발시킨다.", "en": "Launches exploding fireballs at the nearest enemies."},
				{"ko": "화염구 +1", "en": "+1 fireball"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "화염구 +1, 폭발 범위 +25%", "en": "+1 fireball, blast area +25%"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "화염구 +1, 쿨타임 -20%", "en": "+1 fireball, cooldown -20%"},
			],
			"stats": {
				"damage":   [14, 14, 20, 20, 28, 28],
				"amount":   [1, 2, 2, 3, 3, 4],
				"cooldown": [1.5, 1.5, 1.5, 1.5, 1.5, 1.2],
				"area":     [1.0, 1.0, 1.0, 1.25, 1.25, 1.25],
			},
		},
		"bomb": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/bomb_weapon.gd",
			"name": {"ko": "고블린 폭탄", "en": "Goblin Bomb"},
			"icon": Vector2i(2, 9),
			"desc": [
				{"ko": "적 무리에 폭탄을 던져 크게 폭발시킨다.", "en": "Lobs bombs into crowds for a big blast."},
				{"ko": "폭탄 +1", "en": "+1 bomb"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "폭발 범위 +30%", "en": "Blast area +30%"},
				{"ko": "폭탄 +1", "en": "+1 bomb"},
				{"ko": "피해 +40%, 쿨타임 -25%", "en": "Damage +40%, cooldown -25%"},
			],
			"stats": {
				"damage":   [30, 30, 42, 42, 42, 60],
				"amount":   [1, 2, 2, 2, 3, 3],
				"cooldown": [3.0, 3.0, 3.0, 3.0, 3.0, 2.25],
				"area":     [1.0, 1.0, 1.0, 1.3, 1.3, 1.3],
			},
		},
		"blade": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/orbit_blade_weapon.gd",
			"name": {"ko": "회전 칼날", "en": "Orbit Blades"},
			"icon": {"path": "res://dynamic/2_enemy/Skeleton/Sprites/Sword_sprite.png", "region": Rect2(30, 34, 36, 36)},
			"desc": [
				{"ko": "칼날이 주위를 돌며 닿는 적을 벤다.", "en": "Blades orbit you, cutting anything they touch."},
				{"ko": "칼날 +1", "en": "+1 blade"},
				{"ko": "피해 +30%, 회전 속도 +20%", "en": "Damage +30%, spin speed +20%"},
				{"ko": "칼날 +1", "en": "+1 blade"},
				{"ko": "회전 반경 +25%", "en": "Orbit radius +25%"},
				{"ko": "칼날 +1, 피해 +30%", "en": "+1 blade, damage +30%"},
			],
			"stats": {
				"damage": [8, 8, 10.4, 10.4, 10.4, 13.5],
				"amount": [2, 3, 3, 4, 4, 5],
				"area":   [1.0, 1.0, 1.0, 1.0, 1.25, 1.25],
				"speed":  [3.0, 3.0, 3.6, 3.6, 3.6, 3.6],
			},
		},
		"aura": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/holy_aura_weapon.gd",
			"name": {"ko": "성스러운 오라", "en": "Holy Aura"},
			"icon": Vector2i(3, 9),
			"desc": [
				{"ko": "주변의 적에게 지속 피해를 주고 밀어낸다.", "en": "Damages and repels nearby enemies over time."},
				{"ko": "범위 +20%", "en": "Area +20%"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "범위 +20%", "en": "Area +20%"},
				{"ko": "피해 간격 -20%", "en": "Tick interval -20%"},
				{"ko": "피해 +40%, 범위 +20%", "en": "Damage +40%, area +20%"},
			],
			"stats": {
				"damage":   [5, 5, 7, 7, 7, 10],
				"area":     [1.0, 1.2, 1.2, 1.4, 1.4, 1.6],
				"cooldown": [0.6, 0.6, 0.6, 0.6, 0.48, 0.48],
			},
		},
		"eyebolt": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/eye_bolt_weapon.gd",
			"name": {"ko": "눈알 탄환", "en": "Eye Bolt"},
			"icon": {"path": "res://dynamic/2_enemy/FlyingEye/Sprites/projectile_sprite.png", "region": Rect2(8, 8, 32, 32)},
			"desc": [
				{"ko": "이동 방향으로 적을 꿰뚫는 탄환을 연사한다.", "en": "Fires piercing bolts in your moving direction."},
				{"ko": "탄환 +1", "en": "+1 bolt"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "탄환 +1, 관통 +1", "en": "+1 bolt, +1 pierce"},
				{"ko": "쿨타임 -20%", "en": "Cooldown -20%"},
				{"ko": "탄환 +2", "en": "+2 bolts"},
			],
			"stats": {
				"damage":   [9, 9, 12.6, 12.6, 12.6, 12.6],
				"amount":   [1, 2, 2, 3, 3, 5],
				"pierce":   [2, 2, 2, 3, 3, 3],
				"cooldown": [1.1, 1.1, 1.1, 1.1, 0.88, 0.88],
			},
		},
		"spore": {
			"type": "weapon", "max_level": 6, "script": "res://dynamic/8_roguelike/weapons/spore_weapon.gd",
			"name": {"ko": "버섯 포자", "en": "Spore Chain"},
			"icon": {"path": "res://dynamic/2_enemy/Mushroom/Sprites/Projectile_sprite.png", "region": Rect2(13, 13, 24, 24)},
			"desc": [
				{"ko": "맞히면 다른 적에게 튕겨 가는 포자를 쏜다.", "en": "Shoots spores that bounce between enemies."},
				{"ko": "튕김 +1", "en": "+1 bounce"},
				{"ko": "피해 +40%", "en": "Damage +40%"},
				{"ko": "포자 +1", "en": "+1 spore"},
				{"ko": "튕김 +2", "en": "+2 bounces"},
				{"ko": "피해 +40%, 포자 +1", "en": "Damage +40%, +1 spore"},
			],
			"stats": {
				"damage":   [11, 11, 15.4, 15.4, 15.4, 21.5],
				"amount":   [1, 1, 1, 2, 2, 3],
				"bounce":   [2, 3, 3, 3, 5, 5],
				"cooldown": [1.4, 1.4, 1.4, 1.4, 1.4, 1.4],
			},
		},
		"shadow": {
			"type": "weapon", "max_level": 3, "script": "res://dynamic/8_roguelike/weapons/shadow_weapon.gd",
			"name": {"ko": "그림자 분신", "en": "Shadow Partner"},
			"icon": "res://dynamic/5_title_screen/store/store_sprites/shadow_partner.png",
			"desc": [
				{"ko": "나를 따라다니며 함께 싸우는 그림자를 소환한다.", "en": "Summons a shadow that follows and fights with you."},
				{"ko": "그림자 2연타", "en": "Shadow double strike"},
				{"ko": "그림자 3연타", "en": "Shadow triple strike"},
			],
			"stats": {},
		},

		# ---------- 패시브 ----------
		"might": {
			"type": "passive", "max_level": 5, "icon": Vector2i(1, 10),
			"name": {"ko": "힘", "en": "Might"},
			"desc": [{"ko": "모든 공격 피해 +10%", "en": "All damage +10%"}],
		},
		"max_hp": {
			"type": "passive", "max_level": 5, "icon": Vector2i(0, 9),
			"name": {"ko": "활력", "en": "Vitality"},
			"desc": [{"ko": "최대 체력 +20, 체력 20 회복", "en": "Max HP +20, heal 20"}],
		},
		"speed": {
			"type": "passive", "max_level": 5, "icon": Vector2i(3, 11),
			"name": {"ko": "신속", "en": "Swiftness"},
			"desc": [{"ko": "이동 속도 +8%", "en": "Move speed +8%"}],
		},
		"vampire": {
			"type": "passive", "max_level": 5, "icon": Vector2i(1, 9),
			"name": {"ko": "흡혈", "en": "Vampirism"},
			"desc": [{"ko": "고유 무기 적중 시 피해의 1% 회복", "en": "Signature hits heal 1% of damage"}],
		},
		"magnet": {
			"type": "passive", "max_level": 5, "icon": Vector2i(10, 10),
			"name": {"ko": "자석", "en": "Magnet"},
			"desc": [{"ko": "아이템 흡수 범위 +25%", "en": "Pickup range +25%"}],
		},
		"armor": {
			"type": "passive", "max_level": 5, "icon": Vector2i(7, 9),
			"name": {"ko": "갑옷", "en": "Armor"},
			"desc": [{"ko": "받는 피해 -5%", "en": "Damage taken -5%"}],
		},
		"cooldown": {
			"type": "passive", "max_level": 5, "icon": Vector2i(8, 8),
			"name": {"ko": "가속", "en": "Haste"},
			"desc": [{"ko": "모든 쿨타임 -8%", "en": "All cooldowns -8%"}],
		},
		"area": {
			"type": "passive", "max_level": 5, "icon": Vector2i(0, 10),
			"name": {"ko": "확장", "en": "Expanse"},
			"desc": [{"ko": "공격 범위 +10%", "en": "Attack area +10%"}],
		},
		"amount": {
			"type": "passive", "max_level": 2, "icon": Vector2i(5, 9),
			"name": {"ko": "분열", "en": "Duplicator"},
			"desc": [{"ko": "투사체 +1", "en": "+1 projectile"}],
		},
		"growth": {
			"type": "passive", "max_level": 5, "icon": Vector2i(5, 11),
			"name": {"ko": "성장", "en": "Growth"},
			"desc": [{"ko": "경험치 획득 +10%", "en": "Experience +10%"}],
		},

		# ---------- 대체 선택지 (모두 최대 레벨일 때) ----------
		"food": {
			"type": "consumable", "max_level": 999, "icon": Vector2i(4, 8),
			"name": {"ko": "고기", "en": "Roast"},
			"desc": [{"ko": "체력 30 회복", "en": "Heal 30 HP"}],
		},
		"gold": {
			"type": "consumable", "max_level": 999, "icon": "res://dynamic/6_utillity/Items/gold/coin_05d.png",
			"name": {"ko": "금화 주머니", "en": "Gold Pouch"},
			"desc": [{"ko": "골드 +25", "en": "+25 gold"}],
		},
	}
