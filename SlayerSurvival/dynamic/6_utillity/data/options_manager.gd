extends Node

var language_list = ["한국어", "English"]

var is_fullscreen = true

var is_master_muted = false
var is_bgm_muted    = false
var is_sfx_muted    = false
var master_volume = 0.3
var bgm_volume    = 0.3
var sfx_volume    = 0.3


func _ready():
	apply_volume()


func _process(_delta):
	# 전체화면 모드만 사용하므로 창모드 관련 프로세스 제거
	pass


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

# 화면 모드 변경 함수
func apply_screen_mode(fullscreen: bool):
	is_fullscreen = fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		print("전체화면 모드로 변경")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("창모드로 변경")