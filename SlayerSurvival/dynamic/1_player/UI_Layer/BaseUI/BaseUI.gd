extends Control

@onready var select_ui   = get_parent().get_node("SelectUI")
@onready var pause_panel = get_node("PausePanel")
@onready var death_panel = get_node("DeathPanel")
@onready var stopwatch   = get_node("Stopwatch")
@onready var fatal_state = $FatalState

var sec                 = 0.0
var minute              = 0
var globl_pause_flag    = false
var lvlup_pause_flag    = false
var death_pause_flag    = false

var player = null

func _ready():
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	pause_panel.visible = false		# PausePanel 가리기
	death_panel.visible = false		# DeathPanel 가리기
	select_ui.connect("pause", Callable(self, "check_level_up_pause_flag"))
	# player 세팅
	player = get_parent().get_parent()
	# print(player)
	# print(player.death_flag)

func _process(delta):
	process_fatal_state()
	check_pause_pressed()

	death_pause_flag = player.death_flag

	if globl_pause_flag:			# esc 키 눌렀을 때
		pause_panel.visible = true
		get_tree().paused   = true
	elif lvlup_pause_flag: 				# 레벨 업 때
		pause_panel.visible = false
		get_tree().paused   = true
		if globl_pause_flag:
			pause_panel.visible = true
		else:
			pass
	elif death_pause_flag:			# 플레이서 사망 시
		pause_panel.visible = false
		death_panel.visible = true
		get_tree().paused   = true
	else:
		pause_panel.visible = false
		get_tree().paused   = false
		
	if (!lvlup_pause_flag)&&(!death_pause_flag)&&(!globl_pause_flag):
		process_stopwatch(delta)

# esc 키(=pause)를 눌렀을 때
func check_pause_pressed():
	if Input.is_action_just_pressed("pause") : 
		globl_pause_flag = !globl_pause_flag

# fatal_state 효과 (빨간빛)
func process_fatal_state():
	var health_ratio = float (player.current_hp) / player.max_hp
	if health_ratio < 0.3:  # 체력이 30% 미만일 때 효과 적용
		var intensity = health_ratio
		fatal_state.material.set_shader_parameter("health", intensity)
	else:
		fatal_state.material.set_shader_parameter("health", 1.0)  # 체력이 높을 때 효과 제거

# 레벨 업 시 pause 관련 신호 수신 함수
func check_level_up_pause_flag(pause_state: bool):
	lvlup_pause_flag = pause_state

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

# 게임오버 후 Quit 버튼 누를 때
func _on_quit_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 스톱워치 처리
func process_stopwatch(time):
	sec += time							# time은 process에서 delta 값 으로 설정
	if sec >= 60.0:
		minute += 1
		sec = 0.0
	var minute_str = str(minute).pad_zeros(2)
	var sec_str = str(int(sec)).pad_zeros(2)
	stopwatch.text = minute_str + ":" + sec_str
