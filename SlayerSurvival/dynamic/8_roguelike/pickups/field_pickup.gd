extends PickupBase

class_name FieldPickup

## 필드 픽업 (적이 드물게 떨어뜨림)
## - magnet: 맵 위의 모든 경험치/골드를 끌어당김
## - nuke:   화면 안의 일반 적 전멸, 엘리트/보스에게 큰 피해

const NUKE_RANGE  = 900.0
const NUKE_DAMAGE = 250.0

var kind := "magnet"

static func create(pickup_kind: String) -> FieldPickup:
	var p = FieldPickup.new()
	p.kind = pickup_kind
	p.collision_mask = 2			# 플레이어 (자석 범위에도 감지되도록 레이어는 기본값 유지)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	p.add_child(shape)
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = UpgradeDB.sheet_icon(10, 10) if pickup_kind == "magnet" else UpgradeDB.sheet_icon(2, 10)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.6, 1.6)
	p.add_child(sprite)
	p.z_index = 3
	return p

func _ready():
	body_entered.connect(_on_body_entered)
	super._ready()

func on_collect():
	match kind:
		"magnet":
			var target = player.get_node("MagneticArea")
			for node in get_tree().get_nodes_in_group("Exp") + get_tree().get_nodes_in_group("Gold"):
				if node is PickupBase:
					node.attract(target)
			GameFeel.flash_screen(Color(0.4, 0.8, 1.0, 0.3), 0.3)
		"nuke":
			GameFeel.flash_screen(Color(1, 1, 1, 0.85), 0.5)
			GameFeel.shake(0.8)
			GameFeel.hitstop(0.12, 0.03)
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy.global_position.distance_to(player.global_position) > NUKE_RANGE:
					continue
				var is_minion = ("is_elite" in enemy) and not enemy.is_elite
				var dmg = enemy.health + 1.0 if is_minion else NUKE_DAMAGE
				enemy.take_damage(dmg, player.global_position, 2.0)
				RunStats.add_damage("nuke", dmg)
