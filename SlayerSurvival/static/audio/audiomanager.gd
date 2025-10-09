extends AudioStreamPlayer

@export var menu_bgm: AudioStream
@export var ingame_bgm: AudioStream

# 현재 재생 중인 음악의 종류를 저장할 변수 "menu", "ingame"
var current_music_state = ""

# func _process(_delta):
# 	print(current_music_state)

func play_music_for_scene(scene_name: String):
	match scene_name:
		"menu":
			if current_music_state == "menu" and is_playing():
				return
			
			stream = menu_bgm
			play()
			current_music_state = "menu" # 현재 상태를 기록
			
		"ingame":
			if current_music_state == "ingame" and is_playing():
				return
			
			stream = ingame_bgm
			play()
			current_music_state = "ingame"
			
		_: # "menu"나 "ingame"이 아닌 다른 이름이 들어오면 음악을 멈춥니다.
			stop()
			current_music_state = ""

func _on_finished():
	play()