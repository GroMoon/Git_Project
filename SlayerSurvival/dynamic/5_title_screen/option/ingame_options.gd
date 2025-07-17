extends Panel

@onready var full_screen     = $Screen/screen_mode/full_screen
@onready var window_screen   = $Screen/screen_mode/window_screen
# 오디오
@onready var master_volume = $Volume/volume1/master_slider
@onready var bgm_slider    = $Volume/volume2/bgm_slider
@onready var sfx_slider    = $Volume/volume3/sfx_slider
@onready var master_toggle = $Volume/volume1/master_toggle
@onready var bgm_toggle    = $Volume/volume2/bgm_toggle
@onready var sfx_toggle    = $Volume/volume3/sfx_toggle

func _ready():
	update_ui()

func update_ui():
	full_screen.disabled = false
	window_screen.disabled = false

	full_screen.button_pressed = OptionsManager.is_fullscreen
	window_screen.button_pressed = !OptionsManager.is_fullscreen

	full_screen.disabled = OptionsManager.is_fullscreen
	window_screen.disabled = !OptionsManager.is_fullscreen

	master_volume.value = OptionsManager.master_volume
	bgm_slider.value = OptionsManager.bgm_volume
	sfx_slider.value = OptionsManager.sfx_volume

	master_toggle.button_pressed = OptionsManager.is_master_muted or OptionsManager.master_volume == 0.0
	bgm_toggle.button_pressed = OptionsManager.is_bgm_muted or OptionsManager.bgm_volume == 0.0
	sfx_toggle.button_pressed = OptionsManager.is_sfx_muted or OptionsManager.sfx_volume == 0.0

func _on_full_screen_toggled(toggled_on):
	if toggled_on and !OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(true)
		update_ui()

func _on_window_screen_toggled(toggled_on):
	if toggled_on and OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(false)
		update_ui()

func _on_master_slider_value_changed(value):
	OptionsManager.master_volume = value
	OptionsManager.apply_volume()
	update_ui()

func _on_bgm_slider_value_changed(value):
	OptionsManager.bgm_volume = value
	OptionsManager.apply_volume()
	update_ui()

func _on_sfx_slider_value_changed(value):
	OptionsManager.sfx_volume = value
	OptionsManager.apply_volume()
	update_ui()

# 음소거 버튼
func _on_master_toggle_toggled(toggled_on):
	if toggled_on:
		OptionsManager.mute_master()
	else:
		OptionsManager.unmute_master()
	update_ui()

func _on_bgm_toggle_toggled(toggled_on):
	if toggled_on:
		OptionsManager.mute_bgm()
	else:
		OptionsManager.unmute_bgm()
	update_ui()

func _on_sfx_toggle_toggled(toggled_on):
	if toggled_on:
		OptionsManager.mute_sfx()
	else:
		OptionsManager.unmute_sfx()
	update_ui()


func _on_back_pressed():
	queue_free()