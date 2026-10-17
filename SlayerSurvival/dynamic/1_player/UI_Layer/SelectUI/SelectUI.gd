extends Control

## 레벨업 선택 UI (카드 3장)
## - 무기 / 패시브 / 대체(음식, 골드) 후보를 가중치로 뽑아 카드로 표시
## - 마우스 클릭 또는 숫자키 1~3, 방향키 + Enter 로 선택
## - 일시정지는 기존 방식대로 BaseUI 에 pause 신호를 보내 처리

signal pause

const CARD_COUNT  = 3
const CARD_SIZE   = Vector2(280, 270)
const INPUT_DELAY = 0.35		# 실수로 바로 선택되는 것 방지
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
# 보물상자
var chest_overlay: Control
var chest_box: HBoxContainer
var chest_title: Label
var chest_continue: Control		# "계속하기" 메뉴 (공개가 끝나면 보임)
var chest_menu: TextMenu
var chest_open := false
var pending_chests: Array = []

func _init_after_parent_ready():
	player = get_parent().get_parent()
	selectUI_panel.visible = false			# 기존 패널은 사용하지 않음
	player.connect("levelup", Callable(self, "create_upgrade_selection"))

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS		# 일시정지 중에도 키 입력 처리
	_build_overlay()
	call_deferred("_init_after_parent_ready")

# ================= UI 구성 (액션 모드 강화 선택창 방식) =================
var cards: Array = []
var selected := 0

func _build_overlay():
	overlay = Control.new()
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.z_index = 2
	add_child(overlay)
	var dim = GameUI.dim_backdrop(0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	title_label = GameUI.centered("", "TitleLabel", 150, 50)
	title_label.add_theme_font_size_override("font_size", 34)
	overlay.add_child(title_label)
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 30)
	cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_box.size = Vector2(1280, CARD_SIZE.y)
	cards_box.position = Vector2(0, 225)
	overlay.add_child(cards_box)
	overlay.add_child(GameUI.hint(GameUI.t("← →  선택        Enter / 클릭  결정        1 2 3  바로 선택",
		"← →  Select        Enter / Click  Choose        1 2 3  Quick pick"), 525))

func _make_card(id: String, index: int) -> PanelContainer:
	var lv = player.get_upgrade_level(id)
	var entry = UpgradeDB.get_entry(id)
	var type = entry.get("type", "")
	var card = GameUI.panel("CardPanel")
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var box = GameUI.vbox(8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var icon = TextureRect.new()
	icon.texture = UpgradeDB.icon(id, player.character_name)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var name_label = GameUI.label(UpgradeDB.display_name(id, player.character_name), "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	var kind = _type_text(type)
	if type == "weapon" or type == "passive":
		kind += "   ·   " + ("NEW!" if lv == 0 else "Lv %d → %d" % [lv, lv + 1])
	var kind_label = GameUI.label(kind, "RoleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	if lv == 0 and type != "consumable":
		kind_label.add_theme_color_override("font_color", COLOR_NEW)
	box.add_child(kind_label)
	var desc = GameUI.label(UpgradeDB.level_desc(id, lv + 1, player.character_name), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(CARD_SIZE.x - 40, 60)
	box.add_child(desc)
	card.mouse_entered.connect(func():
		if choosing and selected != index:
			_select(index))
	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select(index, false)
			_on_upgrade_button_pressed(id))
	return card

func _type_text(type: String) -> String:
	match type:
		"weapon":
			return GameUI.t("무기", "Weapon")
		"passive":
			return GameUI.t("패시브", "Passive")
	return GameUI.t("보너스", "Bonus")

func _select(index: int, sound: bool = true):
	if cards.is_empty():
		return
	selected = wrapi(index, 0, cards.size())
	if sound:
		GameUI.click()
	_refresh_cards()

func _refresh_cards():
	for i in cards.size():
		if is_instance_valid(cards[i]):
			GameUI.set_card_active(cards[i], i == selected, 1.05)

# ================= 선택지 생성 =================
func create_upgrade_selection():
	if choosing or chest_open:
		return
	choosing = true
	emit_signal("pause", true)						# 퍼즈 신호 BaseUI에 보내기
	current_choices = roll_choices(CARD_COUNT)
	for child in cards_box.get_children():
		child.queue_free()
	cards.clear()
	for i in current_choices.size():
		var card = _make_card(current_choices[i], i)
		cards_box.add_child(card)
		cards.append(card)
	title_label.text = GameUI.t("LEVEL UP  —  강화를 하나 선택하세요", "LEVEL UP  —  Choose an upgrade")
	selected = 0
	_refresh_cards.call_deferred()
	overlay.visible = true
	GameUI.fade_in(overlay, 0.2)
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
	if event.is_echo():
		return
	if chest_open:
		if chest_menu and chest_menu.handle_input(event):
			get_viewport().set_input_as_handled()
		return
	if not choosing or not overlay.visible:
		return
	var handled = true
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		_select(selected - 1)
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		_select(selected + 1)
	elif event.is_action_pressed("ui_accept"):
		_on_upgrade_button_pressed(current_choices[selected])
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3]:
		var idx = {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_KP_1: 0, KEY_KP_2: 1, KEY_KP_3: 2}[event.keycode]
		if idx < current_choices.size():
			_select(idx, false)
			_on_upgrade_button_pressed(current_choices[idx])
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

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
	GameUI.click()
	for child in cards_box.get_children():
		child.queue_free()
	cards.clear()
	overlay.visible = false
	emit_signal("pause", false)
	_after_ui_closed()

# UI가 닫힌 뒤: 대기 중인 상자 → 남은 경험치로 연속 레벨업
func _after_ui_closed():
	if not pending_chests.is_empty():
		open_chest.call_deferred(pending_chests.pop_front())
	else:
		player.call_deferred("calculate_exp")

# ================= 보물상자 =================
func open_chest(count: int):
	if choosing or chest_open:
		pending_chests.append(count)
		return
	if chest_overlay == null:
		_build_chest_overlay()
	chest_open = true
	emit_signal("pause", true)
	var rewards = player.roll_chest_rewards(count)
	for child in chest_box.get_children():
		child.queue_free()
	var ko = GameUI.ko()
	var has_evo = rewards.any(func(r): return r["kind"] == "evolve")
	chest_title.text = GameUI.t("진화!", "EVOLUTION!") if has_evo else GameUI.t("보물상자!", "TREASURE!")
	chest_overlay.visible = true
	chest_continue.visible = false
	# 보상이 많을수록 한 개씩 천천히 공개하며 폭죽을 터뜨림 (뱀서식 연출)
	var step = 0.3 if rewards.size() == 1 else 0.55
	var first = 0.35
	var slots = []
	for i in rewards.size():
		var slot = _make_reward_slot(rewards[i], ko)
		chest_box.add_child(slot)
		slots.append(slot)
		slot.modulate.a = 0.0
		slot.scale = Vector2(0.4, 0.4)
		var t = slot.create_tween().set_parallel(true)
		t.tween_property(slot, "modulate:a", 1.0, 0.15).set_delay(first + i * step)
		t.tween_property(slot, "scale", Vector2.ONE, 0.3).set_delay(first + i * step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play_chest_fireworks(slots, rewards, first, step)
	# 모두 공개된 뒤 계속 버튼
	var reveal_time = first + rewards.size() * step + (0.6 if rewards.size() > 1 else 0.2)
	chest_menu.active = false
	get_tree().create_timer(reveal_time, true).timeout.connect(func():
		if is_instance_valid(chest_continue) and chest_open:
			chest_continue.visible = true
			chest_menu.active = true
			GameUI.fade_in(chest_continue, 0.15))
	accept_input_at = Time.get_ticks_msec() / 1000.0 + reveal_time

# 보물상자 폭죽: 열 때 한 번, 보상마다 한 번, 여러 개면 마지막에 대형 피날레
func _play_chest_fireworks(slots: Array, rewards: Array, first: float, step: float):
	var seq = chest_overlay.create_tween()
	seq.tween_callback(func():
		_firework(Vector2(640, 420), Color(1.0, 0.85, 0.3), 1.2)
		GameFeel.play_sfx("chest", 1.0, -4.0, 0.05))
	seq.tween_interval(first)
	for i in slots.size():
		var slot = slots[i]
		var evolve = rewards[i]["kind"] == "evolve"
		seq.tween_callback(func():
			if not is_instance_valid(slot):
				return
			var center = slot.global_position + slot.size * 0.5 - chest_overlay.global_position
			var hue = fmod(0.08 + i * 0.17, 1.0)
			_firework(center, Color(1.0, 0.3, 0.3) if evolve else Color.from_hsv(hue, 0.75, 1.0), 1.0 + i * 0.12)
			# 여러 개일 때는 하늘에도 하나씩 더
			if slots.size() > 1:
				_firework(Vector2(randf_range(200, 1080), randf_range(90, 220)), Color.from_hsv(randf(), 0.7, 1.0), 0.8)
			GameFeel.play_sfx("explosion", 1.7 + i * 0.12, -12.0, 0.02)
			GameFeel.play_sfx("pickup", 1.0 + i * 0.15, -6.0, 0.02))
		seq.tween_interval(step)
	if slots.size() > 1:
		seq.tween_callback(func():
			GameFeel.flash_screen(Color(1.0, 0.95, 0.6, 0.35), 0.4)
			GameFeel.play_sfx("chest", 1.25, -3.0, 0.05))
		for k in 6:
			seq.tween_callback(func():
				_firework(Vector2(randf_range(120, 1160), randf_range(80, 330)), Color.from_hsv(randf(), 0.8, 1.0), 1.4)
				GameFeel.play_sfx("explosion", randf_range(1.4, 2.0), -10.0, 0.02))
			seq.tween_interval(0.09)

func _firework(pos: Vector2, color: Color, power: float = 1.0):
	if chest_overlay == null:
		return
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(64 * power)
	p.lifetime = 0.95
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 240)
	p.initial_velocity_min = 180.0 * power
	p.initial_velocity_max = 380.0 * power
	p.damping_min = 70.0
	p.damping_max = 110.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 8.0
	var ramp = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.add_point(0.2, color)
	ramp.set_color(ramp.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.position = pos
	chest_overlay.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	# 반짝임 (작은 흰 불꽃이 한 번 더)
	var sparkle = p.duplicate()
	sparkle.amount = int(18 * power)
	sparkle.initial_velocity_min = 40.0
	sparkle.initial_velocity_max = 110.0 * power
	sparkle.scale_amount_min = 3.0
	sparkle.scale_amount_max = 4.5
	var white = Gradient.new()
	white.set_color(0, Color.WHITE)
	white.set_color(1, Color(1, 1, 0.8, 0.0))
	sparkle.color_ramp = white
	chest_overlay.get_tree().create_timer(0.18, true).timeout.connect(func():
		if is_instance_valid(chest_overlay):
			chest_overlay.add_child(sparkle)
			sparkle.emitting = true
			sparkle.finished.connect(sparkle.queue_free)
		else:
			sparkle.free())

func _build_chest_overlay():
	chest_overlay = Control.new()
	chest_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	chest_overlay.size = Vector2(1280, 720)
	chest_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	chest_overlay.visible = false
	chest_overlay.z_index = 2
	add_child(chest_overlay)
	var dim = GameUI.dim_backdrop(0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_overlay.add_child(dim)
	chest_title = GameUI.centered("", "TitleLabel", 130, 60)
	chest_overlay.add_child(chest_title)
	chest_box = HBoxContainer.new()
	chest_box.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_box.add_theme_constant_override("separation", 24)
	chest_box.size = Vector2(1280, 250)
	chest_box.position = Vector2(0, 220)
	chest_overlay.add_child(chest_box)
	# 공개가 끝나면 나타나는 "계속하기" 메뉴 + 안내
	chest_continue = Control.new()
	chest_continue.size = Vector2(1280, 160)
	chest_continue.position = Vector2(0, 500)
	chest_continue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_overlay.add_child(chest_continue)
	chest_menu = TextMenu.new(26, 52)
	chest_menu.add_item(GameUI.t("계속하기", "Continue"), _close_chest)
	chest_menu.custom_minimum_size = Vector2(1280, 0)
	chest_continue.add_child(chest_menu)
	var hint = GameUI.hint(GameUI.t("Enter / 클릭  계속하기", "Enter / Click  Continue"), 0)
	hint.position = Vector2(0, 140)
	chest_continue.add_child(hint)

func _make_reward_slot(reward: Dictionary, _ko: bool) -> Control:
	var id = reward["id"]
	var evolve = reward["kind"] == "evolve"
	var card = GameUI.panel("CardActive" if evolve else "CardPanel")
	if evolve:
		var red = StyleBoxFlat.new()
		red.bg_color = Color(0.08, 0.07, 0.11, 0.95)
		red.border_color = Color(1.0, 0.35, 0.3)
		red.set_border_width_all(4)
		red.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", red)
	card.custom_minimum_size = Vector2(200, 240)
	card.pivot_offset = Vector2(100, 120)
	var box = GameUI.vbox(8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var icon = TextureRect.new()
	icon.texture = UpgradeDB.icon(id, player.character_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var name_text = UpgradeDB.evolved_name(id, player.character_name) if evolve else UpgradeDB.display_name(id, player.character_name)
	var name_label = GameUI.label(name_text, "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(170, 0)
	box.add_child(name_label)
	var info = ""
	if evolve:
		info = UpgradeDB.evolved_desc(id)
	elif reward["kind"] == "gold":
		info = "+30 G"
	else:
		info = "Lv %d" % reward["level"]
	var info_label = GameUI.label(info, "RoleLabel" if not evolve else "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	if evolve:
		info_label.add_theme_color_override("font_color", GameUI.RED)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(170, 0)
	box.add_child(info_label)
	return card

func _close_chest():
	if not chest_open or Time.get_ticks_msec() / 1000.0 < accept_input_at:
		return
	chest_open = false
	chest_overlay.visible = false
	emit_signal("pause", false)
	_after_ui_closed()

# 자동 플레이 테스트용: 상자 닫기
func autoclose_chest():
	if chest_open:
		accept_input_at = 0.0
		_close_chest()
