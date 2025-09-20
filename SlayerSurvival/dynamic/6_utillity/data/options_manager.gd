extends Node

var language_list = ["한국어", "English"]

var resolution_list     = [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]
var current_resolution := Vector2(1280, 720)  # 기본 해상도
var is_fullscreen = true # 기본 화면모드 -> 전체화면

var is_master_muted = false
var is_bgm_muted    = false
var is_sfx_muted    = false
var master_volume = 0.3
var bgm_volume    = 0.3
var sfx_volume    = 0.3

# 윈도우 모드 버그 해결
var current_window_mode
var window_mode_saved
var was_maximized = false

# 전체화면 이전 윈도우 상태 기억
var pre_fullscreen_window_mode = DisplayServer.WINDOW_MODE_WINDOWED
var pre_fullscreen_resolution = Vector2(1280, 720)

func _ready():
	apply_volume()

func _process(_delta):
	current_window_mode = DisplayServer.window_get_mode()
	if current_window_mode != window_mode_saved:
		# 이전 모드가 최대화였는지 확인하고 플래그 설정
		if window_mode_saved == DisplayServer.WINDOW_MODE_MAXIMIZED:
			was_maximized = true
		# 창모드로 전환할 때는 최대화 상태 리셋
		elif current_window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			was_maximized = false
		window_mode_saved = current_window_mode

# 화면 해상도 설정
func apply_resolution(res: Vector2):
	current_resolution = res
	DisplayServer.window_set_size(res)
	# EXCLUSIVE_FULLSCREEN 모드일 경우 재적용
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	print("해상도 변경: ", res)

# 화면 모드 설정
# func apply_screen_mode(fullscreen: bool):
# 	is_fullscreen = fullscreen
# 	if fullscreen:
# 		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
# 	else:
# 		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
# 		DisplayServer.window_set_size(current_resolution)

func apply_window_fullscreen_mode():
	# 전체화면으로 전환하기 전에 현재 상태를 기억
	pre_fullscreen_window_mode = DisplayServer.window_get_mode()
	pre_fullscreen_resolution = DisplayServer.window_get_size()
	
	is_fullscreen = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	current_window_mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	print("전체화면 모드로 변경 - 이전 상태: ", pre_fullscreen_window_mode, " 해상도: ", pre_fullscreen_resolution)

func apply_window_windowed_mode():
	is_fullscreen = false
	
	# 전체화면 이전 상태로 복원
	if pre_fullscreen_window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		# 이전이 최대화였다면 최대화로 복원
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		current_window_mode = DisplayServer.WINDOW_MODE_MAXIMIZED
		print("최대화 모드로 복원")
	else:
		# 이전이 일반 창모드였다면 일반 창모드로 복원
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(pre_fullscreen_resolution)
		current_resolution = pre_fullscreen_resolution
		current_window_mode = DisplayServer.WINDOW_MODE_WINDOWED
		print("일반 창모드로 복원 - 해상도: ", pre_fullscreen_resolution)

func apply_window_maximized_mode():
	is_fullscreen = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	was_maximized = false
	print("최대화 모드로 변경")
	# DisplayServer.window_set_size(current_resolution)

# 소리 설정
func apply_volume():
	_set_bus_volume("Master", master_volume, is_master_muted)
	_set_bus_volume("BGM", bgm_volume, is_bgm_muted)
	_set_bus_volume("SFX", sfx_volume, is_sfx_muted)

func _set_bus_volume(bus_name: String, volume: float, is_muted: bool):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return

	# is_muted가 true이거나 volume이 0 이하면 음소거(-80dB) 처리
	var final_db = -80.0 if is_muted or volume <= 0.0 else linear_to_db(volume)
	AudioServer.set_bus_volume_db(bus_index, final_db)

# 볼륨 -> db로 변경 
func linear_to_db(linear: float) -> float:
	if linear == null or linear <= 0.001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# 볼륨 설정 함수
func set_volume(bus_name: String, volume: float):
	var clamped_volume = clampf(volume, 0.0, 1.0)

	match bus_name:
		"Master":
			master_volume = clamped_volume
			if master_volume > 0.0 and is_master_muted:
				is_master_muted = false
		"BGM":
			bgm_volume = clamped_volume
			if bgm_volume > 0.0 and is_bgm_muted:
				is_bgm_muted = false
		"SFX":
			sfx_volume = clamped_volume
			if sfx_volume > 0.0 and is_sfx_muted:
				is_sfx_muted = false
		_:
			return

	apply_volume()

# 음소거 복원 함수
func set_mute(bus: String, mute: bool):
	match bus:
		"Master":
			is_master_muted = mute
			is_bgm_muted = mute
			is_sfx_muted = mute
		"BGM":
			is_bgm_muted = mute
		"SFX":
			is_sfx_muted = mute
		_:
			return
	apply_volume()

# func update_master_mute_state():
# 	if is_bgm_muted and is_sfx_muted:
# 		if !is_master_muted:
# 			prev_master_volume = master_volume
# 			master_volume = 0.0
# 			is_master_muted = true
# 	elif is_master_muted:
# 		master_volume = prev_master_volume
# 		is_master_muted = false
