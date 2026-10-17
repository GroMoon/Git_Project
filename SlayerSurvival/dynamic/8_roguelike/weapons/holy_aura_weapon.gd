extends WeaponBase

## 성스러운 오라: 플레이어 주변 원형 범위에 주기적으로 피해 + 밀쳐냄 (마늘형)

const BASE_RADIUS = 62.0
const LIGHT_TEX   = preload("res://static/textures/light/circle.png")

var area_node: Area2D
var shape: CircleShape2D
var visual: Sprite2D
var pulse_tween: Tween

func _ready():
	area_node = Area2D.new()
	area_node.collision_layer = 0
	area_node.collision_mask = ENEMY_MASK
	area_node.monitorable = false
	var cs = CollisionShape2D.new()
	shape = CircleShape2D.new()
	cs.shape = shape
	area_node.add_child(cs)
	add_child(area_node)
	visual = Sprite2D.new()
	visual.texture = LIGHT_TEX
	visual.modulate = Color(1.0, 0.85, 0.35, 0.22)
	add_child(visual)
	_update_radius()

func on_level_changed():
	if shape:
		_update_radius()

func _update_radius():
	var radius = BASE_RADIUS * get_area()
	shape.radius = radius
	# circle.png 는 800px, 가장자리가 부드럽게 빠지므로 살짝 크게
	var s = radius * 2.3 / LIGHT_TEX.get_width()
	visual.scale = Vector2(s, s)

func fire() -> bool:
	_update_radius()
	var hit_any = false
	for body in area_node.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			hit(body, get_damage(), 0.55, global_position)
			hit_any = true
	# 피해 줄 때마다 은은하게 맥동
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	visual.modulate.a = 0.4 if hit_any else 0.28
	pulse_tween = visual.create_tween()
	pulse_tween.tween_property(visual, "modulate:a", 0.2, 0.35)
	return true
