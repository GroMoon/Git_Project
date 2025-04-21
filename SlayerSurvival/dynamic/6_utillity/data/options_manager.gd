extends Node

var resolution_list     = [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]
var current_resolution := Vector2(1280, 720)  # 기본 해상도
var is_fullscreen = false # 기본 화면모드 -> 창모드

# 화면 해상도 설정
func apply_resolution(res: Vector2):
	current_resolution = res
	DisplayServer.window_set_size(res)
	print("해상도 변경: ", res)

# 화면 모드 설정
func apply_screen_mode(fullscreen: bool):
	# 화면 모드 변경 -> 전체화면
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# 화면 모드 변경 -> 창화면
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	is_fullscreen = fullscreen
