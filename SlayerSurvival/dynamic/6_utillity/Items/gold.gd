extends Area2D

@export var gold_value = 10

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_parent().get_node("player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# 플레이어 충돌
func _on_body_entered(body):
	player.add_gold(gold_value)
	queue_free()
