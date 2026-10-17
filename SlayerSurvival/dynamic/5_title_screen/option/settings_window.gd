extends Control

class_name SettingsWindow

## 설정 창 (타이틀 / 게임 중 공용)
## 탭: 화면 / 사운드 / 게임. 바뀐 설정은 바로 적용되고 user://settings.cfg 에 저장됨

signal closed

const LOUD_ICON = preload("res://static/png/sound/loud_w.png")
const MUTE_ICON = preload("res://static/png/sound/mute_w.png")
const PANEL_SIZE = Vector2(660, 460)

var handle_escape := true		# 게임 중에는 BaseUI 가 ESC 를 처리하므로 false
var tab := 0
var content: VBoxContainer
var tab_row: HBoxContainer
var window: PanelContainer

static func create(escape_closes: bool = true) -> SettingsWindow:
	var w = SettingsWindow.new()
	w.handle_escape = escape_closes
	return w

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	z_index = 10
	add_child(GameUI.blur_backdrop(0.5))
	_build()
	GameFeel.play_sfx("ui_open", 1.2, -10.0, 0.1)

func _build():
	for c in get_children():
		if c is PanelContainer:
			c.queue_free()
	window = GameUI.panel()
	window.position = (Vector2(1280, 720) - PANEL_SIZE) / 2.0
	window.custom_minimum_size = PANEL_SIZE
	window.size = PANEL_SIZE
	add_child(window)
	var root = GameUI.vbox(14)
	window.add_child(root)

	# 제목 + 닫기
	var head = GameUI.hbox(8)
	var title = GameUI.label(GameUI.t("설정", "SETTINGS"), "TitleLabel")
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_btn = GameUI.button("X", "TabButton", Vector2(44, 44))
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	root.add_child(head)

	# 탭
	tab_row = GameUI.segmented([GameUI.t("화면", "Display"), GameUI.t("사운드", "Sound"), GameUI.t("게임", "Game")], tab, func(i):
		tab = i
		_fill_content(), 150.0)
	root.add_child(tab_row)
	root.add_child(GameUI.divider(PANEL_SIZE.x - 50))

	content = GameUI.vbox(18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	_fill_content()

	var ok = GameUI.button(GameUI.t("확인", "OK"), "BigButton", Vector2(200, 50))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(close)
	root.add_child(ok)
	GameUI.pop_in(window)
	tab_row.get_child(tab).grab_focus.call_deferred()

func _fill_content():
	for c in content.get_children():
		c.queue_free()
	match tab:
		0:
			content.add_child(_row(GameUI.t("화면 모드", "Window"), GameUI.segmented(
				[GameUI.t("전체 화면", "Fullscreen"), GameUI.t("창 모드", "Windowed")],
				0 if OptionsManager.is_fullscreen else 1,
				func(i):
					OptionsManager.apply_screen_mode(i == 0)
					OptionsManager.save_settings(), 170.0)))
			content.add_child(GameUI.label(GameUI.t("창 모드는 1280 x 720 크기로 열립니다.", "Windowed mode opens at 1280 x 720."), "DimLabel"))
		1:
			content.add_child(_volume_row(GameUI.t("전체", "Master"), "Master"))
			content.add_child(_volume_row("BGM", "BGM"))
			content.add_child(_volume_row(GameUI.t("효과음", "SFX"), "SFX"))
		2:
			content.add_child(_row(GameUI.t("언어", "Language"), GameUI.segmented(
				["한국어", "English"], 0 if GameUI.ko() else 1,
				func(i):
					TranslationServer.set_locale("ko" if i == 0 else "en")
					OptionsManager.save_settings()
					_build.call_deferred(), 150.0)))
			content.add_child(_row(GameUI.t("화면 흔들림", "Screen shake"), _on_off(OptionsManager.screen_shake, func(on):
				OptionsManager.screen_shake = on)))
			content.add_child(_row(GameUI.t("데미지 숫자", "Damage numbers"), _on_off(OptionsManager.damage_numbers, func(on):
				OptionsManager.damage_numbers = on)))

func _row(title: String, control: Control) -> HBoxContainer:
	var row = GameUI.hbox(16)
	var l = GameUI.label(title, "ValueLabel")
	l.custom_minimum_size = Vector2(170, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	row.add_child(control)
	return row

func _on_off(value: bool, setter: Callable) -> HBoxContainer:
	return GameUI.segmented([GameUI.t("켜기", "On"), GameUI.t("끄기", "Off")], 0 if value else 1, func(i):
		setter.call(i == 0)
		OptionsManager.save_settings(), 110.0)

func _volume_row(title: String, bus: String) -> HBoxContainer:
	var row = GameUI.hbox(14)
	var l = GameUI.label(title, "ValueLabel")
	l.custom_minimum_size = Vector2(110, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(300, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = _volume(bus) * 100.0
	row.add_child(slider)
	var value_label = GameUI.label("%d%%" % int(slider.value), "BodyLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	var mute = GameUI.button("", "TabButton", Vector2(48, 42))
	mute.icon = MUTE_ICON if _muted(bus) else LOUD_ICON
	mute.expand_icon = true
	mute.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mute.tooltip_text = GameUI.t("음소거", "Mute")
	row.add_child(mute)
	slider.value_changed.connect(func(v):
		OptionsManager.set_volume(bus, v / 100.0)
		value_label.text = "%d%%" % int(v)
		mute.icon = MUTE_ICON if _muted(bus) else LOUD_ICON
		OptionsManager.save_settings())
	mute.pressed.connect(func():
		OptionsManager.set_mute(bus, not _muted(bus))
		mute.icon = MUTE_ICON if _muted(bus) else LOUD_ICON
		OptionsManager.save_settings()
		if bus == "Master":
			_fill_content.call_deferred())
	return row

func _volume(bus: String) -> float:
	match bus:
		"Master":
			return OptionsManager.master_volume
		"BGM":
			return OptionsManager.bgm_volume
	return OptionsManager.sfx_volume

func _muted(bus: String) -> bool:
	match bus:
		"Master":
			return OptionsManager.is_master_muted
		"BGM":
			return OptionsManager.is_bgm_muted
	return OptionsManager.is_sfx_muted

func _unhandled_input(event):
	if handle_escape and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()

func close():
	if is_queued_for_deletion():
		return
	OptionsManager.save_settings()
	closed.emit()
	queue_free()
