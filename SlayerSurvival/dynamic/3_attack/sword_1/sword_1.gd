extends Area2D

@onready var character = get_parent().get_parent().get_parent()
@onready var animated_sprite = character.get_node("AnimatedSprite2D")
@onready var collision_shape = character.get_node("CollisionShape2D")

var player_name = "" 	# 캐릭터 이름 전역변수 선언

var level       = 1
var damage      = 1
var attack_size = 1.1
var direction   = 1

# Called when the node enters the scene tree for the first time.
func _ready():

	player_name = character.character_name

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

	# print(character.scale)

	match player_name:
		"slime":
			$AnimatedSprite2D.scale.x = 0.4
			$AnimatedSprite2D.scale.y = 0.4
			$CollisionShape2D.scale.x = 0.4
			$CollisionShape2D.scale.y = 0.4
			set_character_side(30, -10)
		"golem":
			# 골렘에 맞게 scale 조정 필요
			$AnimatedSprite2D.scale.x = 2	#TODO 캐릭터 사이즈? offset?
			$AnimatedSprite2D.scale.y = 2
			$CollisionShape2D.scale.x = 2
			$CollisionShape2D.scale.y = 2
			# 골렘의 스킬 이펙트 위치 설정
			set_character_side(30, 0)
	
	# print("character_width : ", character_width)
	# print("character_scale : ", character_scale)
	# print("character global position : ", character.global_position)
	# print("attack global position : ", global_position)

	$AnimatedSprite2D.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_timer_timeout():
	queue_free() # delete node

func set_character_side(x, y):
	if character.velocity.x < 0:
		global_position = character.global_position + Vector2(-x, y)
		$AnimatedSprite2D.flip_h = true
	else:
		global_position = character.global_position + Vector2(x, y)