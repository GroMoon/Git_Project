extends "res://dynamic/8_action/enemy/action_enemy.gd"
## 보스 : 브링어 오브 데스
##   1페이즈 : 접근 → 낫 휘두르기(바닥 예고) / 주문(플레이어 발밑 어둠의 손)
##   2페이즈(HP 50% 이하) : 더 빠르게, 주문 3곳, 사라졌다가 등 뒤에서 나타나 베기
##   항상 슈퍼아머 → 내구도를 깎아 ARMOR BREAK 시킨 동안만 경직/띄우기 가능

const BossSpell = preload("res://dynamic/8_action/enemy/boss_spell.gd")

var phase := 1

func _ready():
	super._ready()
	add_to_group("action_boss")
	_attack_cd = 2.0

func _physics_process(delta):
	if phase == 1 and hp <= max_hp * 0.5 and state != State.DEAD:
		phase = 2
		attack_cooldown = 1.05
		move_speed *= 1.35
		if fx:
			fx.spawn_text("분노!", get_hit_point(facing) + Vector2(0, -120), Color(1.0, 0.3, 0.3), 34)
			fx.shake(6.0)
	super._physics_process(delta)

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

	if _attack_cd <= 0.0:
		var patterns: Dictionary = def.patterns
		var near := absf(dx) < 300.0 and absf(dy) < 55.0
		if phase == 2 and randf() < 0.3:
			_start_attack(patterns.teleport)
			return
		if near:
			_start_attack(patterns.scythe if randf() < 0.7 else patterns.cast)
			return
		if randf() < 0.55:
			_start_attack(patterns.cast)
			return
		_attack_cd = 0.4		# 다가가서 다시 판단

	# 낫 사거리 안쪽으로 접근, 같은 라인 맞추기
	var desired := Vector2(player.position.x - facing * 210.0, player.position.y)
	var to := desired - position
	if to.length() > 12.0:
		state = State.CHASE
		var dir := to.normalized()
		move_ground(Vector2(dir.x * move_speed.x, dir.y * move_speed.y), delta)
		play_anim("run")
	else:
		state = State.IDLE
		play_anim("idle")

## 공격이 끝나면 "then"에 지정된 다음 패턴으로 바로 연결
func _finish_attack():
	var next_name: String = _attack.get("then", "")
	if next_name != "" and stage.player and not stage.player.is_dead():
		if _attack.get("teleport", false):
			_teleport_behind(stage.player)
		_start_attack(def.patterns[next_name])
		return
	super._finish_attack()

func _teleport_behind(player: Node2D):
	var side: int = -player.facing
	var target := Vector2(player.position.x + side * 190.0, player.position.y)
	if stage.clamp_to_floor(target).x != target.x:
		target.x = player.position.x - side * 190.0
	position = stage.clamp_to_floor(target)
	facing = 1 if player.position.x > position.x else -1

func _on_attack_frame(frame: int):
	super._on_attack_frame(frame)
	if _attack.get("spell_frame", -1) == frame:
		_cast_spells()

func _cast_spells():
	var player: Node2D = stage.player
	var spots := [player.position]
	if phase == 2:
		spots.append(player.position + Vector2(randf_range(130.0, 200.0), randf_range(-60.0, 60.0)))
		spots.append(player.position - Vector2(randf_range(130.0, 200.0), randf_range(-60.0, 60.0)))
	for spot in spots:
		var spell := BossSpell.new()
		spell.stage = stage
		spell.caster = self
		spell.sheet = def.spell_sheet
		spell.attack = def.spell_attack
		spell.power = power * 0.8
		spell.position = stage.clamp_to_floor(spot)
		stage.actors.add_child(spell)

## 보스는 날아가지 않고 그 자리에서 쓰러짐 + 슬로우 모션 연출
func _die(attacker: Node2D, atk: Dictionary):
	super._die(attacker, atk)
	z_velocity = 0.0
	z = 0.0
	velocity = Vector2.ZERO
	visual.rotation = 0.0
	_dead_landed = true
	sprite.play("death")
	if fx:
		fx.slow_motion(0.25, 1.6)
		fx.flash_screen(Color(1, 1, 1, 0.9), 0.5)
		fx.shake(14.0)

func _state_dead(delta: float):
	_fade_time += delta
	if _fade_time > 2.0:
		modulate.a = maxf(0.0, 1.0 - (_fade_time - 2.0) / 0.8)
		if modulate.a <= 0.0:
			queue_free()
