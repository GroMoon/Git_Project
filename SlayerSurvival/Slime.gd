extends CharacterBody2D

const MOVE_SPEED = 200

var target_position = Vector2.ZERO

func set_random_target():
    var viewport_size = get_viewport().get_visible_rect().size
    target_position = Vector2(randi() % int(viewport_size.x), randi() % int(viewport_size.y))
    print("Global position    : ", global_position)
    print("New target position: ", target_position)

func _ready():
    var viewport_size = get_viewport().get_visible_rect().size
    global_position = viewport_size / 2

    set_random_target()

func _physics_process(delta):
	
	# velocity.x = 0
	# velocity.y = 0

	# # 수평 이동 처리
	# if Input.is_action_pressed("right"):
	# 	velocity.x = MOVE_SPEED
	# 	$AnimatedSprite2D.flip_h = false
	# elif Input.is_action_pressed("left"):
	# 	velocity.x = -MOVE_SPEED
	# 	$AnimatedSprite2D.flip_h = true

	# # 수직 이동 처리
	# if Input.is_action_pressed("up"):
	# 	velocity.y = -MOVE_SPEED
	# elif Input.is_action_pressed("down"):
	# 	velocity.y = MOVE_SPEED


	# # 움직임 정규화
	# if velocity.length() > 0:
	# 	velocity = velocity.normalized()*MOVE_SPEED
	# 	$AnimatedSprite2D.play("move")
	# else:
	# 	$AnimatedSprite2D.play("idle")

	# 자동 이동
    if target_position != Vector2.ZERO:
        var direction = (target_position - global_position).normalized()
        velocity = direction * MOVE_SPEED

		# 목표 지점에 도달했는지 확인
        if global_position.distance_to(target_position) < 10:
            velocity = Vector2.ZERO
            set_random_target()
    else:
        velocity = Vector2.ZERO

    move_and_slide()

	# 애니메이션 처리
    if velocity.length() > 0:
        $AnimatedSprite2D.play("move")
        $AnimatedSprite2D.flip_h = velocity.x < 0
    else:
        $AnimatedSprite2D.play("idel")


