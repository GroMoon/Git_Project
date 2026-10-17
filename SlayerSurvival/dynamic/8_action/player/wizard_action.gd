extends "res://dynamic/8_action/player/action_player.gd"
## Wizard (액션 모드) — 원거리 마법사
##   X  : 마력탄 → 마력탄 → 마력 폭발(앞쪽 띄우기)
##   A 체인 라이트닝(가까운 적 3명 낙뢰) / S 그라비티 홀(적을 빨아들이는 마법사의 몰이기) /
##   D 블링크(무적 순간이동 + 도착 폭발) / F 메테오 스톰
## 시트 : 231x190 (발 y=141, 몸 중심 x≈110)

const Magic = preload("res://dynamic/8_action/player/magic.gd")

const SHEET_DIR := "res://dynamic/1_player/characters/Wizard/Sprites/"
const FRAME_W   := 231
const FRAME_H   := 190
const BOLT_COLOR := Color(0.75, 0.5, 1.0)

func _setup_character():
	sheet_key     = "wizard"
	display_name  = "Wizard"
	sprite_offset = Vector2(5, -46)
	sprite_scale  = 1.3
	body_radius   = 18.0
	body_height   = 105.0
	shadow_size   = Vector2(64, 18)
	max_hp        = 24000.0
	attack_power  = 1250.0
	max_mp        = 1400.0
	mp_regen      = 55.0
	walk_speed    = Vector2(250, 165)
	run_speed     = Vector2(460, 195)

	sheets = {
		"idle"     : _sheet("Idle.png", 8.0, true),
		"run"      : _sheet("Run.png", 12.0, true),
		"attack_1" : _sheet("Attack1.png", 12.0, false),
		"attack_2" : _sheet("Attack2.png", 12.0, false),
		"jump"     : _sheet("Jump.png", 10.0, false),
		"fall"     : _sheet("Fall.png", 8.0, true),
		"take_hit" : _sheet("Hit.png", 12.0, false),
		"death"    : _sheet("Death.png", 9.0, false),
	}

	moves = {
		# 1·2타 : 마력탄 발사
		"atk1": _bolt_move(1.25, 13.0, "atk2", false),
		"atk2": _bolt_move(1.35, 16.0, "atk3", true),		# 2타 마력탄은 관통 (줄 세운 적 정리)
		# 3타 : 지팡이 앞 마력 폭발 — 앞쪽 적을 띄움
		"atk3": {
			"anim": "attack_1", "frames": [2, 3, 4, 5, 6, 7],
			"frame_times": [0.04, 0.045, 0.06, 0.07, 0.08, 0.1],
			"swing": {"frame": 3, "sound": "wizard_1"},
			"events": [{"frame": 3, "type": "shockwave", "radius": 130.0, "offset": 130.0}],
			"hits": [{"from": 3, "to": 4, "attack": Combat.attack({
				"damage": 2.3, "reach": 220.0, "back": -40.0, "depth": 75.0, "z_max": 280.0,
				"launch": 430.0, "knockback": 60.0, "align": 0.5,
				"hitstop": 0.09, "shake": 6.0, "spark": "heavy"})}],
			"cancel": 5, "next": "atk1",
		},
		"dash_attack": {
			"anim": "attack_1", "frames": [3, 4, 5, 6, 7],
			"frame_times": [0.05, 0.06, 0.07, 0.08, 0.12],
			"swing": {"frame": 1, "sound": "wizard_1"},
			"steps": [{"frame": 0, "speed": 600.0, "time": 0.14}],
			"hits": [{"from": 1, "to": 2, "attack": Combat.attack({
				"damage": 1.4, "reach": 200.0, "back": -20.0, "depth": 55.0,
				"hitstun": 0.55, "knockback": 380.0, "align": 0.4,
				"hitstop": 0.07, "shake": 5.0, "spark": "heavy"})}],
			"cancel": 3, "next": "atk2",
		},
		# 점프 공격 : 공중에서 마력탄
		"jump_attack": {
			"anim": "attack_2", "frames": [4, 5, 6], "air": true,
			"frame_times": [0.05, 0.07, 0.1],
			"swing": {"frame": 1, "sound": "wizard_1"},
			"spawns": [{"frame": 1, "type": "bolt", "radius": 15.0, "attack": _bolt_attack(1.0, 240.0)}],
		},
	}
	_setup_skills()

func _setup_skills():
	skill_slots = [
		{"action": "act_skill_1", "key": "A", "move": "chain_lightning"},
		{"action": "act_skill_2", "key": "S", "move": "gravity_hole"},
		{"action": "act_skill_3", "key": "D", "move": "blink"},
		{"action": "act_skill_4", "key": "F", "move": "meteor_storm"},
	]
	# A : 체인 라이트닝 — 가까운 적 3명에게 낙뢰 (띄움)
	moves["chain_lightning"] = {
		"anim": "attack_1", "frames": [0, 1, 2, 3],
		"frame_times": [0.05, 0.05, 0.06, 0.14],
		"skill": {"name": "체인 라이트닝", "cooldown": 4.0, "mp": 90.0, "icon": Vector2i(4, 10)},
		"swing": {"frame": 2, "sound": "wizard_1"},
		"spawns": [{"frame": 2, "type": "lightning", "count": 3, "range": 650.0, "attack": Combat.attack({
			"damage": 2.6, "reach": 50.0, "back": 50.0, "depth": 40.0, "z_min": -20.0, "z_max": 400.0,
			"launch": 480.0, "knockback": 30.0, "hitstop": 0.06, "shake": 4.0, "spark": "heavy"})}],
		"cancel": 3, "next": "atk1",
	}
	# S : 그라비티 홀 — 앞쪽에 소용돌이를 만들어 주변 적을 계속 빨아들인 뒤 폭발
	var hole_radius := 260.0
	moves["gravity_hole"] = {
		"anim": "attack_2", "frames": [0, 1, 2, 3, 4, 5],
		"frame_times": [0.05, 0.05, 0.06, 0.06, 0.08, 0.14],
		"skill": {"name": "그라비티 홀", "cooldown": 9.0, "mp": 160.0, "icon": Vector2i(8, 8)},
		"swing": {"frame": 4, "sound": "wizard_1"},
		"spawns": [{"frame": 4, "type": "vortex", "offset": 260.0, "life": 1.6, "radius": hole_radius,
			"pulse": Combat.attack({
				"damage": 0.25, "reach": hole_radius, "back": hole_radius, "depth": hole_radius * 0.45,
				"z_min": -60.0, "z_max": 260.0, "vacuum": 10.0, "align": 0.6,
				"hitstun": 0.45, "knockback": 0.0, "juggle": 70.0, "hitstop": 0.0, "shake": 0.5, "spark": "blunt"}),
			"burst": Combat.attack({
				"damage": 2.4, "reach": hole_radius * 1.1, "back": hole_radius * 1.1, "depth": hole_radius * 0.55,
				"z_min": -60.0, "z_max": 300.0, "launch": 650.0, "knockback": 40.0,
				"hitstop": 0.1, "shake": 8.0, "spark": "heavy"})}],
		"cancel": 5, "next": "atk1",
	}
	# D : 블링크 — 무적 순간이동, 도착 지점 마력 폭발
	moves["blink"] = {
		"anim": "jump", "frames": [0, 1, 1, 1],
		"frame_times": [0.04, 0.06, 0.06, 0.1],
		"skill": {"name": "블링크", "cooldown": 3.0, "mp": 50.0, "icon": Vector2i(9, 10)},
		"invuln": true, "afterimage": true,
		"steps": [{"frame": 0, "speed": 2400.0, "time": 0.12}],
		"events": [{"frame": 3, "type": "shockwave", "radius": 140.0}],
		"hits": [{"from": 3, "to": 3, "attack": Combat.attack({
			"damage": 1.0, "reach": 120.0, "back": 120.0, "depth": 60.0,
			"hitstun": 0.5, "knockback": 220.0, "hitstop": 0.04, "shake": 3.0, "spark": "blunt"})}],
		"cancel": 3, "next": "atk1",
	}
	# F : 메테오 스톰 — 화면 암전 후 앞쪽에 운석 8개
	moves["meteor_storm"] = {
		"anim": "attack_1", "frames": [0, 1, 2, 2, 3, 4, 5, 6, 7],
		"frame_times": [0.1, 0.1, 0.12, 0.12, 0.06, 0.08, 0.1, 0.1, 0.18],
		"skill": {"name": "메테오 스톰", "cooldown": 22.0, "mp": 320.0, "icon": Vector2i(11, 8)},
		"invuln": true,
		"swing": {"frame": 4, "sound": "wizard_1"},
		"events": [
			{"frame": 0, "type": "banner", "text": "메테오 스톰!"},
			{"frame": 0, "type": "flash", "color": Color(0, 0, 0, 0.5), "time": 0.6},
			{"frame": 4, "type": "flash", "color": Color(1.0, 0.6, 0.3, 0.45), "time": 0.3},
			{"frame": 4, "type": "zoom", "amount": 0.1, "time": 0.4},
		],
		"spawns": [{"frame": 4, "type": "meteor", "count": 8, "attack": Combat.attack({
			"damage": 2.0, "reach": 110.0, "back": 110.0, "depth": 70.0, "z_min": -20.0, "z_max": 260.0,
			"launch": 520.0, "knockback": 60.0, "hitstop": 0.05, "shake": 5.0, "spark": "heavy"})}],
	}

## 마력탄 기본 공격
func _bolt_move(damage: float, radius: float, next_move: String, pierce: bool) -> Dictionary:
	return {
		"anim": "attack_2", "frames": [1, 2, 3, 4, 5, 6],
		"frame_times": [0.035, 0.035, 0.04, 0.045, 0.06, 0.08],
		"swing": {"frame": 4, "sound": "wizard_1"},
		"spawns": [{"frame": 4, "type": "bolt", "radius": radius, "pierce": pierce, "attack": _bolt_attack(damage, 0.0)}],
		"cancel": 4, "next": next_move,
	}

func _bolt_attack(damage: float, juggle: float) -> Dictionary:
	return Combat.attack({
		"damage": damage, "reach": 26.0, "back": 26.0, "depth": 32.0, "z_min": -70.0, "z_max": 160.0,	# 마력탄은 위아래로 넉넉히 (공중 적 추격)
		"hitstun": 0.38, "knockback": 90.0, "juggle": juggle if juggle > 0.0 else 160.0,
		"hitstop": 0.035, "shake": 1.5, "spark": "blunt"})

## 기술 중 마법 생성
func _on_spawn(spawn: Dictionary):
	match spawn.type:
		"bolt":
			var bolt := Magic.Bolt.new()
			bolt.caster = self
			bolt.attack = spawn.attack
			bolt.facing = facing
			bolt.z = z + 72.0
			bolt.radius = spawn.get("radius", 14.0)
			bolt.pierce = spawn.get("pierce", false)
			bolt.color = BOLT_COLOR
			bolt.position = position + Vector2(facing * 70.0, 0.0)
			stage.actors.add_child(bolt)
		"vortex":
			var vortex := Magic.Vortex.new()
			vortex.caster = self
			vortex.pulse_attack = spawn.pulse
			vortex.burst_attack = spawn.burst
			vortex.life = spawn.life
			vortex.radius = spawn.radius
			vortex.position = stage.clamp_to_floor(position + Vector2(facing * spawn.offset, 0.0))
			stage.actors.add_child(vortex)
		"lightning":
			var spots := _nearest_enemy_spots(spawn.count, spawn.range)
			if spots.is_empty():
				spots.append(stage.clamp_to_floor(position + Vector2(facing * 220.0, 0.0)))
			for spot in spots:
				var strike := Magic.LightningStrike.new()
				strike.caster = self
				strike.attack = spawn.attack
				strike.position = spot
				stage.actors.add_child(strike)
		"meteor":
			for i in spawn.count:
				var meteor := Magic.Meteor.new()
				meteor.caster = self
				meteor.attack = spawn.attack
				meteor.delay = i * 0.09
				meteor.position = stage.clamp_to_floor(position + Vector2(
					facing * randf_range(60.0, 440.0), randf_range(-95.0, 95.0)))
				stage.actors.add_child(meteor)

## 가까운 적 count명의 바닥 위치
func _nearest_enemy_spots(count: int, max_range: float) -> Array:
	var enemies := get_tree().get_nodes_in_group("action_enemy").filter(
		func(e): return e.can_be_hit() and e.position.distance_to(position) <= max_range)
	enemies.sort_custom(func(a, b): return a.position.distance_to(position) < b.position.distance_to(position))
	var spots := []
	for i in mini(count, enemies.size()):
		spots.append(enemies[i].position)
	return spots

func _sheet(file: String, fps: float, loop: bool) -> Dictionary:
	return {"path": SHEET_DIR + file, "frame_width": FRAME_W, "frame_height": FRAME_H, "fps": fps, "loop": loop}
