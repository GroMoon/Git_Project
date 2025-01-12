extends CharacterBody2D

const ANIMATION_SPEED = 2.0
const START_HP        = 50

@onready var attack_area_1    = $Attack/attack_1
@onready var attack_area_2    = $Attack/attack_2
@onready var attack_area_3    = $Attack/attack_3
@onready var animated_sprite  = $AnimatedSprite2D
@onready var magnetic_area    = $MagneticArea/CollisionShape2D

# 캐릭터 특성
@export var character_name  = "fantasy_warrior"
@export var move_speed      = 250
@export var character_level = 1
@export var attack_times    = 1 	# 공격 횟수 (default 1)
@export var shadow_attack   = 1		# 그림자 분신술 (default 0)

var attack_damage       = 5			# 일반 공격 데미지
var is_attacking        = false
var magnetic_area_scale = 100.0		# 자석 범위(원 기준)
var is_shadow_on        = 0

# 경험치
@onready var exp_bar = $UI_Layer/BaseUI/Exp_Bar
var start_exp = 0
var max_exp:
	set(set_value):
		max_exp = set_value
		exp_bar.max_value = max_exp
var current_exp:
	set(set_value):
		current_exp = set_value
		exp_bar.value = current_exp

# 체력
@onready var hp_bar = $UI_Layer/BaseUI/Hp_Bar
var max_hp = START_HP:
	set(set_value):
		max_hp = set_value
		hp_bar.max_value = max_hp
var current_hp = max_hp:
	set(set_value):
		current_hp = set_value
		hp_bar.value = current_hp
		if current_hp > max_hp:
			current_hp = max_hp

# 골드
@onready var gold_label = get_node("UI_Layer/BaseUI/goldcollect/GoldCount")
@export var gold_count = 0

# 적 처치
@onready var kill_label = get_node("UI_Layer/BaseUI/killcollect/KillCount")
@export var kill_count = 0

var damage_flag = false 	# 데미지 플래그 (=무적 플래그)
var hit_flag    = false 	# 히트 플래그

@onready var level_label = $UI_Layer/BaseUI/level

func _ready():
	# 캐릭터를 뷰포트 중앙으로 이동
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = viewport_size / 2
	# 캐릭터 특성 설정
	max_hp = START_HP
	current_exp = start_exp
	# 자석 범위 설정
	$MagneticArea.connect("area_entered", Callable(self, "_on_magnetic_area_area_entered"))	# 시그널 코드로 연결결
	magnetic_area.shape.radius = magnetic_area_scale
	# 공격 범위 초기화(off)
	attack_area_1.set_deferred("disabled", true)
	attack_area_2.set_deferred("disabled", true)
	attack_area_3.set_deferred("disabled", true)

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
	level_label.text = "LV " + str(character_level)
	# 그림자 분신술
	# add_shadow(shadow_attack)

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
		current_hp -= damage
		print("max_hp", hp_bar.max_value)					# FIXME : 현재 데미지 꺼놓은 상태 아래 FIXME 작업 완료 후 주석 제거 필요
		damage_flag = false
		if current_hp <= 0:
			die_character()
			print("사망") 									# FIXME : 사망 시 필요한 작업 (메인메뉴 돌아가기, 사망 모션, 사망 사운드 등) 추가 필요
		else:
			print("현재 체력 : ", current_hp)
			hit_flag = true
			if (animated_sprite.is_playing()) && ((animated_sprite.animation == "attack_1")||(animated_sprite.animation == "attack_2")||(animated_sprite.animation == "attack_3")):
				animated_sprite.modulate = Color(1,0,0)
			else:
				animated_sprite.stop()
				animated_sprite.speed_scale = 3.0
				animated_sprite.play("take_hit")
				animated_sprite.modulate = Color(1, 0, 0)	# 피해 입으면 컬러 변경(빨간색)
				await animated_sprite.animation_finished      
		hit_flag    = false

func die_character():
	var BaseUI_PATH = $UI_Layer
	var death_pannel = $UI_Layer/BaseUI/DeathPanel
	BaseUI_PATH.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = true
	death_pannel.visible = true
	
	var cur_gold = int(gold_count)
	Global.character_data["GOLD"]["gold"] += cur_gold
	Global.save_character_data()

# 골드 추가
func add_gold(gold_value):
	gold_count += gold_value
	#print("현재 골드 : ", gold_count)

# 경험치 추가
func add_exp(_exp_value):
	current_exp += _exp_value
	calculate_exp()
	#print("경험치 획득!")

# 경험치 계산
func calculate_exp():
	if character_level < 5:
		max_exp = character_level * 20
		print("max 경험치 : ",max_exp)
		level_up()
	elif character_level < 10:
		max_exp = character_level * 24
		print("max 경험치 : ",max_exp)
		level_up()
	elif character_level < 15:
		max_exp = character_level * 27
		level_up()
	elif character_level < 20:
		max_exp = character_level * 30
		level_up()
	elif character_level < 25:
		max_exp = character_level * 32
		level_up()
	else:
		max_exp = character_level * 34
		level_up()

# 레벨 업
func level_up():
	if current_exp >= max_exp:
		character_level += 1
		print("레벨 업! : ", character_level)
		current_exp = current_exp - max_exp

# 그림자 공격
# func add_shadow(shadow_attack):
# 	if shadow_attack and !is_shadow_on:
# 		var shadow_instance = shadow.instantiate()
# 		shadow_instance.name = "shadow"
# 		add_child(shadow_instance)
# 		is_shadow_on = 1
# 	else:
# 		pass


func _on_magnetic_area_area_entered(area:Area2D):
	if area.is_in_group("Gold") or area.is_in_group("Exp"):
		area.target = self

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

func _on_damage_timer_timeout():
	damage_flag = true
	animated_sprite.modulate = Color(1, 1, 1)        # 피해 이펙트 원상복귀
