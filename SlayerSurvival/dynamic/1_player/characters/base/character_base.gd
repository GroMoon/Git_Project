extends CharacterBody2D

class_name CharacterBase 

signal levelup

## CONSTANT

## 하위 노드 상대경로
@onready var animated_sprite  = $AnimatedSprite2D
@onready var magnetic_area    = $MagneticArea/CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var damage_timer     = $DamageTimer
@onready var attack_timer     = $AttackTimer
@onready var baseui = $UI_Layer/BaseUI

## 기본 파라미터
@export var character_name      = "CharacterBase"	# 캐릭터 이름
@export var move_speed          = 200				# 캐릭터 이동속도
@export var character_level     = 1					# 캐릭터 레벨
@export var attack_times        = 1					# 캐릭터 공격 콤보
@export var shadow_attack       = false				# 캐릭터 그림자 분신술
@export var attack_damage       = 5					# 캐릭터 일반 공격 데미지
@export var magnetic_area_scale = 100:				# 캐릭터 자석 범위
	set(value):
		magnetic_area_scale = value
		if magnetic_area:
			magnetic_area.shape.radius = value
@export var animation_speed     = 1.0				# 캐릭터 기본 애니메이션 속도
@export var start_hp            = 100.0				# 캐릭터 시작 체력
@export var vampire             = 0.0				# 캐릭터 흡혈 퍼센트
@export var shield              = 0.0               # 캐릭터 방어력
@export var attack_wait_time    = 1.2  				# 기본 공격 쿨타임(초)
@export var attack_anim_speed   = 1.0				# 기본 공격 모션 재생 속도(AnimationPlayer)
@export var cooldown            = 0.0				# 캐릭터 쿨타임 감소값(어택타이머)
@export var gold_drop           = 0.0				# 캐릭터 골드(2개) 드롭 퍼센트
@export var gem_drop            = 0.0				# 캐릭터 경험치(2개) 드롭 퍼센트
@export var crit_chance         = 0.08				# 치명타 확률
@export var crit_multiplier     = 2.0				# 치명타 배율

const COOLDOWN_REFERENCE = 4.0		# cooldown 값(초) → 비율 환산 기준 (cooldown 0.2 = 5% 감소)
const MIN_COOLDOWN_MULT  = 0.35		# 쿨타임 최대 감소 한도
const AUTO_AIM_RANGE     = 260.0	# 근접 공격 자동 조준 범위


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
var shield_level         = 0	# 방어력
var cooldown_level       = 0	# 쿨타임 TODO : 미개발
var respawn_times        = 0	# 리스폰 횟수

var invincibility_duration = 2.0  # 초 단위 무적 시간

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
@onready var hp_bar = $Health_Bar
var max_hp = start_hp:
	set(set_value):
		max_hp = set_value
		hp_bar.max_value = max_hp
var current_hp = max_hp:
	set(set_value):
		current_hp = set_value
		hp_bar.value = snappedf(current_hp, 0.01)	# 체력 소수점 2자리까지만 표시 
		if current_hp > max_hp:
			current_hp = max_hp

## 골드
@onready var gold_label = get_node("UI_Layer/BaseUI/goldcollect/GoldCount")
@export var gold_count = 0

## 적 처치
@onready var kill_label = get_node("UI_Layer/BaseUI/killcollect/KillCount")
@export var kill_count  = 0

## 업그레이드 
@onready var upgrade_container = $UI_Layer/SelectUI/select_panel/upgrade_container
@onready var select_panel      = $UI_Layer/SelectUI/select_panel

## 레벨
@onready var level_label = $UI_Layer/BaseUI/Level

func _ready():
	# 플레이어 데이터 동기화
	bind_player_data()
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
	animation_player.speed_scale = attack_anim_speed
	# 공격 타이머는 공격이 끝날 때마다 다시 시작 (콤보 중 중복 발동 방지)
	attack_timer.one_shot = true
	attack_timer.wait_time = get_attack_wait_time()
	attack_timer.start()
	# 몬스터펫 초기화
	Dialogic.VAR.mushroom_pet_diag  = false
	Dialogic.VAR.skeleton_pet_diag  = false
	Dialogic.VAR.goblin_pet_diag    = false
	Dialogic.VAR.flyingeye_pet_diag = false

func _physics_process(_delta):
	if is_dead:
		return

	# 키보드 입력 (공격 중에도 이동 가능)
	process_keyboard_input()
	# 캐릭터 이동 및 충돌 감지
	move_and_slide()
	# hit_effect (깜빡거림) 추가
	apply_hit_effect()
	# 애니메이션 처리 (공격 모션 중에는 AnimationPlayer가 스프라이트를 제어)
	if !hit_flag and !is_attacking:
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

func bind_player_data():
	max_hp        = max_hp + int(Global.character_data["CHARACTER_STORE_UPGRADES"]["health"])
	shield        = shield + float(Global.character_data["CHARACTER_STORE_UPGRADES"]["shield"])
	respawn_times = respawn_times + int(Global.character_data["CHARACTER_STORE_UPGRADES"]["respawn"])
	attack_damage = attack_damage + int(Global.character_data["CHARACTER_STORE_UPGRADES"]["damage"])
	move_speed    = move_speed + int(Global.character_data["CHARACTER_STORE_UPGRADES"]["speed"])
	cooldown      = cooldown + float(Global.character_data["CHARACTER_STORE_UPGRADES"]["cooldown"])
	vampire       = vampire + float(Global.character_data["CHARACTER_STORE_UPGRADES"]["vampire"])
	gold_drop     = gold_drop + float(Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"])
	gem_drop      = gem_drop + float(Global.character_data["CHARACTER_STORE_UPGRADES"]["gem_drop"])

# Enemy 충돌 처리
func process_collision_enemy(damage):
	if !damage_flag:
		var damage_shielded = damage*(1-shield) # 방어력에 반감된 데미지
		current_hp -= damage_shielded
		DamageVisual.show_damage(damage_shielded, self.position)
		# 피격 피드백: 화면 흔들림 + 붉은 화면 플래시
		GameFeel.shake(0.35)
		GameFeel.flash_screen(Color(0.8, 0.05, 0.05, 0.25), 0.2)
		# print("max_hp", hp_bar.max_value)					
		damage_flag = true
		damage_timer.start()
		# print(current_hp)
		if current_hp <= 0:
			if respawn_times != 0:
				hit_flag = true
				# 퍼즈 걸기
				$CollisionShape2D.disabled = true
				# print(respawn_times)
				respawn_times -= 1
				animated_sprite.play("death")
				await animated_sprite.animation_finished
				await respawn()
				$CollisionShape2D.disabled = false
				# print("남은 부활 횟수 : ", respawn_times)
			else:
				$CollisionShape2D.disabled = true
				is_dead = true
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
	_pulse_exp_bar()
	calculate_exp()

# 경험치 바 반짝임
var exp_bar_tween: Tween
func _pulse_exp_bar():
	if exp_bar_tween and exp_bar_tween.is_valid():
		exp_bar_tween.kill()
	exp_bar.modulate = Color(1.8, 1.8, 2.2)
	exp_bar_tween = exp_bar.create_tween()
	exp_bar_tween.tween_property(exp_bar, "modulate", Color.WHITE, 0.2)

# 체력 회복(음식)
func add_food(health_value):
	current_hp += health_value

# 경험치 계산
func calculate_exp():
	if character_level >= 30:
		max_exp = 0  # 30 이상은 레벨업 없음(원하는 정책으로 변경 가능)
	elif character_level < 5:          # 1~4
		max_exp = character_level * 20
	elif character_level < 10:         # 5~9
		max_exp = character_level * 24
	elif character_level < 15:         # 10~14
		max_exp = character_level * 27
	elif character_level < 19:         # 15~18
		max_exp = character_level * 30
	else:                              # 19~29 (고정값)
		max_exp = 124

	# 총합 정합성 맞추기 위한 미세 조정: Lv5만 -4exp (120 -> 116)
	if character_level == 5:
		max_exp -= 4

	level_up()

# 레벨 업
func level_up():
	if current_exp >= max_exp:
		character_level += 1
		# print("레벨 업! : ", character_level)
		current_exp = current_exp - max_exp
		levelup_shockwave()
		emit_signal("levelup")

# 레벨업 충격파: 주변 적을 밀어내고 화면 플래시 (선택 창이 닫히면 적들이 날아감)
func levelup_shockwave():
	GameFeel.flash_screen(Color(1.0, 0.95, 0.6, 0.45), 0.35)
	GameFeel.burst(global_position, Color(1.0, 0.9, 0.4), 24, 260.0, 4.0)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) < 220.0 and enemy.has_method("apply_knockback"):
			enemy.apply_knockback(self, 3.0)

# ================= 전투 유틸 =================
# 쿨타임 감소 비율 (1.0 = 감소 없음)
func get_cooldown_mult() -> float:
	return clamp(1.0 - cooldown / COOLDOWN_REFERENCE, MIN_COOLDOWN_MULT, 1.0)

# 시그니처 공격 대기 시간
func get_attack_wait_time() -> float:
	return max(attack_wait_time * get_cooldown_mult(), 0.1)

# 치명타 판정: [최종 데미지, 치명타 여부]
func roll_damage(base_damage: float) -> Array:
	if randf() < crit_chance:
		return [base_damage * crit_multiplier, true]
	return [base_damage, false]

# 가장 가까운 적 (범위 밖이면 null)
func get_nearest_enemy(max_range: float = INF) -> Node2D:
	var nearest: Node2D = null
	var best = max_range
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var d = global_position.distance_to(enemy.global_position)
		if d < best:
			best = d
			nearest = enemy
	return nearest

# 근접 공격 자동 조준: 범위 내 가장 가까운 적 쪽을 바라봄
func face_nearest_enemy():
	var enemy = get_nearest_enemy(AUTO_AIM_RANGE)
	if enemy:
		animated_sprite.flip_h = enemy.global_position.x < global_position.x

# 근접 콤보 공격 공통 처리 (전사, 왕)
# attack_areas: 콤보 단계별 공격 범위, right_offsets: 오른쪽을 볼 때의 x 위치
func run_melee_combo(attack_areas: Array, right_offsets: Array):
	if is_dead:
		return
	is_attacking = true
	animated_sprite.speed_scale = animation_speed
	face_nearest_enemy()
	var side = -1 if animated_sprite.flip_h else 1
	for i in attack_areas.size():
		attack_areas[i].position.x = right_offsets[i] * side
	for i in clampi(attack_times, 1, attack_areas.size()):
		# pause 해제 대기
		if is_dead or not await wait_for_pause_resume():
			is_attacking = false
			return
		animation_player.play("attack_%d" % (i + 1))
		await animation_player.animation_finished
	if not await wait_for_pause_resume():
		is_attacking = false
		return
	is_attacking = false
	# 타이머 재시작
	attack_timer.wait_time = get_attack_wait_time()
	attack_timer.start()

# 흡혈 능력
func apply_health(_source):
	var heal = vampire * float(attack_damage)
	if vampire != 0:
		current_hp += heal
		current_hp = clamp(current_hp, 0, max_hp)
		VampireVisual.show_vampire(heal, self.position, Color.GREEN)

# 부활
func respawn():
	animated_sprite.material.set_shader_parameter("hit_flag", true)
	baseui.respawn_pause_flag = true
	animation_player.speed_scale = 1.0
	animation_player.play("respawn" if animation_player.has_animation("respawn") else "revive")
	await animation_player.animation_finished
	animation_player.speed_scale = attack_anim_speed
	await get_tree().create_timer(invincibility_duration).timeout
	current_hp = max_hp * 0.5
	baseui.respawn_pause_flag = false

# hit_effect
func apply_hit_effect():
	if self.hit_flag:
		animated_sprite.material.set_shader_parameter("hit_flag", true)
	else:
		animated_sprite.material.set_shader_parameter("hit_flag", false)

func _on_magnetic_area_area_entered(area:Area2D):
	if area is PickupBase:
		area.attract($MagneticArea)

func _on_damage_timer_timeout():
	damage_flag = false

# pause가 해제될 때까지 대기하는 헬퍼 함수
# pause 중에는 코드가 실행되지 않으므로, pause 해제 후에 확인
func wait_for_pause_resume():
	# pause 상태 확인
	# BaseUI는 PAUSE_MODE_PROCESS 모드이므로 pause 중에도 실행됨
	# 따라서 BaseUI의 pause 플래그를 확인할 수 있음
	var is_paused = false
	if baseui:
		is_paused = baseui.globl_pause_flag or baseui.lvlup_pause_flag or baseui.death_pause_flag or baseui.diag_pause_flag or baseui.respawn_pause_flag
	else:
		is_paused = get_tree().paused
	
	if is_paused:
		# pause 중에는 사망 상태 확인
		if is_dead:
			return false
		# pause가 해제될 때까지 대기
		# BaseUI는 PAUSE_MODE_PROCESS 모드이므로 pause 중에도 실행됨
		# 따라서 BaseUI의 pause 플래그를 확인할 수 있음
		if baseui:
			while baseui.globl_pause_flag or baseui.lvlup_pause_flag or baseui.death_pause_flag or baseui.diag_pause_flag or baseui.respawn_pause_flag:
				if is_dead:
					return false
				# pause 해제를 기다리기 위해 다음 프레임까지 대기
				# BaseUI는 PAUSE_MODE_PROCESS 모드이므로 pause 중에도 실행됨
				# 하지만 character_base는 pause 중에 실행되지 않으므로
				# pause 해제 후에만 이 코드가 실행됨
				# 따라서 BaseUI의 pause 플래그를 확인하는 것으로 충분함
				await Engine.get_main_loop().process_frame
		else:
			# BaseUI가 없으면 get_tree().paused만 확인
			while get_tree().paused:
				if is_dead:
					return false
				# pause 해제를 기다리기 위해 다음 프레임까지 대기
				# pause 중에는 코드가 실행되지 않으므로 pause 해제 후에만 실행됨
				await Engine.get_main_loop().process_frame
	return true
