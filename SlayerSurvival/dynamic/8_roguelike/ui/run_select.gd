extends Control

class_name RunSelect

## 출발 전 선택 화면 (액션 모드 캐릭터/던전 선택 방식)
## 1단계 캐릭터 선택 → 2단계 맵 선택 → 시작.  ← → (또는 마우스)로 고르고 Enter / 클릭으로 결정
## ESC: 맵 단계에서는 캐릭터로, 캐릭터 단계에서는 메인 메뉴로

signal finished(character_id: String, map_id: String)
signal cancelled

const CARD_SIZE := Vector2(340, 470)
const MAP_CARD_SIZE := Vector2(440, 470)

# 스탯 칸 수는 기존 선택 화면(■ 개수)을 5칸 기준으로 맞춤
const CHARACTERS := [
	{"id": "fantasy_warrior", "role": ["균형형 검사", "Balanced swordsman"],
	 "stats": {"공격": 2, "체력": 3, "속도": 4}, "desc_key": "WARRIOR_DETAILS",
	 "skills": ["고유 무기 : 전사의 검\n레벨업으로 2연속 · 3연속 베기", "Signature: Warrior's Blade\nLevels up to double and triple slash"]},
	{"id": "medieval_king", "role": ["중장갑 대검사", "Armored greatsword"],
	 "stats": {"공격": 4, "체력": 5, "속도": 2}, "desc_key": "KING_DETAILS",
	 "skills": ["고유 무기 : 왕의 대검\n넓고 무거운 베기", "Signature: Royal Greatsword\nWide, heavy slashes"]},
	{"id": "wizard", "role": ["원거리 마법사", "Ranged wizard"],
	 "stats": {"공격": 4, "체력": 3, "속도": 2}, "desc_key": "WIZARD_DETAILS",
	 "skills": ["고유 무기 : 번개 마법\n가까운 적에게 번개를 여러 번", "Signature: Lightning\nStrikes nearby enemies with bolts"]},
]
const MAPS := [
	{"id": "cave", "image": "res://dynamic/4_world/cave/cave_illust.png", "desc_key": "CAVE_DETAILS",
	 "boss": ["파이어 웜", "Fire Worm"]},
	{"id": "dungeon_B1F", "image": "res://dynamic/4_world/dungeon_B1F/dungeon_B1F_illust.webp", "desc_key": "DUNGEON_DETAILS",
	 "boss": ["브링어 오브 데스", "Bringer of Death"]},
]

var selected := 0
var step := "character"
var cards: Array = []
var character_cards: Array = []
var map_cards: Array = []
var character_index := 0
var starting := false
var title: Label
var subtitle: Label
var hint: Label

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.045, 0.07)
	bg.size = size
	add_child(bg)
	title = GameUI.centered("", "TitleLabel", 26, 60)
	title.add_theme_font_size_override("font_size", 46)
	add_child(title)
	subtitle = GameUI.centered("", "DimLabel", 82, 30)
	subtitle.add_theme_font_size_override("font_size", 20)
	add_child(subtitle)
	if Global.character_data.has("GOLD"):
		var gold = GameUI.label(GameUI.t("보유 골드  %d G", "Gold  %d G") % int(Global.character_data["GOLD"]["gold"]), "BodyLabel")
		gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		gold.add_theme_font_size_override("font_size", 20)
		gold.position = Vector2(1040, 30)
		add_child(gold)
	for i in CHARACTERS.size():
		var card = _character_card(CHARACTERS[i], i)
		card.position = Vector2(640 - CARD_SIZE.x * 1.5 - 30 + i * (CARD_SIZE.x + 30), 128)
		add_child(card)
		character_cards.append(card)
	for i in MAPS.size():
		var card = _map_card(MAPS[i], i)
		card.position = Vector2(640 - MAP_CARD_SIZE.x - 20 + i * (MAP_CARD_SIZE.x + 40), 128)
		card.visible = false
		add_child(card)
		map_cards.append(card)
	hint = GameUI.hint("", 664)
	add_child(hint)
	_show_step("character")

func _unhandled_input(event):
	if starting or event.is_echo():
		return
	var handled = true
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		_select(selected - 1)
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		_select(selected + 1)
	elif event.is_action_pressed("ui_accept"):
		_confirm()
	elif event.is_action_pressed("pause"):
		if step == "map":
			GameUI.click()
			_show_step("character")
		else:
			cancelled.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _select(index: int, sound: bool = true):
	if sound:
		GameUI.click()
	selected = wrapi(index, 0, cards.size())
	_refresh()

# 단계 전환: 캐릭터 카드 ↔ 맵 카드
func _show_step(name_: String):
	step = name_
	for c in character_cards:
		c.visible = step == "character"
	for c in map_cards:
		c.visible = step == "map"
	if step == "character":
		cards = character_cards
		selected = character_index
		title.text = GameUI.t("캐릭터 선택", "Choose Character")
		subtitle.text = GameUI.t("1 / 2  캐릭터", "1 / 2  Character")
		hint.text = GameUI.t("← →  선택        Enter / 클릭  결정        ESC  메뉴", "← →  Select        Enter / Click  Confirm        ESC  Menu")
	else:
		cards = map_cards
		selected = 0
		title.text = GameUI.t("맵 선택", "Choose Map")
		subtitle.text = GameUI.t("2 / 2  맵   ·   캐릭터 : %s", "2 / 2  Map   ·   Character : %s") % GameUI.character_name(CHARACTERS[character_index].id)
		hint.text = GameUI.t("← →  선택        Enter / 클릭  출발        ESC  캐릭터 다시 고르기", "← →  Select        Enter / Click  Start        ESC  Back")
	_refresh()

func _refresh():
	for i in cards.size():
		GameUI.set_card_active(cards[i], i == selected, 1.04)

# 결정: 캐릭터 단계면 맵 단계로, 맵 단계면 시작
func _confirm():
	GameUI.click()
	if step == "character":
		character_index = selected
		_show_step("map")
		return
	starting = true
	var flash = ColorRect.new()
	flash.color = Color(0, 0, 0, 0)
	flash.size = size
	add_child(flash)
	var tw = create_tween()
	tw.tween_property(cards[selected], "scale", Vector2.ONE * 1.1, 0.12)
	tw.tween_property(flash, "color:a", 1.0, 0.3)
	tw.tween_callback(func(): finished.emit(CHARACTERS[character_index].id, MAPS[selected].id))

func _hook(card: Control, index: int, card_step: String):
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_entered.connect(func():
		if not starting and card_step == step and selected != index:
			_select(index))
	card.gui_input.connect(func(event):
		if starting or card_step != step:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select(index, false)
			_confirm())

func _character_card(data: Dictionary, index: int) -> PanelContainer:
	var card = GameUI.panel("CardPanel")
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	_hook(card, index, "character")
	var box = GameUI.vbox(6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var portrait = TextureRect.new()
	portrait.texture = GameUI.PORTRAITS[data.id]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(200, 190)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)
	var name_label = GameUI.label(GameUI.character_name(data.id), "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	box.add_child(GameUI.label(data.role[0] if GameUI.ko() else data.role[1], "RoleLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var stats = GameUI.vbox(2)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in data.stats:
		var row = GameUI.hbox(14)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var title_text = {"공격": GameUI.t("공격", "ATK"), "체력": GameUI.t("체력", "HP"), "속도": GameUI.t("속도", "SPD")}[key]
		row.add_child(GameUI.label(title_text, "DimLabel"))
		var bar = GameUI.label("■".repeat(data.stats[key]) + "□".repeat(5 - data.stats[key]), "BodyLabel")
		bar.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
		row.add_child(bar)
		stats.add_child(row)
	box.add_child(stats)
	var desc = GameUI.label(tr(data.desc_key), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	desc.add_theme_font_size_override("font_size", 15)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(CARD_SIZE.x - 36, 0)
	box.add_child(desc)
	var skills = GameUI.label(data.skills[0] if GameUI.ko() else data.skills[1], "SkillLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(skills)
	return card

func _map_card(data: Dictionary, index: int) -> PanelContainer:
	var card = GameUI.panel("CardPanel")
	card.custom_minimum_size = MAP_CARD_SIZE
	card.size = MAP_CARD_SIZE
	_hook(card, index, "map")
	var box = GameUI.vbox(10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var image = TextureRect.new()
	image.texture = load(data.image)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size = Vector2(MAP_CARD_SIZE.x - 36, 230)
	image.clip_contents = true
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(image)
	var name_label = GameUI.label(GameUI.map_name(data.id), "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_font_size_override("font_size", 30)
	box.add_child(name_label)
	var boss = GameUI.label(GameUI.t("10분 생존   ·   보스 : %s", "Survive 10 min   ·   Boss : %s") % (data.boss[0] if GameUI.ko() else data.boss[1]), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	boss.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	box.add_child(boss)
	var desc = GameUI.label(tr(data.desc_key), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	desc.add_theme_font_size_override("font_size", 16)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(MAP_CARD_SIZE.x - 40, 0)
	box.add_child(desc)
	return card
