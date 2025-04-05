extends Node2D

@onready var select_character = get_node("Select_Character_Panel")
@onready var select_map = get_node("Select_Map_Panel")

# 캐릭터, 맵 선택 마우스 오버 관련 선언
@onready var attack_label = $Select_Character_Panel/CharacterInfo/LabelContainer/attack
@onready var move_label   = $Select_Character_Panel/CharacterInfo/LabelContainer/move
@onready var helth_label  = $Select_Character_Panel/CharacterInfo/LabelContainer/health
@onready var character_icon = $Select_Character_Panel/CharacterInfo/icon
@onready var character_details = $Select_Character_Panel/CharacterInfo/details
@onready var preview_map = $Select_Map_Panel/MapInfo/preview_map
@onready var map_details = $Select_Map_Panel/MapInfo/details

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
# 펫을 인스턴스 하기 위한 선언
var mushroom_pet_preload
var skeleton_pet_preload
var goblin_pet_preload
var flyingeye_pet_preload

func _ready():
	select_character.visible = false
	select_map.visible = true
	get_tree().paused = true
	# 펫 미리 preload
	mushroom_pet_preload  = preload("res://dynamic/2_enemy/Mushroom/Mushroom_Pet/mushroom_pet.tscn")
	skeleton_pet_preload  = preload("res://dynamic/2_enemy/Skeleton/Skeleton_Pet/skeleton_pet.tscn")
	goblin_pet_preload    = preload("res://dynamic/2_enemy/Goblin/Goblin_Pet/goblin_pet.tscn")
	flyingeye_pet_preload = preload("res://dynamic/2_enemy/FlyingEye/FlyingEye_Pet/flyingeye_pet.tscn")

func _process(_delta):
	player = get_node("player")
	if player:
		# 그림자 소환 알고리즘
		if (player.shadow_attack == 1) and (player.is_shadow_on == 0):
			var shadow_instance = shadow_preload.instantiate()
			shadow_instance.name = "shadow"
			shadow_instance.global_position = player.global_position
			add_child(shadow_instance)
			move_child(shadow_instance, player.get_index() - 1)
			player.is_shadow_on = 1
		# mushroom 펫 소환 알고리즘
		if (player.mushroom_pet_on == true) and (player.is_mushroom_pet == false):
			var mushroom_pet_instance = mushroom_pet_preload.instantiate()
			mushroom_pet_instance.name = "mushroom_pet"
			mushroom_pet_instance.global_position = player.global_position
			add_child(mushroom_pet_instance)
			move_child(mushroom_pet_instance, player.get_index() - 1)
			player.is_mushroom_pet = true
		# skeleton 펫 소환 알고리즘
		if (player.skeleton_pet_on == true) and (player.is_skeleton_pet == false):
			var skeleton_pet_instance = skeleton_pet_preload.instantiate()
			skeleton_pet_instance.name = "skeleton_pet"
			skeleton_pet_instance.global_position = player.global_position
			add_child(skeleton_pet_instance)
			move_child(skeleton_pet_instance, player.get_index() - 1)
			player.is_skeleton_pet = true
		# goblin 펫 소환 알고리즘
		if (player.goblin_pet_on == true) and (player.is_goblin_pet == false):
			var goblin_pet_instance = goblin_pet_preload.instantiate()
			goblin_pet_instance.name = "goblin_pet"
			goblin_pet_instance.global_position = player.global_position
			add_child(goblin_pet_instance)
			move_child(goblin_pet_instance, player.get_index() - 1)
			player.is_goblin_pet = true
		# flyingeye 펫 소환 알고리즘
		if (player.flyingeye_pet_on == true) and (player.is_flyingeye_pet == false):
			var flyingeye_pet_instance = flyingeye_pet_preload.instantiate()
			flyingeye_pet_instance.name = "flyingeye_pet"
			flyingeye_pet_instance.global_position = player.global_position
			add_child(flyingeye_pet_instance)
			move_child(flyingeye_pet_instance, player.get_index() - 1)
			player.is_flyingeye_pet = true
			
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
	# 그림자 결정
	shadow_preload = preload("res://dynamic/1_player/characters/Medieval_King/Shadow/medieval_king_shadow.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(1,1)
	add_child(instance_character)
	get_tree().paused = false
	select_character.queue_free()

# Wizard
func _on_wizard_pressed():
	character_load = preload("res://dynamic/1_player/characters/Wizard/wizard.tscn")
	# 그림자 결정
	shadow_preload = preload("res://dynamic/1_player/characters/Wizard/Shadow/wizard_shadow.tscn")
	instance_character = character_load.instantiate()
	instance_character.name = "player"
	# 스케일 조정
	instance_character.scale = Vector2(0.8,0.8)
	add_child(instance_character)
	get_tree().paused = false
	select_character.queue_free()

# Cave
func _on_cave_button_pressed():
	map_load = preload("res://dynamic/4_world/Cave/cave.tscn")
	instance_map = map_load.instantiate()
	instance_map.name = "map"
	add_child(instance_map)
	move_child(instance_map, 0)				# map 레이어를 가장 뒤로 보냄
	select_map.queue_free()
	select_character.visible = true

# Dungeon_B1F
func _on_dungeon_button_pressed():
	map_load = preload("res://dynamic/4_world/Dungeon_B1F/dungeon_B1F.tscn")
	instance_map = map_load.instantiate()
	instance_map.name = "map"
	add_child(instance_map)
	move_child(instance_map, 0)				# map 레이어를 가장 뒤로 보냄
	select_map.queue_free()
	select_character.visible = true

func _on_select_warrior_mouse_entered():
	$Button_sound.play()
	character_icon.texture = preload("res://dynamic/1_player/selcet_character/character_img/fantasy_warrior_pixelart.webp")
	character_details.text = "신비로운 과거를 품은 검객, 긴 백발 속에는 싸움의 세월이 녹아 있으며, 한 손에 쥔 검은 마치 그의 분신과도 같습니다. 그는 적들을 단칼에 베어버리는 강력한 공격력과 독보적인 전투 기술로 전장에서의 전설로 불립니다. 하지만 내면 깊은 곳에는 복수를 꿈꾸는 어둠이 자리 잡고 있습니다."
	attack_label.text = "■■"
	move_label.text   = "■■■■"
	helth_label.text  = "■■■"
	
func _on_select_king_mouse_entered():
	$Button_sound.play()
	character_icon.texture = preload("res://dynamic/1_player/selcet_character/character_img/medieval_king_pixelart.webp")
	character_details.text = "왕관을 쓴 전사의 모습을 한 그는, 자신의 영토와 백성을 위해 싸우는 불굴의 지도자입니다. 그가 휘두르는 거대한 검은 적에게 공포를 심어주며, 중세의 전장에서 왕으로서의 강력한 존재감을 드러냅니다. 고결한 로브와 왕관은 그의 권력을 상징하며, 모든 적은 그의 분노 앞에서 무릎을 꿇게 됩니다."
	attack_label.text = "■■■■"
	move_label.text   = "■■"
	helth_label.text  = "■■■■■"

func _on_wizard_mouse_entered():
	$Button_sound.play()
	# FIXME
	character_icon.texture = preload("res://dynamic/1_player/selcet_character/character_img/wizard_pixelart.webp")
	character_details.text = "마법사"
	attack_label.text = "■■■■■■"
	move_label.text   = "■■"
	helth_label.text  = "■■■"
	
func _on_cave_button_mouse_entered():
	preview_map.texture = preload("res://dynamic/4_world/Cave/cave_title.png")
	map_details.text = "어둠 속에 반짝이는 수정들과 습한 공기가 느껴지는 공간... \n바닥의 구멍을 조심하세요!"
	$Button_sound.play()

func _on_dungeon_button_mouse_entered():
	preview_map.texture = preload("res://dynamic/4_world/Dungeon_B1F/dungeon_title.png")
	map_details.text = "거대한 돌벽과 낡은 상자들 사이로 퍼지는 섬뜩한 분위기"
	$Button_sound.play()

# 해당 씬 재시작
func _on_backchar_pressed():
	get_tree().reload_current_scene()

func _on_backmap_pressed():
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")


