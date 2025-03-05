extends Area2D

var direction = Vector2.ZERO
var fire_speed = 400
var fire_damage = 10
var explosion_damage = 15
var damage = 10

var player

@onready var animation_player = $AnimationPlayer

func _ready():
	player = get_parent().get_parent().get_parent().get_node("player")
	animation_player.play("Idle")


func _process(delta):
	position += direction * fire_speed * delta
	print(player)

func explode():
	fire_damage = explosion_damage
	animation_player.play("Explosion")			# 폭발 애니메이션
	fire_speed = 0								# 이동 정지
	await animation_player.animation_finished
	queue_free()

func _on_body_entered(body):
	#player.process_collision_enemy(fire_damage)
	pass
	
func _on_explosion_timer_timeout():
	explode()
