extends "res://dynamic/8_action/core/actor.gd"
## 플레이어 조작 : 이동 / 대시(→→) / 점프 / 백스텝 / 콤보 공격
## 캐릭터별 데이터(시트, 기술)는 하위 스크립트의 _setup_character()에서 채운다.
##
## 기술(move) 정의
##   "anim"         : 애니메이션 이름
##   "frame_offset" : 시트의 몇 번째 프레임부터 쓸지 (기본 0)
##   "frame_times"  : 프레임별 표시 시간(초) — 타격 타이밍을 프레임 단위로 조절
##   "hits"         : [{"from": f, "to": f, "attack": Combat.attack({...})}]  해당 프레임 동안 판정
##   "steps"        : [{"frame": f, "speed": px/s, "time": 초}]  전진 스텝
##   "swing"        : {"frame": f, "sound": 키}  휘두르는 소리
##   "cancel"       : 이 프레임부터 다음 기술로 캔슬 가능
##   "next"         : X 입력 시 이어질 기술
##   "air"          : 공중 기술 (중력 적용, 착지 시 종료)
##   "frames"       : 기술 프레임 → 시트 프레임 매핑 (회전 베기처럼 같은 프레임을 반복할 때)
##   "skill"        : {"name", "cooldown", "mp", "icon": Vector2i}  스킬 (A/S/D/F 슬롯에 등록)
##   "skill_cancel" : 평타 중 이 프레임부터 스킬로 캔슬 가능 (기본: 첫 타격 프레임)
##   "super_armor"  : 맞아도 경직 없음      "invuln" : 기술 동안 무적
##   "mobile"       : 기술 중 방향키로 이동  "afterimage" : 잔상
##   "events"       : [{"frame": f, "type": "flash"/"shockwave"/"zoom"/"shake"/"banner"/"whirl", ...}]
##   "spawns"       : [{"frame": f, "type": ...}]  마법/투사체 생성 → _on_spawn() (캐릭터별)

signal hp_changed(hp: float, max_hp: float)
signal mp_changed(mp: float, max_mp: float)
signal hit_landed(target: Node)
signal skill_used(move_id: String)
signal revived(remaining: int)

const Combat      = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

enum State { IDLE, MOVE, RUN, JUMP, BACKSTEP, ATTACK, HURT, AIR_HURT, DOWN, DEAD }

const DOUBLE_TAP_TIME := 0.25	# 대시 더블탭 인식 시간
const ATTACK_BUFFER   := 0.3	# 공격 선입력 유지 시간
const JUMP_BUFFER     := 0.12

## 이동 수치
@export var walk_speed   := Vector2(260, 170)		# (가로, 깊이)
@export var run_speed    := Vector2(480, 200)
@export var jump_power   := 640.0
@export var attack_power := 1200.0
@export var max_mp       := 1000.0
@export var mp_regen     := 35.0		# 초당 MP 회복

## 캐릭터 데이터 (하위 스크립트에서 채움)
var sheet_key := ""
var sheets    := {}
var moves     := {}
var display_name := ""
## 스킬 슬롯 : [{"action": "act_skill_1", "key": "A", "move": "upper_slash"}, ...]
var skill_slots := []

var mp        := 1000.0
var cooldowns := {}				# move_id → 남은 쿨타임
var _skill_buffer := ""
var _skill_buffer_time := 0.0
var _afterimage_timer := 0.0

var state      := State.IDLE
var velocity   := Vector2.ZERO		# 점프/넉백 중 바닥 이동 속도
var is_running := false

## 기술 진행 상태
var move          : Dictionary = {}
var move_name     := ""
var move_time     := 0.0
var move_frame    := -1
var _move_hit_log := []				# hit 항목별로 이미 맞은 대상
var _step_speed   := 0.0
var _step_time    := 0.0
var _air_attack_used := false

## 입력 상태
var attack_buffer  := 0.0
var jump_buffer    := 0.0
var _last_tap_dir  := 0
var _last_tap_time := -10.0

## 피격 상태
var hurt_timer   := 0.0
var down_timer   := 0.0
var invuln_timer := 0.0
var hits_taken   := 0		# 결과 랭크 계산용

## 상점 업그레이드 (Global.character_data["CHARACTER_STORE_UPGRADES"]) 반영 값
var damage_reduction := 0.0		# shield : 받는 피해 감소율
var lifesteal        := 0.0		# vampire : 준 피해의 일부 회복
var revives          := 0		# respawn : 사망 시 부활 횟수
var cooldown_scale   := 1.0		# cooldown : 스킬 쿨타임 배율
var gold_bonus       := 0.0		# gold_drop : 골드 추가 획득률

var fx : Node = null

func _setup_character():
	pass

## 기존 상점 업그레이드를 액션 모드 수치로 환산
##   health +10/레벨 → 최대 HP +1000  |  damage +2/레벨 → 공격력 +4%
##   speed +5/레벨 → 이동 속도 +2%    |  cooldown +0.2/레벨 → 스킬 쿨타임 -4%
##   shield, vampire, gold_drop 는 비율 그대로, gem_drop → MP 회복 속도, respawn → 부활 횟수
func apply_store_upgrades():
	if not Global.character_data.has("CHARACTER_STORE_UPGRADES"):
		return
	var up: Dictionary = Global.character_data["CHARACTER_STORE_UPGRADES"]
	max_hp       += float(up.get("health", 0)) * 100.0
	attack_power *= 1.0 + float(up.get("damage", 0)) * 0.02
	walk_speed   *= 1.0 + float(up.get("speed", 0)) * 0.004
	run_speed    *= 1.0 + float(up.get("speed", 0)) * 0.004
	cooldown_scale = maxf(0.5, 1.0 - float(up.get("cooldown", 0)) * 0.2)
	damage_reduction = clampf(float(up.get("shield", 0)), 0.0, 0.6)
	lifesteal    = float(up.get("vampire", 0))
	gold_bonus   = float(up.get("gold_drop", 0)) * 2.5
	mp_regen     *= 1.0 + float(up.get("gem_drop", 0)) * 2.5
	revives      = int(up.get("respawn", 0))

func _ready():
	_setup_character()
	apply_store_upgrades()
	super._ready()
	add_to_group("action_player")
	sprite.sprite_frames = SpriteSheet.build(sheet_key, sheets)
	play_anim("idle")
	fx = get_tree().get_first_node_in_group("combat_fx")
	mp = max_mp
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)

func _physics_process(delta):
	_tick_effects(delta)
	_read_input(delta)
	_tick_skills(delta)
	invuln_timer = maxf(0.0, invuln_timer - delta)
	match state:
		State.IDLE, State.MOVE, State.RUN:
			_state_ground(delta)
		State.JUMP:
			_state_jump(delta)
		State.BACKSTEP:
			_state_backstep(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HURT:
			_state_hurt(delta)
		State.AIR_HURT:
			_state_air_hurt(delta)
		State.DOWN:
			_state_down(delta)
		State.DEAD:
			_state_dead(delta)
	_update_visual()
	# 무적 중 깜빡임
	var blink := invuln_timer > 0.0 and state != State.BACKSTEP and state != State.ATTACK \
			and (Time.get_ticks_msec() / 70) % 2 == 0
	visual.modulate.a = 0.45 if blink else 1.0

# ───────────────────────────── 입력 ─────────────────────────────

func _input_dir() -> Vector2:
	return Vector2(Input.get_axis("act_left", "act_right"), Input.get_axis("act_up", "act_down"))

func _read_input(delta: float):
	attack_buffer = maxf(0.0, attack_buffer - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if state == State.DEAD:
		return
	if Input.is_action_just_pressed("act_attack"):
		attack_buffer = ATTACK_BUFFER
	if Input.is_action_just_pressed("act_jump"):
		jump_buffer = JUMP_BUFFER
	for slot in skill_slots:
		if Input.is_action_just_pressed(slot.action):
			_skill_buffer = slot.move
			_skill_buffer_time = 0.25
	# 대시 : 같은 방향 더블탭
	for dir in [-1, 1]:
		var action := "act_right" if dir == 1 else "act_left"
		if Input.is_action_just_pressed(action):
			var now := Time.get_ticks_msec() / 1000.0
			is_running = _last_tap_dir == dir and now - _last_tap_time <= DOUBLE_TAP_TIME
			_last_tap_dir = dir
			_last_tap_time = now

# ───────────────────────────── 지상 ─────────────────────────────

func _state_ground(delta: float):
	if _try_skill():
		return
	if jump_buffer > 0.0:
		_start_jump()
		return
	if Input.is_action_just_pressed("act_backstep"):
		_start_backstep()
		return
	if attack_buffer > 0.0:
		var dash := state == State.RUN and moves.has("dash_attack")
		_start_move("dash_attack" if dash else "atk1")
		return

	var dir := _input_dir()
	if dir.x == 0.0:
		is_running = false
	if dir == Vector2.ZERO:
		state = State.IDLE
		sprite.speed_scale = 1.0
		play_anim("idle")
		return

	if dir.x != 0.0:
		facing = 1 if dir.x > 0.0 else -1
	var speed := run_speed if is_running else walk_speed
	move_ground(Vector2(dir.x * speed.x, dir.y * speed.y), delta)
	state = State.RUN if is_running else State.MOVE
	sprite.speed_scale = 1.4 if is_running else 1.0
	play_anim("run")

# ───────────────────────────── 점프 / 백스텝 ─────────────────────────────

func _start_jump():
	jump_buffer = 0.0
	attack_buffer = 0.0
	state = State.JUMP
	_air_attack_used = false
	z_velocity = jump_power
	var dir := _input_dir()
	var speed := run_speed if is_running else walk_speed
	velocity = Vector2(dir.x * speed.x, dir.y * speed.y * 0.6)
	sprite.speed_scale = 1.0

func _state_jump(delta: float):
	move_ground(velocity, delta)
	if attack_buffer > 0.0 and moves.has("jump_attack") and not _air_attack_used:
		_air_attack_used = true
		_start_move("jump_attack")
		return
	if update_air(delta):
		_land()
		return
	_show_air_frame()

func _show_air_frame():
	if z_velocity > jump_power * 0.45:
		show_frame("jump", 0)
	elif z_velocity > 0.0:
		show_frame("jump", 2)
	else:
		play_anim("fall")

func _start_backstep():
	state = State.BACKSTEP
	is_running = false
	z_velocity = 300.0
	velocity = Vector2(-facing * 520.0, 0.0)
	invuln_timer = 0.3

func _state_backstep(delta: float):
	move_ground(velocity, delta)
	show_frame("jump", 1)
	if update_air(delta):
		_land()

func _land():
	velocity = Vector2.ZERO
	state = State.IDLE
	play_anim("idle")

# ───────────────────────────── 공격 기술 ─────────────────────────────

func _start_move(move_id: String):
	move_name = move_id
	move = moves[move_id]
	move_time = 0.0
	move_frame = -1
	_step_time = 0.0
	attack_buffer = 0.0
	jump_buffer = 0.0
	_move_hit_log.clear()
	for i in move.hits.size():
		_move_hit_log.append([])
	state = State.ATTACK
	sprite.speed_scale = 1.0
	_afterimage_timer = 0.0
	if move.get("invuln", false):
		var total := 0.0
		for t in move.frame_times:
			total += t
		invuln_timer = maxf(invuln_timer, total)
	# 콤보 단계마다 방향 전환 허용 (뒤쪽 적 처리)
	if not move.get("air", false):
		var dx := Input.get_axis("act_left", "act_right")
		if dx != 0.0:
			facing = 1 if dx > 0.0 else -1
	_advance_move(0.0)

func _state_attack(delta: float):
	move_time += delta
	_advance_move(delta)

func _advance_move(delta: float):
	var frame := frame_at(move.frame_times, move_time)
	if frame < 0:
		_end_move()
		return
	if frame != move_frame:
		move_frame = frame
		var sheet_frame: int = move.frames[frame] if move.has("frames") else move.get("frame_offset", 0) + frame
		show_frame(move.anim, sheet_frame)
		_on_move_frame(frame)

	# 이동 가능한 스킬 (회오리 베기 등)
	if move.get("mobile", false):
		var dir := _input_dir()
		move_ground(Vector2(dir.x * walk_speed.x, dir.y * walk_speed.y) * 0.6, delta)
	# 잔상
	if move.get("afterimage", false) and fx:
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			_afterimage_timer = 0.03
			fx.spawn_afterimage(sprite)

	# 전진 스텝
	if _step_time > 0.0:
		_step_time -= delta
		move_ground(Vector2(facing * _step_speed, 0.0), delta)

	# 공중 기술 : 중력 + 관성
	if move.get("air", false):
		move_ground(velocity, delta)
		if update_air(delta):
			_land()
			return

	# 타격 판정
	for i in move.hits.size():
		var hit: Dictionary = move.hits[i]
		if frame >= hit.from and frame <= hit.to:
			_check_hits(hit.attack, _move_hit_log[i])

	# 평타 → 스킬 캔슬
	if not move.has("skill") and frame >= move.get("skill_cancel", _first_hit_frame(move)):
		if _try_skill():
			return

	# 캔슬 : 다음 기술 / 점프
	if frame >= move.get("cancel", 999):
		if attack_buffer > 0.0 and move.get("next", "") != "":
			_start_move(move.next)
		elif jump_buffer > 0.0 and not move.get("air", false):
			_start_jump()

func _on_move_frame(frame: int):
	for step in move.get("steps", []):
		if step.frame == frame:
			_step_speed = step.speed
			_step_time = step.time
	var swing: Dictionary = move.get("swing", {})
	if swing.get("frame", -1) == frame and fx:
		fx.play_swing(swing.sound)
	for swing_extra in move.get("swings", []):
		if swing_extra.frame == frame and fx:
			fx.play_swing(swing_extra.sound)
	for event in move.get("events", []):
		if event.frame == frame:
			_play_event(event)
	for spawn in move.get("spawns", []):
		if spawn.frame == frame:
			_on_spawn(spawn)

## 기술 중 마법/투사체 생성 (캐릭터별로 재정의)
func _on_spawn(_spawn: Dictionary):
	pass

## 기술 연출 이벤트
func _play_event(event: Dictionary):
	if fx == null:
		return
	match event.type:
		"flash":
			fx.flash_screen(event.get("color", Color(1, 1, 1, 0.7)), event.get("time", 0.18))
		"shockwave":
			fx.spawn_shockwave(position + Vector2(facing * event.get("offset", 0.0), 0.0), event.get("radius", 280.0))
			fx.play_hit_sound("heavy")
		"zoom":
			fx.zoom_punch(event.get("amount", 0.12), event.get("time", 0.35))
		"shake":
			fx.shake(event.get("power", 8.0))
		"banner":
			fx.spawn_text(event.text, position + Vector2(0, -z - body_height - 70.0), Color(1.0, 0.85, 0.3), 30)
		"whirl":
			fx.spawn_whirl(self, event.get("time", 0.6), event.get("radius", 130.0))

func _end_move():
	if move.get("air", false) and is_airborne():
		state = State.JUMP
		return
	state = State.IDLE
	play_anim("idle")

static func _first_hit_frame(move_def: Dictionary) -> int:
	var first := 99
	for hit in move_def.get("hits", []):
		first = mini(first, hit.from)
	return first

# ───────────────────────────── 스킬 ─────────────────────────────

func _tick_skills(delta: float):
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	if mp < max_mp and state != State.DEAD:
		mp = minf(max_mp, mp + mp_regen * delta)
		mp_changed.emit(mp, max_mp)
	if _skill_buffer != "":
		_skill_buffer_time -= delta
		if _skill_buffer_time <= 0.0:
			_skill_buffer = ""

func get_cooldown(move_id: String) -> float:
	return cooldowns.get(move_id, 0.0)

func can_use_skill(move_id: String) -> bool:
	var skill: Dictionary = moves[move_id].skill
	return get_cooldown(move_id) <= 0.0 and mp >= skill.mp

## 선입력된 스킬이 있으면 사용 (쿨타임/MP 부족이면 무시)
func _try_skill() -> bool:
	if _skill_buffer == "" or not can_use_skill(_skill_buffer):
		return false
	if is_airborne() and not moves[_skill_buffer].get("air", false):
		return false
	var move_id := _skill_buffer
	_skill_buffer = ""
	var skill: Dictionary = moves[move_id].skill
	mp -= skill.mp
	mp_changed.emit(mp, max_mp)
	cooldowns[move_id] = skill.cooldown * cooldown_scale
	is_running = false
	_start_move(move_id)
	skill_used.emit(move_id)
	return true

## frame_times 기준으로 경과 시간 t의 프레임 번호 (끝났으면 -1)
static func frame_at(times: Array, t: float) -> int:
	var acc := 0.0
	for i in times.size():
		acc += times[i]
		if t < acc:
			return i
	return -1

func _check_hits(atk: Dictionary, hit_log: Array):
	deal_hits(self, atk, hit_log)

## source(플레이어 자신 또는 마법 투사체 등)의 위치/방향 기준으로 판정해 적에게 피해를 준다.
## 대미지는 플레이어 공격력 기준, 콤보/흡혈/히트스탑도 플레이어 공격으로 처리. 맞힌 수를 반환.
func deal_hits(source: Node2D, atk: Dictionary, hit_log: Array, max_targets := 99) -> int:
	var count := 0
	for target in get_tree().get_nodes_in_group("action_enemy"):
		if count >= max_targets:
			break
		if target in hit_log or not target.can_be_hit():
			continue
		if Combat.overlaps(source, atk, target):
			hit_log.append(target)
			var dealt := Combat.roll_damage(attack_power, atk)
			target.receive_hit(atk, source, dealt)
			hit_landed.emit(target)
			count += 1
			if lifesteal > 0.0:
				heal(dealt * lifesteal)
	if count > 0 and fx:
		fx.on_attack_landed(atk, count)
		fx.add_combo(count)
	return count

# ───────────────────────────── 피격 ─────────────────────────────

## 방 이동 시 자세 초기화
func reset_pose():
	state = State.IDLE
	move = {}
	move_name = ""
	velocity = Vector2.ZERO
	z = 0.0
	z_velocity = 0.0
	visual.rotation = 0.0
	attack_buffer = 0.0
	jump_buffer = 0.0
	_skill_buffer = ""
	is_running = false
	play_anim("idle")

func can_be_hit() -> bool:
	return state != State.DEAD and state != State.DOWN and invuln_timer <= 0.0

func heal(amount: float):
	if amount <= 0.0 or state == State.DEAD:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)

func receive_hit(atk: Dictionary, attacker: Node2D, damage: int):
	hits_taken += 1
	damage = maxi(1, int(damage * (1.0 - damage_reduction)))
	hp = maxf(0.0, hp - damage)
	hp_changed.emit(hp, max_hp)
	var hit_pos := get_hit_point(attacker.facing)
	# 슈퍼아머 스킬 : 데미지만 받고 기술 유지
	if state == State.ATTACK and move.get("super_armor", false) and hp > 0.0:
		if fx:
			fx.spawn_damage(damage, hit_pos + Vector2(0, -30), "player")
			fx.play_hit_sound("blunt")
		flash(0.08, Color(1.0, 0.5, 0.4))
		return
	if fx:
		fx.spawn_spark(hit_pos, "blunt", attacker.facing, Color(1.0, 0.4, 0.3))
		fx.spawn_damage(damage, hit_pos + Vector2(0, -30), "player")
		fx.hitstop(atk.hitstop)
		fx.shake(atk.shake)
		fx.play_hit_sound("blunt")
	flash(0.1, Color(1.0, 0.35, 0.3))
	hit_shake(0.15, 3.0)
	facing = 1 if attacker.position.x > position.x else -1
	velocity = Vector2(-facing * atk.knockback, 0.0)
	is_running = false
	if hp <= 0.0:
		_die()
		return
	if atk.launch > 0.0 or atk.knockdown or is_airborne():
		state = State.AIR_HURT
		z_velocity = maxf(atk.launch, 260.0)
	else:
		state = State.HURT
		hurt_timer = atk.hitstun
		sprite.stop()
		sprite.play("take_hit")

func _state_hurt(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_ground(velocity, delta)
	hurt_timer -= delta
	if hurt_timer <= 0.0:
		state = State.IDLE
		invuln_timer = 0.25

func _state_air_hurt(delta: float):
	move_ground(velocity, delta)
	show_frame("take_hit", 2)
	visual.rotation = lerpf(visual.rotation, -facing * 0.5, 10.0 * delta)
	if update_air(delta):
		state = State.DOWN
		down_timer = 0.55
		velocity = Vector2.ZERO

func _state_down(delta: float):
	visual.rotation = lerpf(visual.rotation, -facing * PI * 0.5, 18.0 * delta)
	down_timer -= delta
	if down_timer <= 0.0:
		visual.rotation = 0.0
		state = State.IDLE
		invuln_timer = 0.9

func _die():
	if revives > 0:
		_revive()
		return
	state = State.DEAD
	z_velocity = maxf(z_velocity, 200.0)
	visual.rotation = 0.0
	sprite.stop()
	sprite.play("death")
	died.emit(self)

## 부활 (상점 respawn) : 쓰러졌다가 HP 50%로 일어나며 주변 적을 밀쳐냄
func _revive():
	revives -= 1
	invuln_timer = 3.0
	state = State.AIR_HURT
	z_velocity = maxf(z_velocity, 260.0)
	revived.emit(revives)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	hp = max_hp * 0.5
	hp_changed.emit(hp, max_hp)
	invuln_timer = 2.0
	visual.rotation = 0.0
	state = State.IDLE
	if fx:
		fx.spawn_text("REVIVE!", position + Vector2(0, -body_height - 60.0), Color(0.5, 1.0, 0.6), 30)
		fx.flash_screen(Color(0.6, 1.0, 0.7, 0.5), 0.3)
		fx.spawn_shockwave(position, 260.0, Color(0.5, 1.0, 0.6))
	for enemy in get_tree().get_nodes_in_group("action_enemy"):
		if absf(enemy.position.x - position.x) < 260.0 and absf(enemy.position.y - position.y) < 120.0:
			enemy.receive_hit(Combat.attack({"damage": 0.0, "launch": 380.0, "knockback": 300.0, "hitstop": 0.0, "shake": 0.0}),
				self, 0)

func _state_dead(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_ground(velocity, delta)
	update_air(delta)
