extends Panel

# 화면 (전체화면 모드만 사용)
@onready var resol_option    = $ScrollContainer/VBoxContainer/Screen/resolution/resol_option
@onready var full_screen     = $ScrollContainer/VBoxContainer/Screen/screen_mode/full_screen
@onready var window_screen   = $ScrollContainer/VBoxContainer/Screen/screen_mode/window_screen
@onready var language_option = $ScrollContainer/VBoxContainer/Language/language_option
# 오디오
@onready var master_volume = $ScrollContainer/VBoxContainer/Volume/volume1/master_slider
@onready var bgm_slider    = $ScrollContainer/VBoxContainer/Volume/volume2/bgm_slider
@onready var sfx_slider    = $ScrollContainer/VBoxContainer/Volume/volume3/sfx_slider
@onready var master_toggle = $ScrollContainer/VBoxContainer/Volume/volume1/master_toggle
@onready var bgm_toggle    = $ScrollContainer/VBoxContainer/Volume/volume2/bgm_toggle
@onready var sfx_toggle    = $ScrollContainer/VBoxContainer/Volume/volume3/sfx_toggle

func _ready():
	update_ui()
	update_sound()
	get_language_list()
	set_language_list()

func set_language_list():
	var current_locale = TranslationServer.get_locale()
	match current_locale:
		"ko":
			language_option.select(0)
		"en":
			language_option.select(1)

func get_language_list():
	# 언어 버튼 생성(드롭다운)
	language_option.clear()
	for language in OptionsManager.language_list:
		language_option.add_item(language)

func update_ui():
	var is_fullscreen = OptionsManager.is_fullscreen

	full_screen.button_pressed = is_fullscreen
	window_screen.button_pressed = !is_fullscreen

	full_screen.disabled = is_fullscreen
	window_screen.disabled = !is_fullscreen

# 언어 옵션
func _on_language_option_item_selected(index):
	match language_option.get_item_text(index):
		"한국어":
			TranslationServer.set_locale("ko")
		"English":
			TranslationServer.set_locale("en")

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
	$Button_sound.play()
	queue_free()

func _on_back_mouse_entered():
	$Button_sound.play()


func _on_full_screen_toggled(toggled_on:bool):
	if toggled_on:
		OptionsManager.apply_screen_mode(true)
		await get_tree().process_frame
		update_ui()


func _on_window_screen_toggled(toggled_on:bool):
	if toggled_on:
		OptionsManager.apply_screen_mode(false)
		await get_tree().process_frame
		update_ui()