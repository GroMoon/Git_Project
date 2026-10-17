extends Control

class_name BossBar

## 엘리트 / 보스 체력바 (화면 상단, 던전앤파이터식 여러 줄 체력)
## - 마지막으로 공격한 엘리트 또는 보스를 표시 (보스가 살아 있으면 보스 우선)
## - 체력을 여러 줄로 나눠 줄마다 색이 바뀌고, 남은 줄 수 "x12" 표시
## - 깎인 체력은 흰색 잔상으로 천천히 줄어듦

const BAR_SIZE    = Vector2(560, 18)
const ELITE_LINES = 3
const BOSS_LINES  = 15
const LINE_COLORS = [
	Color(0.85, 0.15, 0.15), Color(0.95, 0.5, 0.1), Color(0.95, 0.85, 0.15), Color(0.3, 0.8, 0.25),
	Color(0.15, 0.7, 0.85), Color(0.25, 0.4, 0.95), Color(0.6, 0.3, 0.9),
]

var target: Node = null
var shown_hp := 0.0			# 잔상(흰색) 체력
var name_label: Label
var lines_label: Label
var bar: Control
var hide_timer := 0.0

func _ready():
	position = Vector2((1280 - BAR_SIZE.x) / 2.0, 84)
	size = Vector2(BAR_SIZE.x, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	modulate.a = 0.0
	name_label = _label(16, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = Vector2(0, 0)
	add_child(name_label)
	lines_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	lines_label.position = Vector2(BAR_SIZE.x - 120, 0)
	lines_label.size = Vector2(120, 20)
	add_child(lines_label)
	bar = Control.new()
	bar.position = Vector2(0, 22)
	bar.size = BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	add_child(bar)

func _label(font_size: int, align) -> Label:
	var l = Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = align
	l.size = Vector2(BAR_SIZE.x, 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# 표시 대상 지정 (엘리트/보스가 피해를 받을 때, 보스가 등장할 때 호출)
func track(enemy: Node):
	if enemy == target:
		return
	# 보스를 보고 있으면 엘리트로 바꾸지 않음
	if _alive(target) and _is_boss(target) and not _is_boss(enemy):
		return
	target = enemy
	shown_hp = enemy.health
	hide_timer = 0.0
	name_label.text = enemy.display_name() if enemy.has_method("display_name") else String(enemy.name)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4) if _is_boss(enemy) else Color(1.0, 0.85, 0.4))
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

func _alive(enemy) -> bool:
	return enemy != null and is_instance_valid(enemy) and not enemy.is_dead

func _is_boss(enemy) -> bool:
	return enemy != null and is_instance_valid(enemy) and not ("is_elite" in enemy)

func _process(delta):
	if target == null:
		return
	if not _alive(target):
		# 처치: 잠깐 보여준 뒤 사라짐
		hide_timer += delta
		shown_hp = move_toward(shown_hp, 0.0, _max_hp() * delta * 2.0)
		if hide_timer > 1.0:
			create_tween().tween_property(self, "modulate:a", 0.0, 0.3)
			target = null
		bar.queue_redraw()
		return
	# 잔상은 실제 체력을 천천히 따라감
	var hp = max(target.health, 0.0)
	shown_hp = move_toward(shown_hp, hp, max(_max_hp() * 0.25, abs(shown_hp - hp) * 3.0) * delta)
	var per_line = _per_line()
	var line_index = int(ceil(hp / per_line)) if hp > 0 else 0
	lines_label.text = "x%d" % line_index
	bar.queue_redraw()

func _max_hp() -> float:
	if target == null or not is_instance_valid(target):
		return 1.0
	return max(target.max_health, 1.0)

func _per_line() -> float:
	var lines = BOSS_LINES if _is_boss(target) else ELITE_LINES
	return _max_hp() / lines

func _draw_bar():
	var r = Rect2(Vector2.ZERO, BAR_SIZE)
	bar.draw_rect(r.grow(3.0), Color(0, 0, 0, 0.75))
	if target == null or not is_instance_valid(target):
		return
	var per_line = _per_line()
	var hp = max(target.health, 0.0) if _alive(target) else 0.0
	# 현재 줄 / 다음 줄 색
	var line = int(ceil(hp / per_line)) if hp > 0 else 0
	var in_line = hp - (line - 1) * per_line if line > 0 else 0.0
	var ratio = clamp(in_line / per_line, 0.0, 1.0)
	var color = LINE_COLORS[(line - 1) % LINE_COLORS.size()] if line > 0 else Color.BLACK
	var under = LINE_COLORS[(line - 2) % LINE_COLORS.size()] if line > 1 else Color(0.12, 0.1, 0.1)
	bar.draw_rect(r, under)
	# 잔상 (같은 줄 안에서만)
	var trail_in_line = clamp((shown_hp - (line - 1) * per_line) / per_line, ratio, 1.0) if line > 0 else 0.0
	if trail_in_line > ratio:
		bar.draw_rect(Rect2(Vector2(BAR_SIZE.x * ratio, 0), Vector2(BAR_SIZE.x * (trail_in_line - ratio), BAR_SIZE.y)), Color(1, 1, 1, 0.85))
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)), color)
	# 윗부분 하이라이트
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(BAR_SIZE.x * ratio, 4)), Color(1, 1, 1, 0.25))
