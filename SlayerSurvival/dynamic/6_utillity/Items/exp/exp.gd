extends PickupBase

@export var exp_value = 10

func _ready():
	super._ready()
	_update_tier()

func on_collect():
	player.add_exp(exp_value)

# 젬 합치기 (값이 클수록 색이 바뀌고 커짐)
func add_value(value):
	exp_value += value
	_update_tier()

func _update_tier():
	var sprite = $Sprite2D
	if exp_value >= 50:
		sprite.modulate = Color(1.0, 0.45, 0.45)
		scale = Vector2(1.6, 1.6)
	elif exp_value >= 15:
		sprite.modulate = Color(0.5, 1.0, 0.55)
		scale = Vector2(1.3, 1.3)
