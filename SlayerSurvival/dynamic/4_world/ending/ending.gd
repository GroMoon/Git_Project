extends Control

signal ending_finished

@onready var ending = $ending_img
@onready var white_screen = $whitescreen
var tween: Tween

func _ready():
	ending.modulate.a = 0.0       # 이미지 안 보임
	white_screen.modulate.a = 0.0 # 하얀 막도 안 보임 (투명)
	tween = create_tween()
	tween.tween_property(ending, "modulate:a", 1.0, 7.0)
	tween.tween_interval(2.0)
	tween.tween_property(white_screen, "modulate:a", 1.0, 5.0)
	tween.tween_callback(_on_ending_finished)

func _on_ending_finished():
	ending_finished.emit()
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
