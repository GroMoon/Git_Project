extends Area2D

@onready var character = get_parent().get_parent().get_parent()
@onready var animated_sprite = get_parent().get_parent().get_parent().get_node("AnimatedSprite2D")

var level       = 1
var damage      = 1
var attack_size = 1.1
var direction   = 1

# Called when the node enters the scene tree for the first time.
func _ready():

	# print("sword_1.gd ready")
	# print(character.scale.x)

	match level:
		1:
			damage = 3
			attack_size = 1.1
		2: 
			damage = 5
			attack_size = 1.5
		3:
			damage = 8
			attack_size = 1.8 
		4: 
			damage = 10
			attack_size = 2.2

	$AnimatedSprite2D.scale.x = 2
	$AnimatedSprite2D.scale.y = 2
	$CollisionShape2D.scale.x = 2
	$CollisionShape2D.scale.y = 2
	
	# var character_width = animated_sprite.texture.get_size().x

	if character.velocity.x < 0:
		# global_position = character.global_position + Vector2(-character_width/2, -10) #TODO offset으로 말고 캐릭터의 파라미터로 수정필요
		global_position = character.global_position + Vector2(-30, -10)
		$AnimatedSprite2D.flip_h = true
	else:
		# global_position = character.global_position + Vector2(character_width/2, -10)
		global_position = character.global_position + Vector2(30, -10)
	
	$AnimatedSprite2D.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_timer_timeout():
	queue_free() # delete node
