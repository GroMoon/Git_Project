extends Node

var language_list = ["한국어", "English"]

var resolution_list     = [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]
var current_resolution := Vector2(1280, 720)  # 기본 해상도
var is_fullscreen = false # 기본 화면모드 -> 창모드

var is_master_muted = false
var is_bgm_muted    = false
var is_sfx_muted    = false
var master_volume = 10.0
var bgm_volume    = 10.0
var sfx_volume    = 10.0
# 음소거 on/off 할 때 저장해놓을 볼륨 값
var prev_master_volume
var prev_bgm_volume
var prev_sfx_volume

# 화면 해상도 설정
func apply_resolution(res: Vector2):
	current_resolution = res
	DisplayServer.window_set_size(res)
	# EXCLUSIVE_FULLSCREEN 모드일 경우 재적용
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	print("해상도 변경: ", res)

# 화면 모드 설정
func apply_screen_mode(fullscreen: bool):
	is_fullscreen = fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(current_resolution)

# 소리 설정
func apply_volume():
	var master_val = 0.0
	if is_master_muted:
		master_val = 0.0
	else:
		master_val = master_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_val))

	var bgm_val = 0.0
	if is_bgm_muted:
		bgm_val = 0.0
	else:
		bgm_val = bgm_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(bgm_val))

	var sfx_val = 0.0
	if is_sfx_muted:
		sfx_val = 0.0
	else:
		sfx_val = sfx_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_val))

# 볼륨 -> db로 변경 
func linear_to_db(linear: float) -> float:
	return 20.0 * log(linear) / log(10.0) if linear > 0.0 else -80.0

# 음소거 복원 함수
func set_mute(bus: String, mute: bool):
	match bus:
		"Master":
			if mute:
				if !is_master_muted:
					prev_master_volume = master_volume
					prev_bgm_volume = bgm_volume
					prev_sfx_volume = sfx_volume

				master_volume = 0.0
				bgm_volume = 0.0
				sfx_volume = 0.0

				is_master_muted = true
				is_bgm_muted = true
				is_sfx_muted = true
			else:
				is_master_muted = false
				is_bgm_muted = false
				is_sfx_muted = false

				master_volume = prev_master_volume
				bgm_volume = prev_bgm_volume
				sfx_volume = prev_sfx_volume

		"BGM":
			if mute:
				if !is_bgm_muted and bgm_volume > 0.0:
					prev_bgm_volume = bgm_volume
				bgm_volume = 0.0
				is_bgm_muted = true
			else:
				is_bgm_muted = false
				bgm_volume = prev_bgm_volume

		"SFX":
			if mute:
				if !is_sfx_muted and sfx_volume > 0.0:
					prev_sfx_volume = sfx_volume
				sfx_volume = 0.0
				is_sfx_muted = true
			else:
				is_sfx_muted = false
				sfx_volume = prev_sfx_volume

	update_master_mute_state()
	apply_volume()

func update_master_mute_state():
	if is_bgm_muted and is_sfx_muted:
		if !is_master_muted:
			prev_master_volume = master_volume
			master_volume = 0.0
			is_master_muted = true
	elif is_master_muted:
		master_volume = prev_master_volume
		is_master_muted = false
