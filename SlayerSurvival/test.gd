extends Node2D

const TILE_SIZE = 16
const VIEW_DISTANCE = 10

var player
var tile_map
var player_start_position

func _ready():
	player = get_node("Slime")
	tile_map = get_node("TileMap")
	player_start_position = player.position

	for x in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
		for y in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
			set_tile(x, y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 플레이어의 상대적 위치 계산
	var offset_x = int((player.position.x - player_start_position.x) / TILE_SIZE)
	var offset_y = int((player.position.y - player_start_position.y) / TILE_SIZE)
	# 플레이어의 위치를 중앙으로 고정
	player.position = player_start_position
	# 타일맵을 오프셋에 따라 이동
	for x in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
		for y in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
			var new_x = x + offset_x
			var new_y = y + offset_y
			set_tile(new_x, new_y)
			
func set_tile(x, y):
	var tile_type = (abs(x + y) % 2) + 1  # 타일 타입을 단순하게 설정
	tile_map.set_cell(x, y, tile_type)
