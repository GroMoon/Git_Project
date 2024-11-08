extends Node2D

@onready var character = get_parent()

var attack_preload = {
	"sword_1": preload("res://dynamic/3_attack/sword_1/sword_1.tscn")
}

# sword_1
@onready var sword_1_timer = get_node("%sword_1_timer")
var sword_1_level = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	print("attack.gd ready")
	# print(character.global_position)
	# pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_sword_1_timer_timeout():
	print("sword_1_timer timeout")
	var new_sword_1 = attack_preload["sword_1"].instantiate()
	# new_sword_1.direction = 1
	new_sword_1.level = sword_1_level
	add_child(new_sword_1)
	
	# 휘두를 때 사운드
	$knife_sound.play()
