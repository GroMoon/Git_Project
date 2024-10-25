extends Control

@onready var pause_panel = get_node("PausePanel")

func _ready():
	# PausePanel 가리기
	pause_panel.visible = false

func _process(_delta):
	# esc("pause") 누르면 PausePanel visible 및 모든 노드 중지(PausePanel 제외)
	if Input.is_action_just_pressed("pause"):
		pause_panel.visible = true
		get_tree().paused = true

# resume(돌아가기) 버튼 누를 때
func _on_resume_pressed():
	get_tree().paused = false
	pause_panel.visible = false

# menu(메인메뉴) 버튼 누를 때
func _on_menu_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")
