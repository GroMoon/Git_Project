extends Control

class_name OffscreenIndicators

## 화면 밖 보물상자 / 필드 아이템 위치를 화면 가장자리 화살표로 표시 (뱀파이어 서바이벌식)
## - 대상: 보물상자(Chest), 자석·폭탄(FieldPickup), 음식(Food)
## - 아이템 아이콘 + 바깥쪽을 가리키는 삼각형, 가까운 순으로 최대 MAX_COUNT 개

const MAX_COUNT = 8
const EDGE = Rect2(40, 84, 1280 - 80, 720 - 84 - 54)		# 화살표가 놓이는 영역 (위쪽 HUD 와 아래 조작 안내를 피함)
const ICON = 34.0
const COLORS = {"chest": Color(1.0, 0.8, 0.3), "magnet": Color(0.45, 0.75, 1.0), "nuke": Color(1.0, 0.4, 0.35), "food": Color(0.5, 0.95, 0.5)}

var player
var targets: Array = []			# [Node2D, kind]
var scan_timer := 0.0
var time := 0.0

func setup(p):
	player = p

func _ready():
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta):
	time += delta
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.2
		_scan()
	queue_redraw()

# 표시할 대상 목록 갱신 (매 프레임 그룹을 훑지 않도록 0.2초마다)
func _scan():
	targets.clear()
	for c in get_tree().get_nodes_in_group("Chest"):
		if not c.get("opened"):
			targets.append([c, "chest"])
	for p in get_tree().get_nodes_in_group("FieldPickup"):
		if not p.collected:
			targets.append([p, p.kind])
	for f in get_tree().get_nodes_in_group("Food"):
		if not f.get("collected"):
			targets.append([f, "food"])

func _draw():
	if player == null or not is_instance_valid(player) or player.is_dead:
		return
	var canvas = get_viewport().get_canvas_transform()
	var center = Vector2(640, 360)
	var list = []
	for t in targets:
		# 주운 아이템은 삭제되므로 타입 지정 변수에 넣기 전에 먼저 확인
		if not is_instance_valid(t[0]) or not t[0].is_inside_tree():
			continue
		var node: Node2D = t[0]
		var p = canvas * node.global_position
		if Rect2(Vector2.ZERO, size).grow(-8.0).has_point(p):
			continue		# 화면 안에 보이면 표시 안 함
		list.append([center.distance_squared_to(p), p, node, t[1]])
	list.sort_custom(func(a, b): return a[0] < b[0])
	for i in min(list.size(), MAX_COUNT):
		_draw_indicator(center, list[i][1], list[i][2], list[i][3])

# 화면 중심 → 대상 방향의 직선이 EDGE 사각형과 만나는 곳에 아이콘 + 화살표
func _draw_indicator(center: Vector2, target: Vector2, node: Node2D, kind: String):
	var dir = target - center
	if dir.length() < 1.0:
		return
	var tx = INF
	var ty = INF
	if dir.x != 0.0:
		tx = ((EDGE.end.x if dir.x > 0.0 else EDGE.position.x) - center.x) / dir.x
	if dir.y != 0.0:
		ty = ((EDGE.end.y if dir.y > 0.0 else EDGE.position.y) - center.y) / dir.y
	var pos = center + dir * min(tx, ty)
	var n = dir.normalized()
	var color: Color = COLORS.get(kind, Color.WHITE)
	var pulse = 1.0 + sin(time * 6.0) * 0.08
	# 바깥쪽을 가리키는 삼각형
	var tip = pos + n * (ICON * 0.9 * pulse)
	var side = n.orthogonal() * 9.0
	var base = pos + n * (ICON * 0.5)
	draw_colored_polygon(PackedVector2Array([tip + n * 2.0, base + side * 1.3, base - side * 1.3]), Color(0, 0, 0, 0.8))
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
	# 아이콘 (원형 받침 + 아이템 그림)
	var r = ICON * 0.5 * pulse
	draw_circle(pos, r + 3.0, Color(0, 0, 0, 0.75))
	draw_arc(pos, r + 2.0, 0.0, TAU, 24, color, 2.0)
	var icon = _icon_of(node)
	if icon.size() == 2:
		var tex: Texture2D = icon[0]
		var src: Rect2 = icon[1]
		var s = (r * 1.6) / max(src.size.x, src.size.y)
		var dest = Rect2(pos - src.size * s / 2.0, src.size * s)
		draw_texture_rect_region(tex, dest, src)

# 대상 노드의 스프라이트 그림 (보물상자는 빛 번짐 스프라이트를 건너뛰고 마지막 Sprite2D)
func _icon_of(node: Node) -> Array:
	var sprite: Sprite2D = null
	for c in node.get_children():
		if c is Sprite2D and c.texture != null:
			sprite = c
	if sprite == null:
		return []
	var tex = sprite.texture
	var src = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, tex.get_size())
	var fw = src.size.x / sprite.hframes
	var fh = src.size.y / sprite.vframes
	src = Rect2(src.position + Vector2(sprite.frame_coords.x * fw, sprite.frame_coords.y * fh), Vector2(fw, fh))
	return [tex, src]
