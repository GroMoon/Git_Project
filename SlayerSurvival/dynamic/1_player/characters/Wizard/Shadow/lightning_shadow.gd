extends Node2D

@onready var animation_player = $AnimatedPlayer

var attack_damage

func _ready():
	attack_damage = get_parent().get_node("shadow").attack_damage		# 공격력 증가 업그레이드가 player의 damage증가이기 때문에 player를 찾아서 데미지 넣어줌
	animation_player.play("lightning")
	await animation_player.animation_finished
	queue_free()

func _process(delta):
	pass
