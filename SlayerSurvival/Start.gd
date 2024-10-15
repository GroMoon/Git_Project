extends Button

func _on_pressed():
	get_tree().change_scene_to_file("res://test.tscn")


func _on_click_sound_child_entered_tree(node):
	pass # Replace with function body.


func _on_mouse_entered():
	# 마우스 커서 위에 있을 때 Button Sound 재생
	$Button_sound.play()
	pass # Replace with function body.
