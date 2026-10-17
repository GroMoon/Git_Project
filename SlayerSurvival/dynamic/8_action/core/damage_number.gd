extends Node2D
## 데미지 숫자 : 크게 튀어나왔다가 줄어들고, 위로 떠오르며 사라짐

const FONT = preload("res://static/font/DNFBitBitTTF.ttf")

var value     := 0
var text      := ""		# 비어있지 않으면 숫자 대신 표시 (COUNTER!, GUARD 등)
var color     := Color(1.0, 0.92, 0.45)
var font_size := 26

func _ready():
	var label := Label.new()
	label.text = text if text != "" else str(value)
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	label.add_theme_constant_override("outline_size", 7)
	add_child(label)
	label.position = -label.get_minimum_size() * 0.5

	scale = Vector2(1.9, 1.9)
	var rise_to := position.y - 46.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.22)
	tween.tween_property(self, "position:y", rise_to, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
