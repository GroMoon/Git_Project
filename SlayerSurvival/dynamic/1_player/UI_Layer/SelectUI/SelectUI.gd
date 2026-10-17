extends Control

## 레벨업 선택 UI (카드 3장)
## - 무기 / 패시브 / 대체(음식, 골드) 후보를 가중치로 뽑아 카드로 표시
## - 마우스 클릭 또는 숫자키 1~3, 방향키 + Enter 로 선택
## - 일시정지는 기존 방식대로 BaseUI 에 pause 신호를 보내 처리

signal pause

const CARD_COUNT  = 3
const CARD_SIZE   = Vector2(300, 340)
const INPUT_DELAY = 0.35		# 실수로 바로 선택되는 것 방지
const COLOR_WEAPON  = Color(1.0, 0.78, 0.3)
const COLOR_PASSIVE = Color(0.45, 0.85, 1.0)
const COLOR_OTHER   = Color(0.6, 0.9, 0.5)
const COLOR_NEW     = Color(1.0, 0.95, 0.4)

@onready var selectUI_panel = $select_panel
@onready var upgrade_container = $select_panel/upgrade_container

var player
var overlay: Control
var title_label: Label
var cards_box: HBoxContainer
var current_choices: Array = []
var accept_input_at := 0.0
var choosing := false

func _init_after_parent_ready():
	player = get_parent().get_parent()
	selectUI_panel.visible = false			# 기존 패널은 사용하지 않음
	player.connect("levelup", Callable(self, "create_upgrade_selection"))

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS		# 일시정지 중에도 키 입력 처리
	_build_overlay()
	call_deferred("_init_after_parent_ready")

# ================= UI 구성 =================
func _build_overlay():
	overlay = Control.new()
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.z_index = 2
	add_child(overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = overlay.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	title_label = Label.new()
	title_label.text = "LEVEL UP!"
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", COLOR_NEW)
	title_label.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size = Vector2(1280, 60)
	title_label.position = Vector2(0, 70)
	overlay.add_child(title_label)

	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 28)
	cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_box.size = Vector2(1280, CARD_SIZE.y)
	cards_box.position = Vector2(0, 160)
	overlay.add_child(cards_box)

	var hint = Label.new()
	hint.text = "1 / 2 / 3"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280, 24)
	hint.position = Vector2(0, 160 + CARD_SIZE.y + 22)
	overlay.add_child(hint)

func _make_card(id: String, index: int) -> Button:
	var lv = player.get_upgrade_level(id)
	var entry = UpgradeDB.get_entry(id)
	var type = entry.get("type", "")
	var accent = COLOR_WEAPON if type == "weapon" else (COLOR_PASSIVE if type == "passive" else COLOR_OTHER)

	var card = Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _card_style(accent, false))
	card.add_theme_stylebox_override("hover", _card_style(accent, true))
	card.add_theme_stylebox_override("focus", _card_style(accent, true))
	card.add_theme_stylebox_override("pressed", _card_style(accent, true))
	card.pivot_offset = CARD_SIZE / 2

	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(18, 18)
	box.size = CARD_SIZE - Vector2(36, 36)
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	# 상단: 종류 + 레벨 표시
	var top = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var kind = _label(_type_text(type), 15, accent)
	kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(kind)
	var lv_text = ""
	if type == "weapon" or type == "passive":
		lv_text = "NEW!" if lv == 0 else "Lv %d → %d" % [lv, lv + 1]
	top.add_child(_label(lv_text, 17, COLOR_NEW if lv == 0 else Color.WHITE))

	# 아이콘 (테두리 박스 안)
	var icon_frame = PanelContainer.new()
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.custom_minimum_size = Vector2(112, 112)
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0.35)
	frame_style.border_color = accent.darkened(0.3)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(6)
	icon_frame.add_theme_stylebox_override("panel", frame_style)
	var icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = UpgradeDB.icon(id, player.character_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(96, 96)
	icon_frame.add_child(icon)
	box.add_child(icon_frame)

	# 이름
	var name_label = _label(UpgradeDB.display_name(id, player.character_name), 26, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	# 설명 (새로 얻는 경우 무기 소개, 아니면 다음 레벨 효과)
	var desc = _label(UpgradeDB.level_desc(id, lv + 1, player.character_name), 18, Color(0.88, 0.88, 0.92))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(CARD_SIZE.x - 36, 80)
	box.add_child(desc)

	# 단축키
	var key = _label("[%d]" % (index + 1), 15, Color(1, 1, 1, 0.45))
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.size_flags_vertical = Control.SIZE_EXPAND_FILL
	key.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(key)

	card.pressed.connect(_on_upgrade_button_pressed.bind(id))
	card.mouse_entered.connect(func(): card.grab_focus())
	card.focus_entered.connect(func(): _hover(card, true))
	card.focus_exited.connect(func(): _hover(card, false))
	return card

func _card_style(accent: Color, highlighted: bool) -> StyleBoxFlat:
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.08, 0.13, 0.97) if not highlighted else Color(0.16, 0.13, 0.2, 0.98)
	st.border_color = accent if highlighted else accent.darkened(0.45)
	st.set_border_width_all(4 if highlighted else 3)
	st.set_corner_radius_all(10)
	st.shadow_color = Color(accent.r, accent.g, accent.b, 0.35 if highlighted else 0.0)
	st.shadow_size = 12 if highlighted else 0
	return st

func _label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l

func _type_text(type: String) -> String:
	var ko = TranslationServer.get_locale().begins_with("ko")
	match type:
		"weapon":
			return "무기" if ko else "WEAPON"
		"passive":
			return "패시브" if ko else "PASSIVE"
	return "보너스" if ko else "BONUS"

func _hover(card: Button, on: bool):
	var t = card.create_tween()
	t.tween_property(card, "scale", Vector2(1.05, 1.05) if on else Vector2.ONE, 0.1)

# ================= 선택지 생성 =================
func create_upgrade_selection():
	if choosing:
		return
	choosing = true
	emit_signal("pause", true)						# 퍼즈 신호 BaseUI에 보내기
	current_choices = roll_choices(CARD_COUNT)
	for child in cards_box.get_children():
		child.queue_free()
	for i in current_choices.size():
		var card = _make_card(current_choices[i], i)
		cards_box.add_child(card)
		# 등장 연출 (차례로 튀어나옴)
		card.modulate.a = 0.0
		card.scale = Vector2(0.7, 0.7)
		var t = card.create_tween().set_parallel(true)
		t.tween_property(card, "modulate:a", 1.0, 0.18).set_delay(i * 0.07)
		t.tween_property(card, "scale", Vector2.ONE, 0.25).set_delay(i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_label.scale = Vector2(1.3, 1.3)
	title_label.pivot_offset = title_label.size / 2
	title_label.create_tween().tween_property(title_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	overlay.visible = true
	accept_input_at = Time.get_ticks_msec() / 1000.0 + INPUT_DELAY

# 가중치 랜덤으로 count개 (중복 없음)
func roll_choices(count: int) -> Array:
	var pool = []
	var weapon_count = player.weapons.size()
	var passive_count = player.passives.size()
	for id in UpgradeDB.weapon_ids():
		var lv = player.get_upgrade_level(id)
		if lv > 0:
			if lv < UpgradeDB.max_level(id):
				pool.append([id, UpgradeDB.WEIGHT_OWNED_WEAPON])
		elif weapon_count < UpgradeDB.WEAPON_SLOTS:
			pool.append([id, UpgradeDB.WEIGHT_NEW_WEAPON])
	for id in UpgradeDB.passive_ids():
		var lv = player.get_upgrade_level(id)
		if lv > 0:
			if lv < UpgradeDB.max_level(id):
				pool.append([id, UpgradeDB.WEIGHT_OWNED_PASSIVE])
		elif passive_count < UpgradeDB.PASSIVE_SLOTS:
			pool.append([id, UpgradeDB.WEIGHT_NEW_PASSIVE])

	var selected = []
	while selected.size() < count and not pool.is_empty():
		var total = 0
		for item in pool:
			total += item[1]
		var r = randf() * total
		for item in pool:
			r -= item[1]
			if r <= 0.0:
				selected.append(item[0])
				pool.erase(item)
				break
	# 더 이상 고를 것이 없으면 음식/골드로 채움
	for filler in ["food", "gold", "food"]:
		if selected.size() >= count:
			break
		if not selected.has(filler):
			selected.append(filler)
	return selected

# ================= 입력 =================
func _unhandled_input(event):
	if not choosing or not overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx = -1
		match event.keycode:
			KEY_1, KEY_KP_1:
				idx = 0
			KEY_2, KEY_KP_2:
				idx = 1
			KEY_3, KEY_KP_3:
				idx = 2
		if idx >= 0 and idx < current_choices.size():
			get_viewport().set_input_as_handled()
			_on_upgrade_button_pressed(current_choices[idx])
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D] and get_viewport().gui_get_focus_owner() == null:
			var cards = cards_box.get_children()
			if not cards.is_empty():
				cards[0].grab_focus()

# 자동 플레이 테스트용: 첫 번째 카드 선택
func autopick():
	if choosing and not current_choices.is_empty():
		accept_input_at = 0.0
		_on_upgrade_button_pressed(current_choices[0])

# 업그레이드 적용
func _on_upgrade_button_pressed(upgrade_key):
	if not choosing or Time.get_ticks_msec() / 1000.0 < accept_input_at:
		return
	choosing = false
	player.add_upgrade(upgrade_key)
	for child in cards_box.get_children():
		child.queue_free()
	overlay.visible = false
	emit_signal("pause", false)
	# 경험치가 남아 있으면 연속 레벨업
	player.call_deferred("calculate_exp")
