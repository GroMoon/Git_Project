extends Control
## 액션 모드 캐릭터 → 던전 선택 : ← → (또는 마우스)로 고르고 X / Enter / 클릭으로 결정
## 1단계 캐릭터 선택 → 2단계 던전 선택 → 입장.  ESC : 던전 단계에서는 캐릭터로, 캐릭터 단계에서는 메뉴로

const ActionInput = preload("res://dynamic/8_action/core/action_input.gd")
const ActionStage = preload("res://dynamic/8_action/stage/action_stage.gd")
const DungeonData = preload("res://dynamic/8_action/stage/dungeon_data.gd")
const CLICK = preload("res://static/audio/sfx/button_sounds/button_sound_1.mp3")
const FONT = preload("res://static/font/DNFBitBitTTF.ttf")

const STAGE_SCENE := "res://dynamic/8_action/stage/action_stage.tscn"
const MENU_SCENE  := "res://dynamic/5_title_screen/menu.tscn"
const IMG_DIR     := "res://dynamic/1_player/selcet_character/character_img/"
const CARD_SIZE   := Vector2(340, 470)
const DUNGEON_CARD_SIZE := Vector2(440, 470)

const CHARACTERS := [
	{"id": "warrior", "name": "Fantasy Warrior", "role": "균형형 검사", "image": "fantasy_warrior_pixelart.webp",
	 "stats": {"공격": 3, "체력": 3, "속도": 4},
	 "desc": "빠른 3타 콤보와 회오리 베기로\n적을 모아 띄우는 정석 근접형",
	 "skills": "어퍼 슬래시 · 회오리 베기\n섬광 돌진 · 파멸의 일격"},
	{"id": "king", "name": "Medieval King", "role": "중장갑 대검사", "image": "medieval_king_pixelart.webp",
	 "stats": {"공격": 5, "체력": 5, "속도": 2},
	 "desc": "느리지만 한 방이 무겁고 넓다\n왕의 부름으로 넓게 끌어모은다",
	 "skills": "왕의 일격 · 왕의 부름\n돌격 찌르기 · 성검 심판"},
	{"id": "wizard", "name": "Wizard", "role": "원거리 마법사", "image": "wizard_pixelart.webp",
	 "stats": {"공격": 4, "체력": 2, "속도": 3},
	 "desc": "마력탄으로 멀리서 견제하고\n그라비티 홀로 몰아 메테오로 마무리",
	 "skills": "체인 라이트닝 · 그라비티 홀\n블링크 · 메테오 스톰"},
]

var selected := 0
var step := "character"			# "character" → "dungeon"
var _cards : Array[Control] = []		# 현재 단계의 카드
var _character_cards : Array[Control] = []
var _dungeon_cards : Array[Control] = []
var _character_index := 0
var _starting := false
var _title : Label
var _subtitle : Label
var _hint : Label

## 카드 테두리 (선택 시 금색)
class CardFrame extends Control:
	var active := false
	func _draw():
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.08, 0.07, 0.1, 0.92))
		draw_rect(rect, Color(1.0, 0.8, 0.3) if active else Color(0.35, 0.33, 0.4), false, 4.0 if active else 2.0)

func _ready():
	ActionInput.ensure_actions()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.045, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_title = _label("캐릭터 선택", 46, Color(1.0, 0.85, 0.4))
	_title.position = Vector2(0, 26)
	_title.size = Vector2(1280, 60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_subtitle = _label("1 / 2  캐릭터", 20, Color(0.75, 0.75, 0.82))
	_subtitle.position = Vector2(0, 82)
	_subtitle.size = Vector2(1280, 30)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle)
	if Global.character_data.has("GOLD"):
		var gold := _label("보유 골드  %d G" % int(Global.character_data["GOLD"]["gold"]), 20, Color(1.0, 0.85, 0.35))
		gold.position = Vector2(1040, 30)
		add_child(gold)

	for i in CHARACTERS.size():
		var card := _build_card(CHARACTERS[i], i)
		card.position = Vector2(640 - CARD_SIZE.x * 1.5 - 30 + i * (CARD_SIZE.x + 30), 128)
		add_child(card)
		_character_cards.append(card)
	var order: Array = DungeonData.DUNGEON_ORDER
	for i in order.size():
		var card := _build_dungeon_card(DungeonData.get_dungeon(order[i]), i)
		card.position = Vector2(640 - DUNGEON_CARD_SIZE.x - 20 + i * (DUNGEON_CARD_SIZE.x + 40), 128)
		card.visible = false
		add_child(card)
		_dungeon_cards.append(card)

	_hint = _label("", 20, Color(1, 1, 1, 0.75))
	_hint.position = Vector2(0, 664)
	_hint.size = Vector2(1280, 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	_show_step("character")

func _unhandled_input(event: InputEvent):
	if _starting or event.is_echo():
		return
	if event.is_action_pressed("act_left"):
		_select(selected - 1)
	elif event.is_action_pressed("act_right"):
		_select(selected + 1)
	elif event.is_action_pressed("act_attack") or event.is_action_pressed("ui_accept"):
		_start()
	elif event.is_action_pressed("act_menu"):
		if step == "dungeon":
			_click()
			_show_step("character")
		else:
			get_tree().change_scene_to_file(MENU_SCENE)

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
	selected = wrapi(index, 0, _cards.size())
	_refresh()

## 단계 전환 : 캐릭터 카드 ↔ 던전 카드
func _show_step(name_: String):
	step = name_
	for card in _character_cards:
		card.visible = step == "character"
	for card in _dungeon_cards:
		card.visible = step == "dungeon"
	if step == "character":
		_cards = _character_cards
		selected = maxi(0, CHARACTERS.map(func(c): return c.id).find(ActionStage.selected_character))
		_title.text = "캐릭터 선택"
		_subtitle.text = "1 / 2  캐릭터"
		_hint.text = "← →  선택        X / Enter / 클릭  결정        ESC  메뉴"
	else:
		_cards = _dungeon_cards
		selected = maxi(0, DungeonData.DUNGEON_ORDER.find(ActionStage.selected_dungeon))
		_title.text = "던전 선택"
		_subtitle.text = "2 / 2  던전   ·   캐릭터 : %s" % CHARACTERS[_character_index].name
		_hint.text = "← →  선택        X / Enter / 클릭  입장        ESC  캐릭터 다시 고르기"
	_refresh()

func _refresh():
	for i in _cards.size():
		var card := _cards[i]
		var active := i == selected
		card.get_node("Frame").active = active
		card.get_node("Frame").queue_redraw()
		card.modulate = Color.WHITE if active else Color(0.55, 0.55, 0.6)
		var tween := card.create_tween()
		tween.tween_property(card, "scale", Vector2.ONE * (1.04 if active else 0.96), 0.12)

## 결정 : 캐릭터 단계면 던전 단계로, 던전 단계면 입장
func _start():
	_click()
	if step == "character":
		_character_index = selected
		ActionStage.selected_character = CHARACTERS[selected].id
		_show_step("dungeon")
		return
	_starting = true
	ActionStage.selected_dungeon = DungeonData.DUNGEON_ORDER[selected]
	var flash := ColorRect.new()
	flash.color = Color(0, 0, 0, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(_cards[selected], "scale", Vector2.ONE * 1.1, 0.12)
	tween.tween_property(flash, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(STAGE_SCENE))

func _on_card_hover(index: int, card_step: String):
	if not _starting and card_step == step and selected != index:
		_select(index)

func _on_card_input(event: InputEvent, index: int, card_step: String):
	if _starting or card_step != step or not (event is InputEventMouseButton):
		return
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)
		_start()

func _build_card(data: Dictionary, index: int) -> Control:
	var card := Control.new()
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_entered.connect(_on_card_hover.bind(index, "character"))
	card.gui_input.connect(_on_card_input.bind(index, "character"))

	var frame := CardFrame.new()
	frame.name = "Frame"
	frame.size = CARD_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)

	var portrait := TextureRect.new()
	portrait.texture = load(IMG_DIR + data.image)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(70, 14)
	portrait.size = Vector2(200, 200)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)

	var name_label := _label(data.name, 26, Color(1.0, 0.88, 0.5))
	name_label.position = Vector2(0, 218)
	name_label.size = Vector2(CARD_SIZE.x, 34)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var role := _label(data.role, 18, Color(0.7, 0.85, 1.0))
	role.position = Vector2(0, 252)
	role.size = Vector2(CARD_SIZE.x, 26)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(role)

	var row := 0
	for stat in data.stats:
		var key := _label(stat, 17, Color(0.85, 0.85, 0.9))
		key.position = Vector2(46, 288 + row * 26)
		card.add_child(key)
		var bar := _label("■".repeat(data.stats[stat]) + "□".repeat(5 - data.stats[stat]), 17, Color(1.0, 0.75, 0.3))
		bar.position = Vector2(110, 288 + row * 26)
		card.add_child(bar)
		row += 1

	var desc := _label(data.desc, 16, Color(0.9, 0.9, 0.92))
	desc.position = Vector2(0, 372)
	desc.size = Vector2(CARD_SIZE.x, 44)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(desc)
	var skills := _label(data.skills, 15, Color(0.6, 1.0, 0.7))
	skills.position = Vector2(0, 420)
	skills.size = Vector2(CARD_SIZE.x, 44)
	skills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(skills)

	for child in card.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

## 던전 카드 : 일러스트 + 이름 + 보스 + 설명
func _build_dungeon_card(data: Dictionary, index: int) -> Control:
	var size_ := DUNGEON_CARD_SIZE
	var card := Control.new()
	card.size = size_
	card.pivot_offset = size_ * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_entered.connect(_on_card_hover.bind(index, "dungeon"))
	card.gui_input.connect(_on_card_input.bind(index, "dungeon"))
	var frame := CardFrame.new()
	frame.name = "Frame"
	frame.size = size_
	card.add_child(frame)
	var image := TextureRect.new()
	image.texture = load(data.image)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.position = Vector2(14, 14)
	image.size = Vector2(size_.x - 28, 230)
	image.clip_contents = true
	card.add_child(image)
	var name_label := _label(data.name, 30, Color(1.0, 0.88, 0.5))
	name_label.position = Vector2(0, 256)
	name_label.size = Vector2(size_.x, 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var boss := _label("방 %d개   ·   보스 : %s" % [data.rooms.size(), data.boss], 18, Color(1.0, 0.55, 0.45))
	boss.position = Vector2(0, 304)
	boss.size = Vector2(size_.x, 28)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(boss)
	var desc := _label(data.desc, 18, Color(0.9, 0.9, 0.92))
	desc.position = Vector2(0, 350)
	desc.size = Vector2(size_.x, 60)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(desc)
	for child in card.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
