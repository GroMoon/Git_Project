extends Node2D
## 용암 동굴 배경 : 기존 cave 타일셋(cave.png, 16px 격자)을 4배로 키워 가로로 이어 그린다.
##   y 0~160   : 동굴 천장 어둠
##   y 40~390  : 갈라진 암벽 (아래로 갈수록 용암빛)
##   y 390~    : 흙바닥 + 용암 웅덩이(hazards)
## dungeon_backdrop.gd 와 같은 인터페이스 (room_width, show_exit, hazards)

const ATLAS = preload("res://dynamic/4_world/cave/cave.png")

const S          := 4.0		# 타일 배율
const WALL       := Rect2(192, 16, 64, 32)		# 갈라진 암벽
const ARCH       := Rect2(48, 16, 48, 32)		# 동굴 입구
const LIGHT_HOLE := Rect2(48, 64, 48, 32)		# 빛이 새는 구멍
const FLOOR_PLAIN := Rect2(0, 160, 16, 16)
const FLOOR_DECO := [Rect2(0, 112, 16, 16), Rect2(16, 112, 16, 16), Rect2(0, 128, 16, 16),
	Rect2(16, 128, 16, 16), Rect2(0, 144, 16, 16), Rect2(16, 144, 16, 16)]
const LAVA_TILES := [Rect2(0, 304, 16, 16), Rect2(16, 304, 16, 16), Rect2(32, 304, 16, 16),
	Rect2(48, 320, 16, 16), Rect2(64, 320, 16, 16), Rect2(80, 304, 16, 16)]

const WALL_TOP    := 40.0
const WALL_BOTTOM := 390.0
const MARGIN      := 240.0

var room_width := 2200.0
var show_exit  := true
var hazards : Array = []		# [Rect2] 용암 웅덩이 (바닥 좌표)

var _pools : Array[Node2D] = []
var _embers : CPUParticles2D

## 용암 웅덩이 : 타일 + 일렁이는 밝기 + 가장자리 빛
class LavaPool extends Node2D:
	var rect := Rect2()
	var _t := 0.0
	func _process(delta):
		_t += delta
		modulate = Color(1.0, 0.9 + 0.1 * sin(_t * 3.0), 0.85 + 0.15 * sin(_t * 2.3 + 1.0))
		queue_redraw()
	func _draw():
		var tile := 16.0 * S
		var col := 0
		var x := rect.position.x
		while x < rect.end.x:
			var row := 0
			var y := rect.position.y
			while y < rect.end.y:
				var w := minf(tile, rect.end.x - x)
				var h := minf(tile, rect.end.y - y)
				var region: Rect2 = LAVA_TILES[(col * 3 + row * 5 + int(_t * 2.0)) % LAVA_TILES.size()]
				draw_texture_rect_region(ATLAS, Rect2(x, y, w, h), Rect2(region.position, Vector2(region.size.x * w / tile, region.size.y * h / tile)))
				y += tile
				row += 1
			x += tile
			col += 1
		var glow := 0.55 + 0.25 * sin(_t * 4.0)
		draw_rect(rect.grow(4.0), Color(1.0, 0.55, 0.15, glow * 0.6), false, 4.0)
		draw_rect(rect.grow(10.0), Color(1.0, 0.35, 0.1, glow * 0.25), false, 6.0)

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_embers = CPUParticles2D.new()
	_embers.amount = 70
	_embers.lifetime = 4.0
	_embers.preprocess = 4.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.direction = Vector2(0, -1)
	_embers.spread = 25.0
	_embers.gravity = Vector2(0, -12)
	_embers.initial_velocity_min = 20.0
	_embers.initial_velocity_max = 60.0
	_embers.scale_amount_min = 2.0
	_embers.scale_amount_max = 4.0
	_embers.color = Color(1.0, 0.55, 0.2, 0.8)
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.7, 0.3, 0.9))
	fade.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	_embers.color_ramp = fade
	add_child(_embers)
	rebuild()

## stage가 room_width / hazards 를 바꾼 뒤 호출
func rebuild():
	for pool in _pools:
		pool.queue_free()
	_pools.clear()
	for rect in hazards:
		var pool := LavaPool.new()
		pool.rect = rect
		add_child(pool)
		_pools.append(pool)
	_embers.position = Vector2(room_width * 0.5, 700)
	_embers.emission_rect_extents = Vector2(room_width * 0.5, 20)
	queue_redraw()

func _draw():
	var left := -MARGIN
	var right := room_width + MARGIN
	draw_rect(Rect2(left, -MARGIN, right - left, 720.0 + MARGIN * 2.0), Color(0.055, 0.035, 0.03))

	# 암벽 (줄마다 반 칸씩 엇갈려 이음매를 숨김)
	var wall_w := WALL.size.x * S
	var wall_h := WALL.size.y * S
	var row := 0
	var y := WALL_TOP
	while y < WALL_BOTTOM:
		var x := left - (wall_w * 0.5 if row % 2 == 1 else 0.0)
		while x < right:
			draw_texture_rect_region(ATLAS, Rect2(x, y, wall_w, wall_h), WALL)
			x += wall_w
		y += wall_h
		row += 1

	# 빛 구멍 장식
	var hole := LIGHT_HOLE.size * S
	var hx := 700.0
	while hx < room_width - 300.0:
		draw_texture_rect_region(ATLAS, Rect2(hx, 180.0, hole.x, hole.y), LIGHT_HOLE)
		hx += 1100.0

	# 천장 어둠 + 벽 하단 용암빛
	_gradient_rect(Rect2(left, -MARGIN, right - left, MARGIN + 170.0), Color(0.02, 0.01, 0.01, 1.0), Color(0.02, 0.01, 0.01, 0.0))
	_gradient_rect(Rect2(left, 290.0, right - left, WALL_BOTTOM - 290.0), Color(1.0, 0.4, 0.1, 0.0), Color(1.0, 0.45, 0.12, 0.42))

	# 입구 / 출구 동굴
	var arch := ARCH.size * 5.0
	draw_texture_rect_region(ATLAS, Rect2(140.0 - arch.x * 0.5, WALL_BOTTOM - arch.y, arch.x, arch.y), ARCH)
	if show_exit:
		draw_texture_rect_region(ATLAS, Rect2(room_width - 140.0 - arch.x * 0.5, WALL_BOTTOM - arch.y, arch.x, arch.y), ARCH)

	# 흙바닥 (무늬 타일은 가끔만)
	var tile := 16.0 * S
	row = 0
	y = WALL_BOTTOM
	while y < 720.0 + MARGIN:
		var col := 0
		var x := left
		while x < right:
			var h := _hash(col, row)
			var region: Rect2 = FLOOR_PLAIN if h % 10 < 7 else FLOOR_DECO[h % FLOOR_DECO.size()]
			draw_texture_rect_region(ATLAS, Rect2(x, y, tile, tile), region)
			x += tile
			col += 1
		y += tile
		row += 1
	_gradient_rect(Rect2(left, WALL_BOTTOM, right - left, 70.0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0))
	_gradient_rect(Rect2(left, 640.0, right - left, 80.0 + MARGIN), Color(0, 0, 0, 0.0), Color(0.05, 0.0, 0.0, 0.6))

func _gradient_rect(rect: Rect2, top: Color, bottom: Color):
	var points := PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	draw_polygon(points, PackedColorArray([top, top, bottom, bottom]))

static func _hash(a: int, b: int) -> int:
	return absi((a * 73856093) ^ (b * 19349663)) % 9973
