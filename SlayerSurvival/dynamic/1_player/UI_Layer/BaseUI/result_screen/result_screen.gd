extends Control

class_name ResultScreen

## 결과 화면 (게임 오버 / 승리)
## - 큰 제목, 이번 판 기록(숫자가 올라가는 연출), 무기별 피해, 보유 장비
## - 다시 도전 / 메인 메뉴

signal retry_requested
signal menu_requested

var player
var base_ui
var shown := false

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

# kind: "defeat" | "victory"
func open(kind: String):
	if shown:
		return
	shown = true
	visible = true
	var victory = kind == "victory"
	add_child(GameUI.blur_backdrop(0.72))

	# ----- 제목 -----
	var title = GameUI.label("VICTORY!" if victory else "GAME OVER", "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", GameUI.GOLD if victory else GameUI.RED)
	title.add_theme_constant_override("outline_size", 12)
	title.size = Vector2(1280, 80)
	title.position = Vector2(0, 28)
	add_child(title)
	var sub = GameUI.label(GameUI.t("보스를 쓰러뜨리고 살아남았습니다!", "You defeated the boss and survived!") if victory
		else GameUI.t("모험가가 쓰러졌습니다...", "You have fallen..."), "BodyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	sub.size = Vector2(1280, 30)
	sub.position = Vector2(0, 108)
	add_child(sub)
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2(1.4, 1.4)
	title.modulate.a = 0.0
	var tw = title.create_tween().set_parallel(true)
	tw.tween_property(title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "modulate:a", 1.0, 0.25)
	GameFeel.play_sfx("chest" if victory else "explosion", 1.0 if victory else 0.6, -4.0, 0.1)

	# ----- 왼쪽: 기록 -----
	var left = GameUI.panel()
	left.position = Vector2(90, 156)
	left.custom_minimum_size = Vector2(460, 430)
	add_child(left)
	var lv = GameUI.vbox(12)
	left.add_child(lv)
	var who = GameUI.hbox(16)
	who.add_child(GameUI.slot(GameUI.PORTRAITS.get(player.character_name), "", "SlotGold", 96))
	var who_text = GameUI.vbox(4)
	who_text.add_child(GameUI.label(GameUI.character_name(player.character_name), "HeaderLabel"))
	who_text.add_child(GameUI.label("Lv %d" % player.character_level, "ValueLabel"))
	var map_id = ""
	var game = player.get_parent()
	if game and "instance_map" in game and game.instance_map:
		map_id = game.instance_map.name
	who_text.add_child(GameUI.label(GameUI.map_name(map_id), "DimLabel"))
	who.add_child(who_text)
	lv.add_child(who)
	lv.add_child(GameUI.divider(410))
	var total_seconds = base_ui.minute * 60 + int(base_ui.sec)
	var rows = [
		[GameUI.t("생존 시간", "Survived"), total_seconds, "time"],
		[GameUI.t("처치한 적", "Enemies slain"), int(player.kill_count), "int"],
		[GameUI.t("획득 골드", "Gold earned"), int(player.gold_count), "int"],
		[GameUI.t("보유 골드", "Total gold"), int(Global.character_data["GOLD"]["gold"]), "int"],
	]
	for i in rows.size():
		lv.add_child(_count_row(rows[i][0], rows[i][1], rows[i][2], 0.35 + i * 0.18))
	lv.add_child(GameUI.divider(410))
	var equip = GameUI.hbox(6)
	for id in player.weapons.keys():
		equip.add_child(GameUI.upgrade_slot(player, id, 44))
	for id in player.passives.keys():
		equip.add_child(GameUI.upgrade_slot(player, id, 44))
	var scroll_equip = HFlowContainer.new()
	scroll_equip.custom_minimum_size = Vector2(410, 0)
	for c in equip.get_children():
		equip.remove_child(c)
		scroll_equip.add_child(c)
	lv.add_child(scroll_equip)
	GameUI.pop_in(left, 0.15)

	# ----- 오른쪽: 무기별 피해 -----
	var right = GameUI.panel()
	right.position = Vector2(580, 156)
	right.custom_minimum_size = Vector2(610, 430)
	add_child(right)
	var rv = GameUI.vbox(8)
	right.add_child(rv)
	rv.add_child(GameUI.label(GameUI.t("무기별 피해", "Damage by weapon"), "HeaderLabel"))
	rv.add_child(GameUI.divider(560))
	var data: Dictionary = RunStats.damage_by_source
	var total = 0.0
	for k in data:
		total += data[k]
	var keys = data.keys()
	keys.sort_custom(func(a, b): return data[a] > data[b])
	if keys.is_empty():
		rv.add_child(GameUI.label(GameUI.t("기록 없음", "No damage recorded"), "DimLabel"))
	for i in min(keys.size(), 7):
		rv.add_child(_damage_row(keys[i], data[keys[i]], total, 0.5 + i * 0.08))
	GameUI.pop_in(right, 0.25)

	# ----- 버튼 -----
	var row = GameUI.hbox(24)
	row.position = Vector2(390, 610)
	row.custom_minimum_size = Vector2(500, 0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	var retry = GameUI.button(GameUI.t("다시 도전", "Try Again"), "BigButton", Vector2(240, 58))
	retry.pressed.connect(func(): retry_requested.emit())
	var menu = GameUI.button(GameUI.t("메인 메뉴", "Main Menu"), "BigButton", Vector2(240, 58))
	menu.pressed.connect(func(): menu_requested.emit())
	row.add_child(retry)
	row.add_child(menu)
	retry.focus_neighbor_right = menu.get_path()
	menu.focus_neighbor_left = retry.get_path()
	GameUI.pop_in(row, 0.6)
	retry.grab_focus.call_deferred()

# 숫자가 0부터 올라가는 기록 한 줄
func _count_row(title: String, value: int, kind: String, delay: float) -> HBoxContainer:
	var row = GameUI.hbox(10)
	var l = GameUI.label(title, "BodyLabel")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v = GameUI.label("0", "ValueLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_theme_font_size_override("font_size", 22)
	row.add_child(v)
	var fmt = func(x): return GameUI.format_time(x) if kind == "time" else str(int(x))
	v.text = fmt.call(0)
	var tw = v.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(func(x): v.text = fmt.call(x), 0.0, float(value), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return row

func _damage_row(id: String, amount: float, total: float, delay: float) -> HBoxContainer:
	var row = GameUI.hbox(10)
	var icon: Texture2D = null
	var name_text = id
	var level_text = ""
	if UpgradeDB.has(id):
		icon = UpgradeDB.icon(id, player.character_name)
		name_text = UpgradeDB.display_name(id, player.character_name)
		if player.weapons.has(id):
			var w = player.weapons[id]
			if w.evolved:
				name_text = UpgradeDB.evolved_name(id, player.character_name)
				level_text = "EVO"
			else:
				level_text = "Lv %d" % w.level
	elif id == "pet":
		icon = UpgradeDB.sheet_icon(4, 9)
		name_text = GameUI.t("펫", "Pets")
	elif id == "nuke":
		icon = UpgradeDB.sheet_icon(2, 10)
		name_text = GameUI.t("폭탄 픽업", "Nuke")
	row.add_child(GameUI.slot(icon, "", "SlotPanel", 40))
	var col = GameUI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var top = GameUI.hbox(8)
	col.add_child(top)
	var n = GameUI.label(name_text, "BodyLabel")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.clip_text = true
	top.add_child(n)
	if level_text != "":
		top.add_child(GameUI.label(level_text, "DimLabel"))
	var value = GameUI.label(str(int(amount)), "ValueLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	value.custom_minimum_size = Vector2(90, 0)
	top.add_child(value)
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = 1.0
	bar.value = 0.0
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.68, 0.25)
	fill.set_expand_margin_all(-3)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	var tw = bar.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(bar, "value", amount / max(total, 1.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return row
