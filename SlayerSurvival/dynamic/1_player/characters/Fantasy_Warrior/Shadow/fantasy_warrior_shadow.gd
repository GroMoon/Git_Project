extends CharacterBody2D

const ANIMATION_SPEED = 2.0
const STOP_DISTANCE   = 50.0 	# 플레이어와의 거리가 해당 값 이하일 땐 멈춤

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3
@onready var animated_sprite  = $AnimatedSprite2D

# 캐릭터 특성
@export var move_speed      = 250 * 0.8
@export var attack_times    = 1 	# 공격 횟수(default 1)

var player = null

var attack_damage       = 5			# 일반 공격 데미지
var is_attacking        = false
var hit_flag            = false 	# 히트 플래그

func _ready():
	# 그림자 처리(회색 처리)
	animated_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	# 공격 범위 초기화(off)
	attack_area_1.set_deferred("disabled", true)
	attack_area_2.set_deferred("disabled", true)
	attack_area_3.set_deferred("disabled", true)

func _physics_process(_delta):
	# player 세팅
	if player == null:
		player = get_parent().get_node("player")
		# print(player)
	# 공격 중에 이동 처리 안 함
	if is_attacking:
		return

	# 플레이어와 거리 계산
	var distance_to_player = global_position.distance_to(player.global_position)
	# STOP_DISTANCE 안에 들어오면 idle 상태 유지
	if distance_to_player <= STOP_DISTANCE:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		return
		
	# 플레이어가 존재하면 플레이어를 향해 이동
	if player:
		var direction = (player.position - position).normalized()
		velocity = direction * move_speed
		move_and_slide()

	# 애니메이션 처리
	if !hit_flag:
		animated_sprite.speed_scale = ANIMATION_SPEED
		if velocity.length() > 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")

func _on_attack_timer_timeout():
	is_attacking = true
	# shadow에 대해서 공격 애니메이션 반대로 실행
	var original_flip = animated_sprite.flip_h
	animated_sprite.flip_h = not original_flip
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
