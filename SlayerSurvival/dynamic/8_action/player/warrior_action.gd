extends "res://dynamic/8_action/player/action_player.gd"
## Fantasy Warrior (액션 모드)
##   X  : 돌진 베기 → 회전 베기(뒤쪽 적까지 앞으로 끌어옴) → 올려 베기(띄우기)
##   →→X: 대시 찌르기 (멀리 밀쳐 벽 쪽으로 몰기)
##   C X: 점프 베기 (공중 적 추가타)

const SHEET_DIR := "res://dynamic/1_player/characters/Fantasy_Warrior/Sprites/"
const FRAME_W   := 162

func _setup_character():
	sheet_key     = "fantasy_warrior"
	sprite_offset = Vector2(-5, -20)		# 시트 프레임(162px) 안의 발 위치 보정
	sprite_scale  = 2.2
	body_radius   = 20.0
	body_height   = 95.0
	shadow_size   = Vector2(70, 18)
	max_hp        = 30000.0
	attack_power  = 1200.0

	sheets = {
		"idle"     : _sheet("Idle.png", 10.0, true),
		"run"      : _sheet("Run.png", 12.0, true),
		"attack_1" : _sheet("Attack1.png", 12.0, false),
		"attack_2" : _sheet("Attack2.png", 12.0, false),
		"attack_3" : _sheet("Attack3.png", 12.0, false),
		"jump"     : _sheet("Jump.png", 10.0, false),
		"fall"     : _sheet("Fall.png", 10.0, true),
		"take_hit" : _sheet("Take hit.png", 12.0, false),
		"death"    : _sheet("Death.png", 9.0, false),
	}

	moves = {
		# 1타 : 짧게 파고들며 베기
		"atk1": {
			"anim": "attack_1",
			"frame_times": [0.035, 0.035, 0.035, 0.045, 0.06, 0.07, 0.09],
			"swing": {"frame": 3, "sound": "warrior_1"},
			"steps": [{"frame": 3, "speed": 360.0, "time": 0.07}],
			"hits": [{"from": 3, "to": 4, "attack": Combat.attack({
				"damage": 1.0, "reach": 120.0, "back": 15.0, "depth": 40.0,
				"hitstun": 0.4, "knockback": 70.0, "align": 0.35,
				"hitstop": 0.045, "shake": 2.0, "spark": "slash",
			})}],
			"cancel": 5, "next": "atk2",
		},
		# 2타 : 회전 베기 — 몸 뒤쪽까지 판정, 맞은 적을 앞으로 끌어와 한 줄로 모은다 (몰이)
		"atk2": {
			"anim": "attack_2",
			"frame_times": [0.035, 0.04, 0.05, 0.05, 0.06, 0.07, 0.09],
			"swing": {"frame": 2, "sound": "warrior_2"},
			"steps": [{"frame": 1, "speed": 160.0, "time": 0.06}],
			"hits": [{"from": 2, "to": 3, "attack": Combat.attack({
				"damage": 1.15, "reach": 125.0, "back": 140.0, "depth": 62.0,
				"hitstun": 0.45, "knockback": 30.0, "pull": 75.0, "align": 0.75,
				"hitstop": 0.06, "shake": 3.0, "spark": "slash",
			})}],
			"cancel": 4, "next": "atk3",
		},
		# 3타 : 올려 베기 — 띄우기 + 낮은 후속타
		"atk3": {
			"anim": "attack_3",
			"frame_times": [0.04, 0.035, 0.035, 0.04, 0.075, 0.06, 0.08, 0.1],
			"swing": {"frame": 4, "sound": "warrior_3"},
			"steps": [{"frame": 4, "speed": 220.0, "time": 0.06}],
			"hits": [
				{"from": 4, "to": 4, "attack": Combat.attack({
					"damage": 1.6, "reach": 150.0, "back": 50.0, "depth": 52.0, "z_max": 230.0,
					"launch": 660.0, "knockback": 50.0, "align": 0.5,
					"hitstop": 0.095, "shake": 7.0, "spark": "heavy",
				})},
				{"from": 5, "to": 5, "attack": Combat.attack({
					"damage": 0.8, "reach": 140.0, "back": 0.0, "depth": 45.0, "z_max": 180.0,
					"juggle": 230.0, "knockback": 110.0, "hitstun": 0.4,
					"hitstop": 0.04, "shake": 2.5, "spark": "slash",
				})},
			],
			"cancel": 7, "next": "atk1",
		},
		# 대시 공격 : 길게 미끄러지며 찌르기, 강한 넉백
		"dash_attack": {
			"anim": "attack_1", "frame_offset": 2,
			"frame_times": [0.04, 0.05, 0.07, 0.08, 0.12],
			"swing": {"frame": 1, "sound": "warrior_1"},
			"steps": [{"frame": 0, "speed": 700.0, "time": 0.16}],
			"hits": [{"from": 1, "to": 3, "attack": Combat.attack({
				"damage": 1.4, "reach": 125.0, "back": 10.0, "depth": 45.0,
				"hitstun": 0.55, "knockback": 420.0, "align": 0.3,
				"hitstop": 0.07, "shake": 5.0, "spark": "heavy",
			})}],
			"cancel": 3, "next": "atk2",
		},
		# 점프 공격 : 아래쪽까지 판정 → 공중/지상 적 모두 추가타
		"jump_attack": {
			"anim": "attack_1", "frame_offset": 3, "air": true,
			"frame_times": [0.04, 0.06, 0.07, 0.1],
			"swing": {"frame": 0, "sound": "warrior_1"},
			"hits": [{"from": 0, "to": 2, "attack": Combat.attack({
				"damage": 1.1, "reach": 115.0, "back": 25.0, "depth": 42.0,
				"z_min": -150.0, "z_max": 80.0,
				"hitstun": 0.4, "knockback": 80.0, "juggle": 260.0,
				"hitstop": 0.05, "shake": 2.5, "spark": "slash",
			})}],
		},
	}
	_setup_skills()

## A/S/D/F 스킬
func _setup_skills():
	display_name = "Fantasy Warrior"
	skill_slots = [
		{"action": "act_skill_1", "key": "A", "move": "upper_slash"},
		{"action": "act_skill_2", "key": "S", "move": "whirlwind"},
		{"action": "act_skill_3", "key": "D", "move": "charge_slash"},
		{"action": "act_skill_4", "key": "F", "move": "ruin_strike"},
	]

	# A : 어퍼 슬래시 — 크게 띄우고 평타로 이어서 공중 콤보
	moves["upper_slash"] = {
		"anim": "attack_3", "frames": [3, 4, 4, 5, 6, 7],
		"frame_times": [0.05, 0.05, 0.04, 0.06, 0.08, 0.1],
		"skill": {"name": "어퍼 슬래시", "cooldown": 3.0, "mp": 60.0, "icon": Vector2i(9, 8)},
		"swing": {"frame": 1, "sound": "warrior_3"},
		"steps": [{"frame": 0, "speed": 260.0, "time": 0.06}],
		"hits": [{"from": 1, "to": 2, "attack": Combat.attack({
			"damage": 2.2, "reach": 145.0, "back": 40.0, "depth": 55.0, "z_max": 260.0,
			"launch": 820.0, "knockback": 40.0, "align": 0.6,
			"hitstop": 0.1, "shake": 6.0, "spark": "heavy",
		})}],
		"cancel": 3, "next": "atk1",
	}

	# S : 회오리 베기 — 회전하며 주변 적을 빨아들여 한 덩어리로 몰고, 마지막에 한꺼번에 띄움
	moves["whirlwind"] = {
		"anim": "attack_2", "frames": [0, 1, 2, 3, 2, 3, 2, 3, 2, 3, 4, 5, 6],
		"frame_times": [0.04, 0.04, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.07, 0.07, 0.1],
		"skill": {"name": "회오리 베기", "cooldown": 7.0, "mp": 120.0, "icon": Vector2i(10, 10)},
		"super_armor": true, "mobile": true,
		"events": [{"frame": 1, "type": "whirl", "time": 0.5, "radius": 150.0}],
		"swings": [{"frame": 2, "sound": "warrior_2"}, {"frame": 4, "sound": "warrior_2"},
			{"frame": 6, "sound": "warrior_2"}, {"frame": 8, "sound": "warrior_2"}, {"frame": 10, "sound": "warrior_3"}],
		"hits": [
			{"from": 2, "to": 2, "attack": _whirl_hit(270.0, 130.0, 30.0)},	# 첫 회전 : 넓게 빨아들이기
			{"from": 4, "to": 4, "attack": _whirl_hit(180.0, 85.0, 35.0)},
			{"from": 6, "to": 6, "attack": _whirl_hit(180.0, 85.0, 35.0)},
			{"from": 8, "to": 8, "attack": _whirl_hit(180.0, 85.0, 35.0)},
			{"from": 10, "to": 10, "attack": Combat.attack({
				"damage": 1.6, "reach": 175.0, "back": 175.0, "depth": 90.0, "z_max": 240.0,
				"launch": 560.0, "knockback": 30.0, "align": 0.6,
				"hitstop": 0.09, "shake": 6.0, "spark": "heavy",
			})},
		],
	}

	# D : 섬광 돌진 — 무적 돌진, 경로상의 적을 끌고 가며 앞으로 날려 벽 쪽에 몰아넣음
	moves["charge_slash"] = {
		"anim": "attack_1", "frames": [2, 3, 3, 3, 4, 5, 6],
		"frame_times": [0.05, 0.06, 0.06, 0.06, 0.07, 0.08, 0.1],
		"skill": {"name": "섬광 돌진", "cooldown": 5.0, "mp": 80.0, "icon": Vector2i(11, 10)},
		"invuln": true, "afterimage": true,
		"swing": {"frame": 1, "sound": "warrior_1"},
		"steps": [{"frame": 1, "speed": 1250.0, "time": 0.2}],
		"hits": [{"from": 1, "to": 4, "attack": Combat.attack({
			"damage": 1.9, "reach": 100.0, "back": 70.0, "depth": 55.0,
			"pull": 110.0, "align": 0.8, "hitstun": 0.6, "knockback": 480.0,
			"hitstop": 0.06, "shake": 5.0, "spark": "heavy",
		})}],
		"events": [{"frame": 4, "type": "shake", "power": 4.0}],
		"cancel": 5, "next": "atk1",
	}

	# F : 파멸의 일격 — 화면을 어둡게 모았다가 내려찍어 3단 충격파 (각성기 연출)
	moves["ruin_strike"] = {
		"anim": "attack_3", "frames": [0, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7],
		"frame_times": [0.06, 0.07, 0.08, 0.12, 0.05, 0.06, 0.06, 0.08, 0.1, 0.1, 0.14],
		"skill": {"name": "파멸의 일격", "cooldown": 18.0, "mp": 250.0, "icon": Vector2i(6, 10)},
		"invuln": true,
		"swing": {"frame": 5, "sound": "warrior_3"},
		"events": [
			{"frame": 0, "type": "banner", "text": "파멸의 일격!"},
			{"frame": 0, "type": "flash", "color": Color(0, 0, 0, 0.5), "time": 0.55},
			{"frame": 5, "type": "flash", "color": Color(1, 1, 1, 0.85), "time": 0.25},
			{"frame": 5, "type": "shockwave", "radius": 320.0, "offset": 60.0},
			{"frame": 5, "type": "zoom", "amount": 0.14, "time": 0.4},
			{"frame": 7, "type": "shockwave", "radius": 380.0, "offset": 60.0},
			{"frame": 9, "type": "shockwave", "radius": 440.0, "offset": 60.0},
		],
		"hits": [
			{"from": 5, "to": 5, "attack": Combat.attack({
				"damage": 4.0, "reach": 320.0, "back": 260.0, "depth": 150.0, "z_max": 320.0,
				"launch": 760.0, "knockback": 120.0, "align": 0.5,
				"hitstop": 0.16, "shake": 12.0, "spark": "heavy",
			})},
			{"from": 7, "to": 7, "attack": Combat.attack({
				"damage": 1.6, "reach": 380.0, "back": 300.0, "depth": 170.0, "z_max": 400.0,
				"juggle": 320.0, "knockback": 100.0, "hitstop": 0.05, "shake": 6.0, "spark": "heavy",
			})},
			{"from": 9, "to": 9, "attack": Combat.attack({
				"damage": 1.6, "reach": 440.0, "back": 340.0, "depth": 190.0, "z_max": 450.0,
				"juggle": 320.0, "knockback": 160.0, "hitstop": 0.05, "shake": 6.0, "spark": "heavy",
			})},
		],
	}

func _whirl_hit(radius: float, depth: float, vacuum: float) -> Dictionary:
	return Combat.attack({
		"damage": 0.65, "reach": radius, "back": radius, "depth": depth, "z_max": 220.0,
		"vacuum": vacuum, "align": 0.9, "hitstun": 0.5, "knockback": 0.0, "juggle": 130.0,
		"hitstop": 0.03, "shake": 2.5, "spark": "slash",
	})

func _sheet(file: String, fps: float, loop: bool) -> Dictionary:
	return {"path": SHEET_DIR + file, "frame_width": FRAME_W, "fps": fps, "loop": loop}
