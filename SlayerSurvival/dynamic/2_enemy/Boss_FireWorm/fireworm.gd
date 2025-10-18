extends CharacterBody2D

const BODY_ANIMATION_SPEED   = 2.0		# 기본 body 애니메이션 속도
const ATTACK_ANIMATION_SPEED = 2.0

@onready var body_collision_shape   	  = $CollisionShape2D
@onready var body_animated_sprite   	  = $AnimatedSprite2D

@onready var body_interaction_sensor      = $interaction_sensor 

@onready var death_sound  = $death_sound

# 파이어볼 씬
var fireball_tscn = preload("res://dynamic/2_enemy/Boss_FireWorm/fire_ball/fire_ball.tscn")

# 아이템
var gold_img = preload("res://dynamic/6_utillity/items/gold/gold.tscn")
var exp_img  = preload("res://dynamic/6_utillity/items/exp/exp.tscn")
var food_img = preload("res://dynamic/6_utillity/items/food/food.tscn")
#var golds = 25

# 적 특성
var enemy_name   = "FireWorm"
var health       = 1000		# 적 체력
var move_speed   = 80 		# 적 이동 속도
var damage       = 10  		# 적 데미지
var spawn_radius = 200  	# 스폰 범위
# 전역 변수
var player 
var touch_flag    = false
var hit_flag      = false
var is_dead       = false
var is_attacking  = false
var targeted_flag = false

# 넉백 관련
var knockback_vector   = Vector2.ZERO
var knockback_time     = 0.0			# 넉백 유지 시간
var knockback_duration = 0.2			# 넉백 몇 초 동안?
var knockback_strength = 100.0  		# 넉백 세기

func _ready():
	# player 노드 찾기
	player = get_parent().get_parent().get_node("player")
	
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
		if player:
			var direction = (player.position - position).normalized()
			velocity = direction * move_speed
			if is_attacking:
				velocity = Vector2.ZERO
			move_and_slide()

		# 애니메이션 처리
		if (velocity.length() > 0) && (!hit_flag):
			body_animated_sprite.speed_scale = BODY_ANIMATION_SPEED
			$AnimatedSprite2D.play("walk")
			$AnimatedSprite2D.flip_h = velocity.x < 0

	if touch_flag:
		player.process_collision_enemy(damage)

# 사망 처리 함수
func die_enemy():
	is_dead = true 										# 사망 상태 활성화
	drop_item()
	player.kill_count += 1
	$AttackTimer.stop()
	body_collision_shape.call_deferred("set_disabled",true)	# CollisionShape2D 비활성화
	body_interaction_sensor.call_deferred("queue_free")		# body_interaction_sensor 삭제
	body_animated_sprite.play("death")
	death_sound.play()
	await body_animated_sprite.animation_finished
	body_animated_sprite.hide()							# 사운드 유지를 위해 노드 숨기기
	await death_sound.finished
	queue_free()									# 적 노드 삭제

# 아이템 드랍 함수
func drop_item():
	# 골드
	var gold_chance = randf()
	if gold_chance <= 0.5:								# 드랍 확률 조정 (0.0~1.0)
		var new_gold = gold_img.instantiate()
		new_gold.global_position = global_position
		get_parent().call_deferred("add_child", new_gold)
	# 경험치
	var exp_chance = randf()
	if exp_chance <= 0.7:								# 드랍 확률 조정 (0.0~1.0)
		var new_exp = exp_img.instantiate()
		new_exp.global_position = global_position + Vector2(10, 0)
		get_parent().call_deferred("add_child", new_exp)
	# 음식(체력회복)	FIXME 일단 보스몬스터를 처치하였을 때 드롭되는 것으로 설정 게임 개발 방향에 따라 추후 수정 필요
	var new_food = food_img.instantiate()
	new_food.global_position = global_position + Vector2(5, -5)
	get_parent().call_deferred("add_child", new_food)

# 넉백 함수
func apply_knockback(attacker: Node2D):
	# 방향 : (적의 위치 - 공격자=플레이어 위치)
	var direction    = (position - attacker.position).normalized()
	knockback_vector = direction * knockback_strength
	knockback_time   = knockback_duration

# 파이어볼 인스턴스
func fireball():
	var fireball = fireball_tscn.instantiate()
	# 왼쪽
	if body_animated_sprite.flip_h:
		fireball.global_position = self.global_position + Vector2(-120, -15)
	# 오른쪽
	else:
		fireball.global_position = self.global_position + Vector2(120, -15)
	fireball.direction = (player.global_position - fireball.global_position).normalized()
	fireball.rotation = (player.global_position - fireball.global_position).angle()
	get_parent().add_child(fireball)

# 접촉 상태가 되었을 때
func _on_interaction_sensor_body_entered(_body:Node2D):
	if _body == player and not touch_flag:
		player.process_collision_enemy(damage)
		touch_flag = true
		# print(touch_flag)

# 접촉 상태에서 벗어날 때
func _on_interaction_sensor_body_exited(_body:Node2D):
	if _body == player:
		touch_flag = false
	
func _on_interaction_sensor_area_entered(area:Area2D):
	if area.is_in_group("attack"):
		var take_damage = area.get_parent().attack_damage
		health -= take_damage       # TODO area.damage가 무기 추가 후 각 공격에 맞는 damage가 들어오는지 확인할 필요가 있음
		DamageVisual.show_damage(take_damage, self.position)
		if health <= 0:
			die_enemy()
			return
		else:
			apply_knockback(area.get_parent())
			# 데미지 모션 추가
			hit_flag = true
			body_animated_sprite.stop()						# 현재 애니메이션(walk)을 중지시킴
			body_animated_sprite.speed_scale = 2.0
			body_animated_sprite.play("take_hit")
			await body_animated_sprite.animation_finished
		hit_flag = false

func _on_attack_timer_timeout():
	is_attacking = true
	body_animated_sprite.play("attack")
	await body_animated_sprite.animation_finished
	fireball()
	is_attacking = false
	# 타이머 재시작
	$AttackTimer.start()
