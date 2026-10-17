extends WeaponBase

## 성스러운 오라: 플레이어 주변 원형 범위에 주기적으로 피해 + 밀쳐냄 (마늘형)
## 범위가 한눈에 보이도록 반투명 원 + 테두리 + 회전하는 룬 + 피해 줄 때마다 퍼지는 파동

const BASE_RADIUS = 62.0
const RUNE_COUNT  = 10

var area_node: Area2D
var shape: CircleShape2D
var visual: Node2D
var radius := BASE_RADIUS
var spin := 0.0
var pulse := 1.0				# 0 → 1 로 진행하는 파동 (1이면 없음)

func _ready():
	area_node = Area2D.new()
	area_node.collision_layer = 0
	area_node.collision_mask = ENEMY_MASK
	var cs = CollisionShape2D.new()
	shape = CircleShape2D.new()
	cs.shape = shape
	area_node.add_child(cs)
	add_child(area_node)
	visual = Node2D.new()
	visual.draw.connect(_draw_aura)
	# 바닥(맵 z -10) 바로 위에 그려서 플레이어/적 스프라이트를 덮지 않게
	visual.z_as_relative = false
	visual.z_index = -5
	add_child(visual)
	_update_radius()

func on_level_changed():
	if shape:
		_update_radius()

func _update_radius():
	radius = BASE_RADIUS * get_area()
	shape.radius = radius

func _process(delta):
	spin += delta * 0.8
	if pulse < 1.0:
		pulse = min(pulse + delta / 0.35, 1.0)
	visual.queue_redraw()

func _colors() -> Array:
	# [채움, 테두리, 룬]
	if evolved:
		return [Color(1.0, 0.2, 0.25, 0.07), Color(1.0, 0.35, 0.35, 0.45), Color(1.0, 0.55, 0.5, 0.32)]
	return [Color(1.0, 0.9, 0.45, 0.06), Color(1.0, 0.92, 0.55, 0.42), Color(1.0, 0.97, 0.75, 0.3)]

func _draw_aura():
	var c = _colors()
	visual.draw_circle(Vector2.ZERO, radius, c[0])
	visual.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, c[1], 2.0, true)
	visual.draw_arc(Vector2.ZERO, radius - 5.0, 0.0, TAU, 72, Color(c[1].r, c[1].g, c[1].b, c[1].a * 0.35), 1.5, true)
	# 테두리를 따라 도는 룬 조각
	var seg = TAU / RUNE_COUNT
	for i in RUNE_COUNT:
		var a = spin + i * seg
		visual.draw_arc(Vector2.ZERO, radius * 0.88, a, a + seg * 0.35, 6, c[2], 2.0, true)
	# 피해 파동: 안쪽에서 테두리까지 퍼지며 사라짐
	if pulse < 1.0:
		var pr = lerp(radius * 0.35, radius, pulse)
		visual.draw_arc(Vector2.ZERO, pr, 0.0, TAU, 72, Color(c[1].r, c[1].g, c[1].b, (1.0 - pulse) * 0.5), 2.5, true)

func fire() -> bool:
	_update_radius()
	var hit_count = 0
	for body in area_node.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			hit(body, get_damage(), 0.55, global_position)
			hit_count += 1
	# 진화(피의 성역): 적중한 적 수만큼 체력 회복
	if evolved and hit_count > 0:
		player.add_food(min(hit_count * 0.3, 2.0))
	# 피해 줄 때마다 파동
	if hit_count > 0:
		pulse = 0.0
	return true
