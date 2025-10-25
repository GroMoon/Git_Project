extends Panel

# 화면
@onready var resol_option    = $ScrollContainer/VBoxContainer/Screen/resolution/resol_option
@onready var full_screen     = $ScrollContainer/VBoxContainer/Screen/screen_mode/full_screen
@onready var window_screen   = $ScrollContainer/VBoxContainer/Screen/screen_mode/window_screen
@onready var language_option = $ScrollContainer/VBoxContainer/Language/language_option
@onready var resolution_box  = $ScrollContainer/VBoxContainer/Screen/resolution/resol_option
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
	get_resolutions_list()
	get_language_list()
	set_current_resolution()

func get_resolutions_list():
	# 해상도 버튼 생성(드롭다운)
	resol_option.clear()
	for res in OptionsManager.resolution_list:
		resol_option.add_item("%dx%d" % [res.x, res.y])

func get_language_list():
	# 언어 버튼 생성(드롭다운)
	language_option.clear()
	for language in OptionsManager.language_list:
		language_option.add_item(language)

func set_current_resolution():
	# find로 해당 해상도의 list를 찾고 없다면 해상도의 변경을 하지 않음
	var index = OptionsManager.resolution_list.find(OptionsManager.current_resolution)
	if index != -1:
		resol_option.select(index)
	else:
		# 1920x1080이 기본값이므로 인덱스 2를 선택 (resolution_list의 마지막 항목)
		resol_option.select(2)

func update_ui():
	# 현재 윈도우 모드 확인
	# var current_mode = DisplayServer.window_get_mode()
	var current_mode = OptionsManager.current_window_mode
	var is_fullscreen_mode = (current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# 해상도 설정 활성화/비활성화
	if is_fullscreen_mode:
		resolution_box.disabled = true
	else:
		resolution_box.disabled = false
	
	# 체크박스 상태 업데이트
	full_screen.button_pressed = is_fullscreen_mode
	window_screen.button_pressed = !is_fullscreen_mode
	
	# 체크박스 비활성화 상태 업데이트
	full_screen.disabled = is_fullscreen_mode
	window_screen.disabled = !is_fullscreen_mode
	
	

# 해상도 적용 시그널 연결
func _on_resol_option_item_selected(index):
	var res = OptionsManager.resolution_list[index]
	OptionsManager.apply_resolution(res)

func _on_full_screen_toggled(toggled_on):
	if toggled_on:
		OptionsManager.apply_window_fullscreen_mode()
		# UI 업데이트를 위해 약간의 지연 후 실행
		await get_tree().process_frame
		update_ui()

func _on_window_screen_toggled(toggled_on):
	if toggled_on:
		# 새로운 시스템: 전체화면 이전 상태로 복원
		OptionsManager.apply_window_windowed_mode()
		# UI 업데이트를 위해 약간의 지연 후 실행
		await get_tree().process_frame
		update_ui()

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
