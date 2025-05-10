extends CharacterBody2D

class_name CharacterBase 

signal levelup

## CONSTANT

## 하위 노드 상대경로
@onready var animated_sprite  = $AnimatedSprite2D
@onready var magnetic_area    = $MagneticArea/CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var damage_timer     = $DamageTimer

## 기본 파라미터
@export var character_name      = "CharacterBase"	# 캐릭터 이름
@export var move_speed          = 200				# 캐릭터 이동속도
@export var character_level     = 1					# 캐릭터 레벨
@export var attack_times        = 1					# 캐릭터 공격 콤보
@export var shadow_attack       = false				# 캐릭터 그림자 분신술
@export var attack_damage       = 5					# 캐릭터 일반 공격 데미지
@export var magnetic_area_scale = 100				# 캐릭터 자석 범위 
@export var animation_speed     = 1.0				# 캐릭터 기본 애니메이션 속도
@export var start_hp            = 100				# 캐릭터 시작 체력
@export var drain_percent       = 0.0				# 캐릭터 흡혈 퍼센트

## 펫 관련
# mushroom
var mushroom_pet     = false
var mushroom_pet_on  = false
var is_mushroom_pet  = false
# skeleton
var skeleton_pet     = false
var skeleton_pet_on  = false
var is_skeleton_pet  = false
# goblin
var goblin_pet       = false
var goblin_pet_on    = false
var is_goblin_pet    = false
# flyingeye
var flyingeye_pet    = false
var flyingeye_pet_on = false
var is_flyingeye_pet = false

## 플래그
var is_attacking         = false		# 캐릭터 공격 중 플래그
var is_shadow_on         = false		# 캐릭터 그림자 분신술 플래그
var is_dead              = false		# 캐릭터 사망 플래그 
var damage_flag          = false		# 캐릭터 무적 플래그 
var hit_flag             = false		# 캐릭터 히트 플래그 
var death_flag_for_pause = false		# BaseUI에서 사망 시 퍼즈를 위한 플래그 

## 능력 레벨 관리
var attack_times_level   = 0	# 캐릭터 고유 특성
var max_hp_level         = 0	# 최대 체력 증가
var damage_level         = 0	# 데미지 증가
var move_speed_level     = 0	# 이동 속도 증가
var drain_level          = 0	# 흡혈
var shadow_partner_level = 0	# 그림자 분신
var magnetic_area_level  = 0	# 자석 범위
# var 방어력
# var 공격 속도
# var 부활
# var 쿨타임

## 경험치
@onready var exp_bar = $UI_Layer/BaseUI/Exp_Bar
var start_exp = 0
var max_exp:
	set(set_value):
		max_exp = set_value
		exp_bar.max_value = max_exp
var current_exp = 0:
	set(set_value):
		current_exp = set_value
		exp_bar.value = current_exp

## 체력
@onready var hp_bar = $UI_Layer/BaseUI/Health_Bar
var max_hp = start_hp:
	set(set_value):
		max_hp = set_value
		hp_bar.max_value = max_hp
var current_hp = max_hp:
	set(set_value):
		current_hp = set_value
		hp_bar.value = current_hp
		if current_hp > max_hp:
			current_hp = max_hp

## 골드
@onready var gold_label = get_node("UI_Layer/BaseUI/goldcollect/GoldCount")
@export var gold_count = 0

## 적 처치
@onready var kill_label = get_node("UI_Layer/BaseUI/killcollect/KillCount")
@export var kill_count = 0

## 업그레이드 
@onready var upgrade_container = $UI_Layer/SelectUI/select_panel/upgrade_container
@onready var select_panel = $UI_Layer/SelectUI/select_panel

## 레벨
@onready var level_label = $UI_Layer/BaseUI/Level

func _ready():
	# 캐릭터를 뷰포트 중앙으로 이동
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = viewport_size / 2
	# 캐릭터 특성 설정
	max_hp = start_hp
	current_hp = start_hp
	current_exp = start_exp
	# 자석 시그널 연결 및 범위 설정
	$MagneticArea.connect("area_entered", Callable(self, "_on_magnetic_area_area_entered"))	# 시그널 코드로 연결결
	magnetic_area.shape.radius = magnetic_area_scale
	# attack timer 시그널 연결
	# $AttackTimer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	# damage timer 시그널 연결
	$DamageTimer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	# 공격 범위 초기화(off)
	animation_player.play("RESET")
	# 몬스터펫 초기화
	Dialogic.VAR.mushroom_pet_diag  = false
	Dialogic.VAR.skeleton_pet_diag  = false
	Dialogic.VAR.goblin_pet_diag    = false
	Dialogic.VAR.flyingeye_pet_diag = false


func _physics_process(_delta):
	if is_dead:
		return
	# 공격 중에 이동 처리 안 함
	if is_attacking:
		return
		
	# 키보드 입력
	process_keyboard_input()
	# 캐릭터 이동 및 충돌 감지
	move_and_slide()
	# hit_effect (깜빡거림) 추가
	apply_hit_effect()
	
	# 애니메이션 처리
	if !hit_flag:
		animated_sprite.speed_scale = animation_speed
		if velocity.length() > 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")	
	
	# 라벨 업데이트
	gold_label.text = str(gold_count)
	kill_label.text = str(kill_count)
	level_label.text = "LV " + str(character_level)

	#? diaglogic variable test
	mushroom_pet_on  = Dialogic.VAR.mushroom_pet_diag
	skeleton_pet_on  = Dialogic.VAR.skeleton_pet_diag
	goblin_pet_on    = Dialogic.VAR.goblin_pet_diag
	flyingeye_pet_on = Dialogic.VAR.flyingeye_pet_diag

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
	if !damage_flag:
		current_hp -= damage
		DamageVisual.show_damage(-damage, self.position)
		print("max_hp", hp_bar.max_value)					# FIXME : 현재 데미지 꺼놓은 상태 아래 FIXME 작업 완료 후 주석 제거 필요
		damage_flag = true
		damage_timer.start()
		if current_hp <= 0:
			$CollisionShape2D.disabled = true
			is_dead = true
			# [CHARACTER-019] [DEV] 캐릭터 사망 애니메이션 적용
			hit_flag = true									# FIXME : 사망 시 필요한 작업(사망 사운드 등) 추가 필요
			animated_sprite.stop()
			animated_sprite.speed_scale = animation_speed
			animated_sprite.play("death")
			await animated_sprite.animation_finished
			die_character()
			return								    
		hit_flag = false

func die_character():
	var cur_gold = int(gold_count)
	Global.character_data["GOLD"]["gold"] += cur_gold
	Global.save_character_data()
	
	death_flag_for_pause = true

# 골드 추가
func add_gold(gold_value):
	gold_count += gold_value

# 경험치 추가
func add_exp(_exp_value):
	current_exp += _exp_value
	calculate_exp()

# 체력 회복(음식)
func add_food(health_value):
	current_hp += health_value

# 경험치 계산
func calculate_exp():
	if character_level < 5:
		max_exp = character_level * 20
	elif character_level < 10:
		max_exp = character_level * 24
	elif character_level < 15:
		max_exp = character_level * 27
	elif character_level < 20:
		max_exp = character_level * 30
	elif character_level < 25:
		max_exp = character_level * 32
	else:
		max_exp = character_level * 34
	level_up()

# 레벨 업
func level_up():
	if current_exp >= max_exp:
		character_level += 1
		print("레벨 업! : ", character_level)
		current_exp = current_exp - max_exp
		emit_signal("levelup")

# 흡혈 능력
func apply_health(source):
	# 흡혈 레벨이 0이거나 주체가 자신이 아니라면 무시
	if drain_level == 0 || source != self:
		return
	print(1)
	var heal = drain_percent * attack_damage
	if heal < 1:
		heal = 1
	current_hp += heal
	current_hp = clamp(current_hp, 0, max_hp)
	DamageVisual.show_damage(heal, self.position, Color.GREEN)

# hit_effect
func apply_hit_effect():
	if self.hit_flag:
		animated_sprite.material.set_shader_parameter("hit_flag", true)
	else:
		animated_sprite.material.set_shader_parameter("hit_flag", false)

func _on_magnetic_area_area_entered(area:Area2D):
	if area.is_in_group("Gold") or area.is_in_group("Exp"):
		area.target = $MagneticArea

func _on_damage_timer_timeout():
	damage_flag = false
