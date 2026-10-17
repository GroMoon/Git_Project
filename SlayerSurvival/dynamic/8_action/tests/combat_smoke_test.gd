extends SceneTree
## 액션 모드 헤드리스 스모크 테스트 (입력 시뮬레이션 → 상태 검사)
## 실행 (프로젝트 폴더에서):
##   Godot_v4.2.1-stable_win64_console.exe --headless --path . --script res://dynamic/8_action/tests/combat_smoke_test.gd
## 결과 : 항목별 PASS/FAIL 출력 후 종료 (FAIL이 있으면 exit code 1)

const STAGE_SCENE := "res://dynamic/8_action/stage/action_stage.tscn"
const ATTACK_STATE := 5		# ActionPlayer.State.ATTACK
const DUNGEON_ROOMS = preload("res://dynamic/8_action/stage/dungeon_data.gd").ROOMS

var stage
var player
var results := []
var _step := 0
var _frame := 0
var _data := {}

func _initialize():
	stage = load(STAGE_SCENE).instantiate()
	stage.save_rewards = false		# 테스트가 세이브 파일(골드)을 건드리지 않도록
	stage.recruit_chance = 0.0		# 무작위 동료 합류가 다른 검사에 끼어들지 않도록
	stage.elite_recruit_chance = 0.0
	root.add_child(stage)

func _physics_process(_delta):
	if player == null:
		player = stage.player
		return false
	_frame += 1
	_run_step()
	return false

func check(name: String, ok: bool, detail := ""):
	results.append([name, ok])
	print(("PASS  " if ok else "FAIL  ") + name + ("" if detail == "" else "  (" + detail + ")"))

func enemies() -> Array:
	return get_nodes_in_group("action_enemy")

func clear_enemies():
	for e in enemies():
		e.remove_from_group("action_enemy")
		e.queue_free()
	stage._next_wave_timer = -1.0
	stage._enemy_count = 0

func tap(action: String, at: int, hold := 2):
	if _frame == at:
		Input.action_press(action)
	elif _frame == at + hold:
		Input.action_release(action)

func _avg_dist() -> float:
	var list := enemies()
	if list.is_empty():
		return 0.0
	var total := 0.0
	for e in list:
		total += absf(e.position.x - player.position.x) + absf(e.position.y - player.position.y)
	return total / list.size()

func next_step():
	_step += 1
	_frame = 0
	_data.clear()
	reset_player()

## 진행 중인 기술/선입력을 끊고 대기 상태로
func reset_player():
	for action in ["act_attack", "act_jump", "act_left", "act_right", "act_up", "act_down", "act_backstep",
			"act_skill_1", "act_skill_2", "act_skill_3", "act_skill_4"]:
		Input.action_release(action)
	player.state = 0
	player.attack_buffer = 0.0
	player.jump_buffer = 0.0
	player.velocity = Vector2.ZERO
	player.z = 0.0
	player.z_velocity = 0.0
	player.invuln_timer = 0.0
	player.visual.rotation = 0.0

func _run_step():
	match _step:
		0:	# ── 3타 콤보 체인 + 몰이 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(800, 560)
				player.facing = 1
				stage.spawn_enemy("goblin", Vector2(870, 520))
				stage.spawn_enemy("goblin", Vector2(900, 600))
				stage.spawn_enemy("mushroom", Vector2(940, 560))
				_data.moves = []
			for e in enemies():
				if e.state <= 1:
					e._think = 1.0		# AI 정지 (제자리 대기)
					e._attack_cd = 99.0
			if _frame > 2 and _frame % 8 == 3:
				Input.action_press("act_attack")
			elif _frame > 2 and _frame % 8 == 5:
				Input.action_release("act_attack")
			if player.state == ATTACK_STATE and (_data.moves.is_empty() or _data.moves[-1] != player.move_name):
				_data.moves.append(player.move_name)
			if _frame == 100:
				var ys := enemies().map(func(e): return e.position.y)
				var spread: float = ys.max() - ys.min()
				check("combo chain atk1>atk2>atk3", str(_data.moves).begins_with('["atk1", "atk2", "atk3"'), str(_data.moves))
				check("combo counter increases", stage.fx.max_combo >= 6, "max_combo=%d" % stage.fx.max_combo)
				check("mob gather: depth spread shrinks", spread < 40.0, "spread=%.1f (start 80)" % spread)
				check("launcher: enemy airborne", enemies().any(func(e): return e.z > 60.0))
				Input.action_release("act_attack")
				next_step()
		1:	# ── 스켈레톤 가드 / 가드 브레이크 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(800, 560)
				player.facing = 1
				var skel = stage.spawn_enemy("skeleton", Vector2(890, 560))
				skel.guard_chance = 1.0
				skel._attack_cd = 99.0
				skel.facing = -1
				_data.guarded = false
			tap("act_attack", 10)
			var skel = enemies()[0] if not enemies().is_empty() else null
			if skel and skel.state == 7:	# GUARD
				_data.guarded = true
			if _frame == 40:
				check("skeleton frontal guard", _data.guarded)
				next_step()
		2:	# ── 엘리트 슈퍼아머 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(800, 560)
				player.facing = 1
				var elite = stage.spawn_enemy("goblin", Vector2(880, 560), true)
				elite._attack_cd = 99.0
				_data.hurt_while_armored = false
				_data.broke = false
			var elite = enemies()[0] if not enemies().is_empty() else null
			if elite:
				if elite.has_super_armor() and elite.state == 3:	# HURT
					_data.hurt_while_armored = true
				if elite._armor_break_timer > 0.0:
					_data.broke = true
			if _frame > 2 and _frame % 8 == 3:
				Input.action_press("act_attack")
			elif _frame > 2 and _frame % 8 == 5:
				Input.action_release("act_attack")
			if _frame == 200:
				check("no hitstun while super armor", not _data.hurt_while_armored)
				check("armor break happens", _data.broke)
				Input.action_release("act_attack")
				next_step()
		3:	# ── 비행형 : 떠 있다가 맞으면 추락 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(800, 560)
				player.facing = 1
				var eye = stage.spawn_enemy("flyingeye", Vector2(890, 560))
				eye._attack_cd = 99.0
				_data.fell = false
			var eye = enemies()[0] if not enemies().is_empty() else null
			if _frame == 20 and eye:
				check("flyer hovers", eye.z > 50.0, "z=%.1f" % eye.z)
			tap("act_attack", 24)
			if eye and eye.state == 4:	# AIR
				_data.fell = true
			if _frame == 60:
				check("flyer falls when hit (AIR)", _data.fell)
				next_step()
		4:	# ── 원거리 : 머쉬룸 포자 투사체 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(600, 560)
				player.facing = 1
				var shroom = stage.spawn_enemy("mushroom", Vector2(950, 560))
				shroom._attack_cd = 0.0
				_data.hp = player.hp
				_data.shot = false
			for node in stage.actors.get_children():
				if node.get_script() == preload("res://dynamic/8_action/enemy/projectile.gd"):
					_data.shot = true
			if _frame == 240:
				check("mushroom fires spore", _data.shot)
				check("spore damages player", player.hp < _data.hp, "hp %d -> %d" % [_data.hp, player.hp])
				next_step()
		5:	# ── 웨이브 클리어 → 다음 웨이브 ──
			if _frame == 1:
				clear_enemies()
				player.hp = player.max_hp
				var last = stage.spawn_enemy("goblin", Vector2(880, 560))
				last.hp = 1.0
				last._attack_cd = 99.0
				player.position = Vector2(800, 560)
				player.facing = 1
				_data.wave = stage.wave_index
			tap("act_attack", 5)
			if _frame == 260:
				check("wave clear -> next wave", stage.wave_index != _data.wave and enemies().size() > 0,
					"wave %d -> %d, enemies %d" % [_data.wave, stage.wave_index, enemies().size()])
				next_step()
		6:	# ── 스킬 S : 회오리 베기 (빨아들여 모으기 → 띄우기) ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(1000, 560)
				player.facing = 1
				player.mp = player.max_mp
				player.cooldowns.clear()
				for offset in [Vector2(-220, -90), Vector2(230, 100), Vector2(-150, 110), Vector2(200, -80)]:
					stage.spawn_enemy("goblin", Vector2(1000, 560) + offset)
				_data.start_dist = _avg_dist()
				_data.min_dist = 9999.0
				_data.max_z = 0.0
			for e in enemies():
				if e.state <= 1:
					e._think = 1.0
					e._attack_cd = 99.0
				_data.max_z = maxf(_data.max_z, e.z)
			tap("act_skill_2", 5)
			if _frame == 8:
				check("skill S starts whirlwind", player.move_name == "whirlwind", player.move_name)
				check("skill uses MP + cooldown", player.mp < player.max_mp and player.get_cooldown("whirlwind") > 0.0,
					"mp=%d cd=%.1f" % [player.mp, player.get_cooldown("whirlwind")])
			if _frame > 8 and _frame < 45:
				_data.min_dist = minf(_data.min_dist, _avg_dist())
			if _frame == 70:
				check("whirlwind vacuums enemies in", _data.min_dist < _data.start_dist * 0.5,
					"avg dist %.0f -> %.0f" % [_data.start_dist, _data.min_dist])
				check("whirlwind finisher launches", _data.max_z > 80.0, "max z %.0f" % _data.max_z)
				next_step()
		7:	# ── 스킬 A : 어퍼 슬래시 / 평타 → 스킬 캔슬 ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(800, 560)
				player.facing = 1
				player.mp = player.max_mp
				player.cooldowns.clear()
				var dummy = stage.spawn_enemy("skeleton", Vector2(880, 560))
				dummy.guard_chance = 0.0
				_data.moves = []
				_data.max_z = 0.0
			for e in enemies():
				if e.state <= 1:
					e._think = 1.0
					e._attack_cd = 99.0
				_data.max_z = maxf(_data.max_z, e.z)
			if player.state == ATTACK_STATE and (_data.moves.is_empty() or _data.moves[-1] != player.move_name):
				_data.moves.append(player.move_name)
			tap("act_attack", 3)
			tap("act_skill_1", 9)
			if _frame == 60:
				check("basic attack cancels into skill", str(_data.moves) == '["atk1", "upper_slash"]' or str(_data.moves).begins_with('["atk1", "upper_slash"'), str(_data.moves))
				check("upper slash launches high", _data.max_z > 150.0, "max z %.0f" % _data.max_z)
				next_step()
		8:	# ── 스킬 D : 섬광 돌진 (무적 + 장거리 이동 + 경로상 다수 타격) ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(600, 560)
				player.facing = 1
				player.mp = player.max_mp
				player.cooldowns.clear()
				for x in [700, 760, 820]:
					stage.spawn_enemy("goblin", Vector2(x, 560 + (x - 760) * 0.5))
				_data.start_x = player.position.x
				_data.invuln = false
				_data.hp_sum = enemies().reduce(func(a, e): return a + e.hp, 0.0)
			for e in enemies():
				if e.state <= 1:
					e._think = 1.0
					e._attack_cd = 99.0
			tap("act_skill_3", 3)
			if player.move_name == "charge_slash" and not player.can_be_hit():
				_data.invuln = true
			if _frame == 50:
				var hp_now: float = enemies().reduce(func(a, e): return a + e.hp, 0.0)
				var hit_count: int = enemies().filter(func(e): return e.hp < e.max_hp).size()
				check("charge dash travels far", player.position.x - _data.start_x > 200.0, "moved %.0f" % (player.position.x - _data.start_x))
				check("charge is invulnerable", _data.invuln)
				check("charge hits all 3 on path", hit_count == 3, "hit %d" % hit_count)
				next_step()
		9:	# ── 스킬 F : 파멸의 일격 (광역 + 띄우기) ──
			if _frame == 1:
				clear_enemies()
				player.position = Vector2(1000, 560)
				player.facing = 1
				player.mp = player.max_mp
				player.cooldowns.clear()
				for offset in [Vector2(-200, -80), Vector2(250, 90), Vector2(120, -100), Vector2(-60, 120)]:
					stage.spawn_enemy("mushroom", Vector2(1000, 560) + offset)
				_data.max_z = {}
			for e in enemies():
				if e.state <= 1:
					e._think = 1.0
					e._attack_cd = 99.0
				_data.max_z[e] = maxf(_data.max_z.get(e, 0.0), e.z)
			tap("act_skill_4", 3)
			if _frame == 90:
				var launched: int = _data.max_z.values().filter(func(v): return v > 60.0).size()
				check("ultimate hits all 4 around", enemies().all(func(e): return e.hp < e.max_hp), "")
				check("ultimate launches all", launched == 4, "launched %d" % launched)
				next_step()
		10:	# ── 방 클리어 → 포털 열림 → 다음 방 ──
			if _frame == 1:
				clear_enemies()
				stage.wave_index = DUNGEON_ROOMS[stage.room_index].waves.size() - 1
				player.position = Vector2(800, 560)
				player.facing = 1
				var last = stage.spawn_enemy("goblin", Vector2(880, 560))
				last.hp = 1.0
				last._attack_cd = 99.0
				_data.room = stage.room_index
			tap("act_attack", 5)
			if _frame == 90:
				check("room clear offers boons (paused)", stage.boon_panel != null and paused,
					"panel %s paused %s" % [stage.boon_panel != null, paused])
				check("portal stays closed while choosing", not stage.portal.is_open)
				_data.power = player.attack_power
				_data.boon = stage.boon_panel.options[0].id
				stage.boon_panel.choose(0)
			if _frame == 94:
				check("boon chosen -> unpause + portal opens", not paused and stage.portal.is_open)
				check("boon applied to player", player.boons.has(_data.boon), str(player.boons))
				player.position = stage.portal.position
			if _frame == 175:
				check("portal moves to next room", stage.room_index == _data.room + 1,
					"room %d -> %d" % [_data.room, stage.room_index])
				check("next room spawns enemies", enemies().size() > 0, "enemies %d" % enemies().size())
				next_step()
		11:	# ── 보스방 : 보스 등장 / 슈퍼아머 / 공격 패턴 ──
			if _frame == 1:
				stage.load_room(DUNGEON_ROOMS.size() - 1, false)
				player.max_hp = 9999999.0
				player.hp = player.max_hp
				_data.hp = player.hp
				_data.pattern_seen = false
			if _frame == 3:
				check("boss spawns in last room", stage.boss != null and is_instance_valid(stage.boss))
				check("boss has super armor", stage.boss.has_super_armor())
				player.position = stage.boss.position - Vector2(240, 0)
			if stage.boss and is_instance_valid(stage.boss) and stage.boss.state == 2:	# ATTACK
				_data.pattern_seen = true
			if _frame == 420:
				check("boss uses attack patterns", _data.pattern_seen)
				check("boss damages player", player.hp < _data.hp, "hp -%d" % int(_data.hp - player.hp))
				next_step()
		12:	# ── 보스 처치 → 슬로우 모션 → 결과창 ──
			if _frame == 1:
				player.state = 0
				var b = stage.boss
				b.hp = 1.0
				b.state = 0
				b._attack_cd = 99.0
				player.position = b.position - Vector2(b.facing * -1 * 0 + 90, 0)
				player.position.y = b.position.y
				player.facing = 1 if b.position.x > player.position.x else -1
			tap("act_attack", 4)
			if _frame == 30:
				check("boss death triggers slow motion", Engine.time_scale < 1.0, "time_scale %.2f" % Engine.time_scale)
			if _frame == 260:
				check("dungeon clear shows result", stage._dungeon_clear and stage.hud._result_panel != null)
				next_step()
		13:	# ── 몬스터 동료 : 적 공격 / 플레이어 따라다니기 / 방 이동 유지 ──
			if _frame == 1:
				stage.load_room(0, false)
				clear_enemies()
				player.hp = player.max_hp
				player.position = Vector2(500, 560)
				player.facing = 1
				_data.ally = stage.recruit("goblin", Vector2(560, 520))
				var dummy = stage.spawn_enemy("skeleton", Vector2(820, 560))
				dummy.guard_chance = 0.0
				dummy.hp = 999999.0
				dummy.max_hp = 999999.0
				_data.dummy = dummy
			if is_instance_valid(_data.dummy) and _data.dummy.state <= 1:
				_data.dummy._think = 1.0
				_data.dummy._attack_cd = 99.0
			if _frame == 240:
				check("ally attacks enemies", _data.dummy.hp < _data.dummy.max_hp,
					"dummy hp -%d" % int(_data.dummy.max_hp - _data.dummy.hp))
				clear_enemies()
				player.position = Vector2(1400, 600)
			if _frame == 400:
				var dist: float = _data.ally.position.distance_to(player.position)
				check("ally follows player", dist < 250.0, "dist %.0f" % dist)
				stage.load_room(1, false)
			if _frame == 404:
				check("ally persists to next room", is_instance_valid(_data.ally) and _data.ally.is_inside_tree()
					and stage.party.has(_data.ally))
				next_step()
		14:
			var failed := results.filter(func(r): return not r[1]).size()
			print("RESULT  %d/%d passed" % [results.size() - failed, results.size()])
			quit(1 if failed > 0 else 0)
