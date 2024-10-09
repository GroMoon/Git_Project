extends Area2D

@onready var character = get_tree().get_first_node_in_group("Slime")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_timer_timeout():
	queue_free() # delete node
	# pass
