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
	update_sound()

func update_ui():
	# 스크린 설정
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

# 사운드 설정
func update_sound():
	# 사운드 설정(슬라이더 값 업데이트)
	master_volume.value = OptionsManager.master_volume * 100.0
	bgm_slider.value    = OptionsManager.bgm_volume * 100.0
	sfx_slider.value    = OptionsManager.sfx_volume * 100.0

	# mute(음소거 버튼)이 on이면 slider로 볼륨을 0으로 맞춤
	master_toggle.button_pressed = OptionsManager.is_master_muted
	bgm_toggle.button_pressed = OptionsManager.is_bgm_muted
	sfx_toggle.button_pressed = OptionsManager.is_sfx_muted

# 소리 옵션
func _on_master_slider_value_changed(value):
	var linear_volume = value / 100.0 
	OptionsManager.set_volume("Master", linear_volume)
	update_sound()

func _on_bgm_slider_value_changed(value):
	var linear_volume = value / 100.0
	OptionsManager.set_volume("BGM", linear_volume)
	update_sound()

func _on_sfx_slider_value_changed(value):
	var linear_volume = value / 100.0
	OptionsManager.set_volume("SFX", linear_volume)
	update_sound()

# 음소거 버튼
func _on_master_toggle_toggled(toggled_on):
	OptionsManager.set_mute("Master", toggled_on)
	update_sound()

func _on_bgm_toggle_toggled(toggled_on):
	OptionsManager.set_mute("BGM", toggled_on)
	update_sound()

func _on_sfx_toggle_toggled(toggled_on):
	OptionsManager.set_mute("SFX", toggled_on)
	update_sound()

func _on_back_pressed():
	queue_free()