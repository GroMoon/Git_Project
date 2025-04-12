extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_back_button_pressed():
	#! FIXME : 데이터 저장 코드 필요
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")
