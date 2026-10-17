extends VBoxContainer

class_name HudSlots

## HUD 왼쪽 위: 보유 무기 / 패시브 작은 아이콘 (뱀서식)
## 장비가 바뀔 때만 다시 그림

const WEAPON_SIZE  = 34.0
const PASSIVE_SIZE = 28.0

var player
var key := ""
var timer := 0.0

func setup(p):
	player = p

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("separation", 3)

func _process(delta):
	timer -= delta
	if timer > 0.0 or player == null or not ("weapons" in player):
		return
	timer = 0.25
	var k = str(player.passives)
	for id in player.weapons.keys():
		k += id + str(player.weapons[id].level) + str(player.weapons[id].evolved)
	if k == key:
		return
	key = k
	for c in get_children():
		c.queue_free()
	add_child(_row(player.weapons.keys(), UpgradeDB.WEAPON_SLOTS, WEAPON_SIZE))
	add_child(_row(player.passives.keys(), UpgradeDB.PASSIVE_SLOTS, PASSIVE_SIZE))

func _row(ids: Array, slots: int, size: float) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in slots:
		var s = GameUI.upgrade_slot(player, ids[i] if i < ids.size() else "", size)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i >= ids.size():
			s.modulate.a = 0.3
		row.add_child(s)
	return row
