extends SceneTree
## 용암 동굴 던전 헤드리스 테스트 (배경 / 용암 화상 / 보스 파이어 웜)
## 실행 (프로젝트 폴더에서):
##   Godot_v4.2.1-stable_win64_console.exe --headless --path . --script res://dynamic/8_action/tests/cave_smoke_test.gd

const STAGE_SCENE := "res://dynamic/8_action/stage/action_stage.tscn"

var ActionStage : GDScript
var stage
var player
var results := []
var _step := 0
var _frame := 0
var _data := {}

func _initialize():
	ActionStage = load("res://dynamic/8_action/stage/action_stage.gd")
	ActionStage.selected_character = "warrior"
	ActionStage.selected_dungeon = "cave"
	stage = load(STAGE_SCENE).instantiate()
	stage.save_rewards = false
	stage.recruit_chance = 0.0
	stage.elite_recruit_chance = 0.0
	root.add_child(stage)

func _physics_process(_delta):
	if not is_instance_valid(player):
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
	stage._enemy_count = 0
	stage._next_wave_timer = -1.0

func count_nodes(script_path: String) -> int:
	var script = load(script_path)
	return stage.actors.get_children().filter(func(n): return n.get_script() == script).size()

func next_step():
	_step += 1
	_frame = 0
	_data.clear()

func _run_step():
	match _step:
		0:	# ── 던전 구성 / 배경 ──
			if _frame == 1:
				check("cave dungeon selected", stage.dungeon.name == "용암 동굴", stage.dungeon.name)
				check("cave backdrop used", stage.backdrop.get_script().resource_path.ends_with("cave_backdrop.gd"))
				check("room 1 has lava pool", stage.backdrop.hazards.size() == 1 and stage.backdrop._pools.size() == 1)
				next_step()
		1:	# ── 용암 : 플레이어 화상 + 튕겨 나감 ──
			if _frame == 1:
				clear_enemies()
				var lava: Rect2 = stage.backdrop.hazards[0]
				player.reset_pose()
				player.position = lava.get_center()
				_data.hp = player.hp
			if _frame == 20:
				check("lava burns player", player.hp < _data.hp, "hp -%d" % int(_data.hp - player.hp))
			if _frame == 90:
				var lava: Rect2 = stage.backdrop.hazards[0]
				check("player pushed out of lava", not lava.has_point(player.position), str(player.position))
				player.hp = player.max_hp
				next_step()
		2:	# ── 용암 : 적도 화상 ──
			if _frame == 1:
				player.position = Vector2(300, 560)
				var lava: Rect2 = stage.backdrop.hazards[0]
				var goblin = stage.spawn_enemy("goblin", lava.get_center())
				goblin._think = 5.0
				goblin._attack_cd = 99.0
				goblin.position = lava.get_center()
				_data.goblin = goblin
			if _frame == 20:
				check("lava burns enemies", _data.goblin.hp < _data.goblin.max_hp, "hp -%d" % int(_data.goblin.max_hp - _data.goblin.hp))
				clear_enemies()
				next_step()
		3:	# ── 보스방 : 파이어 웜 ──
			if _frame == 1:
				stage.load_room(stage.rooms.size() - 1, false)
				player.max_hp = 9999999.0
				player.hp = player.max_hp
				_data.hp = player.hp
				_data.fireball = false
				_data.eruption = false
			if _frame == 3:
				check("fireworm boss spawns", stage.boss != null and stage.boss.kind == "fireworm")
				check("fireworm has super armor", stage.boss.has_super_armor())
				player.position = stage.boss.position - Vector2(420, 0)
			if count_nodes("res://dynamic/8_action/enemy/projectile.gd") > 0:
				_data.fireball = true
			if count_nodes("res://dynamic/8_action/enemy/boss_spell.gd") > 0:
				_data.eruption = true
			if _frame == 600:
				check("fireworm uses fireball or eruption", _data.fireball or _data.eruption,
					"fireball %s, eruption %s" % [_data.fireball, _data.eruption])
				check("fireworm damages player", player.hp < _data.hp, "hp -%d" % int(_data.hp - player.hp))
				next_step()
		4:	# ── 2페이즈 : 화염구 3갈래 / 용암 분출 5곳 ──
			var boss = stage.boss
			if _frame == 1:
				for node in stage.actors.get_children():
					if node.get_script() in [load("res://dynamic/8_action/enemy/projectile.gd"), load("res://dynamic/8_action/enemy/boss_spell.gd")]:
						node.queue_free()
				boss.hp = boss.max_hp * 0.4
			if _frame == 3:
				check("fireworm enters phase 2", boss.phase == 2)
				boss.state = 0
				boss._start_attack(boss.def.patterns.spit)
			if _frame == 75:
				check("phase 2 spits 3 fireballs", count_nodes("res://dynamic/8_action/enemy/projectile.gd") == 3,
					"%d" % count_nodes("res://dynamic/8_action/enemy/projectile.gd"))
				boss.state = 0
				boss._start_attack(boss.def.patterns.eruption)
			if _frame == 95:
				check("phase 2 erupts 5 spots", count_nodes("res://dynamic/8_action/enemy/boss_spell.gd") == 5,
					"%d" % count_nodes("res://dynamic/8_action/enemy/boss_spell.gd"))
				next_step()
		5:	# ── 보스 처치 → 결과창 ──
			if _frame == 1:
				var boss = stage.boss
				boss.hp = 1.0
				boss.state = 0
				boss._attack_cd = 99.0
				player.reset_pose()
				player.position = boss.position - Vector2(90, 0)
				player.facing = 1
				Input.action_press("act_attack")
			if _frame == 3:
				Input.action_release("act_attack")
			if _frame == 260:
				check("cave clear shows result", stage._dungeon_clear and stage.hud._result_panel != null)
				var failed := results.filter(func(r): return not r[1]).size()
				print("RESULT  %d/%d passed" % [results.size() - failed, results.size()])
				quit(1 if failed > 0 else 0)
