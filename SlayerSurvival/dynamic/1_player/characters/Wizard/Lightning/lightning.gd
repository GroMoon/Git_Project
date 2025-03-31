extends Node2D

@onready var animation_player = $AnimatedPlayer

var lightning_damage = 15

func _ready():
	print("라이트닝 소환")
	animation_player.play("lightning")
	await animation_player.animation_finished
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
