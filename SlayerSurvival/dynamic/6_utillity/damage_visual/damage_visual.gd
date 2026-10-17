extends Node

const FONT_PATH  = "res://static/font/DNFBitBitTTF.ttf"
const MAX_LABELS = 80			# 동시에 표시할 최대 데미지 숫자 (호드 상황 성능 보호)
const CRIT_COLOR = Color(1.0, 0.85, 0.2)

var font: Font
var active_labels := 0

func _ready():
	font = load(FONT_PATH)

# 데미지 숫자 표시: 튀어오르며(팝) 위로 떠오른 뒤 사라짐
func show_damage(damage: float, position: Vector2, color : Color = Color.RED, is_crit: bool = false):
	var scene = get_tree().current_scene
	if scene == null:
		return
	# 너무 많으면 일반 데미지는 생략 (치명타는 항상 표시)
	if active_labels >= MAX_LABELS and not is_crit:
		return
	var label = Label.new()
	label.text = _format_damage(damage) + ("!" if is_crit else "")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 22 if is_crit else 15)
	label.add_theme_color_override("font_color", CRIT_COLOR if is_crit else color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4 if is_crit else 3)
	label.z_index = 50
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 씬 추가 + 위치 설정 (살짝 랜덤하게 흩어지도록)
	scene.add_child(label)
	var start = position + Vector2(randf_range(-10, 10), randf_range(-14, -4))
	label.position = start
	label.reset_size()
	label.pivot_offset = label.size / 2
	label.scale = Vector2(1.8, 1.8) if is_crit else Vector2(1.4, 1.4)
	active_labels += 1
	label.tree_exited.connect(func(): active_labels -= 1)

	# 애니메이션 (팝 → 위로 떠오름 → 사라짐)
	var rise = 34.0 if is_crit else 24.0
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", start.y - rise, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)

func _format_damage(damage: float) -> String:
	if is_equal_approx(damage, round(damage)):
		return str(int(round(damage)))
	return str(snappedf(damage, 0.1))
