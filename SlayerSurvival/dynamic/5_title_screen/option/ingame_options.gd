extends Panel

@onready var full_screen     = $Screen/screen_mode/full_screen
@onready var window_screen   = $Screen/screen_mode/window_screen

func _ready():
	update_ui()

func update_ui():
	full_screen.disabled = false
	window_screen.disabled = false

	full_screen.button_pressed = OptionsManager.is_fullscreen
	window_screen.button_pressed = !OptionsManager.is_fullscreen

	full_screen.disabled = OptionsManager.is_fullscreen
	window_screen.disabled = !OptionsManager.is_fullscreen


func _on_full_screen_toggled(toggled_on):
	if toggled_on and !OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(true)
		update_ui()

func _on_window_screen_toggled(toggled_on):
	if toggled_on and OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(false)
		update_ui()

func _on_back_pressed():
	queue_free()
