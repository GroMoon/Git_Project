extends CharacterBase

const LIGHTNING_RANGE = 380.0		# 번개 대상 탐색 범위 (밸런스: 450 → 380)

var lightning = preload("res://dynamic/1_player/characters/Wizard/Lightning/lightning.tscn")

func _initialize():
	# 캐릭터 특성
	character_name      = "wizard"
	move_speed          = 150
	attack_damage       = 12		# 밸런스: 16 → 12 (원거리 자동 조준 + 범위 피해라 근접보다 낮게)
	magnetic_area_scale = 100
	animation_speed     = 1.5
	start_hp            = 55.0
	attack_wait_time    = 0.95		# 밸런스: 0.55 → 0.95 (번개가 너무 자주 나가던 문제)
	attack_anim_speed   = 1.6

func _ready():
	_initialize()
	super._ready()

func _physics_process(_delta):
	super._physics_process(_delta)


func cast_lightning(target: Node2D):
	var lightning_instance = lightning.instantiate()
	lightning_instance.global_position = target.global_position
	lightning_instance.scale = Vector2.ONE * area_mult * signature_area_mult
	get_parent().add_child(lightning_instance)

# 범위 내 적을 가까운 순으로 count개 (이미 고른 적은 제외)
func get_closest_enemies(count: int) -> Array:
	var candidates = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var d = global_position.distance_to(enemy.global_position)
		if d < LIGHTNING_RANGE:
			candidates.append([d, enemy])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var result = []
	for i in min(count, candidates.size()):
		result.append(candidates[i][1])
	return result

func _on_attack_timer_timeout():
	# 사망 시 공격 모션 비활성화를 위한 조건
	if is_dead:
		return
	var targets = get_closest_enemies(attack_times + amount_bonus)
	# 주변에 적이 없으면 잠시 후 다시 확인
	if targets.is_empty():
		attack_timer.wait_time = 0.25
		attack_timer.start()
		return
	is_attacking = true
	animated_sprite.speed_scale = animation_speed
	animated_sprite.flip_h = targets[0].global_position.x < global_position.x

	# pause 해제 대기 후 시전 모션 1회
	if not await wait_for_pause_resume():
		is_attacking = false
		return
	animation_player.play("attack")
	await animation_player.animation_finished
	is_attacking = false		# 시전 모션이 끝나면 다시 이동 가능
	# 번개를 짧은 간격으로 연속 시전
	for target in targets:
		if is_dead:
			break
		if not await wait_for_pause_resume():
			is_attacking = false
			return
		# 대상이 이미 죽었으면 다른 가까운 적에게
		if not is_instance_valid(target) or not target.is_in_group("enemy"):
			var others = get_closest_enemies(1)
			if others.is_empty():
				continue
			target = others[0]
		cast_lightning(target)
		await get_tree().create_timer(0.08, false).timeout

	is_attacking = false
	# 타이머 재시작
	attack_timer.wait_time = get_attack_wait_time()
	attack_timer.start()

func _on_damage_timer_timeout():
	damage_flag = false
