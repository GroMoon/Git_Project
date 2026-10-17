extends Node2D
## 횡스크롤 던전 배경 : 기존 던전 타일셋(mainlevbuild.png)의 벽/바닥 조각을 가로로 이어 그린다.
##   y 0~147   : 벽돌 상단
##   y 147~381 : 지하묘지 벽 패널
##   y 390~    : 바닥 타일

const ATLAS = preload("res://dynamic/4_world/dungeon_B1F/mainlevbuild.png")

const TILE_SCALE := 3.0
const BRICK      := Rect2(272, 272, 160, 49)
const PANELS     := [Rect2(58, 192, 204, 78), Rect2(58, 336, 204, 78), Rect2(58, 416, 204, 78)]
const FLOORS     := [Rect2(736, 272, 32, 32), Rect2(784, 272, 32, 32), Rect2(736, 320, 32, 32), Rect2(784, 320, 32, 32)]
const DOOR       := Rect2(640, 0, 80, 96)
const STAIRS     := Rect2(880, 0, 64, 105)

const WALL_TOP    := 0.0
const PANEL_TOP   := 147.0
const WALL_BOTTOM := 390.0
const MARGIN      := 240.0		# 화면 흔들림 대비 여유 영역

var room_width := 2600.0
var show_exit  := true
var hazards : Array = []		# (지하묘지는 위험 지대 없음, cave_backdrop.gd 와 인터페이스 통일)

## stage가 room_width 를 바꾼 뒤 호출
func rebuild():
	queue_redraw()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw():
	var left := -MARGIN
	var right := room_width + MARGIN
	# 바탕 어둠
	draw_rect(Rect2(left, -MARGIN, right - left, 720.0 + MARGIN * 2.0), Color(0.04, 0.035, 0.045))

	# 벽돌 상단
	var brick_w := BRICK.size.x * TILE_SCALE
	var x := left
	while x < right:
		draw_texture_rect_region(ATLAS, Rect2(x, WALL_TOP, brick_w, BRICK.size.y * TILE_SCALE), BRICK)
		x += brick_w
	# 상단을 어둡게 (천장 그림자)
	_gradient_rect(Rect2(left, WALL_TOP, right - left, 150.0), Color(0, 0, 0, 0.75), Color(0, 0, 0, 0.0))

	# 벽 패널
	var panel_w: float = PANELS[0].size.x * TILE_SCALE
	var index := 0
	x = left
	while x < right:
		var region: Rect2 = PANELS[_hash(index, 7) % PANELS.size()]
		draw_texture_rect_region(ATLAS, Rect2(x, PANEL_TOP, panel_w, region.size.y * TILE_SCALE), region)
		x += panel_w
		index += 1

	# 입구 / 출구 문
	_draw_on_wall(DOOR, 140.0)
	if show_exit:
		_draw_on_wall(STAIRS, room_width - 140.0)

	# 벽 하단 걸레받이 + 바닥 접합부 그림자
	draw_rect(Rect2(left, WALL_BOTTOM - 10.0, right - left, 12.0), Color(0.07, 0.06, 0.06))

	# 바닥 타일
	var tile: float = FLOORS[0].size.x * TILE_SCALE
	var row := 0
	var y := WALL_BOTTOM
	while y < 720.0 + MARGIN:
		var col := 0
		x = left
		while x < right:
			var region: Rect2 = FLOORS[_hash(col, row) % FLOORS.size()]
			draw_texture_rect_region(ATLAS, Rect2(x, y, tile, tile), region)
			x += tile
			col += 1
		y += tile
		row += 1
	# 벽 쪽 바닥 그림자 + 화면 앞쪽 어둡게 (원근감)
	_gradient_rect(Rect2(left, WALL_BOTTOM, right - left, 70.0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0))
	_gradient_rect(Rect2(left, 640.0, right - left, 80.0 + MARGIN), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6))

## 벽 하단에 붙여 그리기 (center_x 기준)
func _draw_on_wall(region: Rect2, center_x: float):
	var size := region.size * TILE_SCALE
	draw_texture_rect_region(ATLAS, Rect2(center_x - size.x * 0.5, WALL_BOTTOM - size.y, size.x, size.y), region)

func _gradient_rect(rect: Rect2, top: Color, bottom: Color):
	var points := PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	draw_polygon(points, PackedColorArray([top, top, bottom, bottom]))

static func _hash(a: int, b: int) -> int:
	return absi((a * 73856093) ^ (b * 19349663)) % 9973
