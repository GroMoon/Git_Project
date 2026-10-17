extends PickupBase

@export var gold_value = 10

func on_collect():
	player.add_gold(gold_value)
