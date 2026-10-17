extends Node2D

@onready var main_character = $MainCharacter/AnimatedSprite2D
@onready var main_enemy     = $MainEnemy/AnimatedSprite2D

func _ready():
	# 오토로드(오디오) bgm 재생
	Audiomanager.play_music_for_scene("menu")
	_style_menu()

# 금테 버튼 / 금색 제목 / 키보드 선택
func _style_menu():
	var buttons = [$ColorRect/Start_Button, $ColorRect/Store_Button, $ColorRect/Setting_Button, $ColorRect/Quit_Button]
	for b in buttons:
		GameUI.use_theme_button(b, 30)
		b.mouse_entered.connect(b.grab_focus)
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
	buttons[0].grab_focus.call_deferred()
	var title = $Slayer_Survival
	GameUI.style_title(title)
	# 제목이 천천히 위아래로 떠 있음
	var y = title.position.y
	var tw = title.create_tween().set_loops()
	tw.tween_property(title, "position:y", y - 6, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(title, "position:y", y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var version = $version
	version.add_theme_color_override("font_color", GameUI.TEXT_DIM)
	version.add_theme_color_override("font_outline_color", Color.BLACK)
	version.add_theme_constant_override("outline_size", 4)
	version.add_theme_font_size_override("font_size", 16)
	
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
	$Button_sound.play()
	var window = SettingsWindow.create(true)
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	layer.add_child(window)
	# 설정 화면이 떠 있는 동안 뒤의 제목/버튼은 숨김 (글자가 겹쳐 보이지 않게)
	var behind = [$Slayer_Survival, $ColorRect/Start_Button, $ColorRect/Store_Button, $ColorRect/Setting_Button, $ColorRect/Quit_Button]
	for n in behind:
		n.visible = false
	window.closed.connect(func():
		for n in behind:
			n.visible = true
		layer.queue_free()
		$ColorRect/Setting_Button.grab_focus())


