extends Node2D

signal reset_store

var gold
@onready var gold_label = $Gold/Gold_label

# Called when the node enters the scene tree for the first time.
func _ready():
	# 게임 일시정지 해제 (test 씬에서 일시정지된 상태를 해제)
	get_tree().paused = false
	Global.connect("purchase", Callable(self, "update_gold"))
	update_gold()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func update_gold():
	gold = Global.character_data["GOLD"]["gold"]
	gold_label.text = str(gold)

func _on_back_button_pressed():
	$Button_sound.play()
	# Save store data
	StoreData.save_store_data()
	# Save character data
	Global.save_character_data()
	# Change scene to menu
	get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")
	

func _on_reset_button_pressed():
	# Reset gold by refunding all spent gold
	var total_refund = 0
	for item in StoreData.store_data:
		total_refund += StoreData.store_data[item]["used_gold"]
		# Reset store data levels to 0
		StoreData.store_data[item]["level"] = "0"
		StoreData.store_data[item]["used_gold"] = 0
	
	Global.character_data["GOLD"]["gold"] += total_refund
	
	# Reset all character upgrades to 0
	for upgrade in Global.character_data["CHARACTER_STORE_UPGRADES"]:
		Global.character_data["CHARACTER_STORE_UPGRADES"][upgrade] = 0
		
	# Update displayed gold
	update_gold()
	
	# Emit reset signal to update all store panels
	emit_signal("reset_store")
	$Button_sound.play()
	
func _on_reset_button_mouse_entered():
	$Button_sound.play()

func _on_back_button_mouse_entered():	
	$Button_sound.play()
