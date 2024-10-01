extends CharacterBody2D

# 적 이동 속도
var move_speed = 100
# slime (플레이어) 노드에 대한 참조
var player

func _ready():
	# slime 노드 찾기 (예: 플레이어 노드가 "Slime"이라고 가정)
	player = get_parent().get_node("Slime")  # 경로는 상황에 맞게 변경

func _physics_process(_delta):
	# 플레이어가 존재하면 그 위치로 움직임
	if player:
		# 플레이어와 적 사이의 방향 계산
		var direction = (player.position - position).normalized()
		
		# 그 방향으로 이동
		velocity = direction * move_speed
		
		# 이동 적용
		move_and_slide()

	# 애니메이션 처리
    if velocity.length() > 0:
        $AnimatedSprite2D.play("enemy_type_A")
        $AnimatedSprite2D.flip_h = velocity.x > 0
    else:
        $AnimatedSprite2D.play("enemy_type_A")