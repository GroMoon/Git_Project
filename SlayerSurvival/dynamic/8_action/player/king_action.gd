extends "res://dynamic/8_action/player/action_player.gd"
## Medieval King (액션 모드) — 느리지만 한 방이 무거운 대검 캐릭터
##   X  : 가로 베기 → 대회전 베기(뒤쪽 적 끌어오기) → 초승달 올려베기(띄우기) + 찌르기
##   A 왕의 일격(띄우기) / S 왕의 부름(넓게 빨아들여 모은 뒤 회전 베기) / D 돌격 찌르기 / F 성검 심판
## 시트 : 160x111, 공격 4프레임 (점프 시트가 없어 대기 프레임으로 대체)

const SHEET_DIR := "res://dynamic/1_player/characters/Medieval_King/Sprites/"
const FRAME_W   := 160

func _setup_character():
	sheet_key     = "medieval_king"
	display_name  = "Medieval King"
	sprite_offset = Vector2(-1, -50)
	sprite_scale  = 2.0
	body_radius   = 22.0
	body_height   = 100.0
	shadow_size   = Vector2(74, 20)
	max_hp        = 38000.0
	attack_power  = 1420.0
	walk_speed    = Vector2(230, 150)
	run_speed     = Vector2(420, 180)
	jump_power    = 600.0

	sheets = {
		"idle"     : _sheet("Idle.png", 10.0, true),
		"run"      : _sheet("Run.png", 12.0, true),
		"attack_1" : _sheet("Attack1.png", 10.0, false),
		"attack_2" : _sheet("Attack2.png", 10.0, false),
		"attack_3" : _sheet("Attack3.png", 10.0, false),
		"take_hit" : _sheet("Take Hit.png", 12.0, false),
		"death"    : _sheet("Death.png", 8.0, false),
		"jump"     : {"path": SHEET_DIR + "Idle.png", "frame_width": FRAME_W, "loop": false, "cells": [[0, 1], [0, 2], [0, 3]]},
		"fall"     : {"path": SHEET_DIR + "Idle.png", "frame_width": FRAME_W, "fps": 8.0, "loop": true, "cells": [[0, 5], [0, 6]]},
	}

	moves = {
		"atk1": {
			"anim": "attack_1", "frames": [0, 1, 2, 2, 3],
			"frame_times": [0.07, 0.06, 0.05, 0.07, 0.12],
			"swing": {"frame": 2, "sound": "king_1"},
			"steps": [{"frame": 2, "speed": 300.0, "time": 0.06}],
			"hits": [{"from": 2, "to": 3, "attack": Combat.attack({
				"damage": 1.55, "reach": 150.0, "back": 10.0, "depth": 45.0, "z_max": 160.0,
				"hitstun": 0.45, "knockback": 90.0, "align": 0.4,
				"hitstop": 0.06, "shake": 3.0, "spark": "slash"})}],
			"cancel": 3, "next": "atk2",
		},
		"atk2": {
			"anim": "attack_2", "frames": [0, 1, 2, 2, 3],
			"frame_times": [0.06, 0.06, 0.05, 0.07, 0.12],
			"swing": {"frame": 2, "sound": "king_2"},
			"hits": [{"from": 2, "to": 3, "attack": Combat.attack({
				"damage": 1.7, "reach": 165.0, "back": 145.0, "depth": 65.0, "z_max": 160.0,
				"hitstun": 0.5, "knockback": 30.0, "pull": 85.0, "align": 0.75,
				"hitstop": 0.07, "shake": 4.0, "spark": "slash"})}],
			"cancel": 3, "next": "atk3",
		},
		"atk3": {
			"anim": "attack_3", "frames": [0, 1, 2, 2, 3, 3],
			"frame_times": [0.07, 0.07, 0.06, 0.08, 0.06, 0.12],
			"swing": {"frame": 2, "sound": "king_3"},
			"steps": [{"frame": 4, "speed": 380.0, "time": 0.08}],
			"hits": [
				{"from": 2, "to": 3, "attack": Combat.attack({
					"damage": 2.3, "reach": 165.0, "back": 120.0, "depth": 55.0, "z_max": 280.0,
					"launch": 700.0, "knockback": 50.0, "align": 0.5,
					"hitstop": 0.1, "shake": 8.0, "spark": "heavy"})},
				{"from": 4, "to": 4, "attack": Combat.attack({
					"damage": 1.2, "reach": 175.0, "back": 0.0, "depth": 40.0, "z_max": 200.0,
					"juggle": 220.0, "knockback": 120.0, "hitstun": 0.45,
					"hitstop": 0.05, "shake": 3.0, "spark": "slash"})},
			],
			"cancel": 5, "next": "atk1",
		},
		"dash_attack": {
			"anim": "attack_3", "frames": [3, 3, 3],
			"frame_times": [0.08, 0.1, 0.14],
			"swing": {"frame": 0, "sound": "king_3"},
			"steps": [{"frame": 0, "speed": 760.0, "time": 0.18}],
			"hits": [{"from": 0, "to": 1, "attack": Combat.attack({
				"damage": 1.5, "reach": 165.0, "back": 10.0, "depth": 45.0,
				"hitstun": 0.55, "knockback": 450.0, "align": 0.3,
				"hitstop": 0.08, "shake": 5.0, "spark": "heavy"})}],
			"cancel": 2, "next": "atk2",
		},
		"jump_attack": {
			"anim": "attack_1", "frames": [1, 2, 2, 3], "air": true,
			"frame_times": [0.05, 0.06, 0.07, 0.1],
			"swing": {"frame": 1, "sound": "king_1"},
			"hits": [{"from": 1, "to": 2, "attack": Combat.attack({
				"damage": 1.2, "reach": 150.0, "back": 25.0, "depth": 42.0,
				"z_min": -160.0, "z_max": 80.0,
				"hitstun": 0.4, "knockback": 90.0, "juggle": 250.0,
				"hitstop": 0.06, "shake": 3.0, "spark": "slash"})}],
		},
	}
	_setup_skills()

func _setup_skills():
	skill_slots = [
		{"action": "act_skill_1", "key": "A", "move": "royal_smash"},
		{"action": "act_skill_2", "key": "S", "move": "royal_call"},
		{"action": "act_skill_3", "key": "D", "move": "lance_charge"},
		{"action": "act_skill_4", "key": "F", "move": "holy_judgement"},
	]
	# A : 왕의 일격 — 초승달 올려베기 + 작은 충격파
	moves["royal_smash"] = {
		"anim": "attack_3", "frames": [1, 2, 2, 3],
		"frame_times": [0.05, 0.06, 0.05, 0.12],
		"skill": {"name": "왕의 일격", "cooldown": 3.5, "mp": 70.0, "icon": Vector2i(1, 10)},
		"swing": {"frame": 1, "sound": "king_3"},
		"events": [{"frame": 1, "type": "shockwave", "radius": 170.0, "offset": 80.0}],
		"hits": [{"from": 1, "to": 2, "attack": Combat.attack({
			"damage": 3.0, "reach": 175.0, "back": 80.0, "depth": 60.0, "z_max": 300.0,
			"launch": 860.0, "knockback": 40.0, "align": 0.6,
			"hitstop": 0.11, "shake": 7.0, "spark": "heavy"})}],
		"cancel": 3, "next": "atk1",
	}
	# S : 왕의 부름 — 넓은 범위의 적을 발밑으로 끌어모은 뒤 대회전 베기로 한꺼번에 띄움
	moves["royal_call"] = {
		"anim": "attack_2", "frames": [0, 1, 1, 1, 2, 2, 3],
		"frame_times": [0.08, 0.1, 0.1, 0.1, 0.06, 0.08, 0.14],
		"skill": {"name": "왕의 부름", "cooldown": 8.0, "mp": 130.0, "icon": Vector2i(2, 11)},
		"super_armor": true,
		"swing": {"frame": 4, "sound": "king_2"},
		"events": [
			{"frame": 1, "type": "shockwave", "radius": 420.0},
			{"frame": 1, "type": "flash", "color": Color(1.0, 0.85, 0.4, 0.25), "time": 0.25},
			{"frame": 4, "type": "whirl", "time": 0.25, "radius": 170.0},
		],
		"hits": [
			{"from": 1, "to": 1, "attack": Combat.attack({
				"damage": 0.4, "reach": 430.0, "back": 430.0, "depth": 170.0, "z_max": 300.0,
				"vacuum": 45.0, "align": 1.0, "hitstun": 0.9, "knockback": 0.0, "juggle": 60.0,
				"hitstop": 0.04, "shake": 3.0, "spark": "blunt"})},
			{"from": 4, "to": 5, "attack": Combat.attack({
				"damage": 1.6, "reach": 190.0, "back": 190.0, "depth": 90.0, "z_max": 260.0,
				"launch": 540.0, "knockback": 40.0, "align": 0.6,
				"hitstop": 0.09, "shake": 7.0, "spark": "heavy"})},
		],
	}
	# D : 돌격 찌르기 — 무적 돌진, 경로상의 적을 끌고 가 앞으로 날림
	moves["lance_charge"] = {
		"anim": "attack_3", "frames": [3, 3, 3, 3, 3],
		"frame_times": [0.04, 0.06, 0.06, 0.06, 0.12],
		"skill": {"name": "돌격 찌르기", "cooldown": 5.0, "mp": 90.0, "icon": Vector2i(11, 10)},
		"invuln": true, "afterimage": true,
		"swing": {"frame": 0, "sound": "king_3"},
		"steps": [{"frame": 0, "speed": 1150.0, "time": 0.24}],
		"hits": [{"from": 0, "to": 3, "attack": Combat.attack({
			"damage": 2.0, "reach": 150.0, "back": 60.0, "depth": 55.0,
			"pull": 120.0, "align": 0.8, "hitstun": 0.6, "knockback": 500.0,
			"hitstop": 0.06, "shake": 5.0, "spark": "heavy"})}],
		"cancel": 4, "next": "atk1",
	}
	# F : 성검 심판 — 성검을 높이 들었다가 내려쳐 2단 대충격파
	moves["holy_judgement"] = {
		"anim": "attack_1", "frames": [0, 0, 1, 1, 2, 2, 2, 3],
		"frame_times": [0.1, 0.1, 0.1, 0.12, 0.06, 0.08, 0.1, 0.18],
		"skill": {"name": "성검 심판", "cooldown": 20.0, "mp": 280.0, "icon": Vector2i(0, 10)},
		"invuln": true,
		"swing": {"frame": 4, "sound": "king_1"},
		"events": [
			{"frame": 0, "type": "banner", "text": "성검 심판!"},
			{"frame": 0, "type": "flash", "color": Color(0, 0, 0, 0.5), "time": 0.6},
			{"frame": 4, "type": "flash", "color": Color(1.0, 0.95, 0.7, 0.9), "time": 0.3},
			{"frame": 4, "type": "shockwave", "radius": 360.0, "offset": 80.0},
			{"frame": 4, "type": "zoom", "amount": 0.15, "time": 0.45},
			{"frame": 6, "type": "shockwave", "radius": 470.0, "offset": 80.0},
		],
		"hits": [
			{"from": 4, "to": 4, "attack": Combat.attack({
				"damage": 4.5, "reach": 360.0, "back": 300.0, "depth": 170.0, "z_max": 350.0,
				"launch": 800.0, "knockback": 120.0, "align": 0.5,
				"hitstop": 0.17, "shake": 13.0, "spark": "heavy"})},
			{"from": 6, "to": 6, "attack": Combat.attack({
				"damage": 2.0, "reach": 470.0, "back": 400.0, "depth": 190.0, "z_max": 450.0,
				"juggle": 340.0, "knockback": 160.0, "hitstop": 0.06, "shake": 7.0, "spark": "heavy"})},
		],
	}

func _sheet(file: String, fps: float, loop: bool) -> Dictionary:
	return {"path": SHEET_DIR + file, "frame_width": FRAME_W, "fps": fps, "loop": loop}
