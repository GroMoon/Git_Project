extends Node

const FONT_PATH = "res://static/font/DNFBitBitTTF.ttf"

func show_damage(damage: float, position: Vector2, color : Color = Color.RED):
	var label = Label.new()
	var font = FontFile.new()
	font = load(FONT_PATH)
	
	label.text = str(damage)
	label.global_position = position
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	# 씬 추가 + 위치 설정
	get_tree().current_scene.add_child(label)
	label.position = position
	
	# 애니메이션 (데미지 뜨는 방식) >>> 위로 날아가면서 천천히 사라짐
	var tween = create_tween()
	tween.tween_property(label, "position:y", position.y - 30, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD)
	await  tween.finished
	if is_instance_valid(label):
		label.queue_free()
