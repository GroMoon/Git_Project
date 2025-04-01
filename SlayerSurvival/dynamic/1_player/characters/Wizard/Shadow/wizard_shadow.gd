extends CharacterBody2D

const ANIMATION_SPEED = 1.5
const STOP_DISTANCE   = 50.0 	# 플레이어와의 거리가 해당 값 이하일 땐 멈춤

@onready var animated_sprite  = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

# 캐릭터 특성
@export var move_speed      = 130 * 0.8
@export var attack_times    = 1 	# 공격 횟수(default 1)

var player = null

var attack_damage       = 15			# 일반 공격 데미지
var is_attacking        = false
var hit_flag            = false 		# 히트 플래그

func _ready():
	# 그림자 처리(회색 처리)
	animated_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)

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

func cast_lightning():
	var target = get_closest_enemy()
	var lightning = preload("res://dynamic/1_player/characters/Wizard/Shadow/lightning_shadow.tscn").instantiate()
	lightning.global_position = target.global_position
	get_parent().add_child(lightning)

func get_closest_enemy():
	var closest_enemy = null
	var closest_distance = 300
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	return closest_enemy if closest_enemy else self

func _on_attack_timer_timeout():
	is_attacking = true
	# shadow에 대해서 공격 애니메이션 반대로 실행
	var original_flip = animated_sprite.flip_h
	animated_sprite.flip_h = not original_flip
	animated_sprite.speed_scale = ANIMATION_SPEED
	# print("attack timer timeout!")
	
	if attack_times == 1:
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
	elif attack_times == 2:
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
		animation_player.play("attack")
		await animation_player.animation_finished
		cast_lightning()
	else:
		pass

	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
