extends Control

class_name RunSelect

## 출발 전 선택 화면 (액션 모드 캐릭터/던전 선택 방식)
## 1단계 모드(클래식/무한) → 2단계 캐릭터 → 3단계 맵 → 시작.  ← → (또는 마우스)로 고르고 Enter / 클릭으로 결정
## ESC: 한 단계 뒤로, 모드 단계에서는 메인 메뉴로. 고른 모드는 RunMode 에 저장

signal finished(character_id: String, map_id: String)
signal cancelled

const CARD_SIZE := Vector2(340, 470)
const MAP_CARD_SIZE := Vector2(440, 470)
const MODE_CARD_SIZE := Vector2(460, 470)
const STEPS := ["mode", "character", "map"]

const MODES := [
	{"id": RunMode.CLASSIC, "title": ["클래식", "CLASSIC"], "tag": ["10분 생존 · 보스 처치 = 엔딩", "Survive 10 min · Beat the boss to win"],
	 "rules": [
		["10분 동안 몰려오는 적을 버티며 빌드를 완성", "Hold out for 10 minutes and complete your build"],
		["10:00 에 보스 등장", "The boss appears at 10:00"],
		["보스를 잡으면 엔딩", "Defeat the boss to see the ending"],
		["무기 · 패시브는 최대 레벨까지 강화", "Weapons and passives level up to MAX"],
	 ]},
	{"id": RunMode.ENDLESS, "title": ["무한", "ENDLESS"], "tag": ["쓰러질 때까지 계속 · 기록 도전", "Keep going until you fall"],
	 "rules": [
		["첫 보스까지는 클래식과 같음", "Same as Classic until the first boss"],
		["보스를 잡아도 게임이 계속됨", "The run continues after the boss"],
		["★ 첫 보스 처치 후 한계 돌파 : 최대 레벨을 넘어 계속 강화", "★ Limit Break after the first boss: upgrade beyond MAX"],
		["10분마다 보스 웨이브 : 2번째는 2마리, 3번째부터 3마리", "Boss wave every 10 min: 2 bosses, then 3"],
		["시간이 갈수록 적이 더 강하고 빠르게, 엘리트도 더 많이", "Enemies grow tougher, faster and more elite over time"],
	 ]},
]
static var last_mode_index := 0		# 다시 도전 시 이전에 고른 모드를 기본 선택

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
var step := "mode"
var cards: Array = []
var mode_cards: Array = []
var character_cards: Array = []
var map_cards: Array = []
var map_boss_labels: Array = []
var mode_index := 0
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
	for i in MODES.size():
		var card = _mode_card(MODES[i], i)
		card.position = Vector2(640 - MODE_CARD_SIZE.x - 20 + i * (MODE_CARD_SIZE.x + 40), 128)
		card.visible = false
		add_child(card)
		mode_cards.append(card)
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
	mode_index = last_mode_index
	_show_step("mode")

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
		if step == "mode":
			cancelled.emit()
		else:
			GameUI.click()
			_show_step(STEPS[STEPS.find(step) - 1])
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _select(index: int, sound: bool = true):
	if sound:
		GameUI.click()
	selected = wrapi(index, 0, cards.size())
	_refresh()

# 단계 전환: 모드 카드 → 캐릭터 카드 → 맵 카드
func _show_step(name_: String):
	step = name_
	for c in mode_cards:
		c.visible = step == "mode"
	for c in character_cards:
		c.visible = step == "character"
	for c in map_cards:
		c.visible = step == "map"
	var mode_name = RunMode.display_name(MODES[mode_index].id)
	match step:
		"mode":
			cards = mode_cards
			selected = mode_index
			title.text = GameUI.t("모드 선택", "Choose Mode")
			subtitle.text = GameUI.t("1 / 3  모드", "1 / 3  Mode")
			hint.text = GameUI.t("← →  선택        Enter / 클릭  결정        ESC  메뉴", "← →  Select        Enter / Click  Confirm        ESC  Menu")
		"character":
			cards = character_cards
			selected = character_index
			title.text = GameUI.t("캐릭터 선택", "Choose Character")
			subtitle.text = GameUI.t("2 / 3  캐릭터   ·   %s", "2 / 3  Character   ·   %s") % mode_name
			hint.text = GameUI.t("← →  선택        Enter / 클릭  결정        ESC  모드 다시 고르기", "← →  Select        Enter / Click  Confirm        ESC  Back")
		_:
			cards = map_cards
			selected = 0
			title.text = GameUI.t("맵 선택", "Choose Map")
			subtitle.text = GameUI.t("3 / 3  맵   ·   %s   ·   %s", "3 / 3  Map   ·   %s   ·   %s") % [mode_name, GameUI.character_name(CHARACTERS[character_index].id)]
			hint.text = GameUI.t("← →  선택        Enter / 클릭  출발        ESC  캐릭터 다시 고르기", "← →  Select        Enter / Click  Start        ESC  Back")
			_update_map_boss_text()
	_refresh()

# 맵 카드의 보스 안내 문구 (모드에 따라)
func _update_map_boss_text():
	var endless = MODES[mode_index].id == RunMode.ENDLESS
	for i in map_boss_labels.size():
		var boss_name = MAPS[i].boss[0] if GameUI.ko() else MAPS[i].boss[1]
		if endless:
			map_boss_labels[i].text = GameUI.t("10분마다 보스   ·   첫 보스 : %s", "Boss every 10 min   ·   First : %s") % boss_name
		else:
			map_boss_labels[i].text = GameUI.t("10분 생존   ·   보스 : %s", "Survive 10 min   ·   Boss : %s") % boss_name

func _refresh():
	for i in cards.size():
		GameUI.set_card_active(cards[i], i == selected, 1.04)

# 결정: 다음 단계로, 맵 단계면 시작
func _confirm():
	GameUI.click()
	if step == "mode":
		mode_index = selected
		_show_step("character")
		return
	if step == "character":
		character_index = selected
		_show_step("map")
		return
	starting = true
	last_mode_index = mode_index
	RunMode.mode = MODES[mode_index].id
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
	var boss = GameUI.label("", "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)		# 문구는 모드에 따라 _update_map_boss_text
	boss.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	box.add_child(boss)
	map_boss_labels.append(boss)
	var desc = GameUI.label(tr(data.desc_key), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	desc.add_theme_font_size_override("font_size", 16)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(MAP_CARD_SIZE.x - 40, 0)
	box.add_child(desc)
	return card

# 모드 카드: 큰 이름 + 한 줄 요약 + 규칙 목록 (무한 모드는 보라색 강조)
func _mode_card(data: Dictionary, index: int) -> PanelContainer:
	var endless = data.id == RunMode.ENDLESS
	var accent = GameUI.STAR if endless else GameUI.GOLD
	var card = GameUI.panel("CardPanel")
	card.custom_minimum_size = MODE_CARD_SIZE
	card.size = MODE_CARD_SIZE
	_hook(card, index, "mode")
	var box = GameUI.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var name_label = GameUI.label(data.title[0] if GameUI.ko() else data.title[1], "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_font_size_override("font_size", 52)
	name_label.add_theme_color_override("font_color", accent)
	box.add_child(name_label)
	var tag = GameUI.label(data.tag[0] if GameUI.ko() else data.tag[1], "RoleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(tag)
	var div = GameUI.divider(MODE_CARD_SIZE.x - 60)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(div)
	var rules = GameUI.vbox(10)
	rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rule in data.rules:
		var text: String = rule[0] if GameUI.ko() else rule[1]
		var star = text.begins_with("★")
		var line = GameUI.label(text if star else "·  " + text, "BodyLabel")
		line.add_theme_font_size_override("font_size", 17)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(MODE_CARD_SIZE.x - 56, 0)
		if star:
			line.add_theme_color_override("font_color", accent)
		rules.add_child(line)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(rules)
	box.add_child(margin)
	return card
