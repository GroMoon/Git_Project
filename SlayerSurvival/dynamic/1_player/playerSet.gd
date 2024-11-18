extends Node2D

@onready hp_bar = get_node("")
# hp 설정 (체력 value 관리)
var max_hp = 50.0
var hp = max_hp:	#TODO 왜 변수가 함수처럼 쓰이는지 어떤 경우 그렇게 쓰이는지 확인 필요
	set(value):
		hp = value
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		if hp > max_hp:
			hp = max_hp

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
