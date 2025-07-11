extends Node

var resolution_list     = [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]
var current_resolution := Vector2(1280, 720)  # 기본 해상도

var is_fullscreen = false # 기본 화면모드 -> 창모드

var language_list = ["한국어", "English"]


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
