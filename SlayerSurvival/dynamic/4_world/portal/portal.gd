extends Area2D

var player

func _ready():
	$AnimatedSprite2D.sprite_frames.set_animation_loop("idle", true)
	$AnimatedSprite2D.play("idle")

func _on_body_entered(body):
	# player.
	pass
