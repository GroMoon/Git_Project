extends Node2D

func _ready():
	pass

func _process(_delta):
	pass

# START BUTTON
func _on_start_button_mouse_entered():
	$Button_sound.play()

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://test.tscn")

# ITEM BUTTON
func _on_item_button_mouse_entered():
	$Button_sound.play()

# SETTING BUTTON
func _on_setting_button_mouse_entered():
	$Button_sound.play()

# STORE BUTTON
func _on_store_button_mouse_entered():
	$Button_sound.play()

# QUIT BUTTON
func _on_quit_button_mouse_entered():
	$Button_sound.play()

func _on_quit_button_pressed():
	get_tree().quit()



