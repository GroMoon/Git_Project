extends Control

@onready var select_ui   = get_parent().get_node("SelectUI")
@onready var pause_panel = get_node("PausePanel")
@onready var death_panel = get_node("DeathPanel")
@onready var stopwatch   = get_node("Stopwatch")

# 피해 입을 때 효과
@onready var fatal_state = $FatalState

# 퍼즈 시 플레이어 정보
@onready var respawn_label      = $PausePanel/PlayerInfo/Title/respawn_
@onready var character_img      = $PausePanel/PlayerInfo/Title_img
@onready var status_label       = $PausePanel/PlayerInfo/Status_label
@onready var name_label         = $PausePanel/PlayerInfo/Title/name_
@onready var LV_label           = $PausePanel/PlayerInfo/Title/LV_
@onready var health_label       = $PausePanel/PlayerInfo/Status/health_
@onready var attack_label       = $PausePanel/PlayerInfo/Status/attack_
@onready var shield_label       = $PausePanel/PlayerInfo/Status/shield_
@onready var move_speed_label   = $PausePanel/PlayerInfo/Status/move_speed_
@onready var attack_speed_label = $PausePanel/PlayerInfo/Status/atteck_speed_

# 스킬 레벨 정보
@onready var combo_level        = $PausePanel/PlayerInfo/Skill/combo_
@onready var damage_level       = $PausePanel/PlayerInfo/Skill/damage_
@onready var shield_level       = $PausePanel/PlayerInfo/Skill/shield_
@onready var max_hp_level       = $PausePanel/PlayerInfo/Skill/max_hp_
@onready var move_speed_level   = $PausePanel/PlayerInfo/Skill/move_speed_
@onready var drain_level        = $PausePanel/PlayerInfo/Skill/drain_
@onready var magnetic_level     = $PausePanel/PlayerInfo/Skill/magnetic_
@onready var attack_speed_level = $PausePanel/PlayerInfo/Skill/attack_speed_
@onready var shadow_level       = $PausePanel/PlayerInfo/Skill/shadow_
@onready var cooldown_level     = $PausePanel/PlayerInfo/Skill/cooldown_

# 게임 오버 정보
@onready var survival_time = $DeathPanel/FinalResult/survival_time_
@onready var kill_enemy    = $DeathPanel/FinalResult/kill_enemy_
@onready var get_gold      = $DeathPanel/FinalResult/get_gold_
#@onready var total_gold    = $DeathPanel/FinalResult/total_gold_

# 엔딩 정보
@onready var ending_survival_time = $EndingPanel/FinalResult/survival_time_
@onready var ending_kill_enemy    = $EndingPanel/FinalResult/kill_enemy_
@onready var ending_get_gold      = $EndingPanel/FinalResult/get_gold_
@onready var ending_panel 		  = $EndingPanel
@onready var ending_scene		  = preload("res://dynamic/4_world/ending/ending.tscn")
var ending_instance 			  = null
var is_ending_played 			  = false

var sec                 = 0.0
var minute              = 0
var globl_pause_flag    = false
var lvlup_pause_flag    = false
var death_pause_flag    = false
var diag_pause_flag     = false
var respawn_pause_flag  = false
var ending_pause_flag   = false

var player = null
var boss_bar: BossBar
var pause_menu: PauseMenu			# 새 일시정지 메뉴 (기존 PausePanel 대체)
var result_screen: ResultScreen		# 새 결과 화면 (기존 DeathPanel / EndingPanel 대체)

func _ready():
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	pause_panel.visible = false		# 기존 PausePanel 은 사용하지 않음 (PauseMenu 로 대체)
	death_panel.visible = false		# DeathPanel 가리기
	ending_panel.visible = false	# EndingPanel 가리기
	select_ui.connect("pause", Callable(self, "check_level_up_pause_flag"))
	# player 세팅
	player = get_parent().get_parent()
	# 엘리트/보스 체력바
	boss_bar = BossBar.new()
	add_child(boss_bar)
	move_child(boss_bar, 1)		# 일시정지/결과 패널보다 아래에 그림
	# 일시정지 메뉴 / 결과 화면
	pause_menu = PauseMenu.new()
	pause_menu.setup(player, self)
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.settings_requested.connect(_on_option_pressed)
	pause_menu.menu_requested.connect(_on_menu_pressed)
	result_screen = ResultScreen.new()
	result_screen.setup(player, self)
	add_child(result_screen)
	result_screen.retry_requested.connect(_on_restart_pressed)
	result_screen.menu_requested.connect(_on_quit_pressed)
	_style_hud()

# ================= HUD (액션 모드 HUD 방식) =================
# 왼쪽 위: 이름 · 레벨 / HP 바 / 경험치 바,  가운데 위: 시간,  오른쪽 위: 처치 · 골드
# 왼쪽 아래: 보유 무기 · 패시브 아이콘,  맨 아래: 조작 안내
const HUD_BAR_WIDTH = 280.0
var hud_slots: HudSlots
var hud_hp: Control
var hud_hp_label: Label
var hp_ratio_late := 1.0		# 깎인 체력이 천천히 따라오는 잔상

func _style_hud():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 이름 + 레벨
	var name_label = GameUI.label("", "BodyLabel")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", GameUI.GOLD)
	name_label.position = Vector2(16, 4)
	add_child(name_label)
	# player 의 _ready(캐릭터 이름 설정)가 이 노드보다 늦게 실행되므로 한 프레임 뒤에 이름 표시
	(func(): name_label.text = GameUI.character_name(player.character_name)).call_deferred()
	var level = $Level
	level.position = Vector2(16 + HUD_BAR_WIDTH - 90, 4)
	level.size = Vector2(90, 20)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level.add_theme_font_size_override("font_size", 16)
	level.add_theme_color_override("font_color", Color.WHITE)
	_outline(level, 5)
	# HP 바 (붉은 바 + 잔상 + 숫자)
	hud_hp = Control.new()
	hud_hp.position = Vector2(16, 26)
	hud_hp.size = Vector2(HUD_BAR_WIDTH, 18)
	hud_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_hp.draw.connect(_draw_hud_hp)
	add_child(hud_hp)
	hud_hp_label = GameUI.label("", "BodyLabel")
	hud_hp_label.add_theme_font_size_override("font_size", 13)
	hud_hp_label.position = Vector2(6, -1)
	hud_hp.add_child(hud_hp_label)
	# 경험치 바 (얇은 파란 바)
	var exp_bar = $Exp_Bar
	exp_bar.position = Vector2(16, 48)
	exp_bar.custom_minimum_size = Vector2(HUD_BAR_WIDTH, 8)
	exp_bar.size = Vector2(HUD_BAR_WIDTH, 8)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.15)
	bg.border_color = Color(0, 0, 0, 0.75)
	bg.set_border_width_all(2)
	bg.set_expand_margin_all(2)
	exp_bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.55, 1.0)
	exp_bar.add_theme_stylebox_override("fill", fill)
	# 시간 (가운데 위)
	stopwatch.position = Vector2(540, 8)
	stopwatch.size = Vector2(200, 40)
	stopwatch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stopwatch.add_theme_font_size_override("font_size", 28)
	stopwatch.add_theme_color_override("font_color", Color.WHITE)
	_outline(stopwatch, 6)
	# 처치 / 골드 (오른쪽 위)
	$killcollect.position = Vector2(1110, 12)
	$goldcollect/GoldCount.position = Vector2(1206, 12)
	_outline($killcollect/KillCount, 5)
	_outline($goldcollect/GoldCount, 5)
	# 보유 장비 (왼쪽 아래)
	hud_slots = HudSlots.new()
	hud_slots.setup(player)
	hud_slots.position = Vector2(16, 610)
	add_child(hud_slots)
	move_child(hud_slots, 1)
	# 조작 안내 (맨 아래)
	var controls = GameUI.hint(GameUI.t("WASD / 방향키  이동        ESC  일시정지", "WASD / Arrows  Move        ESC  Pause"), 694)
	controls.add_theme_font_size_override("font_size", 13)
	controls.modulate.a = 0.55
	controls.size.y = 22
	add_child(controls)
	move_child(controls, 1)
	# 보스 체력바는 시간 아래로
	boss_bar.position.y = 62

func _draw_hud_hp():
	var ratio = clamp(player.current_hp / max(player.max_hp, 1.0), 0.0, 1.0)
	var rect = Rect2(Vector2.ZERO, hud_hp.size)
	hud_hp.draw_rect(rect.grow(3.0), Color(0, 0, 0, 0.75))
	hud_hp.draw_rect(rect, Color(0.18, 0.05, 0.05))
	hud_hp.draw_rect(Rect2(0, 0, rect.size.x * hp_ratio_late, rect.size.y), Color(1.0, 0.85, 0.5))
	hud_hp.draw_rect(Rect2(0, 0, rect.size.x * ratio, rect.size.y), Color(0.85, 0.12, 0.1))
	hud_hp.draw_rect(Rect2(0, 0, rect.size.x * ratio, rect.size.y * 0.35), Color(1, 1, 1, 0.18))

func _update_hud_hp(delta: float):
	if hud_hp == null or player == null:
		return
	var ratio = clamp(player.current_hp / max(player.max_hp, 1.0), 0.0, 1.0)
	hp_ratio_late = max(ratio, move_toward(hp_ratio_late, ratio, delta * 0.6))
	hud_hp_label.text = "HP %d / %d" % [int(ceil(max(player.current_hp, 0.0))), int(player.max_hp)]
	hud_hp.queue_redraw()

func _outline(label: Label, size: int):
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.05))
	label.add_theme_constant_override("outline_size", size)

func _process(delta):
	_update_hud_hp(delta)
	process_fatal_state()
	check_pause_pressed()

	death_pause_flag = player.death_flag_for_pause
	diag_pause_flag  = Dialogic.VAR.diag_pause_flag

	if globl_pause_flag && lvlup_pause_flag:	# 레벨업 중 esc 키 눌렀을 때
		_show_pause(true)
		select_ui.visible = false
		get_tree().paused   = true
	elif globl_pause_flag:				# esc 키 눌렀을 때
		_show_pause(true)
		# select_ui.visible = false
		get_tree().paused   = true
	elif lvlup_pause_flag: 				# 레벨 업 때
		_show_pause(false)
		select_ui.visible = true
		get_tree().paused   = true
	elif death_pause_flag:				# 플레이서 사망 시
		_show_pause(false)
		result_screen.open("defeat")		# 결과 화면 (게임 오버)
		get_tree().paused   = true
		# 게임 오버
		survival_time.text = stopwatch.text
		kill_enemy.text    = str(int(player.kill_count))
		get_gold.text      = str(int(player.gold_count))
		#total_gold.text    = str(int(Global.character_data["GOLD"]["gold"]))
		
		
		
	elif diag_pause_flag:				# diag 창 뜰 시
		_show_pause(false)
		get_tree().paused   = true
	elif respawn_pause_flag:				# 부활 퍼즈
		get_tree().paused   = true
	elif ending_pause_flag:				# 엔딩 표시
		_show_pause(false)
		ending_survival_time.text = stopwatch.text
		ending_kill_enemy.text    = str(int(player.kill_count))
		ending_get_gold.text      = str(int(player.gold_count))
		# 엔딩 인스턴스 생성
		if ending_instance == null and not is_ending_played:
			ending_instance = ending_scene.instantiate()
			ending_instance.connect("ending_finished", Callable(self, "_on_ending_finished"))
			add_child(ending_instance)

	else:
		_show_pause(false)
		get_tree().paused   = false
		update_info()
		
	if (!lvlup_pause_flag)&&(!death_pause_flag)&&(!globl_pause_flag)&&(!diag_pause_flag)&&(!respawn_pause_flag)&&(!ending_pause_flag):
		process_stopwatch(delta)

# 새 일시정지 메뉴 열기/닫기
func _show_pause(on: bool):
	if pause_menu == null:
		return
	if on and not pause_menu.is_open():
		pause_menu.open()
	elif not on and pause_menu.is_open():
		pause_menu.close()

func _on_ending_finished():
	get_tree().paused   = true
	ending_instance = null    # 인스턴스 변수 비우기
	is_ending_played = true   # "연출 보여줬음" 표시 -> 다시 생성 안 함
	# 승리 시에도 이번 판 골드를 저장 (기존에는 사망 시에만 저장됨)
	if not result_screen.shown:
		Global.character_data["GOLD"]["gold"] += int(player.gold_count)
		Global.save_character_data()
	# 결과 화면 (승리)
	result_screen.open("victory")

# esc 키(=pause)를 눌렀을 때
func check_pause_pressed():
	if Input.is_action_just_pressed("pause") : 
		# 설정 창이 열려 있으면 설정 창만 닫음 (일시정지 화면으로 돌아감)
		if is_instance_valid(options_window):
			options_window.close()
			options_window = null
			return
		# 일시정지 메뉴의 하위 페이지(설정/확인)면 메인 페이지로, 메인이면 게임 재개
		if pause_menu and pause_menu.is_open() and globl_pause_flag:
			pause_menu.back()
			return
		# 결과 화면 / 엔딩 중에는 일시정지하지 않음
		if death_pause_flag or ending_pause_flag or (result_screen and result_screen.shown):
			return
		globl_pause_flag = !globl_pause_flag
		update_info()

# fatal_state 효과 (빨간빛)
func process_fatal_state():
	# 결과 화면에서는 붉은 저체력 효과를 끔
	if result_screen and result_screen.shown:
		fatal_state.material.set_shader_parameter("fatal_flag", false)
		return
	var health_ratio = float (player.current_hp) / player.max_hp
	if health_ratio < 0.3:  # 체력이 30% 미만일 때 효과 적용
		var intensity = health_ratio
		fatal_state.material.set_shader_parameter("fatal_flag", true)		# 플레그 ON
		fatal_state.material.set_shader_parameter("health", intensity)		# 체력이 따라 효과 진해
	else:
		fatal_state.material.set_shader_parameter("fatal_flag", false)		# 플레그 OFF

# 레벨 업 시 pause 관련 신호 수신 함수
func check_level_up_pause_flag(pause_state: bool):
	lvlup_pause_flag = pause_state

# 스톱워치 처리
func process_stopwatch(time):
	sec += time							# time은 process에서 delta 값 으로 설정
	if sec >= 60.0:
		minute += 1
		sec = 0.0
	var minute_str = str(minute).pad_zeros(2)
	var sec_str = str(int(sec)).pad_zeros(2)
	stopwatch.text = minute_str + ":" + sec_str

# 정보 업데이트
func update_info():
	# 스테이터스
	status_label.text       = player.character_name
	name_label.text         = ": " + player.character_name
	LV_label.text           = ": " + str(player.character_level)
	respawn_label.text      = ": " + str(player.respawn_times)
	health_label.text       = ": " + str(player.current_hp) + " / " + str(player.max_hp)
	attack_label.text       = ": " + str(player.attack_damage)
	shield_label.text       = ": " + str(float(player.shield))
	move_speed_label.text   = ": " + str(player.move_speed)
	attack_speed_label.text = ": " + str(float(player.animation_speed))
	if player.character_name == "fantasy_warrior":
		character_img.texture = preload("res://dynamic/1_player/selcet_character/character_img/fantasy_warrior_pixelart.webp")
	elif player.character_name == "medieval_king":
		character_img.texture = preload("res://dynamic/1_player/selcet_character/character_img/medieval_king_pixelart.webp")
	elif player.character_name == "wizard":
		character_img.texture = preload("res://dynamic/1_player/selcet_character/character_img/wizard_pixelart.webp")
		
	# 스킬 레벨
	combo_level.text        = ": " + str(player.attack_times_level)
	damage_level.text       = ": " + str(player.damage_level)
	shield_level.text       = ": " + str(player.shield_level)
	max_hp_level.text       = ": " + str(player.max_hp_level)
	move_speed_level.text   = ": " + str(player.move_speed_level)
	drain_level.text        = ": " + str(player.drain_level)
	magnetic_level.text     = ": " + str(player.magnetic_area_level)
	cooldown_level.text     = ": " + str(player.cooldown_level)
	shadow_level.text       = ": " + str(player.shadow_partner_level)
	update_build_rows()

# ================= 결과 화면: 무기별 누적 피해 =================
var damage_report: Panel
func show_damage_report():
	if damage_report != null or player == null or not ("weapons" in player):
		return
	var ko = TranslationServer.get_locale().begins_with("ko")
	damage_report = Panel.new()
	damage_report.position = Vector2(898, 60)
	damage_report.size = Vector2(285, 600)
	damage_report.z_index = 5
	add_child(damage_report)
	var title = Label.new()
	title.text = "무기별 피해" if ko else "Damage Dealt"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 16)
	title.size = Vector2(285, 36)
	damage_report.add_child(title)
	var rows = VBoxContainer.new()
	rows.position = Vector2(14, 66)
	rows.size = Vector2(257, 520)
	rows.add_theme_constant_override("separation", 8)
	damage_report.add_child(rows)
	var data: Dictionary = RunStats.damage_by_source
	var total = 0.0
	for k in data:
		total += data[k]
	var keys = data.keys()
	keys.sort_custom(func(a, b): return data[a] > data[b])
	for id in keys.slice(0, 10):
		rows.add_child(_damage_row(id, data[id], total, ko))

func _damage_row(id: String, amount: float, total: float, ko: bool) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(36, 36)
	var name_text = id
	var level_text = ""
	if UpgradeDB.has(id):
		icon.texture = UpgradeDB.icon(id, player.character_name)
		name_text = UpgradeDB.display_name(id, player.character_name)
		if player.weapons.has(id):
			var w = player.weapons[id]
			if w.evolved:
				name_text = UpgradeDB.evolved_name(id, player.character_name)
				level_text = "EVO"
			else:
				level_text = "Lv %d" % w.level
	elif id == "pet":
		icon.texture = UpgradeDB.sheet_icon(4, 9)
		name_text = "펫" if ko else "Pets"
	elif id == "nuke":
		icon.texture = UpgradeDB.sheet_icon(2, 10)
		name_text = "폭탄 픽업" if ko else "Nuke"
	row.add_child(icon)
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var top = HBoxContainer.new()
	col.add_child(top)
	var name_label = Label.new()
	name_label.text = name_text + ("  " + level_text if level_text != "" else "")
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	top.add_child(name_label)
	var dmg_label = Label.new()
	dmg_label.text = str(int(amount))
	dmg_label.add_theme_font_size_override("font_size", 15)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	top.add_child(dmg_label)
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.max_value = 1.0
	bar.value = amount / max(total, 1.0)
	col.add_child(bar)
	return row

# 보유 무기 / 패시브 아이콘 + 레벨 (일시정지 패널 하단)
var build_rows: VBoxContainer
var build_rows_key := ""
func update_build_rows():
	if player == null or not ("weapons" in player):
		return
	# 변경이 있을 때만 다시 그림 (update_info 는 매 프레임 호출됨)
	var key = str(player.passives)
	for id in player.weapons.keys():
		key += id + str(player.weapons[id].level) + str(player.weapons[id].evolved)
	if key == build_rows_key:
		return
	build_rows_key = key
	if build_rows == null:
		build_rows = VBoxContainer.new()
		build_rows.position = Vector2(139, 585)
		build_rows.add_theme_constant_override("separation", 6)
		pause_panel.add_child(build_rows)
	for child in build_rows.get_children():
		child.queue_free()
	var weapon_row = HBoxContainer.new()
	var passive_row = HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 10)
	passive_row.add_theme_constant_override("separation", 10)
	build_rows.add_child(weapon_row)
	build_rows.add_child(passive_row)
	for id in player.weapons.keys():
		var slot = _build_slot(id, player.weapons[id].level)
		if player.weapons[id].evolved:
			slot.get_child(1).text = "EVO"
			slot.get_child(1).add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		weapon_row.add_child(slot)
	for id in player.passives.keys():
		passive_row.add_child(_build_slot(id, player.passives[id]))

func _build_slot(id: String, lv: int) -> Control:
	var slot = HBoxContainer.new()
	slot.add_theme_constant_override("separation", 2)
	var icon = TextureRect.new()
	icon.texture = UpgradeDB.icon(id, player.character_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(40, 40)
	icon.tooltip_text = UpgradeDB.display_name(id, player.character_name)
	slot.add_child(icon)
	var label = Label.new()
	label.text = str(lv) if lv < UpgradeDB.max_level(id) else "MAX"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4) if lv >= UpgradeDB.max_level(id) else Color.WHITE)
	slot.add_child(label)
	return slot
	
	

# resume(돌아가기) 버튼 누를 때
func _on_resume_pressed():
	globl_pause_flag   = false
	get_tree().paused   = false
	_show_pause(false)

# menu(메인메뉴) 버튼 누를 때
func _on_menu_pressed():
	globl_pause_flag = !globl_pause_flag
	get_tree().paused = false
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# Option(설정) 버튼 누를 때
var options_window: Node = null
func _on_option_pressed():
	# 게임 중 설정은 일시정지 메뉴 안의 설정 페이지
	if pause_menu and pause_menu.is_open():
		pause_menu.show_page("settings")
		return
	if is_instance_valid(options_window):
		return		# 이미 열려 있음
	# ESC 는 BaseUI 가 처리하므로 창 자체의 ESC 처리는 끔
	var window = SettingsWindow.create(false)
	add_child(window)
	options_window = window
	window.closed.connect(func(): options_window = null)

# 게임오버 후 Quit 버튼 누를 때
func _on_quit_pressed():
	# 게임 오버 로깅
	# log_game_over_data()
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 게임 오버 후 Restart 버튼 누를 때
func _on_restart_pressed():
	get_tree().change_scene_to_file("res://test.tscn")

# 엔딩 후 Quit 버튼 누를 때
func _on_ending_quit_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 게임 오버 데이터 로깅
func log_game_over_data():
	var log_file = FileAccess.open("res://log.txt", FileAccess.READ_WRITE)
	if not log_file:
		# 파일이 없으면 새로 생성
		log_file = FileAccess.open("res://log.txt", FileAccess.WRITE_READ)
		if not log_file:
			print("Error: Cannot create log.txt file")
			return
	
	# 파일 끝으로 이동
	log_file.seek_end()
	
	# 현재 시간
	var current_time = Time.get_datetime_string_from_system()
	
	# 플레이 시간 (초 단위)
	var total_seconds = minute * 60 + int(sec)
	
	# 로그 데이터 구성
	var log_data = []
	log_data.append("=== GAME OVER LOG - " + current_time + " ===")
	log_data.append("플레이한 캐릭터: " + get_character_display_name(player.character_name))
	log_data.append("플레이한 맵: " + get_current_map_name())
	log_data.append("플레이 시간: " + stopwatch.text + " (" + str(total_seconds) + "초)")
	log_data.append("플레이어 레벨: " + str(player.character_level))
	log_data.append("처치한 적 수: " + str(int(player.kill_count)))
	log_data.append("획득한 골드: " + str(int(player.gold_count)))
	log_data.append("총 보유 골드: " + str(int(Global.character_data["GOLD"]["gold"])))
	log_data.append("")
	log_data.append("=== 플레이어 업그레이드 현황 ===")
	log_data.append("체력 증가 레벨: " + str(player.max_hp_level))
	log_data.append("공격력 증가 레벨: " + str(player.damage_level))
	log_data.append("이동속도 증가 레벨: " + str(player.move_speed_level))
	log_data.append("흡혈 레벨: " + str(player.drain_level))
	log_data.append("자석 범위 레벨: " + str(player.magnetic_area_level))
	log_data.append("방어력 레벨: " + str(player.shield_level))
	log_data.append("쿨타임 레벨: " + str(player.cooldown_level))
	log_data.append("그림자 분신 레벨: " + str(player.shadow_partner_level))
	log_data.append("연타 레벨: " + str(player.attack_times_level))
	# log_data.append("")
	# log_data.append("=== 상점 데이터 ===")
	
	# # StoreData에서 상점 정보 가져오기
	# var store_data = StoreData.store_data
	# for item_key in store_data:
	# 	var item_data = store_data[item_key]
	# 	var item_name = get_store_item_name(item_key)
	# 	log_data.append(item_name + " 레벨: " + str(item_data["level"]) + " (사용 골드: " + str(item_data["used_gold"]) + ")")
	
	log_data.append("")
	log_data.append("=== 플레이어 데이터 ===")
	var character_upgrades = Global.character_data["CHARACTER_STORE_UPGRADES"]
	for upgrade_key in character_upgrades:
		var upgrade_name = get_character_upgrade_name(upgrade_key)
		log_data.append(upgrade_name + ": " + str(character_upgrades[upgrade_key]))
	
	log_data.append("")
	log_data.append("==========================================")
	log_data.append("")
	
	# 로그 파일에 쓰기
	for line in log_data:
		log_file.store_line(line)
	
	log_file.close()
	print("게임 오버 로그가 log.txt에 저장되었습니다.")

# 상점 아이템 이름 변환
func get_store_item_name(item_key: String) -> String:
	match item_key:
		"STORE_ITEM_HEALTH":
			return "체력 증가"
		"STORE_ITEM_SHIELD":
			return "방어력"
		"STORE_ITEM_RESPAWN":
			return "부활 횟수"
		"STORE_ITEM_DAMAGE":
			return "공격력"
		"STORE_ITEM_SPEED":
			return "이동속도"
		"STORE_ITEM_COOLDOWN":
			return "쿨타임"
		"STORE_ITEM_VAMPIRE":
			return "흡혈"
		"STORE_ITEM_GOLD_DROP":
			return "골드 드롭"
		"STORE_ITEM_GEM_DROP":
			return "젬 드롭"
		_:
			return item_key

# 캐릭터 업그레이드 이름 변환
func get_character_upgrade_name(upgrade_key: String) -> String:
	match upgrade_key:
		"health":
			return "체력"
		"shield":
			return "방어력"
		"respawn":
			return "부활 횟수"
		"damage":
			return "공격력"
		"speed":
			return "이동속도"
		"cooldown":
			return "쿨타임"
		"vampire":
			return "흡혈"
		"gold_drop":
			return "골드 드롭"
		"gem_drop":
			return "젬 드롭"
		_:
			return upgrade_key

# 캐릭터 표시 이름 변환
func get_character_display_name(character_name: String) -> String:
	match character_name:
		"fantasy_warrior":
			return "fantasy_warrior"
		"medieval_king":
			return "medieval_king"
		"wizard":
			return "wizard"
		_:
			return character_name

# 현재 맵 이름 가져오기
func get_current_map_name() -> String:
	# 현재 씬에서 맵 노드를 찾기
	var map_node = get_tree().current_scene.get_node_or_null("cave")
	if map_node:
		return "cave"
	
	map_node = get_tree().current_scene.get_node_or_null("dungeon_B1F")
	if map_node:
		return "dungeon_B1F"
	
	# 맵 노드를 찾지 못한 경우 기본값 반환
	return "unknown_map"
