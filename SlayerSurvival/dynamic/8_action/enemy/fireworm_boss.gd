extends "res://dynamic/8_action/enemy/boss_enemy.gd"
## 보스 : 파이어 웜 (용암 동굴)
##   거리를 벌리고 화염구로 견제하는 원거리형 보스
##   가까이 붙으면 물어뜯기(바닥 예고), 수시로 플레이어 발밑에 용암 분출
##   2페이즈(HP 50% 이하) : 화염구 3갈래, 용암 분출 5곳 (페이즈 전환·처치 연출은 boss_enemy.gd 공통)

const KEEP_DISTANCE := 360.0

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
		if absf(dx) < 240.0 and absf(dy) < 50.0:
			_start_attack(patterns.bite if randf() < 0.75 else patterns.eruption)
		elif absf(dy) < 70.0 and randf() < 0.6:
			_start_attack(patterns.spit)
		else:
			_start_attack(patterns.eruption)
		return

	# 화염구 사거리 유지 + 라인은 느슨하게 맞춤
	var desired := Vector2(player.position.x - facing * KEEP_DISTANCE, player.position.y)
	var to := desired - position
	if to.length() > 20.0:
		state = State.CHASE
		var dir := to.normalized()
		move_ground(Vector2(dir.x * move_speed.x, dir.y * move_speed.y), delta)
		play_anim("run")
	else:
		state = State.IDLE
		play_anim("idle")

func _on_attack_frame(frame: int):
	super._on_attack_frame(frame)
	if _attack.get("fireball_frame", -1) == frame:
		var offsets := [-75.0, 0.0, 75.0] if phase == 2 else [0.0]
		for offset in offsets:
			_fire_projectile(def.fireball, offset)
	if _attack.get("eruption_frame", -1) == frame:
		_erupt()

## 플레이어 발밑부터 주변으로 차례차례 용암 분출
func _erupt():
	var player: Node2D = stage.player
	var data: Dictionary = def.eruption
	var count := 5 if phase == 2 else 3
	var sound: AudioStream = load(data.sound)
	for i in count:
		var spot := player.position
		if i > 0:
			spot += Vector2(randf_range(-260.0, 260.0), randf_range(-90.0, 90.0))
		var eruption := BossSpell.new()
		eruption.stage = stage
		eruption.caster = self
		eruption.sheet = data.sheet
		eruption.attack = data.attack
		eruption.power = power * 0.8
		eruption.warn_time = 0.85 + i * 0.22
		eruption.hit_frames = [1, 4]
		eruption.sprite_offset = Vector2(0, -20)
		eruption.sprite_scale = 4.5
		eruption.zone_size = Vector2(150, 80)
		eruption.sound = sound
		eruption.position = stage.clamp_to_floor(spot)
		stage.actors.add_child(eruption)
