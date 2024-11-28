extends Node2D

@onready var select_panel = get_node("Select_Character_Panel")

# 캐릭터를 인스턴스 하기 위한 선언
var character_load
var instance_character

func _ready():
	select_panel.visible = true
	get_tree().paused = true

func _process(_delta):
	pass

# 슬라임 버튼 누르면
func _on_select_slime_pressed():
	character_load = preload("res://dynamic/slime.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(0.5,0.5)
	add_child(instance_character)
	get_tree().paused = false
	select_panel.queue_free()

# 골렘 버튼 누르면
func _on_select_golem_pressed():
	character_load = preload("res://dynamic/1_player/characters/Fantasy_Warrior/fantasy_warrior.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(1,1)
	add_child(instance_character)
	get_tree().paused = false
	select_panel.queue_free()

# Slime 마우스 올리면
func _on_select_slime_mouse_entered():
	$Button_sound.play()

# Golem 마우스 올리면
func _on_select_golem_mouse_entered():
	$Button_sound.play()
