extends CharacterBody2D

const MOVE_SPEED    = 200
const IDLE_TIME     = 2.0  # 정지 대기 시간 2초
const MOVE_DURATION = 3.0  # 랜덤 방향으로 이동하는 시간 1초

var idle_timer     = 0.0
var move_timer     = 0.0
var move_direction = Vector2.ZERO

# weapon level
var sword_1_level = 1

# Damage
@onready var damagetimer = get_node("DamageTimer")
var invincibility_flag
# GUI
@onready var hp_bar = get_node("Healthbar/HpBar")
# hp 설정 (체력 value 관리)
var max_hp = 50.0
var hp = max_hp:
	set(value):
		hp = value
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		if hp > max_hp:
			hp = max_hp

func _ready():
	# 캐릭터를 뷰포트 중앙으로 이동
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = viewport_size / 2
	
	# 체력 바 위치 관리 (global_position 이용)
	hp_bar.global_position = global_position + Vector2(-8, 15)

	# 초기 이동 방향 설정
	set_random_direction()

func _process(delta):
	# 키보드 입력 확인
	if Input.is_action_pressed("right") or Input.is_action_pressed("left") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
		idle_timer = 0.0
	else:
		idle_timer += delta

func _physics_process(delta):
	if process_keyboard_input():
		move_timer = 0.0  # 이동 타이머 초기화
	else:
		if idle_timer >= IDLE_TIME:
			process_auto_movement(delta)

	# 캐릭터 이동 및 충돌 감지
	move_and_slide()
	if is_on_wall() or is_on_floor():
		set_random_direction()

	# 애니메이션 처리
	if velocity.length() > 0:
		$AnimatedSprite2D.play("move")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.play("idle")

func process_keyboard_input() -> bool:  # -> 반환 값
	var direction = Vector2.ZERO

	# 키보드 입력 처리
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	
	if direction != Vector2.ZERO:
		# 키보드 입력에 따른 이동
		direction = direction.normalized()
		velocity = direction * MOVE_SPEED
		return true
	else:
		velocity = Vector2.ZERO
		return false

func process_auto_movement(delta):
	move_timer += delta
	if move_timer >= MOVE_DURATION:
		set_random_direction()
		move_timer = 0.0

	# 랜덤 방향으로 이동
	if move_direction != Vector2.ZERO:
		velocity = move_direction * MOVE_SPEED

func set_random_direction():
	# 무작위 방향 설정
	var angle = randf() * 2 * PI  # 0에서 2*PI 사이의 각도
	move_direction = Vector2(cos(angle), sin(angle)).normalized()
	#? for debug
	#print("New mov direction: ", move_direction)

# Enemy 충돌 시
func Enemy_Collision(damage):
	if invincibility_flag == true:
		hp -= damage
		print("현재 체력 : ", hp)		# 체력 디버깅
		# 피해 입으면 컬러 변경(빨간색)
		$AnimatedSprite2D.modulate = Color(1, 0, 0)
		invincibility_flag = false
		damagetimer.start()
	
	# die (hp <= 0)
	if hp <= 0:
		# gameover sound
		$gameover.play()
		get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 피해 입은 후 timer 지나면 원래 컬러로
func _on_damage_timer_timeout():
	invincibility_flag = true
	$AnimatedSprite2D.modulate = Color(1, 1, 1)
