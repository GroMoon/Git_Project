extends Node2D

@onready var main_character = $MainCharacter/AnimatedSprite2D
@onready var main_enemy     = $MainEnemy/AnimatedSprite2D

func _ready():
	# 오토로드(오디오) bgm 재생
	Audiomanager.play_music_for_scene("menu")
	
func _process(_delta):
	main_character.play("idle")
	main_enemy.play("idle")

# START BUTTON
func _on_start_button_mouse_entered():
	$Button_sound.play()

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://test.tscn")

# ITEM BUTTON
func _on_item_button_mouse_entered():
	$Button_sound.play()

# OPTIONS BUTTON
func _on_setting_button_mouse_entered():
	$Button_sound.play()
	
# STORE BUTTON
func _on_store_button_mouse_entered():
	$Button_sound.play()

func _on_store_button_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/store/store.tscn")

# QUIT BUTTON
func _on_quit_button_mouse_entered():
	$Button_sound.play()

func _on_quit_button_pressed():
	get_tree().quit()


func _on_setting_button_pressed():
	var options = preload("res://dynamic/5_title_screen/option/options.tscn")
	var options_instance = options.instantiate()
	$Button_sound.play()
	add_child(options_instance)


