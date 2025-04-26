extends Area2D

var recovery_value = 20

var player

var target = null
var speed  = -1

func _ready():
	player = get_parent().get_parent().get_node("player")

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 5*delta

func _on_body_entered(body):
	player.add_food(recovery_value)
	queue_free()
