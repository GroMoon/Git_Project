extends PickupBase

var recovery_value = 20

func on_collect():
	player.add_food(recovery_value)
	GameFeel.burst(global_position, Color(0.4, 1.0, 0.4), 10, 120.0, 3.0)
