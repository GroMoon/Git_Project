extends CharacterBody2D

const MOVE_SPEED = 200
const IDLE_TIME  = 2.0  # 정지 대기 시간 2sec

var target_position = Vector2.ZERO
var idle_timer      = 0.0

func set_random_target():
    var viewport_size = get_viewport().get_visible_rect().size
    target_position = Vector2(randi() % int(viewport_size.x), randi() % int(viewport_size.y))

	#? for debug
    print("Global position    : ", global_position)
    print("New target position: ", target_position)

func _ready():
	# 캐릭터 가운데로 이동
    var viewport_size = get_viewport().get_visible_rect().size
    global_position = viewport_size / 2
	# 이동할 위치 설정
    set_random_target()

func _process(delta):
    if Input.is_action_pressed("right") or Input.is_action_pressed("left") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
        idle_timer = 0.0
    else:
        idle_timer += delta

func _physics_process(_delta):
    # 키보드 움직임 처리
    var direction = Vector2.ZERO
    if Input.is_action_pressed("right"):
        direction.x += 1
    if Input.is_action_pressed("left"):
        direction.x -= 1
    if Input.is_action_pressed("up"):
        direction.y -= 1
    if Input.is_action_pressed("down"):
        direction.y += 1
    
    if direction != Vector2.ZERO:
        direction = direction.normalized()
        velocity = direction * MOVE_SPEED
        $AnimatedSprite2D.play("move")
        $AnimatedSprite2D.flip_h = direction.x < 0
    else:
        velocity = Vector2.ZERO
        if idle_timer >= IDLE_TIME:
            # 자동 이동
            if target_position != Vector2.ZERO:
                direction = (target_position - global_position).normalized()
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
        $AnimatedSprite2D.play("idle")


