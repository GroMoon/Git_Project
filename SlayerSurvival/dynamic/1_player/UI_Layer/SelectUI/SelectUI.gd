extends Control

signal pause

@onready var selectUI_panel = $select_panel
@onready var upgrade_container = $select_panel/upgrade_container

var player
var character_features

var upgrade_preload = {
	"increase_max_hp" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_increase_max_hp.tscn"), 50],
	"increase_damage" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_increase_damage.tscn"), 50],
	"increase_moving_speed" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_increase_moving_speed.tscn"), 50],
	"drain_blood" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_drain_blood.tscn"), 20],
	"shadow_partner" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_shadow_partner.tscn"), 15],
	"increase_magnetic_area" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_increase_magnetic_area.tscn"), 50],
	"shield" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_shield.tscn"), 50],
	"cooldown" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/S_cooldown.tscn"), 50]
}

func _init_after_parent_ready():
	player = get_parent().get_parent()
	var character_name = player.character_name
	if character_name == "fantasy_warrior":
		character_features = {
			"combo2" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Fantasy_Warrior/S_combo2.tscn"), 10],
			"combo3" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Fantasy_Warrior/S_combo3.tscn"), 0],
		}
	elif character_name == "medieval_king":
		character_features = {
			"combo2" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Medieval_King/S_combo2.tscn"), 10],
			"combo3" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Medieval_King/S_combo3.tscn"), 0],
		}
	elif character_name == "wizard":
		character_features = {
			"combo2" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Wizard/S_lightning2.tscn"), 10],
			"combo3" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/Wizard/S_lightning3.tscn"), 0],
		}
	else:
		print("character_name을 찾을 수 없음")
		pass
	for key in character_features.keys():			# 특성 append
		upgrade_preload[key] = character_features[key]
	selectUI_panel.visible = false
	player.connect("levelup", Callable(self, "create_upgrade_selection"))

func _ready():
	call_deferred("_init_after_parent_ready")

func _process(_delta):
	pass

# 업그레이드 선택 생성
func create_upgrade_selection():
	emit_signal("pause", true)						# 퍼즈 신호 BaseUI에 보내기
	var select_temp = []
	selectUI_panel.visible = true
	select_temp = select_random_upgrades(3)			# select_temp에 랜덤으로 3개를 저장
	# 선택된 3개의 업그레이드를 인스턴스
	for upgrade_key in select_temp:
		var button_instance = upgrade_preload[upgrade_key][0].instantiate()
		upgrade_container.add_child(button_instance)
		button_instance.connect("pressed", Callable(self, "_on_upgrade_button_pressed").bind(upgrade_key))

# 확률 설정
func select_random_upgrades(count: int) -> Array:
	var total_weight = 0
	var weighted_keys = []
	var selected = []

	# 전체 가중치 저장 및 최신화된 keys 및 weight를 weighted_keys에 추가
	for key in upgrade_preload.keys():
		var weight = upgrade_preload[key][1]
		if weight > 0:  # 가중치가 0보다 큰 것만 선택 대상으로 추가
			total_weight += weight
			weighted_keys.append({ "key": key, "weight": weight })

	# count 만큼 가중치에 의해 계산된 랜덤을 선택
	for i in range(count):
		if weighted_keys.size() == 0:
			selected.append("food")  # 더 이상 선택할 업그레이드가 없으면 food 추가
			continue

		var random_value = randi() % total_weight
		for item in weighted_keys:
			random_value -= item["weight"]
			if random_value < 0:
				selected.append(item["key"])
				total_weight -= item["weight"]
				weighted_keys.erase(item)
				break

	# 부족한 만큼 food로 채움
	while selected.size() < count:
		selected.append("food")

	return selected

# 업그레이드 적용
func _on_upgrade_button_pressed(upgrade_key):
	match upgrade_key:
		"increase_max_hp":
			player.max_hp_level += 1
			player.max_hp += 10
			match player.max_hp_level:
				1:
					upgrade_preload["increase_max_hp"][1] = 40
				2:
					upgrade_preload["increase_max_hp"][1] = 30
				3:
					upgrade_preload["increase_max_hp"][1] = 20
				4:
					upgrade_preload["increase_max_hp"][1] = 10
				5:
					upgrade_preload["increase_max_hp"][1] = 0
					print("체력증가 최대 레벨 도달")

		"increase_damage":
			player.damage_level += 1
			player.attack_damage += 3
			match player.damage_level:
				1:
					upgrade_preload["increase_damage"][1] = 40
				2:
					upgrade_preload["increase_damage"][1] = 30
				3:
					upgrade_preload["increase_damage"][1] = 20
				4:
					upgrade_preload["increase_damage"][1] = 10
				5:
					upgrade_preload["increase_damage"][1] = 0
					print("공격력 증가 최대 레벨 도달")

		"increase_moving_speed":
			player.move_speed_level += 1
			player.move_speed += 5
			match player.move_speed_level:
				1:
					upgrade_preload["increase_moving_speed"][1] = 40
				2:
					upgrade_preload["increase_moving_speed"][1] = 30
				3:
					upgrade_preload["increase_moving_speed"][1] = 20
				4:
					upgrade_preload["increase_moving_speed"][1] = 10
				5:
					upgrade_preload["increase_moving_speed"][1] = 0
					print("이동속도 증가 최대 레벨 도달")

		"drain_blood":
			player.drain_level += 1
			player.vampire += 0.01
			match player.drain_level:
				1:
					upgrade_preload["drain_blood"][1] = 10
				2:
					upgrade_preload["drain_blood"][1] = 8
				3:
					upgrade_preload["drain_blood"][1] = 6
				4:
					upgrade_preload["drain_blood"][1] = 4
				5:
					upgrade_preload["drain_blood"][1] = 0
					print("흡혈 최대 레벨 도달")

		"increase_magnetic_area":
			player.magnetic_area_level += 1
			player.magnetic_area_scale += 20.0
			match player.magnetic_area_level:
				1:
					upgrade_preload["increase_magnetic_area"][1] = 40
				2:
					upgrade_preload["increase_magnetic_area"][1] = 30
				3:
					upgrade_preload["increase_magnetic_area"][1] = 20
				4:
					upgrade_preload["increase_magnetic_area"][1] = 10
				5:
					upgrade_preload["increase_magnetic_area"][1] = 0
					print("자석 범위 증가 최대 레벨 도달")

		"shadow_partner":
			player.shadow_partner_level += 1
			match player.shadow_partner_level:
				1:
					player.shadow_attack = true
					upgrade_preload["shadow_partner"][1] = 10
				2:
					upgrade_preload["shadow_partner"][1] = 5
				3:
					upgrade_preload["shadow_partner"][1] = 0

		"shield":
			player.shield_level += 1
			player.shield += 0.05
			match player.shield_level:
				1:
					upgrade_preload["shield"][1] = 40
				2:
					upgrade_preload["shield"][1] = 30
				3:
					upgrade_preload["shield"][1] = 20
				4:
					upgrade_preload["shield"][1] = 10
				5:
					upgrade_preload["shield"][1] = 0

		"cooldown":
			player.cooldown_level += 1
			player.cooldown += 0.02
			match player.cooldown_level:
				1:
					upgrade_preload["cooldown"][1] = 40
				2:
					upgrade_preload["cooldown"][1] = 30
				3:
					upgrade_preload["cooldown"][1] = 20
				4:
					upgrade_preload["cooldown"][1] = 10
				5:
					upgrade_preload["cooldown"][1] = 0
# =============== 캐릭터 특성 ==================
		"combo2":
			player.attack_times_level += 1
			player.attack_times = 2
			upgrade_preload["combo2"][1] = 0
			upgrade_preload["combo3"][1] = 5
		"combo3":
			player.attack_times_level += 1
			player.attack_times = 3
			upgrade_preload["combo3"][1] = 0

# =============== 음식 ==================
		"food":
			player.current_hp += 10
		_:
			print("ERROR -> 아무것도 선택되지 않음")
			pass

	# 업그레이드 버튼 초기화 (count 갯수의 선택 창들을 모두 제거)
	for child in upgrade_container.get_children():
		child.queue_free()
	
	selectUI_panel.visible = false
	emit_signal("pause", false)
