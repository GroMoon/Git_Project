extends TileMap

var map_width = 1200
var map_height = 650

@onready var player = get_parent().get_node("Slime")

func _ready():
	pass

func _process(_delta):
	if player.position.x < 0:
		player.position.x = map_width
	elif player.position.x > map_width :
		player.position.x = 0

	if player.position.y < 0:
		player.position.y = map_height
	elif player.position.y > map_height:
		player.position.y = 0

"""func  tile_gen():
	var start_x = int(player_position.x) - radi
	var end_x = int(player_position.x) + radi
	var start_y = int(player_position.x) - radi
	var end_y = int(player_position.x) + radi
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var tile_pos = Vector2(x, y)
			if get_cell(tile_pos.x, tile_pos.y) == -1:
				return grass1 if radi() % 2 == 0 else grass2"""
