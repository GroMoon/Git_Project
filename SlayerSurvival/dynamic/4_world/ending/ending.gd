extends CanvasLayer

@onready var ending = $ending_img
var ending_img
var tween: Tween

func _ready():
	ending.modulate.a = 0.0
	tween = create_tween()
	# 서서히 나타나기 (알파값 0 -> 1)
	tween.tween_property(ending, "modulate:a", 1.0, 3.0)
	# 대기
	tween.tween_interval(2.0)
	# 서서히 사라지기 (알파값 1 -> 0)
	tween.tween_property(ending, "modulate:a", 0.0, 3.0)
	tween.tween_callback(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
