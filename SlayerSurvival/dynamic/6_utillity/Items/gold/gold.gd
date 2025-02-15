extends Area2D

@export var gold_value = 10

var player

var target = null
var speed  = -1

func _ready():
	player = get_parent().get_parent().get_node("player")

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 4*delta

# 플레이어 충돌
func _on_body_entered(_body):
	player.add_gold(gold_value)
	queue_free()
