extends Control

class_name ResultScreen

## 결과 화면 (게임 오버 / 승리) — 액션 모드 결과창 방식
## 큰 제목 → 랭크 도장(S/A/B/C/D) → 기록 목록, 아래 텍스트 메뉴 (다시 도전 / 메인 메뉴)
## 단축키: R 다시 도전, ESC 메인 메뉴

signal retry_requested
signal menu_requested

var player
var base_ui
var shown := false
var menu: TextMenu
var root: Control

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

# 생존 시간/승리 여부로 랭크
func _rank(victory: bool, seconds: int) -> String:
	if victory:
		return "S"
	if seconds >= 540:
		return "A"
	if seconds >= 360:
		return "B"
	if seconds >= 180:
		return "C"
	return "D"

func _rank_color(rank: String) -> Color:
	match rank:
		"S":
			return Color(1.0, 0.75, 0.2)
		"A":
			return Color(0.4, 0.85, 1.0)
		"B":
			return Color(0.5, 1.0, 0.5)
	return Color(0.8, 0.8, 0.8)

# kind: "defeat" | "victory"
func open(kind: String):
	if shown:
		return
	shown = true
	visible = true
	var victory = kind == "victory"
	root = Control.new()
	root.size = size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(GameUI.dim_backdrop(0.6))

	var title = GameUI.centered("VICTORY!" if victory else "GAME OVER", "TitleLabel", 110, 60)
	if not victory:
		title.add_theme_color_override("font_color", GameUI.RED)
	root.add_child(title)
	var map_id = ""
	var game = player.get_parent()
	if game and "instance_map" in game and game.instance_map:
		map_id = game.instance_map.name
	root.add_child(GameUI.centered("%s   ·   %s" % [GameUI.map_name(map_id), GameUI.character_name(player.character_name)], "DimLabel", 168, 30))

	# ----- 랭크 도장 -----
	var total_seconds = base_ui.minute * 60 + int(base_ui.sec)
	var rank_text = _rank(victory, total_seconds)
	var rank = GameUI.label(rank_text, "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	rank.add_theme_font_size_override("font_size", 150)
	rank.add_theme_color_override("font_color", _rank_color(rank_text))
	rank.add_theme_constant_override("outline_size", 8)
	rank.position = Vector2(250, 230)
	rank.size = Vector2(380, 180)
	rank.pivot_offset = Vector2(190, 90)
	root.add_child(rank)

	# ----- 기록 -----
	var data: Dictionary = RunStats.damage_by_source
	var best_id = ""
	var total = 0.0
	for k in data:
		total += data[k]
		if best_id == "" or data[k] > data[best_id]:
			best_id = k
	var best_text = "-"
	if best_id != "":
		var best_name = UpgradeDB.display_name(best_id, player.character_name) if UpgradeDB.has(best_id) else best_id
		if player.weapons.has(best_id) and player.weapons[best_id].evolved:
			best_name = UpgradeDB.evolved_name(best_id, player.character_name)
		best_text = "%s %d%%" % [best_name, int(round(data[best_id] / max(total, 1.0) * 100.0))]
	var lines = [
		[GameUI.t("생존 시간", "Survived"), GameUI.format_time(total_seconds)],
		[GameUI.t("도달 레벨", "Level"), "Lv %d" % player.character_level],
		[GameUI.t("처치한 적", "Enemies slain"), "%d" % int(player.kill_count)],
		[GameUI.t("주력 무기", "Top weapon"), best_text],
		[GameUI.t("획득 골드", "Gold earned"), "%d G" % int(player.gold_count)],
		[GameUI.t("보유 골드", "Total gold"), "%d G" % int(Global.character_data["GOLD"]["gold"])],
	]
	for i in lines.size():
		var key = GameUI.label(lines[i][0], "BodyLabel")
		key.add_theme_font_size_override("font_size", 24)
		key.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		key.position = Vector2(680, 245 + i * 38)
		root.add_child(key)
		var value = GameUI.label(lines[i][1], "ValueLabel", HORIZONTAL_ALIGNMENT_RIGHT)
		value.add_theme_font_size_override("font_size", 24)
		value.position = Vector2(800, 245 + i * 38)
		value.size = Vector2(220, 30)
		root.add_child(value)

	# ----- 메뉴 -----
	menu = TextMenu.new(24, 44)
	menu.add_item(GameUI.t("다시 도전", "Try Again"), func(): retry_requested.emit())
	menu.add_item(GameUI.t("메인 메뉴", "Main Menu"), func(): menu_requested.emit())
	menu.position = Vector2(0, 500)
	menu.custom_minimum_size = Vector2(1280, 0)
	root.add_child(menu)
	root.add_child(GameUI.hint(GameUI.t("↑ ↓  선택        Enter  결정        R  다시 도전        ESC  메뉴",
		"↑ ↓  Select        Enter  Confirm        R  Retry        ESC  Menu"), 650))

	# 연출: 페이드 인 → 랭크 도장 찍기
	root.modulate.a = 0.0
	rank.scale = Vector2(3.0, 3.0)
	rank.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.4)
	tw.tween_interval(0.3)
	tw.tween_property(rank, "modulate:a", 1.0, 0.01)
	tw.tween_property(rank, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		GameFeel.shake(0.3)
		GameFeel.play_sfx("explosion", 0.8, -6.0, 0.1))
	GameFeel.play_sfx("chest" if victory else "explosion", 1.0 if victory else 0.6, -4.0, 0.1)

func _unhandled_input(event):
	if not shown:
		return
	if menu and menu.handle_input(event):
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			retry_requested.emit()
		elif event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			menu_requested.emit()
