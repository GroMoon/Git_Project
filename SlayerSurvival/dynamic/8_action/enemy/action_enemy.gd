extends "res://dynamic/8_action/core/actor.gd"
## 적 : 피격 리액션 + AI
##   피격 : 경직 / 넉백 / 띄우기·공중콤보 / 다운 / 기상 / 가드(스켈레톤) / 슈퍼아머(엘리트)
##   보너스 : 공격 준비 중에 맞히면 COUNTER, 등 뒤에서 맞히면 BACK ATTACK
##   AI : 공격권(토큰)이 있으면 접근해서 공격, 없으면 주변에서 대기하며 포위
## 생성 후 add_child 전에 setup(kind, elite)을 호출한다.

const Combat       = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet  = preload("res://dynamic/8_action/core/sprite_sheet.gd")
const EnemyDefs    = preload("res://dynamic/8_action/enemy/enemy_defs.gd")
const Projectile   = preload("res://dynamic/8_action/enemy/projectile.gd")
const ActionPlayer = preload("res://dynamic/8_action/player/action_player.gd")

enum State { IDLE, CHASE, ATTACK, HURT, AIR, DOWN, GETUP, GUARD, DEAD }

const AIR_GRAVITY_SCALE := 0.8		# 공중 체공감을 위해 중력을 살짝 낮춤
const DOWN_TIME         := 0.65
const GETUP_TIME        := 0.22
const MAX_DOWN_BOUNCES  := 2		# 다운 추가타로 튕길 수 있는 횟수
const ARMOR_BREAK_TIME  := 4.0		# 슈퍼아머가 깨진 뒤 다시 생기기까지
const COUNTER_BONUS     := 1.25
const BACK_ATTACK_BONUS := 1.1

var kind := ""
var def  : Dictionary = {}
var display_name := ""
var bar_lines    := 1
var elite        := false

var state        := State.IDLE
var velocity     := Vector2.ZERO	# 넉백 등 바닥 이동 속도
var power        := 1000.0
var move_speed   := Vector2(120, 80)
var attack_cooldown := 2.0
var hover         := 0.0			# 비행 높이 (0 = 지상형)
var guard_chance  := 0.0
var keep_distance := 0.0			# 원거리형 유지 거리
var armor_max     := 0.0
var armor         := 0.0
var launch_scale  := 1.0			# 띄우기/넉백 배율 (보스는 무거움)
var gold          := 10

var _attack_cd    := 1.0
var _think        := 0.0
var _hurt_timer   := 0.0
var _down_timer   := 0.0
var _guard_timer  := 0.0
var _invuln_timer := 0.0
var _armor_break_timer := 0.0
var _air_hits     := 0
var _down_bounces := 0
var _dead_landed  := false
var _fade_time    := 0.0

## 대기(포위) 위치
var _wait_dist   := 220.0
var _lane_offset := 0.0
var _reposition_timer := 0.0

## 끌어오기(몰이)용 슬라이드
var _slide_from := Vector2.ZERO
var _slide_to   := Vector2.ZERO
var _slide_t    := 1.0
var _slide_time := 0.1

## 공격 진행
var _attack      : Dictionary = {}
var _attack_time := 0.0
var _attack_frame := -1
var _attack_hit_log := []
var _step_speed  := 0.0
var _step_time   := 0.0

var fx : Node = null
var _death_sound : AudioStream = null
var _attack_sound : AudioStream = null

func setup(kind_name: String, is_elite := false):
	kind = kind_name
	elite = is_elite
	def = EnemyDefs.get_def(kind, is_elite)
	display_name    = def.name
	bar_lines       = def.bar_lines
	max_hp          = def.hp
	power           = def.power
	move_speed      = def.speed
	attack_cooldown = def.cooldown
	sprite_scale    = def.scale
	sprite_offset   = def.offset
	body_height     = def.body_height
	body_radius     = def.body_radius
	hover           = def.get("hover", 0.0)
	guard_chance    = def.get("guard_chance", 0.0)
	keep_distance   = def.get("keep_distance", 0.0)
	armor_max       = def.armor
	armor           = armor_max
	launch_scale    = def.get("launch_scale", 1.0)
	gold            = def.gold
	sheet_faces_left = def.get("faces_left", false)
	shadow_size     = Vector2(body_radius * 3.4, 16)
	z = hover

func _ready():
	super._ready()
	add_to_group("action_enemy")
	sprite.sprite_frames = SpriteSheet.build("enemy_" + kind, def.sheets)
	play_anim("idle")
	fx = stage.fx if stage else get_tree().get_first_node_in_group("combat_fx")
	_death_sound = load(def.death_sound)
	if def.has("attack_sound"):
		_attack_sound = load(def.attack_sound)
	_attack_cd = randf_range(0.6, 1.8)
	_pick_wait_spot()

func _physics_process(delta):
	_tick_effects(delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	if _armor_break_timer > 0.0:
		_armor_break_timer -= delta
		if _armor_break_timer <= 0.0:
			armor = armor_max
	match state:
		State.IDLE, State.CHASE:
			_ai(delta)
			_keep_hover(hover, delta)
		State.ATTACK:
			_state_attack(delta)
		State.HURT:
			_state_hurt(delta)
			_keep_hover(hover, delta)
		State.AIR:
			_state_air(delta)
		State.DOWN:
			_state_down(delta)
		State.GETUP:
			_state_getup(delta)
		State.GUARD:
			_state_guard(delta)
		State.DEAD:
			_state_dead(delta)
	_update_slide(delta)
	_update_visual()

func has_super_armor() -> bool:
	return armor_max > 0.0 and armor > 0.0 and _armor_break_timer <= 0.0

## 비행형 : 목표 높이로 부드럽게 이동 (중력 없음)
func _keep_hover(target: float, delta: float):
	if hover <= 0.0:
		return
	z_velocity = 0.0
	z = move_toward(z, target, 160.0 * delta)

# ───────────────────────────── 피격 ─────────────────────────────

func can_be_hit() -> bool:
	return state != State.DEAD and state != State.GETUP and _invuln_timer <= 0.0

func get_hurt_height() -> float:
	return 36.0 if state == State.DOWN else body_height

func receive_hit(atk: Dictionary, attacker: Node2D, damage: int):
	if state == State.DEAD:
		return
	var dx: float = attacker.position.x - position.x
	var from_front := absf(dx) < 4.0 or signf(dx) == facing
	var heavy: bool = atk.launch > 0.0 or atk.spark == "heavy"
	var hit_pos := get_hit_point(attacker.facing)

	# 가드 (정면 일반 공격) / 가드 브레이크 (강공격)
	var can_guard := guard_chance > 0.0 and from_front and (state == State.IDLE or state == State.CHASE)
	if state == State.GUARD or (can_guard and not heavy and randf() < guard_chance):
		if from_front and not heavy:
			_guard_hit(atk, attacker, damage, hit_pos)
			return
		if state == State.GUARD and fx:
			fx.spawn_text("GUARD BREAK", hit_pos + Vector2(0, -70), Color(1.0, 0.45, 0.3), 26)
			damage = int(damage * 1.2)

	# 카운터 / 백어택 보너스 (용암 등 환경 피해는 제외)
	if atk.get("environment", false):
		pass
	elif state == State.ATTACK and _attack_frame < _first_hit_frame():
		damage = int(damage * COUNTER_BONUS)
		if fx:
			fx.spawn_text("COUNTER!", hit_pos + Vector2(0, -72), Color(1.0, 0.55, 0.15), 26)
			fx.hitstop(0.06)
	elif not from_front:
		damage = int(damage * BACK_ATTACK_BONUS)
		if fx:
			fx.spawn_text("BACK ATTACK", hit_pos + Vector2(0, -72), Color(0.55, 0.85, 1.0), 22)

	hp -= damage
	if fx:
		fx.spawn_spark(hit_pos, atk.spark, attacker.facing)
		if damage > 0:
			var critical: bool = atk.damage >= 1.5 or atk.get("crit", false)
			fx.spawn_damage(damage, hit_pos + Vector2(0, -34), "critical" if critical else "normal")
	hit_shake(0.14, 3.0)

	# 슈퍼아머 : 경직 없이 버티다가 내구도가 다 닳으면 ARMOR BREAK
	if has_super_armor() and hp > 0.0:
		armor -= atk.damage
		if armor > 0.0:
			flash(0.09, Color(1.0, 0.8, 0.3))
			velocity.x = attacker.facing * atk.knockback * 0.15
			return
		_armor_break_timer = ARMOR_BREAK_TIME
		if fx:
			fx.spawn_text("ARMOR BREAK!", hit_pos + Vector2(0, -95), Color(1.0, 0.85, 0.2), 30)
			fx.hitstop(0.12)
			fx.shake(8.0)
	flash(0.09)
	_release_token()
	facing = -attacker.facing

	# 몰이 : 깊이를 공격자 라인으로 정렬 + (pull) 공격자 앞으로 끌어오기
	var target := position
	target.y = lerpf(position.y, attacker.position.y, atk.align)
	if atk.pull >= 0.0:
		target.x = attacker.position.x + attacker.facing * (atk.pull + randf_range(-14.0, 14.0))
	elif atk.vacuum >= 0.0:
		var side := 1.0 if position.x >= attacker.position.x else -1.0
		target.x = attacker.position.x + side * (atk.vacuum + randf_range(0.0, 16.0))
	_start_slide(target, 0.09)
	velocity = Vector2(attacker.facing * atk.knockback * launch_scale, 0.0)

	if hp <= 0.0:
		_die(attacker, atk)
		return

	if state == State.DOWN:
		# 다운된 적 추가타 : 제한 횟수만큼 살짝 튕김
		if _down_bounces < MAX_DOWN_BOUNCES:
			_down_bounces += 1
			z_velocity = 170.0
			state = State.AIR
		return

	if is_airborne() or state == State.AIR:
		# 공중 콤보 : 맞을수록 덜 뜨게 해서 무한 콤보 방지 (비행형은 맞으면 추락)
		_air_hits += 1
		var lift: float = atk.launch if atk.launch > 0.0 else atk.juggle
		lift *= maxf(0.3, 1.0 - 0.09 * _air_hits) * launch_scale
		if z > 260.0:
			lift *= 0.4
		z_velocity = maxf(z_velocity, lift)
		state = State.AIR
	elif atk.launch > 0.0 or atk.knockdown:
		_air_hits = 0
		z_velocity = (atk.launch if atk.launch > 0.0 else 260.0) * launch_scale
		state = State.AIR
	else:
		_hurt_timer = atk.hitstun
		state = State.HURT
		sprite.stop()
		sprite.play("hit")

func _guard_hit(atk: Dictionary, attacker: Node2D, damage: int, hit_pos: Vector2):
	hp = maxf(1.0, hp - maxi(1, int(damage * 0.1)))
	state = State.GUARD
	_guard_timer = 0.5
	facing = -attacker.facing
	velocity = Vector2(attacker.facing * atk.knockback * 0.5, 0.0)
	play_anim("shield")
	flash(0.06, Color(0.6, 0.8, 1.0))
	if fx:
		fx.spawn_spark(hit_pos, "blunt", attacker.facing, Color(0.55, 0.75, 1.0))
		fx.spawn_text("GUARD", hit_pos + Vector2(0, -50), Color(0.7, 0.85, 1.0), 20)

func _state_guard(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_ground(velocity, delta)
	play_anim("shield")
	_guard_timer -= delta
	if _guard_timer <= 0.0:
		state = State.IDLE
		_attack_cd = minf(_attack_cd, 0.25)		# 막고 나서 바로 반격

func _state_hurt(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	move_ground(velocity, delta)
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		state = State.IDLE
		_think = randf_range(0.1, 0.35)

func _state_air(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
	move_ground(Vector2(velocity.x, 0.0), delta)
	show_frame("hit", 2)
	# 뒤로 젖혀지는 자세
	visual.rotation = lerpf(visual.rotation, -facing * 0.6, 8.0 * delta)
	var fall_speed := -z_velocity
	if update_air(delta, AIR_GRAVITY_SCALE):
		if fall_speed > 520.0 and _down_bounces == 0:
			# 세게 떨어지면 한 번 바운드
			_down_bounces = 1
			z_velocity = 190.0
			if fx:
				fx.shake(2.0)
			return
		_enter_down()

func _enter_down():
	state = State.DOWN
	_down_timer = DOWN_TIME
	velocity = Vector2.ZERO
	show_frame("hit", 3)

func _state_down(delta: float):
	visual.rotation = lerpf(visual.rotation, -facing * PI * 0.5, 20.0 * delta)
	_down_timer -= delta
	if _down_timer <= 0.0:
		state = State.GETUP
		_down_timer = GETUP_TIME

func _state_getup(delta: float):
	visual.rotation = lerpf(visual.rotation, 0.0, 14.0 * delta)
	show_frame("idle", 0)
	_down_timer -= delta
	if _down_timer <= 0.0:
		visual.rotation = 0.0
		state = State.IDLE
		_invuln_timer = 0.2
		_air_hits = 0
		_down_bounces = 0
		_think = randf_range(0.2, 0.5)

## 끌어오기 슬라이드 (히트스탑 동안 거의 멈춰 있다가 풀리면서 빨려 들어감)
func _start_slide(to: Vector2, duration: float):
	_slide_from = position
	_slide_to = to
	_slide_t = 0.0
	_slide_time = duration

func _update_slide(delta: float):
	if _slide_t >= 1.0:
		return
	_slide_t = minf(1.0, _slide_t + delta / _slide_time)
	position = _slide_from.lerp(_slide_to, ease(_slide_t, 0.5))
	if stage:
		position = stage.clamp_to_floor(position)

# ───────────────────────────── 사망 ─────────────────────────────

func _die(attacker: Node2D, atk: Dictionary):
	state = State.DEAD
	remove_from_group("action_enemy")
	_release_token()
	z_velocity = maxf(z_velocity, 420.0)
	velocity = Vector2(attacker.facing * maxf(atk.knockback, 260.0), 0.0)
	if fx and _death_sound:
		fx.play_sound(_death_sound, 0.08, -3.0)
	died.emit(self)

func _state_dead(delta: float):
	if not _dead_landed:
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		move_ground(Vector2(velocity.x, 0.0), delta)
		visual.rotation = lerpf(visual.rotation, -facing * 0.9, 6.0 * delta)
		show_frame("hit", 2)
		if update_air(delta, 0.9):
			_dead_landed = true
			visual.rotation = 0.0
			sprite.play("death")
		return
	_fade_time += delta
	if _fade_time > 0.7:
		modulate.a = maxf(0.0, 1.0 - (_fade_time - 0.7) / 0.4)
		if modulate.a <= 0.0:
			queue_free()

# ───────────────────────────── AI ─────────────────────────────

func _ai(delta: float):
	_attack_cd -= delta
	var player: Node2D = stage.player if stage else null
	if player == null or player.is_dead():
		state = State.IDLE
		play_anim("idle")
		return

	var dx := player.position.x - position.x
	var dy := player.position.y - position.y
	if absf(dx) > 6.0:
		facing = 1 if dx > 0.0 else -1

	# 공격 : 거리/라인 조건에 맞는 공격 중 랜덤 (동시 공격 인원 제한)
	if _attack_cd <= 0.0 and player.state != ActionPlayer.State.DOWN:
		var options := []
		for option in def.attacks:
			if absf(dx) >= option.range[0] and absf(dx) <= option.range[1] and absf(dy) <= option.lane:
				options.append(option)
		if not options.is_empty() and stage.request_attack_token(self):
			_start_attack(options.pick_random())
			return

	_think -= delta
	if _think > 0.0:
		state = State.IDLE
		play_anim("idle")
		return

	_reposition_timer -= delta
	if _reposition_timer <= 0.0:
		_pick_wait_spot()

	# 공격 차례면 공격 거리로, 아니면 주변 대기 위치로 (내가 있는 쪽 기준 → 자연스럽게 포위)
	var side := -facing
	var engage: bool = _attack_cd <= 0.0 and stage.can_take_attack_token(self)
	var desired: Vector2
	if engage:
		var dist := keep_distance if keep_distance > 0.0 else _melee_distance()
		desired = Vector2(player.position.x + side * dist, player.position.y)
	else:
		desired = Vector2(player.position.x + side * _wait_dist, player.position.y + _lane_offset)
	var to := desired - position
	for other in get_tree().get_nodes_in_group("action_enemy"):
		if other == self:
			continue
		var away: Vector2 = position - other.position
		var dist := away.length()
		if dist < 46.0 and dist > 0.01:
			to += away / dist * (46.0 - dist) * 2.0
	if to.length() > 10.0:
		state = State.CHASE
		var dir := to.normalized()
		var speed_scale := 1.0 if engage else 0.55
		move_ground(Vector2(dir.x * move_speed.x, dir.y * move_speed.y) * speed_scale, delta)
		play_anim("run")
	else:
		state = State.IDLE
		play_anim("idle")

func _melee_distance() -> float:
	var best := 9999.0
	for option in def.attacks:
		best = minf(best, option.range[1])
	return best * 0.7

func _pick_wait_spot():
	_wait_dist = randf_range(190.0, 320.0)
	_lane_offset = randf_range(-70.0, 70.0)
	_reposition_timer = randf_range(1.5, 3.0)

func _first_hit_frame() -> int:
	if _attack.has("projectile"):
		return _attack.projectile.frame
	var first := 99
	for hit in _attack.get("hits", []):
		first = mini(first, hit.from)
	return first

func _start_attack(option: Dictionary):
	state = State.ATTACK
	_attack = option
	_attack_time = 0.0
	_attack_frame = -1
	_step_time = 0.0
	_attack_hit_log.clear()
	# 공격 예고 : 붉게 번쩍 (+ 큰 공격은 바닥에 위험 범위 표시)
	flash(0.18, Color(1.0, 0.25, 0.15))
	if option.get("telegraph", false) and fx:
		var first := _first_hit_frame()
		var windup := 0.0
		for i in mini(first, option.frame_times.size()):
			windup += option.frame_times[i]
		for hit in option.hits:
			var atk: Dictionary = hit.attack
			var x0: float = position.x + facing * -atk.back
			var x1: float = position.x + facing * atk.reach
			fx.spawn_telegraph(Rect2(minf(x0, x1), position.y - atk.depth, absf(x1 - x0), atk.depth * 2.0), windup)

func _state_attack(delta: float):
	_attack_time += delta
	var frame: int = ActionPlayer.frame_at(_attack.frame_times, _attack_time)
	if frame < 0:
		_finish_attack()
		return
	if frame != _attack_frame:
		_attack_frame = frame
		show_frame(_attack.anim, _attack.frames[frame] if _attack.has("frames") else frame)
		_on_attack_frame(frame)

	if _step_time > 0.0:
		_step_time -= delta
		move_ground(Vector2(facing * _step_speed, 0.0), delta)
	# 비행형 급강하
	if hover > 0.0:
		var diving: bool = _attack.get("dive", false) and frame >= 2 and frame < _attack.frame_times.size() - 1
		_keep_hover(20.0 if diving else hover, delta * 2.5)

	var player: Node2D = stage.player
	for hit in _attack.get("hits", []):
		if frame < hit.from or frame > hit.to:
			continue
		if player in _attack_hit_log or not player.can_be_hit():
			continue
		if Combat.overlaps(self, hit.attack, player):
			_attack_hit_log.append(player)
			player.receive_hit(hit.attack, self, Combat.roll_damage(power, hit.attack))

func _finish_attack():
	state = State.IDLE
	_attack_cd = attack_cooldown * randf_range(0.8, 1.3)
	_think = randf_range(0.15, 0.4)
	_release_token()

func _on_attack_frame(frame: int):
	if _attack.get("sound_frame", -1) == frame and fx and _attack_sound:
		fx.play_sound(_attack_sound, 0.05, -2.0)
	for step in _attack.get("steps", []):
		if step.frame == frame:
			_step_speed = step.speed
			_step_time = step.time
	if _attack.has("projectile") and _attack.projectile.frame == frame:
		_fire_projectile(_attack.projectile)

func _fire_projectile(data: Dictionary, depth_offset := 0.0):
	var shot := Projectile.new()
	shot.attack = data.attack
	shot.power = power
	shot.speed = data.speed
	shot.facing = facing
	shot.z = z + data.z
	shot.sheet = data.sheet
	shot.stage = stage
	shot.max_distance = data.get("max_distance", 620.0)
	shot.position = stage.clamp_to_floor(position + Vector2(facing * data.get("muzzle", 40.0), depth_offset))
	stage.actors.add_child(shot)

func _release_token():
	if stage:
		stage.release_attack_token(self)
