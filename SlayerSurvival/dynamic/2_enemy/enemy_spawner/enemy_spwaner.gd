extends Node2D

@onready var player = get_parent().get_node("FantasyWarrior")

var skeleton = preload("res://dynamic/2_enemy/Skeleton/skeleton.tscn")
var mushroom = preload("res://dynamic/2_enemy/Mushroom/mushroom.tscn")

func _ready():
	pass # Replace with function body.

func _process(_delta):
	pass

# 적을 스폰하는 함수
func spawn_enemy(enemy_tscn):
	# 경로로부터 적 프리팹을 로드
	var enemy = enemy_tscn
	# 씬이 제대로 로드되었는지 확인
	if enemy:
		var enemy_instance = enemy.instantiate()
		var spawn_radius   = enemy_instance.spawn_radius
	
		# 캐릭터 주변 반경에서 랜덤 위치 생성
		var angle = randf() * PI * 2  # 0부터 360도 사이의 랜덤 각도
		var distance = spawn_radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		# 적의 위치를 캐릭터 위치 + 랜덤 오프셋으로 설정
		enemy_instance.global_position = player.global_position + offset
		
		# 씬에 적 인스턴스를 추가
		add_child(enemy_instance)
	else:
		print("Error: Failed to load enemy scene.")

# Skeleton 소환
func _on_skeleton_timer_timeout():
	spawn_enemy(skeleton)
# Mushrrom 소환
func _on_mushroom_timer_timeout():
	spawn_enemy(mushroom)
