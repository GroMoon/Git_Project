extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_mouse_entered():
	# 마우스 커서 위에 있을 때 Button Sound 재생
	$Button_sound.play()
	pass
