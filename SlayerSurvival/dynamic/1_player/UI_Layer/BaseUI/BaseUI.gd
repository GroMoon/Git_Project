extends Control

@onready var CONNECT_SelectUI = get_parent().get_node("SelectUI")
@onready var pause_panel = get_node("PausePanel")
@onready var death_panel = get_node("DeathPanel")
@onready var stopwatch = get_node("Stopwatch")

var sec = 0.0
var minute = 0
var pause_flag = false
var level_up_pause_flag = false

func _ready():
	pause_panel.visible = false		# PausePanel 가리기
	death_panel.visible = false		# DeathPanel 가리기
	CONNECT_SelectUI.connect("pause", Callable(self, "check_level_up_pause_flag"))

func _process(delta):
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	check_pause_pressed()
	if pause_flag && level_up_pause_flag:
		pause_panel.visible = false
		get_tree().paused = true
	elif pause_flag:
		pause_panel.visible = true
		get_tree().paused   = true
	else:
		pause_panel.visible = false
		get_tree().paused   = false
		
	if !pause_flag:
		process_stopwatch(delta)

func check_pause_pressed():
	if Input.is_action_just_pressed("pause") && level_up_pause_flag == false:
		pause_flag = !pause_flag

func check_level_up_pause_flag(pause_state: bool):
	level_up_pause_flag = pause_state
	pause_flag = !pause_flag

# resume(돌아가기) 버튼 누를 때
func _on_resume_pressed():
	pause_flag = !pause_flag
	get_tree().paused = false
	pause_panel.visible = false

# menu(메인메뉴) 버튼 누를 때
func _on_menu_pressed():
	pause_flag = !pause_flag
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
