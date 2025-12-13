extends Control

signal ending_finished

@onready var ending = $ending_img
@onready var white_screen = $whitescreen

var tween: Tween

func _ready():
	# 맵 이름 확인 후 엔딩 이미지 설정
	var current_map_name = get_tree().get_current_scene().instance_map.name
	match current_map_name:
		"cave":
			ending.texture = preload("res://dynamic/4_world/ending/Ending_Cave.png")
		"dungeon_B1F":
			ending.texture = preload("res://dynamic/4_world/ending/Ending_Dun.png")
		_:
			pass
	ending.modulate.a = 0.0       # 이미지 안 보임
	white_screen.modulate = Color(1, 1, 1, 0) # 하얀 막도 안 보임 (투명)
	tween = create_tween()
	tween.tween_property(ending, "modulate:a", 1.0, 7.0)
	# 2초간 대기
	tween.tween_interval(2.0)
	# 이미지 흰 스크린으로
	tween.tween_property(white_screen, "modulate:a", 1.0, 5.0)
	# 마지막 화면 검정색으로(불투명으로 처리)
	tween.tween_property(white_screen, "modulate", Color.BLACK, 1.0)
	tween.tween_callback(_on_ending_finished)

func _on_ending_finished():
	ending_finished.emit()
	# 엔딩 씬의 검정 화면 z 인덱스 디버깅
	print("Ending scene black screen z index: ", white_screen.z_index)
	# 엔딩 씬의 검정 화면 z 인덱스를 9로 설정
	white_screen.z_index = 7
	print("Ending scene black screen z index: ", white_screen.z_index)
	# 일단 queue_free()를 하지 않고 
	#queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
