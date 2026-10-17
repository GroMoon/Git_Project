extends Control

class_name PauseMenu

## 일시정지 메뉴 (ESC) — 액션 모드식 텍스트 메뉴
## - main: 계속하기 / 설정 / 메인 메뉴  (아래에 현재 캐릭터·기록·보유 장비)
## - settings: 설정 항목 (SettingsWindow.add_items 와 같은 항목)
## - confirm: 메인 메뉴로 나갈지 확인
## ↑ ↓ 선택, Enter 결정, ← → 값 변경, ESC 뒤로/계속하기 (ESC 는 BaseUI 가 back() 호출)

signal resume_requested
signal settings_requested		# (예전 호환용, 현재는 메뉴 안 설정 페이지 사용)
signal menu_requested

var player
var base_ui
var page := "main"
var menu: TextMenu
var title: Label
var hint: Label
var info: Control

func setup(p, ui):
	player = p
	base_ui = ui

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	visible = false
	z_index = 5

# ================= 열기 / 닫기 =================
func open():
	if visible:
		return
	visible = true
	show_page("main")
	GameUI.fade_in(self, 0.15)

func close():
	visible = false
	page = "main"

func is_open() -> bool:
	return visible

func has_confirm() -> bool:
	return visible and page == "confirm"

func _close_confirm():
	show_page("main", 2)

# ESC: 하위 페이지면 메인으로, 메인이면 게임 재개
func back():
	if page != "main":
		show_page("main", 1 if page == "settings" else 2)
	else:
		resume_requested.emit()

func show_page(name_: String, select_index: int = 0):
	page = name_
	for c in get_children():
		c.queue_free()
	add_child(GameUI.dim_backdrop(0.65))
	match page:
		"main":
			title = GameUI.centered(GameUI.t("일시정지", "PAUSED"), "TitleLabel", 110, 56)
			menu = TextMenu.new(28, 60)
			menu.add_item(GameUI.t("계속하기", "Resume"), func(): resume_requested.emit())
			menu.add_item(GameUI.t("설정", "Settings"), func(): show_page("settings"))
			menu.add_item(GameUI.t("메인 메뉴로", "Main Menu"), func(): show_page("confirm", 1))
			menu.position = Vector2(0, 220)
			hint = GameUI.hint(GameUI.t("↑ ↓  선택        Enter  결정        ESC  계속하기",
				"↑ ↓  Select        Enter  Confirm        ESC  Resume"), 650)
			_build_info()
		"settings":
			title = GameUI.centered(GameUI.t("설정", "SETTINGS"), "TitleLabel", 90, 56)
			menu = TextMenu.new(22, 40)
			SettingsWindow.add_items(menu, func(): show_page("main", 1), func(): show_page.call_deferred("settings", 4))
			menu.position = Vector2(0, 175)
			hint = GameUI.hint(GameUI.t("↑ ↓  선택        ← →  값 변경        Enter  결정        ESC  뒤로",
				"↑ ↓  Select        ← →  Change        Enter  Confirm        ESC  Back"), 650)
		"confirm":
			title = GameUI.centered(GameUI.t("메인 메뉴로 나갈까요?", "Return to main menu?"), "TitleLabel", 150, 56)
			title.add_theme_font_size_override("font_size", 36)
			add_child(GameUI.centered(GameUI.t("이번 판의 진행 상황과 획득한 골드는 사라집니다.",
				"This run's progress and gold will be lost."), "DimLabel", 210, 30))
			menu = TextMenu.new(28, 60)
			menu.add_item(GameUI.t("나가기", "Leave"), func(): menu_requested.emit())
			menu.add_item(GameUI.t("취소", "Cancel"), func(): show_page("main", 2))
			menu.position = Vector2(0, 280)
			hint = GameUI.hint(GameUI.t("↑ ↓  선택        Enter  결정        ESC  취소",
				"↑ ↓  Select        Enter  Confirm        ESC  Cancel"), 650)
	add_child(title)
	menu.custom_minimum_size = Vector2(1280, 0)
	menu.size = Vector2(1280, 0)
	add_child(menu)
	menu.select(select_index, false)
	add_child(hint)

# 메인 페이지 아래쪽: 캐릭터 · 기록 · 보유 장비
func _build_info():
	info = GameUI.vbox(10)
	info.position = Vector2(0, 440)
	info.custom_minimum_size = Vector2(1280, 0)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(info)
	var who = GameUI.label("%s   Lv %d   HP %d / %d" % [GameUI.character_name(player.character_name), player.character_level,
		int(player.current_hp), int(player.max_hp)], "HeaderLabel", HORIZONTAL_ALIGNMENT_CENTER)
	who.add_theme_font_size_override("font_size", 20)
	info.add_child(who)
	info.add_child(GameUI.label(GameUI.t("생존 %s     처치 %d     골드 %d", "Time %s     Kills %d     Gold %d") % [
		base_ui.stopwatch.text, int(player.kill_count), int(player.gold_count)], "DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var slots = GameUI.hbox(6)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in player.weapons.keys():
		slots.add_child(GameUI.upgrade_slot(player, id, 44))
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(18, 0)
	slots.add_child(gap)
	for id in player.passives.keys():
		slots.add_child(GameUI.upgrade_slot(player, id, 44))
	info.add_child(slots)

func _unhandled_input(event):
	if visible and menu and menu.handle_input(event):
		get_viewport().set_input_as_handled()
