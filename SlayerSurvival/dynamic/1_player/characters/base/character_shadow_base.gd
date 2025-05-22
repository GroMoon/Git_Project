extends CharacterBody2D

class_name CharacterShadowBase

@onready var animated_sprite  = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

# 그림자 특성
var move_speed      = 150 * 0.8     # 그림자 이동속도
var attack_times    = 1 	        # 그림자 공격 횟수
var attack_damage   = 10			# 그림자 공격 데미지
var animation_speed = 1.0           # 그림자 애니메이션 속도 

# 플래그
var is_attacking  = false
var hit_flag      = false

# 기타 전역변수 
var player        = null
var stop_distance = 50.0            # 플레이어와의 유지 거리

func _ready():
	# 그림자 처리(회색 처리)
	animated_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	# 공격 범위 초기화(off)
	animation_player.play("RESET")

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
	# stop_distance 안에 들어오면 idle 상태 유지
	if distance_to_player <= stop_distance:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		return

	if player:
		# 플레이어 그림자 레벨에 따라 공격 횟수 조절
		attack_times  = player.shadow_partner_level
		# 플레이어가 존재하면 플레이어를 향해 이동
		var direction = (player.position - position).normalized()
		velocity = direction * move_speed
		move_and_slide()

	# 애니메이션 처리
	if !hit_flag:
		animated_sprite.speed_scale = animation_speed
		if velocity.length() > 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")