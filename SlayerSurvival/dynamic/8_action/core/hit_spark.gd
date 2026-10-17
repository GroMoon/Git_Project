extends Node2D
## 타격 스파크 (코드 드로잉, 가산 합성)
##   slash : 사선 베기 섬광 + 방사형 스트릭
##   heavy : 큰 섬광 + 충격파 링 (띄우기/강타)
##   blunt : 짧은 방사형 폭발 (적의 공격 등)

var kind  := "slash"
var color := Color(1.0, 0.9, 0.55)
var dir   := 1
var life  := 0.18

var _t     := 0.0
var _angle := 0.0
var _size  := 60.0
var _rays  : Array[Vector2] = []

func _ready():
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	scale.x = dir
	_angle = deg_to_rad(randf_range(-40.0, 25.0))
	var ray_count := 8
	match kind:
		"heavy":
			life = 0.26
			_size = 95.0
			ray_count = 12
		"blunt":
			life = 0.15
			_size = 48.0
	for i in ray_count:
		_rays.append(Vector2(randf() * TAU, randf_range(0.55, 1.0)))

func _process(delta):
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()

func _draw():
	var p := _t / life
	var fade := 1.0 - p
	# 중심 섬광
	draw_circle(Vector2.ZERO, _size * 0.32 * (1.0 - p * 0.7), Color(1, 1, 1, 0.85 * fade))
	draw_circle(Vector2.ZERO, _size * 0.5 * (1.0 - p * 0.5), Color(color, 0.25 * fade))
	# 방사형 스트릭
	for ray in _rays:
		var v := Vector2.from_angle(ray.x)
		var r0: float = _size * (0.12 + 0.55 * p) * ray.y
		var r1: float = _size * (0.45 + 0.9 * ease(p, 0.4)) * ray.y
		draw_line(v * r0, v * r1, Color(color, fade), 3.0 * fade + 1.0)
	# 베기 섬광
	if kind != "blunt":
		var v := Vector2.from_angle(_angle)
		var half := _size * (0.8 + 0.9 * ease(p, 0.3))
		var width := 12.0 * fade + 1.0
		draw_line(-v * half, v * half, Color(color, 0.8 * fade), width)
		draw_line(-v * half * 0.9, v * half * 0.9, Color(1, 1, 1, fade), width * 0.35)
	# 충격파 링
	if kind == "heavy":
		draw_arc(Vector2.ZERO, _size * (0.25 + 1.1 * p), 0.0, TAU, 40, Color(color, 0.8 * fade), 5.0 * fade + 1.0)
