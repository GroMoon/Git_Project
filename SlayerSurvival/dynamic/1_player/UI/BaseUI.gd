extends Control

@onready var pause_panel = get_node("PausePanel")

var pause_flag = false

func _ready():
	pause_panel.visible = false		# PausePanel 가리기

func _process(_delta):
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	check_pause_pressed()
	if pause_flag:
		pause_panel.visible = true
		get_tree().paused = true
	else:
		pause_panel.visible = false
		get_tree().paused = false

func check_pause_pressed():
	if Input.is_action_just_pressed("pause"):
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
