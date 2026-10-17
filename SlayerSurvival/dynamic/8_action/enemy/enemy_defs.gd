extends RefCounted
## 몬스터별 데이터 (기존 서바이벌 모드의 스프라이트/사운드 재사용)
##   시트 : 150x150 프레임, 발 위치 y=101 → offset.y = 75 - 101 = -26
##
## attacks : AI가 거리 조건에 맞는 공격을 고른다
##   "anim", "frame_times", "hits"   : 플레이어 기술과 같은 형식
##   "range"      : [최소, 최대] 가로 거리
##   "lane"       : 같은 라인으로 인정할 깊이 차
##   "steps"      : 전진 스텝
##   "projectile" : {"frame": f, "speed": px/s, "z": 높이, "attack": ...}  해당 프레임에 투사체 발사

const Combat      = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

const ENEMY_DIR := "res://dynamic/2_enemy/"
const SFX_DIR   := "res://static/audio/sfx/enemy/"

const NAMES := {
	"goblin": "고블린", "skeleton": "스켈레톤", "mushroom": "머쉬룸", "flyingeye": "플라잉 아이",
	"bringer": "브링어 오브 데스", "fireworm": "파이어 웜",
}
const GOLD := {"goblin": 15, "skeleton": 25, "mushroom": 20, "flyingeye": 15, "bringer": 500, "fireworm": 550}

## elite = true 이면 엘리트 강화 (크기, 체력, 공격력, 슈퍼아머)
static func get_def(kind: String, elite := false) -> Dictionary:
	var def := _base_def(kind)
	def["kind"] = kind
	def["name"] = NAMES.get(kind, kind)
	def["elite"] = elite
	def["gold"] = GOLD.get(kind, 10) * (5 if elite else 1)
	if not def.has("armor"):
		def["armor"] = 0.0
	if elite:
		def["name"] = "엘리트 " + def["name"]
		def["hp"] *= 4.0
		def["power"] *= 1.4
		def["scale"] *= 1.3
		def["body_height"] *= 1.3
		def["body_radius"] *= 1.3
		def["speed"] *= 1.1
		def["armor"] = 6.0			# 슈퍼아머 내구도 (공격 배율 합만큼 깎임)
		def["bar_lines"] = 5
		for extra in def.get("elite_attacks", []):
			def["attacks"].append(extra)
	return def

static func _base_def(kind: String) -> Dictionary:
	match kind:
		"goblin":
			return {
				"hp": 14000.0, "power": 900.0, "speed": Vector2(160, 100),
				"cooldown": 1.6, "scale": 2.3, "offset": Vector2(0, -26),
				"body_height": 80.0, "body_radius": 18.0, "bar_lines": 1,
				"death_sound": SFX_DIR + "goblin_death.wav",
				"sheets": _sheets("Goblin", {"idle": "Idle.png", "run": "Run.png", "attack": "Attack.png",
					"attack2": "Attack2.png", "hit": "Take Hit.png", "death": "Death.png"}),
				"attacks": [
					# 근접 베기
					{"anim": "attack", "range": [0.0, 90.0], "lane": 18.0,
					 "frame_times": [0.08, 0.08, 0.08, 0.08, 0.08, 0.07, 0.06, 0.12],
					 "hits": [{"from": 6, "to": 7, "attack": Combat.attack({
						"reach": 85.0, "back": 10.0, "depth": 28.0,
						"hitstun": 0.35, "knockback": 140.0, "hitstop": 0.06, "shake": 4.0, "spark": "blunt"})}]},
					# 공중제비 돌진 베기 (중거리)
					{"anim": "attack2", "range": [130.0, 230.0], "lane": 22.0,
					 "frame_times": [0.08, 0.08, 0.07, 0.07, 0.07, 0.07, 0.05, 0.14],
					 "steps": [{"frame": 1, "speed": 620.0, "time": 0.2}, {"frame": 6, "speed": 300.0, "time": 0.06}],
					 "hits": [{"from": 6, "to": 7, "attack": Combat.attack({
						"reach": 95.0, "back": 10.0, "depth": 30.0,
						"hitstun": 0.4, "knockback": 180.0, "hitstop": 0.07, "shake": 4.5, "spark": "blunt"})}]},
				],
			}
		"skeleton":
			return {
				"hp": 19000.0, "power": 1200.0, "speed": Vector2(110, 75),
				"cooldown": 2.2, "scale": 2.2, "offset": Vector2(-7, -26),
				"body_height": 105.0, "body_radius": 20.0, "bar_lines": 1,
				"guard_chance": 0.4,		# 정면 일반 공격을 방패로 막을 확률 (강공격/띄우기는 가드 브레이크)
				"death_sound": SFX_DIR + "skeleton_death.wav",
				"sheets": _sheets("Skeleton", {"idle": "Idle.png", "run": "Walk.png", "attack": "Attack.png",
					"shield": "Shield.png", "hit": "Take Hit.png", "death": "Death.png"}),
				"attacks": [
					# 내려찍기 (넘어뜨림)
					{"anim": "attack", "range": [0.0, 105.0], "lane": 18.0,
					 "frame_times": [0.09, 0.09, 0.09, 0.09, 0.09, 0.08, 0.06, 0.14],
					 "hits": [{"from": 6, "to": 7, "attack": Combat.attack({
						"reach": 108.0, "back": 10.0, "depth": 30.0,
						"hitstun": 0.4, "knockback": 160.0, "knockdown": true,
						"hitstop": 0.08, "shake": 5.0, "spark": "blunt"})}]},
				],
			}
		"mushroom":
			return {
				"hp": 16000.0, "power": 1000.0, "speed": Vector2(115, 80),
				"cooldown": 2.0, "scale": 2.4, "offset": Vector2(0, -26),
				"body_height": 82.0, "body_radius": 18.0, "bar_lines": 1,
				"keep_distance": 240.0,		# 원거리형 : 이 거리를 유지하려 함
				"death_sound": SFX_DIR + "mushroom_death.wav",
				"sheets": _sheets("Mushroom", {"idle": "Idle.png", "run": "Run.png", "attack": "Attack.png",
					"attack2": "Attack2.png", "attack3": "Attack3.png", "hit": "Take Hit.png", "death": "Death.png"}),
				"attacks": [
					# 근접 박치기
					{"anim": "attack", "range": [0.0, 85.0], "lane": 18.0,
					 "frame_times": [0.08, 0.08, 0.08, 0.08, 0.08, 0.07, 0.06, 0.12],
					 "hits": [{"from": 6, "to": 7, "attack": Combat.attack({
						"reach": 85.0, "back": 10.0, "depth": 28.0,
						"hitstun": 0.35, "knockback": 130.0, "hitstop": 0.06, "shake": 4.0, "spark": "blunt"})}]},
					# 포자 던지기 (원거리)
					{"anim": "attack2", "range": [140.0, 520.0], "lane": 26.0,
					 "frame_times": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.07, 0.14],
					 "projectile": {"frame": 6, "speed": 360.0, "z": 48.0,
						"sheet": {"path": ENEMY_DIR + "Mushroom/Sprites/Projectile_sprite.png", "frame_width": 50},
						"attack": Combat.attack({
							"reach": 22.0, "back": 22.0, "depth": 22.0, "z_min": -30.0, "z_max": 30.0,
							"hitstun": 0.35, "knockback": 120.0, "hitstop": 0.05, "shake": 3.0, "spark": "blunt"})}},
				],
				"elite_attacks": [
					# 포자 폭발 (주변 광역, 띄움)
					{"anim": "attack3", "range": [0.0, 120.0], "lane": 70.0,
					 "frame_times": [0.07, 0.07, 0.07, 0.1, 0.1, 0.1, 0.1, 0.06, 0.06, 0.08, 0.1],
					 "hits": [{"from": 7, "to": 8, "attack": Combat.attack({
						"reach": 130.0, "back": 130.0, "depth": 75.0,
						"launch": 420.0, "knockback": 120.0, "hitstop": 0.08, "shake": 6.0, "spark": "heavy"})}]},
				],
			}
		"flyingeye":
			return {
				"hp": 11000.0, "power": 850.0, "speed": Vector2(150, 110),
				"cooldown": 1.9, "scale": 2.2, "offset": Vector2(-2, -18),
				"body_height": 60.0, "body_radius": 18.0, "bar_lines": 1,
				"hover": 75.0,				# 비행형 : 이 높이에 떠 있음, 맞으면 추락
				"death_sound": SFX_DIR + "flyingeyes.wav",
				"sheets": _sheets("FlyingEye", {"idle": "Flight.png", "run": "Flight.png", "attack": "Attack2.png",
					"hit": "Take Hit.png", "death": "Death.png"}),
				"attacks": [
					# 회전 급강하
					{"anim": "attack", "range": [0.0, 150.0], "lane": 20.0, "dive": true,
					 "frame_times": [0.06, 0.06, 0.06, 0.06, 0.06, 0.07, 0.07, 0.12],
					 "steps": [{"frame": 1, "speed": 300.0, "time": 0.2}],
					 "hits": [{"from": 5, "to": 7, "attack": Combat.attack({
						"reach": 70.0, "back": 40.0, "depth": 28.0, "z_min": -90.0, "z_max": 50.0,
						"hitstun": 0.35, "knockback": 120.0, "hitstop": 0.05, "shake": 3.5, "spark": "blunt"})}]},
				],
			}
		"bringer":
			return _bringer_def()
		"fireworm":
			return _fireworm_def()
	push_error("unknown enemy kind: " + kind)
	return {}

## 보스 : 파이어 웜 (90x90 시트, 발 y=58, 몸 중심 x≈43, 원본이 오른쪽을 봄)
##   패턴 : 화염구(2페이즈 3갈래) / 물어뜯기(바닥 예고) / 용암 분출(발밑 예고 원 3~5곳)
static func _fireworm_def() -> Dictionary:
	var worm := ENEMY_DIR + "Boss_FireWorm/Sprites/Worm/"
	var ball := ENEMY_DIR + "Boss_FireWorm/Sprites/Fire Ball/"
	var sheet := func(file: String, fps: float, loop: bool) -> Dictionary:
		return {"path": worm + file, "frame_width": 90, "fps": fps, "loop": loop}
	var spit_times := []
	for i in 16:
		spit_times.append(0.06 if i < 10 else 0.07)
	return {
		"hp": 380000.0, "power": 2000.0, "speed": Vector2(80, 60),
		"cooldown": 1.5, "scale": 4.0, "offset": Vector2(2, -13),
		"body_height": 170.0, "body_radius": 48.0, "bar_lines": 19,
		"armor": 25.0, "launch_scale": 0.45, "boss": true,
		"death_sound": SFX_DIR + "firewarm/worm_death.mp3",
		"attack_sound": SFX_DIR + "firewarm/fire_ball.mp3",
		"sheets": {
			"idle"   : sheet.call("Idle.png", 9.0, true),
			"run"    : sheet.call("Walk.png", 10.0, true),
			"attack" : sheet.call("Attack.png", 14.0, false),
			"hit"    : sheet.call("Get Hit.png", 10.0, false),
			"death"  : sheet.call("Death.png", 8.0, false),
		},
		"patterns": {
			# 화염구 : 입에서 직선으로 날아가는 불덩이 (맞으면 넘어짐)
			"spit": {"anim": "attack", "sound_frame": 11, "fireball_frame": 11, "frame_times": spit_times},
			# 물어뜯기 : 긴 예고 후 앞으로 돌진하며 넓게 물기
			"bite": {"anim": "attack", "telegraph": true, "frames": [6, 7, 8, 9, 10, 11, 12, 13],
				"frame_times": [0.09, 0.09, 0.09, 0.12, 0.05, 0.06, 0.08, 0.12],
				"steps": [{"frame": 4, "speed": 420.0, "time": 0.12}],
				"hits": [{"from": 4, "to": 6, "attack": Combat.attack({
					"reach": 230.0, "back": 10.0, "depth": 60.0, "z_max": 220.0,
					"knockdown": true, "knockback": 300.0, "hitstop": 0.1, "shake": 8.0, "spark": "heavy"})}]},
			# 용암 분출 : 몸을 일으켜 포효 → 플레이어 주변 바닥에서 차례로 폭발
			"eruption": {"anim": "attack", "eruption_frame": 4, "frames": [0, 1, 2, 3, 4, 5, 5, 5],
				"frame_times": [0.08, 0.08, 0.08, 0.08, 0.1, 0.12, 0.12, 0.12]},
		},
		"fireball": {"speed": 520.0, "z": 120.0, "muzzle": 150.0, "max_distance": 1000.0,
			"sheet": {"path": ball + "Move.png", "frame_width": 46, "fly_count": 6,
				"burst_path": ball + "Explosion.png", "burst_frame_width": 46, "burst_count": 7,
				"scale": 3.0, "burst_sound": SFX_DIR + "firewarm/explosion.wav"},
			"attack": Combat.attack({
				"reach": 34.0, "back": 34.0, "depth": 38.0, "z_min": -140.0, "z_max": 50.0,
				"knockdown": true, "knockback": 220.0, "hitstop": 0.07, "shake": 5.0, "spark": "heavy"})},
		"eruption": {"sheet": {"path": ball + "Explosion.png", "frame_width": 46, "fps": 14.0, "loop": false},
			"sound": SFX_DIR + "firewarm/explosion.wav",
			"attack": Combat.attack({
				"reach": 70.0, "back": 70.0, "depth": 42.0, "z_min": -20.0, "z_max": 220.0,
				"launch": 560.0, "knockback": 60.0, "hitstop": 0.08, "shake": 6.0, "spark": "heavy"})},
		"attacks": [],
	}

## 보스 : 브링어 오브 데스 (140x93 격자 시트, 8열, 원본이 왼쪽을 봄)
static func _bringer_def() -> Dictionary:
	var path := ENEMY_DIR + "Boss_BringOfDeath/Sprites/Bringer-of-Death-SpritSheet.png"
	var cell := func(row: int, col: int, count: int, fps: float, loop: bool) -> Dictionary:
		return {"path": path, "frame_width": 140, "frame_height": 93, "fps": fps, "loop": loop,
			"cells": SpriteSheet.cells_range(row, col, count, 8)}
	var dissolve: Array = SpriteSheet.cells_range(3, 4, 7, 8)
	var reform := dissolve.duplicate()
	reform.reverse()
	return {
		"hp": 400000.0, "power": 2200.0, "speed": Vector2(95, 70),
		"cooldown": 1.6, "scale": 3.0, "offset": Vector2(-36, -45),
		"body_height": 160.0, "body_radius": 34.0, "bar_lines": 20,
		"armor": 25.0, "launch_scale": 0.45, "faces_left": true, "boss": true,
		"death_sound": SFX_DIR + "bringofdeath/bringofdeath_death.mp3",
		"attack_sound": SFX_DIR + "bringofdeath/bringofdeath_attack.wav",
		"sheets": {
			"idle"    : cell.call(0, 0, 8, 8.0, true),
			"run"     : cell.call(1, 0, 8, 9.0, true),
			"attack"  : cell.call(2, 0, 9, 10.0, false),
			"hit"     : cell.call(3, 1, 3, 10.0, false),
			"death"   : cell.call(3, 4, 11, 8.0, false),
			"cast"    : cell.call(4, 7, 9, 10.0, false),
			"dissolve": {"path": path, "frame_width": 140, "frame_height": 93, "fps": 12.0, "loop": false, "cells": dissolve},
			"reform"  : {"path": path, "frame_width": 140, "frame_height": 93, "fps": 12.0, "loop": false, "cells": reform},
		},
		"spell_sheet": {"path": path, "frame_width": 140, "frame_height": 93, "fps": 14.0, "loop": false,
			"cells": SpriteSheet.cells_range(6, 0, 16, 8)},
		"patterns": {
			# 낫 휘두르기 : 긴 예고 후 넓은 범위 (넘어뜨림)
			"scythe": {"anim": "attack", "telegraph": true, "sound_frame": 4,
				"frame_times": [0.11, 0.11, 0.11, 0.16, 0.06, 0.08, 0.1, 0.1, 0.12],
				"hits": [{"from": 4, "to": 5, "attack": Combat.attack({
					"reach": 310.0, "back": 20.0, "depth": 60.0, "z_max": 220.0,
					"knockdown": true, "knockback": 260.0, "hitstop": 0.1, "shake": 8.0, "spark": "heavy"})}]},
			# 주문 : 플레이어 발밑(2페이즈엔 주변 포함 3곳)에 어둠의 손 소환
			"cast": {"anim": "cast", "spell_frame": 5,
				"frame_times": [0.09, 0.09, 0.09, 0.09, 0.09, 0.12, 0.12, 0.1, 0.1]},
			# 2페이즈 : 사라졌다가 플레이어 등 뒤에서 나타나 바로 낫 휘두르기
			"teleport": {"anim": "dissolve", "teleport": true, "then": "reform",
				"frame_times": [0.06, 0.06, 0.06, 0.06, 0.07, 0.08, 0.1]},
			"reform": {"anim": "reform", "then": "scythe",
				"frame_times": [0.06, 0.06, 0.06, 0.06, 0.06, 0.06, 0.08]},
		},
		"spell_attack": Combat.attack({
			"reach": 45.0, "back": 45.0, "depth": 32.0, "z_min": -20.0, "z_max": 160.0,
			"launch": 520.0, "knockback": 40.0, "hitstop": 0.08, "shake": 6.0, "spark": "heavy"}),
		"attacks": [],
	}

static func _sheets(folder: String, files: Dictionary) -> Dictionary:
	var dir := ENEMY_DIR + folder + "/Sprites/"
	var loops := {"idle": true, "run": true, "shield": true}
	var fps := {"idle": 8.0, "run": 12.0, "shield": 10.0, "hit": 14.0, "death": 8.0}
	var result := {}
	for anim in files:
		result[anim] = {"path": dir + files[anim], "frame_width": 150,
			"fps": fps.get(anim, 12.0), "loop": loops.get(anim, false)}
	return result
