extends Area2D

class_name ChestPickup

## 보물상자: 엘리트가 떨어뜨림. 플레이어가 닿으면 열리면서 업그레이드/진화 보상
## 보상 개수: 1개(75%) / 3개(20%) / 5개(5%)

const SHEET = preload("res://dynamic/8_roguelike/pickups/chest.png")
const GLOW  = preload("res://static/textures/light/circle.png")

var sprite: Sprite2D
var opened := false
var time := 0.0

static func create() -> ChestPickup:
	var c = ChestPickup.new()
	c.collision_layer = 0
	c.collision_mask = 2			# 플레이어
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	c.add_child(shape)
	var glow = Sprite2D.new()
	glow.texture = GLOW
	glow.modulate = Color(1.0, 0.85, 0.3, 0.35)
	glow.scale = Vector2(0.09, 0.09)
	c.add_child(glow)
	c.sprite = Sprite2D.new()
	c.sprite.texture = SHEET
	c.sprite.hframes = 2
	c.sprite.frame = 0
	c.sprite.scale = Vector2(2.6, 2.6)
	c.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	c.add_child(c.sprite)
	c.z_index = 4
	c.add_to_group("Chest")
	return c

func _ready():
	body_entered.connect(_on_body_entered)
	# 떨어질 때 통통 튀는 연출
	sprite.position.y = -30.0
	var t = create_tween()
	t.tween_property(sprite, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _process(delta):
	if opened:
		return
	time += delta
	sprite.position.y = sin(time * 4.0) * 2.0

func _on_body_entered(body):
	if opened or not body.has_method("roll_chest_rewards"):
		return
	opened = true
	sprite.frame = 1
	GameFeel.play_sfx("chest", 1.0, -3.0, 0.2)
	GameFeel.flash_screen(Color(1.0, 0.9, 0.5, 0.5), 0.3)
	GameFeel.burst(global_position, Color(1.0, 0.85, 0.3), 30, 260.0, 4.0)
	var r = randf()
	var count = 5 if r < 0.05 else (3 if r < 0.25 else 1)
	var select_ui = body.get_node("UI_Layer/SelectUI")
	select_ui.open_chest.call_deferred(count)		# 물리 콜백 중 노드 추가 방지
	queue_free()
