extends RefCounted
## 스킬 연출용 이펙트 노드 모음 (CombatFX가 생성)

## 잔상 : 현재 프레임을 복사해 색을 입히고 서서히 사라짐
class Afterimage extends Sprite2D:
	var life := 0.25
	var _t := 0.0
	func _ready():
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive
	func _process(delta):
		_t += delta
		modulate.a = maxf(0.0, 0.55 * (1.0 - _t / life))
		if _t >= life:
			queue_free()

## 회오리 : 대상 주변을 도는 호(arc)들
class Whirl extends Node2D:
	var target : Node2D
	var life   := 0.6
	var radius := 120.0
	var color  := Color(0.55, 0.9, 1.0)
	var _t := 0.0
	func _ready():
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive
	func _process(delta):
		_t += delta
		if _t >= life or not is_instance_valid(target):
			queue_free()
			return
		position = target.position + Vector2(0, -target.z - 45.0)
		queue_redraw()
	func _draw():
		var fade := minf(1.0, (life - _t) / 0.15) * minf(1.0, _t / 0.08)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		for i in 4:
			var spin: float = _t * 18.0 + i * TAU / 4.0
			var r: float = radius * (0.55 + 0.15 * i)
			draw_arc(Vector2.ZERO, r, spin, spin + 1.9, 18, Color(color, 0.75 * fade), 7.0 - i)
			draw_arc(Vector2.ZERO, r * 0.95, spin + 0.2, spin + 1.4, 12, Color(1, 1, 1, 0.6 * fade), 2.0)

## 충격파 : 바닥에 납작하게 퍼지는 링 + 파편
class Shockwave extends Node2D:
	var radius := 260.0
	var life   := 0.45
	var color  := Color(1.0, 0.7, 0.35)
	var _t := 0.0
	var _debris : Array[Vector3] = []		# (각도, 속도, 크기)
	func _ready():
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive
		for i in 18:
			_debris.append(Vector3(randf() * TAU, randf_range(0.5, 1.0), randf_range(3.0, 7.0)))
	func _process(delta):
		_t += delta
		if _t >= life:
			queue_free()
			return
		queue_redraw()
	func _draw():
		var p := _t / life
		var fade := 1.0 - p
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		draw_arc(Vector2.ZERO, radius * ease(p, 0.35), 0.0, TAU, 48, Color(color, fade), 14.0 * fade + 2.0)
		draw_arc(Vector2.ZERO, radius * 0.8 * ease(p, 0.35), 0.0, TAU, 48, Color(1, 1, 1, 0.7 * fade), 4.0)
		draw_circle(Vector2.ZERO, radius * 0.35 * (1.0 - p), Color(1, 0.95, 0.8, 0.5 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for d in _debris:
			var dir := Vector2.from_angle(d.x)
			var dist: float = radius * 0.9 * d.y * ease(p, 0.4)
			var pos := Vector2(dir.x * dist, dir.y * dist * 0.32 - sin(p * PI) * 70.0 * d.y)
			draw_rect(Rect2(pos - Vector2.ONE * d.z * 0.5, Vector2.ONE * d.z), Color(0.9, 0.8, 0.65, fade))

## 화면 전체 번쩍임 (CanvasLayer 위 ColorRect)
class ScreenFlash extends ColorRect:
	var life := 0.2
	var _t := 0.0
	var _alpha := 0.8
	func start(c: Color, duration: float):
		color = c
		_alpha = c.a
		life = duration
		_t = 0.0
		visible = true
	func _process(delta):
		if not visible:
			return
		_t += delta
		color.a = _alpha * maxf(0.0, 1.0 - _t / life)
		if _t >= life:
			visible = false

## 위험 범위 표시 : 바닥에 붉은 영역이 차오르다가 공격 순간 사라짐
class Telegraph extends Node2D:
	var rect := Rect2()
	var life := 0.5
	var ellipse := false		# true면 타원 (주문 낙하 지점)
	var _t := 0.0
	func _process(delta):
		_t += delta
		if _t >= life + 0.12:
			queue_free()
			return
		queue_redraw()
	func _draw():
		var p := minf(1.0, _t / life)
		var fade := 1.0 if _t < life else maxf(0.0, 1.0 - (_t - life) / 0.12)
		var pulse := 0.5 + 0.5 * sin(_t * 30.0)
		if ellipse:
			var center := rect.get_center()
			draw_set_transform(center, 0.0, Vector2(1.0, rect.size.y / rect.size.x))
			var radius := rect.size.x * 0.5
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.1, 0.1, 0.18 * fade))
			draw_circle(Vector2.ZERO, radius * p, Color(1.0, 0.15, 0.1, 0.3 * fade))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.3, 0.2, (0.5 + 0.4 * pulse) * fade), 3.0)
			return
		draw_rect(rect, Color(1.0, 0.1, 0.1, 0.16 * fade))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * p)).abs(), Color(1.0, 0.15, 0.1, 0.22 * fade))
		draw_rect(rect, Color(1.0, 0.3, 0.2, (0.45 + 0.4 * pulse) * fade), false, 3.0)
