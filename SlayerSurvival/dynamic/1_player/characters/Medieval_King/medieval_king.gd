extends CharacterBody2D

# @onready var attack_area_tscn = $attack/CollisionShape2D

# 캐릭터 특성
@export var character_name  = "medieval_king"
@export var move_speed      = 200
@export var character_level = 1

var attack_damage  = 5	# 일반 공격 데미지
var is_attacking  = false

# 체력
# @onready var hp_bar = $UI_Layer/BaseUI/Hp_Bar
# var max_hp      = 50
# var current_hp  = max_hp:
# 	set(value):
# 		current_hp = value
# 		hp_bar.max_value = max_hp
# 		hp_bar.value = current_hp
# 		if current_hp > max_hp:
# 			current_hp = max_hp
var damage_flag = false

func _ready():
	# 캐릭터를 뷰포트 중앙으로 이동
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = viewport_size / 2

func _physics_process(_delta):
	# 공격 중에 이동 처리 안 함
	if is_attacking:
		return
		
	# 키보드 입력
	process_keyboard_input()
	# 캐릭터 이동 및 충돌 감지
	move_and_slide()

	# 애니메이션 처리
	if velocity.length() > 0:
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.play("idle")
		


func _on_attack_timer_timeout():
	is_attacking = true
	# attack_area_tscn.set_deferred("disabled", false)

	# if $AnimatedSprite2D.flip_h:		# 왼쪽 공격
	# 	attack_area_tscn.position = Vector2(-73, 0)
	# else: 								# 오른쪽 공격
	# 	attack_area_tscn.position = Vector2(0, 0)
	
	# print("character position : ", global_position)
	# print("attack collision position : ", attack_area_tscn.position)

	$AnimatedSprite2D.play("attack")
	# 공격 애니메이션이 끝나면 이동할 수 있도록 설정
	await $AnimatedSprite2D.animation_finished
	is_attacking = false
	# attack_area_tscn.set_deferred("disabled", true)

func _on_damage_timer_timeout():
	damage_flag = true

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

# # Enemy 충돌 처리
# func process_collision_enemy(damage):
# 	if damage_flag:
# 		current_hp -= damage
# 		print("현재 체력 : ", current_hp)
# 		damage_flag = false
		# $AnimatedSprite2D.modulate = Color(1, 0, 0)        # 피해 입으면 컬러 변경(빨간색)
