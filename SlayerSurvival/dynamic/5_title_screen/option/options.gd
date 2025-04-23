extends Panel

@onready var resol_option    = $Screen/resolution/resol_option
@onready var full_screen     = $Screen/screen_mode/full_screen
@onready var window_screen   = $Screen/screen_mode/window_screen
@onready var language_option = $Language/language_option

func _ready():
	update_ui()
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

func update_ui():
	full_screen.disabled = false
	window_screen.disabled = false

	full_screen.button_pressed = OptionsManager.is_fullscreen
	window_screen.button_pressed = !OptionsManager.is_fullscreen

	full_screen.disabled = OptionsManager.is_fullscreen
	window_screen.disabled = !OptionsManager.is_fullscreen

# 해상도 적용 시그널 연결
func _on_resol_option_item_selected(index):
	var res = OptionsManager.resolution_list[index]
	OptionsManager.apply_resolution(res)

func _on_full_screen_toggled(toggled_on):
	if toggled_on and !OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(true)
		update_ui()

func _on_window_screen_toggled(toggled_on):
	if toggled_on and OptionsManager.is_fullscreen:
		OptionsManager.apply_screen_mode(false)
		update_ui()

func _on_language_option_item_selected(index):
	match language_option.get_item_text(index):
		"한국어":
			TranslationServer.set_locale("ko")
		"English":
			TranslationServer.set_locale("en")

func _on_back_pressed():
	queue_free()
