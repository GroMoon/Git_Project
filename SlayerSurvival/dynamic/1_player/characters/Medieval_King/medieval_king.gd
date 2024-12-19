extends CharacterBody2D

const ANIMATION_SPEED = 1.5

@onready var attack_area_tscn = $attack/CollisionShape2D
@onready var animated_sprite  = $AnimatedSprite2D

# 캐릭터 특성
@export var character_name  = "medieval_king"
@export var move_speed      = 150
@export var character_level = 1

var attack_damage  = 10	# 일반 공격 데미지
var is_attacking  = false

# 체력
@onready var hp_bar = $UI_Layer/BaseUI/Hp_Bar
var max_hp      = 75
var current_hp  = max_hp:
	set(value):
		current_hp = value
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		if current_hp > max_hp:
			current_hp = max_hp

# 골드
@onready var gold_label = get_node("UI_Layer/BaseUI/goldcollect/GoldCount")
@export var gold_count = 0

# 적 처치
@onready var kill_label = get_node("UI_Layer/BaseUI/goldcollect/killcollect/KillCount")
@export var kill_count = 0

var damage_flag = false 	# 데미지 플래그 (=무적 플래그)
var hit_flag    = false 	# 히트 플래그

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
	if !hit_flag:
		animated_sprite.speed_scale = ANIMATION_SPEED
		if velocity.length() > 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")	
	
	# 라벨 업데이트
	gold_label.text = str(gold_count)
	kill_label.text = str(kill_count)

func _on_attack_timer_timeout():
	is_attacking = true
	attack_area_tscn.set_deferred("disabled", false)

	if animated_sprite.flip_h:		# 왼쪽 공격
		attack_area_tscn.position = Vector2(-45, 25)
	else: 								# 오른쪽 공격
		attack_area_tscn.position = Vector2(45, 25)
	
	# print("character position : ", global_position)
	# print("attack collision position : ", attack_area_tscn.position)
	animated_sprite.speed_scale = ANIMATION_SPEED
	animated_sprite.play("attack")
	# 공격 애니메이션이 끝나면 이동할 수 있도록 설정
	await animated_sprite.animation_finished
	is_attacking = false
	attack_area_tscn.set_deferred("disabled", true)

func _on_damage_timer_timeout():
	damage_flag = true
	animated_sprite.modulate = Color(1, 1, 1)        # 피해 이펙트 원상복귀

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

# Enemy 충돌 처리
func process_collision_enemy(damage):
	if damage_flag:
		# current_hp -= damage								# FIXME : 현재 데미지 꺼놓은 상태 아래 FIXME 작업 완료 후 주석 제거 필요
		damage_flag = false
		if current_hp <= 0:
			print("사망") 									# FIXME : 사망 시 필요한 작업 (메인메뉴 돌아가기, 사망 모션, 사망 사운드 등) 추가 필요
		else:
			print("현재 체력 : ", current_hp)
			hit_flag = true
			if (animated_sprite.is_playing()) && (animated_sprite.animation == "attack"):
				animated_sprite.modulate = Color(1,0,0)
			else:
				animated_sprite.stop()
				animated_sprite.speed_scale = 2.0
				animated_sprite.play("take_hit")
				animated_sprite.modulate = Color(1, 0, 0)	# 피해 입으면 컬러 변경(빨간색)
				await animated_sprite.animation_finished      
		hit_flag    = false
		
# 골드 추가 처리
func add_gold(gold_value):
	gold_count += gold_value
	print("현재 골드 : ", gold_count)
