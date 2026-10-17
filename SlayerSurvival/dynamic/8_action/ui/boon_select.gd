extends CanvasLayer
## 강화 선택 창 (게임 일시정지 중에도 동작) : ← → / 마우스로 고르고 X / Enter / 클릭으로 결정

signal chosen(id: String)

const CLICK = preload("res://static/audio/sfx/button_sounds/button_sound_1.mp3")
const FONT  = preload("res://static/font/DNFBitBitTTF.ttf")
const ICONS = preload("res://static/png/icon/spritesheet.png")
const CARD_SIZE := Vector2(280, 250)

var options : Array = []
var selected := 0
var _cards : Array[Control] = []
var _done := false

class CardFrame extends Control:
	var active := false
	func _draw():
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.08, 0.07, 0.11, 0.95))
		draw_rect(rect, Color(1.0, 0.8, 0.3) if active else Color(0.35, 0.33, 0.42), false, 4.0 if active else 2.0)

func _ready():
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var title := _label("ROOM CLEAR  —  강화를 하나 선택하세요", 34, Color(1.0, 0.85, 0.4))
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var total_w := options.size() * CARD_SIZE.x + (options.size() - 1) * 30.0
	for i in options.size():
		var card := _build_card(options[i], i)
		card.position = Vector2(640.0 - total_w * 0.5 + i * (CARD_SIZE.x + 30.0), 230)
		root.add_child(card)
		_cards.append(card)

	var hint := _label("← →  선택        X / Enter / 클릭  결정", 20, Color(1, 1, 1, 0.75))
	hint.position = Vector2(0, 512)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.2)
	_refresh()

func _unhandled_input(event: InputEvent):
	if _done or event.is_echo():
		return
	if event.is_action_pressed("act_left"):
		_select(selected - 1)
	elif event.is_action_pressed("act_right"):
		_select(selected + 1)
	elif event.is_action_pressed("act_attack") or event.is_action_pressed("ui_accept"):
		choose(selected)

func choose(index: int):
	if _done:
		return
	_done = true
	chosen.emit(options[index].id)
	queue_free()

## 선택 효과음 (게임이 멈춘 상태에서도 재생되도록 이 노드 아래에서 재생)
func _click():
	var player := AudioStreamPlayer.new()
	player.stream = CLICK
	player.bus = &"SFX"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _select(index: int):
	_click()
	selected = wrapi(index, 0, options.size())
	_refresh()

func _refresh():
	for i in _cards.size():
		var active := i == selected
		var frame: Control = _cards[i].get_node("Frame")
		frame.active = active
		frame.queue_redraw()
		_cards[i].modulate = Color.WHITE if active else Color(0.6, 0.6, 0.65)
		_cards[i].scale = Vector2.ONE * (1.05 if active else 1.0)

func _on_card_hover(index: int):
	if not _done and selected != index:
		_select(index)

func _on_card_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		choose(index)

func _build_card(boon: Dictionary, index: int) -> Control:
	var card := Control.new()
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE * 0.5
	card.mouse_entered.connect(_on_card_hover.bind(index))
	card.gui_input.connect(_on_card_input.bind(index))
	var frame := CardFrame.new()
	frame.name = "Frame"
	frame.size = CARD_SIZE
	card.add_child(frame)
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2(boon.icon.x * 16, boon.icon.y * 16, 16, 16)
	icon.texture = atlas
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2(CARD_SIZE.x * 0.5 - 32, 24)
	icon.size = Vector2(64, 64)
	card.add_child(icon)
	var name_label := _label(boon.name, 28, Color(1.0, 0.88, 0.5))
	name_label.position = Vector2(0, 104)
	name_label.size = Vector2(CARD_SIZE.x, 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var desc := _label(boon.desc, 20, Color(0.92, 0.92, 0.95))
	desc.position = Vector2(0, 156)
	desc.size = Vector2(CARD_SIZE.x, 70)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(desc)
	if boon.get("party", false):
		var tag := _label("동료", 16, Color(0.55, 1.0, 0.6))
		tag.position = Vector2(12, 10)
		card.add_child(tag)
	for child in card.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	return label
