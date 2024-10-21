extends Node2D

@export var enemy_path: String = "res://dynamic/2_enemy/enemy_1/enemy_type_a.tscn"
@export var spawn_radius: float = 300  # 캐릭터 주위에서 적이 생성될 반경
# @onready var nodes_in_group = get_tree().get_nodes_in_group("enemy_spawner")
@onready var character = get_parent().get_parent().get_node('Slime')

func _physics_process(_delta):
	#print(character.global_position)
	pass

# 적을 스폰하는 함수
func spawn_enemy():
	# 경로로부터 적 프리팹을 로드
	var enemy_scene = load(enemy_path)
	
	# 씬이 제대로 로드되었는지 확인
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		
		# 캐릭터 주변 반경에서 랜덤 위치 생성
		var angle = randf() * PI * 2  # 0부터 360도 사이의 랜덤 각도
		# var distance = randf_range(0, spawn_radius)
		var distance = spawn_radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		#print("character")
		#print(character.global_position)
		
		# 적의 위치를 캐릭터 위치 + 랜덤 오프셋으로 설정
		enemy_instance.global_position = character.global_position + offset
		
		# 씬에 적 인스턴스를 추가
		add_child(enemy_instance)
	else:
		print("Error: Failed to load enemy scene.")

func _on_timer_timeout():
	spawn_enemy() 
