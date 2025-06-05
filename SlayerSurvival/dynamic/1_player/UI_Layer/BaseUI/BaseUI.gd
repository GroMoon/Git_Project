extends Control

@onready var select_ui   = get_parent().get_node("SelectUI")
@onready var pause_panel = get_node("PausePanel")
@onready var death_panel = get_node("DeathPanel")
@onready var stopwatch   = get_node("Stopwatch")

# 피해 입을 때 효과
@onready var fatal_state = $FatalState

# 퍼즈 시 플레이어 정보
@onready var respawn_label      = $PausePanel/PlayerInfo/respawn_
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
@onready var survival_time = $DeathPanel/FinalResult/VBoxContainer/survival_time_
@onready var kill_enemy    = $DeathPanel/FinalResult/VBoxContainer/kill_enemy_
@onready var get_gold      = $DeathPanel/FinalResult/VBoxContainer/get_gold_


var sec                 = 0.0
var minute              = 0
var globl_pause_flag    = false
var lvlup_pause_flag    = false
var death_pause_flag    = false
var diag_pause_flag     = false

var player = null

func _ready():
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	pause_panel.visible = false		# PausePanel 가리기
	death_panel.visible = false		# DeathPanel 가리기
	select_ui.connect("pause", Callable(self, "check_level_up_pause_flag"))
	# player 세팅
	player = get_parent().get_parent()
	# print(player)
	# print(player.death_flag_for_pause)

func _process(delta):
	process_fatal_state()
	check_pause_pressed()

	death_pause_flag = player.death_flag_for_pause
	diag_pause_flag  = Dialogic.VAR.diag_pause_flag

	if globl_pause_flag:				# esc 키 눌렀을 때
		pause_panel.visible = true
		get_tree().paused   = true
	elif lvlup_pause_flag: 				# 레벨 업 때
		pause_panel.visible = false
		get_tree().paused   = true
		if globl_pause_flag:
			pause_panel.visible = true
		else:
			pass
	elif death_pause_flag:				# 플레이서 사망 시
		pause_panel.visible = false
		death_panel.visible = true
		get_tree().paused   = true
		
	elif diag_pause_flag:				# diag 창 뜰 시
		pause_panel.visible = false
		get_tree().paused   = true
	else:
		pause_panel.visible = false
		get_tree().paused   = false
		update_info()
		
	if (!lvlup_pause_flag)&&(!death_pause_flag)&&(!globl_pause_flag)&&(!diag_pause_flag):
		process_stopwatch(delta)

# esc 키(=pause)를 눌렀을 때
func check_pause_pressed():
	if Input.is_action_just_pressed("pause") : 
		globl_pause_flag = !globl_pause_flag
		update_info()

# fatal_state 효과 (빨간빛)
func process_fatal_state():
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
		pass
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
	
	# 게임 오버
	survival_time.text = stopwatch.text
	kill_enemy.text    = str(int(player.kill_count))
	get_gold.text      = str(int(player.gold_count))

# resume(돌아가기) 버튼 누를 때
func _on_resume_pressed():
	globl_pause_flag   = !globl_pause_flag
	get_tree().paused   = false
	pause_panel.visible = false

# menu(메인메뉴) 버튼 누를 때
func _on_menu_pressed():
	globl_pause_flag = !globl_pause_flag
	get_tree().paused = false
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# Option(설정) 버튼 누를 때
func _on_option_pressed():
	var ingame_options = preload("res://dynamic/5_title_screen/option/ingame_options.tscn")
	var ingame_options_instance = ingame_options.instantiate()
	add_child(ingame_options_instance)

# 게임오버 후 Quit 버튼 누를 때
func _on_quit_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 게임 오버 후 Restart 버튼 누를 때
func _on_restart_pressed():
	get_tree().change_scene_to_file("res://test.tscn")
