extends PickupBase

@export var gold_value = 10

func on_collect():
	player.add_gold(gold_value)
	GameFeel.play_sfx("coin", randf_range(0.95, 1.1), -10.0, 0.08)
