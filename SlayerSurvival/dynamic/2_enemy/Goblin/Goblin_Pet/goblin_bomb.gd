extends Area2D

@onready var animation_player = $AnimationPlayer

var direction        = Vector2.ZERO
var bomb_speed       = 400
var target           = Vector2.ZERO

func _ready():
	if target != Vector2.ZERO:
		direction = (target - global_position).normalized()
	else:
		direction = Vector2.RIGHT
	
	animation_player.play("Idle")

func _process(delta):
	position += direction * bomb_speed * delta
	bomb()

func bomb():
	if position.distance_to(target) < 1.0:
		bomb_speed = 0
		animation_player.play("Bomb")
		await animation_player.animation_finished
		queue_free()
