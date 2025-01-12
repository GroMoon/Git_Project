extends Node2D

@onready var select_character = get_node("Select_Character_Panel")
@onready var select_map = get_node("Selecet_Map_Panel")

# 캐릭터를 인스턴스 하기 위한 선언
var character_load
var instance_character
# 맵을 인스턴스 하기 위한 선언
var map_load
var instance_map
# 그림자를 인스턴스 하기 위한 선언
var player
var player_shadow_attack_on = 0
var shadow_preload

func _ready():
	select_character.visible = true
	select_map.visible = true
	get_tree().paused = true

func _process(_delta):
	player = get_node("player")
	if player:
		if (player.shodow_attack == 1) and (player.is_shadow_on == 0):
			var shadow_instance = shadow_preload.instantiate()
			shadow_instance.name = "shadow"
			shadow_instance.global_position = player.global_position
			add_child(shadow_instance)
			player.is_shadow_on = 1

# Fantasy Warrior
func _on_select_warrior_pressed():
	character_load = preload("res://dynamic/1_player/characters/Fantasy_Warrior/fantasy_warrior.tscn")
	# 그림자 결정
	shadow_preload = preload("res://dynamic/1_player/characters/Fantasy_Warrior/Shadow/fantasy_warrior_shadow.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(1,1)
	add_child(instance_character)
	get_tree().paused = false
	select_character.queue_free()

# Medieval King
func _on_select_king_pressed():
	character_load = preload("res://dynamic/1_player/characters/Medieval_King/medieval_king.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(1,1)
	add_child(instance_character)
	get_tree().paused = false
	select_character.queue_free()

# Cave
func _on_cave_button_pressed():
	map_load = preload("res://dynamic/4_world/cave/cave.tscn")
	instance_map = map_load.instantiate()
	instance_map.name = "map"
	add_child(instance_map)
	move_child(instance_map, 0)				# map 레이어를 가장 뒤로 보냄
	select_map.queue_free()

# Dungeon_B1F
func _on_dungeon_button_pressed():
	map_load = preload("res://dynamic/4_world/dungeon_B1F/dungeon_B1F.tscn")
	instance_map = map_load.instantiate()
	instance_map.name = "map"
	add_child(instance_map)
	move_child(instance_map, 0)				# map 레이어를 가장 뒤로 보냄
	select_map.queue_free()

func _on_select_king_mouse_entered():
	$Button_sound.play()

func _on_select_warrior_mouse_entered():
	$Button_sound.play()

func _on_cave_button_mouse_entered():
	$Button_sound.play()

func _on_dungeon_button_mouse_entered():
	$Button_sound.play()
