extends "res://dynamic/8_action/core/actor.gd"
## 몬스터 동료 (노션 컨셉 : "무기가 아닌 몬스터를 파티로 만든다")
## 쓰러뜨린 몬스터가 확률로 동료가 되어 플레이어 곁을 따라다니며 가까운 적을 공격한다.
## 적에게 공격받지 않으며, 같은 던전 안에서 방을 옮겨도 함께 이동한다.
## 생성 후 add_child 전에 setup(kind, slot)을 호출한다.

const Combat       = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet  = preload("res://dynamic/8_action/core/sprite_sheet.gd")
const EnemyDefs    = preload("res://dynamic/8_action/enemy/enemy_defs.gd")
const Projectile   = preload("res://dynamic/8_action/enemy/projectile.gd")
const ActionPlayer = preload("res://dynamic/8_action/player/action_player.gd")

enum State { FOLLOW, ATTACK }

const POWER_RATIO   := 0.35		# 플레이어 공격력 대비 동료 공격력
const SEARCH_RANGE  := 420.0	# 동료 기준 적 탐색 거리
const LEASH_RANGE   := 560.0	# 플레이어에게서 이 이상 떨어진 적은 무시
const SLOT_OFFSETS  := [Vector2(-95, -45), Vector2(-95, 45), Vector2(-170, -10), Vector2(-170, 60)]

var kind := ""
var def  : Dictionary = {}
var display_name := ""
var state := State.FOLLOW
var power := 400.0
var move_speed := Vector2(300, 200)
var hover := 0.0
var slot_offset := Vector2(-95, -45)

var _attack : Dictionary = {}
var _ally_hits := []			# 동료용으로 조정한 공격 데이터 (히트스탑 없음)
var _attack_time := 0.0
var _attack_frame := -1
var _attack_cd := 0.5
var _hit_logs := []
var _step_speed := 0.0
var _step_time := 0.0
var fx : Node = null

func setup(kind_name: String, slot: int):
	kind = kind_name
	def = EnemyDefs.get_def(kind)
	display_name = def.name
	sprite_scale = def.scale * 0.85
	sprite_offset = def.offset
	body_height = def.body_height
	body_radius = def.body_radius
	shadow_size = Vector2(body_radius * 3.0, 14)
	hover = def.get("hover", 0.0)
	z = hover
	move_speed = def.speed * 2.2
	slot_offset = SLOT_OFFSETS[slot % SLOT_OFFSETS.size()]

func _ready():
	super._ready()
	add_to_group("action_ally")
	sprite.sprite_frames = SpriteSheet.build("enemy_" + kind, def.sheets)
	sprite.self_modulate = Color(0.78, 1.0, 0.82)		# 동료는 살짝 초록빛
	play_anim("idle")
	fx = get_tree().get_first_node_in_group("combat_fx")
	var tag := Label.new()
	tag.text = "동료"
	tag.add_theme_font_override("font", preload("res://static/font/DNFBitBitTTF.ttf"))
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 4)
	tag.position = Vector2(-16, -body_height * sprite_scale / 2.2 - 34.0 - hover)
	add_child(tag)

func _physics_process(delta):
	_tick_effects(delta)
	_attack_cd -= delta
	var player: Node2D = stage.player if stage else null
	if player == null:
		return
	if state == State.ATTACK:
		_state_attack(delta)
	else:
		_follow(player, delta)
	if hover > 0.0:
		z = move_toward(z, hover, 160.0 * delta)
	_update_visual()

## 플레이어 곁 대기 / 근처 적이 있으면 공격하러 감
func _follow(player: Node2D, delta: float):
	if player.is_dead():
		play_anim("idle")
		return
	var target := _find_target(player)
	if target and _attack_cd <= 0.0:
		var dx := target.position.x - position.x
		var dy := target.position.y - position.y
		if absf(dx) > 4.0:
			facing = 1 if dx > 0.0 else -1
		var options := []
		for option in def.attacks:
			if absf(dx) >= option.range[0] and absf(dx) <= option.range[1] and absf(dy) <= option.lane:
				options.append(option)
		if not options.is_empty():
			_start_attack(options.pick_random())
			return
		var best_range: float = def.attacks[0].range[1]
		_move_to(Vector2(target.position.x - facing * best_range * 0.7, target.position.y), delta)
		return
	# 플레이어 뒤쪽 자리로
	var desired := player.position + Vector2(slot_offset.x * player.facing, slot_offset.y)
	if position.distance_to(player.position) > 900.0:
		position = stage.clamp_to_floor(desired)
	if position.distance_to(desired) > 24.0:
		_move_to(desired, delta)
	else:
		facing = player.facing
		play_anim("idle")

func _move_to(desired: Vector2, delta: float):
	var to := desired - position
	if to.length() < 6.0:
		play_anim("idle")
		return
	var dir := to.normalized()
	var speed_scale := clampf(to.length() / 120.0, 0.5, 1.6)
	move_ground(Vector2(dir.x * move_speed.x, dir.y * move_speed.y) * speed_scale, delta)
	if absf(dir.x) > 0.2:
		facing = 1 if dir.x > 0.0 else -1
	play_anim("run")

func _find_target(player: Node2D) -> Node2D:
	var best : Node2D = null
	var best_dist := SEARCH_RANGE
	for enemy in get_tree().get_nodes_in_group("action_enemy"):
		if not enemy.can_be_hit() or enemy.position.distance_to(player.position) > LEASH_RANGE:
			continue
		var dist: float = enemy.position.distance_to(position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func _start_attack(option: Dictionary):
	state = State.ATTACK
	_attack = option
	_attack_time = 0.0
	_attack_frame = -1
	_step_time = 0.0
	_ally_hits.clear()
	_hit_logs.clear()
	for hit in option.get("hits", []):
		var atk: Dictionary = hit.attack.duplicate()
		atk["hitstop"] = 0.0
		atk["shake"] = 0.5
		atk["knockback"] = atk["knockback"] * 0.6
		atk["knockdown"] = false
		_ally_hits.append({"from": hit.from, "to": hit.to, "attack": atk})
		_hit_logs.append([])
	power = stage.player.attack_power * POWER_RATIO

func _state_attack(delta: float):
	_attack_time += delta
	var frame: int = ActionPlayer.frame_at(_attack.frame_times, _attack_time)
	if frame < 0:
		state = State.FOLLOW
		_attack_cd = def.cooldown * randf_range(0.6, 0.9)
		return
	if frame != _attack_frame:
		_attack_frame = frame
		show_frame(_attack.anim, frame)
		for step in _attack.get("steps", []):
			if step.frame == frame:
				_step_speed = step.speed
				_step_time = step.time
		if _attack.has("projectile") and _attack.projectile.frame == frame:
			_fire_projectile(_attack.projectile)
	if _step_time > 0.0:
		_step_time -= delta
		move_ground(Vector2(facing * _step_speed, 0.0), delta)
	for i in _ally_hits.size():
		var hit: Dictionary = _ally_hits[i]
		if frame < hit.from or frame > hit.to:
			continue
		for enemy in get_tree().get_nodes_in_group("action_enemy"):
			if enemy in _hit_logs[i] or not enemy.can_be_hit():
				continue
			if Combat.overlaps(self, hit.attack, enemy):
				_hit_logs[i].append(enemy)
				enemy.receive_hit(hit.attack, self, Combat.roll_damage(power, hit.attack))
				if fx:
					fx.add_combo(1)

func _fire_projectile(data: Dictionary):
	var shot := Projectile.new()
	var atk: Dictionary = data.attack.duplicate()
	atk["hitstop"] = 0.0
	shot.attack = atk
	shot.power = power
	shot.speed = data.speed
	shot.facing = facing
	shot.z = z + data.z
	shot.sheet = data.sheet
	shot.stage = stage
	shot.hits_enemies = true
	shot.position = position + Vector2(facing * 40.0, 0.0)
	stage.actors.add_child(shot)
