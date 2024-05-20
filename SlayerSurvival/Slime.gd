extends CharacterBody2D

const MOVE_SPEED = 300

var moving_rightleft = 0
var moving_updown    = 0

func _physics_process(delta):
	
	velocity.x = 0
	velocity.y = 0

	# 수평 이동 처리
	if Input.is_action_pressed("right"):
		velocity.x = MOVE_SPEED
		$AnimatedSprite2D.flip_h = false
	elif Input.is_action_pressed("left"):
		velocity.x = -MOVE_SPEED
		$AnimatedSprite2D.flip_h = true

	# 수직 이동 처리
	if Input.is_action_pressed("up"):
		velocity.y = -MOVE_SPEED
	elif Input.is_action_pressed("down"):
		velocity.y = MOVE_SPEED


	# 움직임 정규화
	if velocity.length() > 0:
		velocity = velocity.normalized()*MOVE_SPEED
		$AnimatedSprite2D.play("move")
	else:
		$AnimatedSprite2D.play("idle")

	move_and_slide()
