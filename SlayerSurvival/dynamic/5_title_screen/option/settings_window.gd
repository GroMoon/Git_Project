extends Control

class_name SettingsWindow

## 설정 화면 (액션 모드식 텍스트 목록)
## ↑ ↓ 선택, ← → 값 변경, Enter 결정, ESC 뒤로. 바뀐 설정은 바로 적용되고 user://settings.cfg 에 저장됨
## 타이틀에서는 이 창을 쓰고, 게임 중에는 일시정지 메뉴 안의 "설정" 페이지가 같은 항목(add_items)을 씀

signal closed

const VOLUME_STEP = 0.1

var handle_escape := true
var menu: TextMenu

static func create(escape_closes: bool = true) -> SettingsWindow:
	var w = SettingsWindow.new()
	w.handle_escape = escape_closes
	return w

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	z_index = 10
	add_child(GameUI.dim_backdrop(0.75))
	_build()

func _build():
	for c in get_children():
		if not (c is ColorRect):
			c.queue_free()
	add_child(GameUI.centered(GameUI.t("설정", "SETTINGS"), "TitleLabel", 100, 56))
	menu = TextMenu.new(22, 40)
	menu.position = Vector2(0, 190)
	menu.custom_minimum_size = Vector2(1280, 0)
	add_child(menu)
	add_items(menu, close, func(): _build.call_deferred())
	add_child(GameUI.hint(GameUI.t("↑ ↓  선택        ← →  값 변경        Enter  결정        ESC  뒤로",
		"↑ ↓  Select        ← →  Change        Enter  Confirm        ESC  Back"), 640))
	GameUI.fade_in(self, 0.15)

# 설정 항목들을 메뉴에 추가 (일시정지 메뉴에서도 사용)
# on_back: "뒤로" 선택 시, on_language: 언어가 바뀌었을 때(화면 다시 그리기)
static func add_items(m: TextMenu, on_back: Callable, on_language: Callable = Callable()):
	var row = func(title: String, value: String) -> String:
		return "%s\t%s" % [title, value]
	m.add_item(func(): return row.call(GameUI.t("화면 모드", "Window"),
			GameUI.t("전체 화면", "Fullscreen") if OptionsManager.is_fullscreen else GameUI.t("창 모드", "Windowed")),
		func(): _toggle_fullscreen(),
		func(_d): _toggle_fullscreen())
	for bus in ["Master", "BGM", "SFX"]:
		var title = {"Master": GameUI.t("전체 볼륨", "Master"), "BGM": "BGM", "SFX": GameUI.t("효과음", "SFX")}[bus]
		m.add_item(func(): return row.call(title, _volume_text(bus)),
			func():
				OptionsManager.set_mute(bus, not _muted(bus))
				OptionsManager.save_settings(),
			func(d):
				OptionsManager.set_volume(bus, clamp(_volume(bus) + d * VOLUME_STEP, 0.0, 1.0))
				OptionsManager.save_settings())
	m.add_item(func(): return row.call(GameUI.t("언어", "Language"), "한국어" if GameUI.ko() else "English"),
		func(): _toggle_language(on_language),
		func(_d): _toggle_language(on_language))
	m.add_item(func(): return row.call(GameUI.t("화면 흔들림", "Screen shake"), _on_off(OptionsManager.screen_shake)),
		func(): _toggle("screen_shake"),
		func(_d): _toggle("screen_shake"))
	m.add_item(func(): return row.call(GameUI.t("데미지 숫자", "Damage numbers"), _on_off(OptionsManager.damage_numbers)),
		func(): _toggle("damage_numbers"),
		func(_d): _toggle("damage_numbers"))
	m.add_item(func(): return GameUI.t("뒤로", "Back"), on_back)

static func _on_off(value: bool) -> String:
	return GameUI.t("켜기", "On") if value else GameUI.t("끄기", "Off")

static func _toggle(key: String):
	OptionsManager.set(key, not OptionsManager.get(key))
	OptionsManager.save_settings()

static func _toggle_fullscreen():
	OptionsManager.apply_screen_mode(not OptionsManager.is_fullscreen)
	OptionsManager.save_settings()

static func _toggle_language(on_language: Callable):
	TranslationServer.set_locale("en" if GameUI.ko() else "ko")
	OptionsManager.save_settings()
	if on_language.is_valid():
		on_language.call()

static func _volume_text(bus: String) -> String:
	if _muted(bus):
		return GameUI.t("음소거", "Muted")
	var v = int(round(_volume(bus) * 100.0))
	return "%s %d%%" % ["■".repeat(int(round(v / 20.0))) + "□".repeat(5 - int(round(v / 20.0))), v]

static func _volume(bus: String) -> float:
	match bus:
		"Master":
			return OptionsManager.master_volume
		"BGM":
			return OptionsManager.bgm_volume
	return OptionsManager.sfx_volume

static func _muted(bus: String) -> bool:
	match bus:
		"Master":
			return OptionsManager.is_master_muted
		"BGM":
			return OptionsManager.is_bgm_muted
	return OptionsManager.is_sfx_muted

func _unhandled_input(event):
	if menu and menu.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if handle_escape and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()

func close():
	if is_queued_for_deletion():
		return
	OptionsManager.save_settings()
	closed.emit()
	queue_free()
