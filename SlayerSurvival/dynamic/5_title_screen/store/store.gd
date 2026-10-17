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
	_style_store()

# 금테 판넬 / 버튼으로 통일
func _style_store():
	_style_tree(self)
	$ResetButton.add_theme_color_override("font_color", GameUI.RED)
	$ResetButton.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.55))
	gold_label.add_theme_color_override("font_color", GameUI.GOLD_LIGHT)
	gold_label.add_theme_color_override("font_outline_color", Color.BLACK)
	gold_label.add_theme_constant_override("outline_size", 6)
	$BackButton.grab_focus.call_deferred()

func _style_tree(node: Node):
	for child in node.get_children():
		if child is Button:
			GameUI.use_theme_button(child)
		elif child is Panel:
			child.remove_theme_stylebox_override("panel")
			child.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			# 판넬 배경을 덮던 색 사각형은 투명하게 (금테가 보이도록)
			for c in child.get_children():
				if c is ColorRect:
					c.color = Color(0, 0, 0, 0)
		_style_tree(child)

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
