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

func _on_select_slime_pressed():
	character_load = preload("res://dynamic/slime.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	add_child(instance_character)
	get_tree().paused = false
	select_panel.queue_free()

func _on_select_golem_pressed():
	character_load = preload("res://dynamic/1_player/characters/golem/golem.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	add_child(instance_character)
	get_tree().paused = false
	select_panel.queue_free()
