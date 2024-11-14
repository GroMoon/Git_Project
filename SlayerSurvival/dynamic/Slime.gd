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
@onready var damagetimer = get_node("PlayerSet/DamageTimer")
var invincibility_flag

# GUI
@onready var hp_bar = get_node("PlayerSet/UI_Layer/BaseUI/HpBar")

# hp 설정 (체력 value 관리)
var max_hp = 50.0
var hp = max_hp:	#TODO 왜 변수가 함수처럼 쓰이는지 어떤 경우 그렇게 쓰이는지 확인 필요
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
	hp_bar.global_position = global_position + Vector2(-23, 30) #TODO offset 방식 말고 뭔가 캐릭터의 파라미터 받아와서 하는 방식으로 

func _physics_process(_delta):
	# 키보드 입력
	process_keyboard_input()
	# 캐릭터 이동 및 충돌 감지
	move_and_slide()


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

# Enemy 충돌 처리
func process_collision_enemy(damage):
	if invincibility_flag == true:
		hp -= damage
		#print("현재 체력 : ", hp)		# 체력 디버깅
		$AnimatedSprite2D.modulate = Color(1, 0, 0)		# 피해 입으면 컬러 변경(빨간색)
		invincibility_flag = false
		damagetimer.start()
	
	# die (hp <= 0)
	if hp <= 0:
		$gameover.play()
		await get_tree().create_timer($gameover.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://dynamic/5_title_screen/menu.tscn")

# 피해 입은 후(damage  timer timeout)
func _on_damage_timer_timeout():
	invincibility_flag = true
	$AnimatedSprite2D.modulate = Color(1, 1, 1)		# 원래 컬러로
