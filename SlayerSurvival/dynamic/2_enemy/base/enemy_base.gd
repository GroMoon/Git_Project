extends CharacterBody2D

class_name EnemyBase

@onready var collision_shape    = $CollisionShape2D
@onready var animated_sprite    = $AnimatedSprite2D
@onready var interaction_sensor = $interaction_sensor 
@onready var death_sound        = $death_sound

# 아이템
var gold_img = preload("res://dynamic/6_utillity/items/gold/gold.tscn")
var exp_img  = preload("res://dynamic/6_utillity/items/exp/exp.tscn")
var food_img = preload("res://dynamic/6_utillity/items/food/food.tscn")
var double_gold_drop
var double_gem_drop

# 적 특성 (default)
var enemy_name      = "EnemyBase"
var health          = 15 	# 적 체력
var move_speed      = 80 	# 적 이동 속도
var damage          = 5  	# 적 데미지
var spawn_radius    = 500  	# 적 스폰 범위
var animation_speed = 1.0	# 적 기본 애니메이션 속도
var pet_chance      = 0.1 	# 적 펫이 될 확률
var exp_reward      = 2		# 처치 시 경험치 (젬 1개에 담김)
# 전역 변수
var player 
var touch_flag    = false
var hit_flag      = false
var is_dead       = false
var targeted_flag = false	# 플레이어가 적을 목표로 설정했는지 확인하는 변수
var is_elite      = false	# 적 특성 중 엘리트 여부
# 넉백 관련
var knockback_vector   = Vector2.ZERO
var knockback_time     = 0.0			# 넉백 유지 시간
var knockback_duration = 0.15			# 넉백 몇 초 동안?
var knockback_strength = 230.0  		# 넉백 세기
var knockback_resist   = 0.0			# 넉백 저항 (0.0 ~ 1.0, 엘리트는 높음)
# 디렉터 제어
var move_override      = Vector2.ZERO		# 0이 아니면 플레이어 추적 대신 이 속도로 직진 (박쥐 떼)
var despawn_far        = false				# 멀어지면 재배치 대신 삭제
# 피격 연출
var base_sprite_scale  = Vector2.ONE
var hit_color          = Color(1.0, 0.35, 0.3)	# 사망 파티클 색


func _ready():
	# player 노드 찾기
	player = get_parent().get_parent().get_node("player")
	# 시그널 연결
	interaction_sensor.connect("area_entered", Callable(self, "_on_interaction_sensor_area_entered"))
	interaction_sensor.connect("body_entered", Callable(self, "_on_interaction_sensor_body_entered"))
	interaction_sensor.connect("body_exited" , Callable(self, "_on_interaction_sensor_body_exited"))
	# 드롭 확률 연결
	double_gold_drop = player.gold_drop
	double_gem_drop  = player.gem_drop
	# 피격 플래시 머티리얼
	GameFeel.ensure_flash_material(animated_sprite)
	base_sprite_scale = animated_sprite.scale
	if is_elite:
		knockback_resist = 0.7

func _physics_process(delta):
	# 사망 상태에서 아무것도 처리 아지 않도록
	if is_dead:
		return

	# 넉백 중이면 넉백 로직 우선 적용
	if knockback_time > 0.0:
		knockback_time -= delta
		velocity = knockback_vector
		move_and_slide()
		return
	else:
		# 넉백 로직 끝날 시 원래 로직으로 복귀귀
		# 플레이어가 존재하면 플레이어를 향해 이동
		if move_override != Vector2.ZERO:
			velocity = move_override
			move_and_slide()
		elif player:
			var direction = (player.position - position).normalized()
			velocity = direction * move_speed
			move_and_slide()

		# 애니메이션 처리
		if (velocity.length() > 0) && (!hit_flag):
			animated_sprite.speed_scale = animation_speed
			$AnimatedSprite2D.play("walk")
			$AnimatedSprite2D.flip_h = velocity.x < 0
			
	if touch_flag:
		player.process_collision_enemy(damage)


# 시간에 따른 강화 (디렉터가 스폰 직후 호출)
func apply_scaling(hp_mult: float, damage_mult: float):
	health = health * hp_mult
	damage = damage * damage_mult

# 사망 처리 함수
func die_enemy():
	death_sound.pitch_scale = randf_range(0.85, 1.15)
	death_sound.play()
	var pet_chance_randf = randf()						# 몬스터펫 확률 (0.0~1.0 사이로 조절)
	is_dead = true 										# 사망 상태 활성화
	remove_from_group("enemy")							# 죽는 중인 적은 공격 대상에서 제외
	# 사망 연출
	GameFeel.burst(global_position, hit_color, 14 if !is_elite else 32, 170.0 if !is_elite else 260.0)
	if is_elite:
		GameFeel.shake(0.5)
		GameFeel.hitstop(0.08)
	drop_item()
	player.kill_count += 1
	collision_shape.call_deferred("set_disabled",true)	# CollisionShape2D 비활성화
	interaction_sensor.call_deferred("queue_free")		# interaction_sensor 삭제
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	
	var is_pet = false
	var pet_dialog_path = ""
	
	if enemy_name == "skeleton":
		is_pet = !player.is_skeleton_pet && pet_chance_randf <= pet_chance
		if is_pet:
			player.skeleton_pet = true
			pet_dialog_path = "res://dynamic/7_dialogic/get_skeleton_pet.dtl"
	elif enemy_name == "mushroom":
		is_pet = !player.is_mushroom_pet && pet_chance_randf <= pet_chance
		if is_pet:
			player.mushroom_pet = true
			pet_dialog_path = "res://dynamic/7_dialogic/get_mushroom_pet.dtl"
	elif enemy_name == "goblin":
		is_pet = !player.is_goblin_pet && pet_chance_randf <= pet_chance
		if is_pet:
			player.goblin_pet = true
			pet_dialog_path = "res://dynamic/7_dialogic/get_goblin_pet.dtl"
	elif enemy_name == "flyingeye":
		is_pet = !player.is_flyingeye_pet && pet_chance_randf <= pet_chance
		if is_pet:
			player.flyingeye_pet = true
			pet_dialog_path = "res://dynamic/7_dialogic/get_flyingeye_pet.dtl"
			
	# 다른 대화가 진행 중이거나 막 시작됐으면 이번 펫 획득은 건너뜀 (동시 실행 시 Dialogic 오류)
	if is_pet and (Dialogic.current_timeline != null or Time.get_ticks_msec() - last_pet_dialog_msec < 1500):
		is_pet = false
	if is_pet:
		last_pet_dialog_msec = Time.get_ticks_msec()
		Dialogic.start(pet_dialog_path).process_mode = Node.PROCESS_MODE_ALWAYS
		Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
		
	queue_free()

# 아이템 드랍 함수
const GOLD_DROP_CHANCE = 0.06
static var last_pet_dialog_msec := -100000
func drop_item():
	# 골드 (호드 규모에 맞춰 확률 하향, 엘리트는 확정)
	var gold_chance = randf()
	if gold_chance <= GOLD_DROP_CHANCE or is_elite:
		spawn_gold()
		if randf() <= double_gold_drop:
			spawn_gold()
	# 경험치 (항상 드롭, 상점 젬 드롭 업그레이드는 두 배 확률)
	spawn_gem()
	if randf() <= double_gem_drop:
		spawn_gem()
	# 엘리트: 음식 + 보물상자
	if is_elite:
		spawn_food()
		var chest = ChestPickup.create()
		chest.global_position = global_position
		get_parent().call_deferred("add_child", chest)
	else:
		# 드문 필드 픽업 (자석 / 폭탄 / 음식)
		var r = randf()
		if r < MAGNET_CHANCE:
			spawn_field_pickup("magnet")
		elif r < MAGNET_CHANCE + NUKE_CHANCE:
			spawn_field_pickup("nuke")
		elif r < MAGNET_CHANCE + NUKE_CHANCE + FOOD_CHANCE:
			spawn_food()

const MAGNET_CHANCE = 0.0025
const NUKE_CHANCE   = 0.0015
const FOOD_CHANCE   = 0.005
func spawn_field_pickup(kind: String):
	var p = FieldPickup.create(kind)
	p.global_position = global_position
	get_parent().call_deferred("add_child", p)

func spawn_gold():
	var new_gold = gold_img.instantiate()
	new_gold.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	get_parent().call_deferred("add_child", new_gold)
	
const GEM_MERGE_THRESHOLD = 120		# 바닥 젬이 이보다 많으면 근처 젬에 합침 (성능)
func spawn_gem():
	var gems = get_tree().get_nodes_in_group("Exp")
	if gems.size() > GEM_MERGE_THRESHOLD:
		var nearest = null
		var best = 90.0
		for g in gems:
			var d = global_position.distance_to(g.global_position)
			if d < best and not g.collected:
				best = d
				nearest = g
		if nearest:
			nearest.add_value(exp_reward)
			return
	var new_exp = exp_img.instantiate()
	new_exp.exp_value = exp_reward
	new_exp.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	get_parent().call_deferred("add_child", new_exp)

func spawn_food():
	var new_food = food_img.instantiate()
	new_food.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	get_parent().call_deferred("add_child", new_food)
# 넉백 함수
func apply_knockback(attacker, strength_mult: float = 1.0):
	# 방향 : (적의 위치 - 공격자=플레이어 위치)
	var from: Vector2 = attacker if attacker is Vector2 else attacker.global_position
	var direction    = (global_position - from).normalized()
	knockback_vector = direction * knockback_strength * strength_mult * (1.0 - knockback_resist)
	knockback_time   = knockback_duration

# 데미지 처리 (모든 무기 공통 진입점)
# source: 넉백 기준 (Node2D 또는 Vector2 위치), knockback_mult: 넉백 배율, is_crit: 치명타 여부
func take_damage(amount: float, source = null, knockback_mult: float = 1.0, is_crit: bool = false):
	if is_dead:
		return
	health -= amount
	DamageVisual.show_damage(amount, self.position, Color.WHITE, is_crit)
	GameFeel.hit_flash(animated_sprite)
	GameFeel.squash(animated_sprite, base_sprite_scale, 0.28 if is_crit else 0.18)
	if is_crit:
		GameFeel.shake(0.12)
	if health <= 0:
		die_enemy()
		return
	if source != null and knockback_mult > 0.0:
		apply_knockback(source, knockback_mult)
	# 데미지 모션 추가
	hit_flag = true
	animated_sprite.stop()						# 현재 애니메이션(walk)을 중지시킴
	animated_sprite.speed_scale = 2.0
	animated_sprite.play("take_hit")
	await animated_sprite.animation_finished
	hit_flag = false

# 접촉 상태가 되었을 때
func _on_interaction_sensor_body_entered(_body:Node2D):
	if _body == player and not touch_flag:
		touch_flag = true
		# print(touch_flag)

# 접촉 상태에서 벗어날 때
func _on_interaction_sensor_body_exited(_body:Node2D):
	if _body == player:
		touch_flag = false

func _on_interaction_sensor_area_entered(area:Area2D):
	if area.is_in_group("attack"):
		var attacker = area.get_parent()
		var rolled = player.roll_damage(attacker.attack_damage)
		if attacker.name.begins_with("player"):
			player.apply_health(player)
		RunStats.add_damage(RunStats.source_of(attacker), rolled[0])
		take_damage(rolled[0], attacker, 1.0, rolled[1])
