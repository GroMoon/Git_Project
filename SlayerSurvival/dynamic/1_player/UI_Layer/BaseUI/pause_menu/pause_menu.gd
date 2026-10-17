extends Control

class_name PauseMenu

## 일시정지 메뉴 (ESC)
## - 왼쪽: 제목 + 메뉴(계속하기 / 설정 / 메인 메뉴), 방향키·Enter 로 선택
## - 오른쪽: 모험가 정보 (초상화, 체력, 능력치, 이번 판 기록, 보유 무기·패시브)
## - 메인 메뉴는 확인 창을 거침 (이번 판 진행이 사라짐)

signal resume_requested
signal settings_requested
signal menu_requested

var player
var base_ui
var left: VBoxContainer
var info_panel: PanelContainer
var buttons: Array = []
var cursor: Label
var confirm: Control
var cursor_time := 0.0

func setup(p, ui):
	player = p
	base_ui = ui

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	visible = false

# ================= 열기 / 닫기 =================
func open():
	if visible:
		refresh()
		return
	visible = true
	refresh()
	GameFeel.play_sfx("ui_open", 1.0, -8.0, 0.1)

func close():
	_close_confirm()
	visible = false

func is_open() -> bool:
	return visible

func has_confirm() -> bool:
	return confirm != null and is_instance_valid(confirm)

# 전체 다시 그리기 (열 때마다 최신 정보)
func refresh():
	for c in get_children():
		c.queue_free()
	buttons.clear()
	confirm = null
	add_child(GameUI.blur_backdrop(0.6))
	_build_left()
	_build_info()
	buttons[0].grab_focus.call_deferred()

func _build_left():
	left = GameUI.vbox(16)
	left.position = Vector2(80, 110)
	left.custom_minimum_size = Vector2(330, 0)
	add_child(left)
	var title = GameUI.label(GameUI.t("일시정지", "PAUSED"), "TitleLabel")
	left.add_child(title)
	var map_id = ""
	var game = player.get_parent()
	if game and "instance_map" in game and game.instance_map:
		map_id = game.instance_map.name
	left.add_child(GameUI.label("%s  ·  %s" % [GameUI.map_name(map_id), base_ui.stopwatch.text], "DimLabel"))
	left.add_child(GameUI.divider(320))
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	left.add_child(spacer)
	for item in [[GameUI.t("계속하기", "Resume"), func(): resume_requested.emit()],
			[GameUI.t("설정", "Settings"), func(): settings_requested.emit()],
			[GameUI.t("메인 메뉴", "Main Menu"), _open_confirm]]:
		var b = GameUI.button(item[0], "BigButton", Vector2(320, 58))
		b.pressed.connect(item[1])
		left.add_child(b)
		buttons.append(b)
	# 키보드 이동: 위아래로 순환
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
	var hint = GameUI.label(GameUI.t("ESC  계속하기", "ESC  Resume"), "DimLabel")
	hint.position = Vector2(80, 660)
	add_child(hint)
	# 선택 커서 ▶
	cursor = GameUI.label("▶", "HeaderLabel")
	cursor.add_theme_color_override("font_color", GameUI.GOLD)
	add_child(cursor)
	GameUI.pop_in(left, 0.0, 0.96)

func _process(delta):
	if not visible or cursor == null or not is_instance_valid(cursor):
		return
	cursor_time += delta
	var focused = get_viewport().gui_get_focus_owner()
	if focused in buttons:
		cursor.visible = true
		var r = focused.get_global_rect()
		cursor.position = Vector2(r.position.x - 34 + sin(cursor_time * 8.0) * 4.0, r.position.y + r.size.y / 2.0 - 16)
	else:
		cursor.visible = false

func _build_info():
	info_panel = GameUI.panel()
	info_panel.position = Vector2(470, 96)
	info_panel.custom_minimum_size = Vector2(740, 0)
	add_child(info_panel)
	var root = GameUI.vbox(12)
	info_panel.add_child(root)

	# ----- 초상화 + 이름 / 레벨 / 체력 -----
	var top = GameUI.hbox(18)
	root.add_child(top)
	var portrait = GameUI.slot(GameUI.PORTRAITS.get(player.character_name), "", "SlotGold", 128)
	top.add_child(portrait)
	var who = GameUI.vbox(6)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(who)
	var name_row = GameUI.hbox(14)
	name_row.add_child(GameUI.label(GameUI.character_name(player.character_name), "HeaderLabel"))
	var lv = GameUI.label("Lv %d" % player.character_level, "ValueLabel")
	lv.add_theme_font_size_override("font_size", 22)
	name_row.add_child(lv)
	who.add_child(name_row)
	who.add_child(_hp_bar())
	var revive_text = GameUI.t("부활 %d회 남음", "%d revive(s) left") % player.respawn_times
	who.add_child(GameUI.label(revive_text, "DimLabel"))
	var run = GameUI.hbox(26)
	run.add_child(_run_stat(GameUI.t("생존", "Time"), base_ui.stopwatch.text))
	run.add_child(_run_stat(GameUI.t("처치", "Kills"), str(int(player.kill_count))))
	run.add_child(_run_stat(GameUI.t("골드", "Gold"), str(int(player.gold_count))))
	who.add_child(run)
	root.add_child(GameUI.divider(700))

	# ----- 능력치 -----
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	root.add_child(grid)
	var cd = int(round((1.0 - player.get_cooldown_mult() * player.signature_cd_mult) * 100.0))
	for s in [
		[Vector2i(1, 10), GameUI.t("공격력", "Attack"), str(int(player.attack_damage))],
		[Vector2i(7, 9), GameUI.t("받는 피해 감소", "Armor"), "%d%%" % int(round(player.shield * 100.0))],
		[Vector2i(3, 11), GameUI.t("이동 속도", "Move speed"), str(int(player.move_speed))],
		[Vector2i(8, 8), GameUI.t("쿨타임 감소", "Cooldown"), "%d%%" % cd],
		[Vector2i(0, 10), GameUI.t("공격 범위", "Area"), "%d%%" % int(round(player.area_mult * player.signature_area_mult * 100.0))],
		[Vector2i(11, 10), GameUI.t("치명타", "Crit"), "%d%%" % int(round((player.crit_chance + player.crit_bonus) * 100.0))],
		[Vector2i(1, 9), GameUI.t("흡혈", "Lifesteal"), "%d%%" % int(round(player.vampire * 100.0))],
		[Vector2i(10, 10), GameUI.t("자석 범위", "Magnet"), str(int(player.magnetic_area_scale))],
	]:
		grid.add_child(_stat_row(UpgradeDB.sheet_icon(s[0].x, s[0].y), s[1], s[2]))
	root.add_child(GameUI.divider(700))

	# ----- 보유 장비 -----
	root.add_child(_equipment_row(GameUI.t("무기", "Weapons"), player.weapons.keys(), UpgradeDB.WEAPON_SLOTS))
	root.add_child(_equipment_row(GameUI.t("패시브", "Passives"), player.passives.keys(), UpgradeDB.PASSIVE_SLOTS))
	GameUI.pop_in(info_panel, 0.05, 0.96)

func _hp_bar() -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(380, 26)
	bar.max_value = player.max_hp
	bar.value = player.current_hp
	bar.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.2)
	fill.set_expand_margin_all(-4)
	bar.add_theme_stylebox_override("fill", fill)
	var text = GameUI.label("%d / %d" % [int(player.current_hp), int(player.max_hp)], "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	text.add_theme_constant_override("outline_size", 4)
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 15)
	bar.add_child(text)
	return bar

func _run_stat(title: String, value: String) -> HBoxContainer:
	var row = GameUI.hbox(6)
	row.add_child(GameUI.label(title, "DimLabel"))
	row.add_child(GameUI.label(value, "ValueLabel"))
	return row

func _stat_row(icon: Texture2D, title: String, value: String) -> HBoxContainer:
	var row = GameUI.hbox(10)
	row.custom_minimum_size = Vector2(320, 0)
	var tr = TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(28, 28)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(tr)
	var l = GameUI.label(title, "BodyLabel")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(GameUI.label(value, "ValueLabel", HORIZONTAL_ALIGNMENT_RIGHT))
	return row

func _equipment_row(title: String, ids: Array, slots: int) -> HBoxContainer:
	var row = GameUI.hbox(10)
	var l = GameUI.label(title, "ValueLabel")
	l.custom_minimum_size = Vector2(80, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	for i in slots:
		row.add_child(GameUI.upgrade_slot(player, ids[i] if i < ids.size() else "", 56))
	return row

# ================= 메인 메뉴 확인 창 =================
func _open_confirm():
	if has_confirm():
		return
	confirm = Control.new()
	confirm.size = Vector2(1280, 720)
	confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = confirm.size
	confirm.add_child(dim)
	var box = GameUI.panel()
	box.custom_minimum_size = Vector2(520, 0)
	box.position = Vector2(380, 250)
	confirm.add_child(box)
	var v = GameUI.vbox(14)
	box.add_child(v)
	v.add_child(GameUI.label(GameUI.t("메인 메뉴로 돌아갈까요?", "Return to main menu?"), "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var warn = GameUI.label(GameUI.t("이번 판의 진행 상황과 획득한 골드는 사라집니다.", "This run's progress and gold will be lost."), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(warn)
	var row = GameUI.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var yes = GameUI.button(GameUI.t("돌아가기", "Leave"), "BigButton", Vector2(200, 52))
	yes.add_theme_color_override("font_color", GameUI.RED)
	yes.pressed.connect(func(): menu_requested.emit())
	var no = GameUI.button(GameUI.t("취소", "Cancel"), "BigButton", Vector2(200, 52))
	no.pressed.connect(_close_confirm)
	row.add_child(yes)
	row.add_child(no)
	v.add_child(row)
	GameUI.pop_in(box)
	no.grab_focus.call_deferred()

func _close_confirm():
	if has_confirm():
		confirm.queue_free()
	confirm = null
	if visible and buttons.size() > 2 and is_instance_valid(buttons[2]):
		buttons[2].grab_focus.call_deferred()
