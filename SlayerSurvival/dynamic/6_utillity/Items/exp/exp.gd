extends PickupBase

@export var exp_value = 10

func on_collect():
	player.add_exp(exp_value)
