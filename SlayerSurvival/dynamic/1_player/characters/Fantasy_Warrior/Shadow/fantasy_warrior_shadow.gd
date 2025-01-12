extends CharacterBody2D

const ANIMATION_SPEED = 2.0

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3
@onready var animated_sprite  = $AnimatedSprite2D
@onready var magnetic_area    = $MagneticArea/CollisionShape2D

# 캐릭터 특성
@export var character_name  = "fantasy_warrior"
@export var move_speed      = 250
@export var character_level = 1
@export var attack_times    = 1 	# 공격 횟수(default 1)

var attack_damage       = 5			# 일반 공격 데미지
var is_attacking        = false
var hit_flag            = false 	# 히트 플래그

func _ready():
	# 공격 범위 초기화(off)
	attack_area_1.set_deferred("disabled", true)
	attack_area_2.set_deferred("disabled", true)
	attack_area_3.set_deferred("disabled", true)

func _physics_process(_delta):
	# 공격 중에 이동 처리 안 함
	if is_attacking:
		return
		
	# 키보드 입력
	# process_keyboard_input()
	# 캐릭터 이동 및 충돌 감지
	move_and_slide()

	# 애니메이션 처리
	if !hit_flag:
		animated_sprite.speed_scale = ANIMATION_SPEED
		if velocity.length() > 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")

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
		velocity = direction * move_speed
		return true
	else:
		velocity = Vector2.ZERO
		return false

func _on_attack_timer_timeout():
	is_attacking = true
	# print("character position : ", global_position)
	# print("attack collision position : ", attack_area_1.position)
	animated_sprite.speed_scale = ANIMATION_SPEED
	# print("attack timer timeout!")
	if attack_times == 2:
		# 공격 1
		attack_area_1.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_1.position = Vector2(-29, -6)
		else: 							# 오른쪽 공격
			attack_area_1.position = Vector2(29, -6)
		animated_sprite.play("attack_1")
		await animated_sprite.animation_finished
		attack_area_1.set_deferred("disabled", true)
		# 공격 2
		attack_area_2.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_2.position = Vector2(4, -10)
		else: 							# 오른쪽 공격
			attack_area_2.position = Vector2(-4, -10)
		animated_sprite.play("attack_2")
		await animated_sprite.animation_finished
		attack_area_2.set_deferred("disabled", true)
	elif attack_times == 3:
		# 공격 1
		attack_area_1.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_1.position = Vector2(-29, -6)
		else: 							# 오른쪽 공격
			attack_area_1.position = Vector2(29, -6)
		animated_sprite.play("attack_1")
		await animated_sprite.animation_finished
		attack_area_1.set_deferred("disabled", true)
		# 공격 2
		attack_area_2.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_2.position = Vector2(4, -10)
		else: 							# 오른쪽 공격
			attack_area_2.position = Vector2(-4, -10)
		animated_sprite.play("attack_2")
		await animated_sprite.animation_finished
		attack_area_2.set_deferred("disabled", true)
		# 공격 3
		attack_area_3.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_3.position = Vector2(-30, -24)
		else: 							# 오른쪽 공격
			attack_area_3.position = Vector2(30, -24)
		animated_sprite.play("attack_3")
		await animated_sprite.animation_finished
		attack_area_3.set_deferred("disabled", true)
	else:
		# 공격 1
		attack_area_1.set_deferred("disabled", false)
		if animated_sprite.flip_h:		# 왼쪽 공격
			attack_area_1.position = Vector2(-29, -6)
		else: 							# 오른쪽 공격
			attack_area_1.position = Vector2(29, -6)
		animated_sprite.play("attack_1")
		await animated_sprite.animation_finished
		attack_area_1.set_deferred("disabled", true)	

	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
