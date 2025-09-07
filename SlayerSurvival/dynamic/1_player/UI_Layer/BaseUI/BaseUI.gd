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
@onready var survival_time = $DeathPanel/FinalResult/survival_time_
@onready var kill_enemy    = $DeathPanel/FinalResult/kill_enemy_
@onready var get_gold      = $DeathPanel/FinalResult/get_gold_
#@onready var total_gold    = $DeathPanel/FinalResult/total_gold_


var sec                 = 0.0
var minute              = 0
var globl_pause_flag    = false
var lvlup_pause_flag    = false
var death_pause_flag    = false
var diag_pause_flag     = false
var respawn_pause_flag  = false

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
		# 게임 오버
		survival_time.text = stopwatch.text
		kill_enemy.text    = str(int(player.kill_count))
		get_gold.text      = str(int(player.gold_count))
		#total_gold.text    = str(int(Global.character_data["GOLD"]["gold"]))
		
		
		
	elif diag_pause_flag:				# diag 창 뜰 시
		pause_panel.visible = false
		get_tree().paused   = true
	elif respawn_pause_flag:				# 부활 퍼즈
		get_tree().paused   = true
	else:
		pause_panel.visible = false
		get_tree().paused   = false
		update_info()
		
	if (!lvlup_pause_flag)&&(!death_pause_flag)&&(!globl_pause_flag)&&(!diag_pause_flag)&&(!respawn_pause_flag):
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
	# 게임 오버 로깅
	log_game_over_data()
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 게임 오버 후 Restart 버튼 누를 때
func _on_restart_pressed():
	get_tree().change_scene_to_file("res://test.tscn")

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
