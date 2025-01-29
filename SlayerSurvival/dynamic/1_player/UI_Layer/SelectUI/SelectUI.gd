extends Control

signal pause

@onready var selectUI_panel = $select_panel
@onready var upgrade_container = $select_panel/upgrade_container

var upgrade_preload = {
	"increase_max_hp" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/increase_max_hp.tscn"), 50],
	"increase_damage" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/increase_damage.tscn"), 50],
	"increase_moving_speed" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/increase_moving_speed.tscn"), 50],
	"drain_blood" : [preload("res://dynamic/1_player/UI_Layer/SelectUI/drain_blood.tscn"), 20],
}
var player
var character_features

func _ready():
	player = get_parent().get_parent()
	character_features = player.character_feature	# 특성 가져오기
	for key in character_features.keys():			# 특성 append
		upgrade_preload[key] = character_features[key]
	selectUI_panel.visible = false
	player.connect("levelup", Callable(self, "create_upgrade_selection"))

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
		total_weight += weight
		weighted_keys.append({ "key": key, "weight": weight })
	# count 만큼 가중치에 의해 계산된 랜덤을 선택
	for i in range(count):
		var random_value = randi() % total_weight
		for item in weighted_keys:
			random_value -= item["weight"]
			if random_value < 0:
				selected.append(item["key"])
				total_weight -= item["weight"]
				weighted_keys.erase(item)
				break
	return selected

# 업그레이드 적용
func _on_upgrade_button_pressed(upgrade_key):
	match upgrade_key:
		"increase_max_hp":
			player.max_hp += 10
			player.current_hp += 10
			print("최대 체력 증가",player.max_hp)
		"increase_damage":
			player.attack_damage += 5
			print("현재 공격력 : ", player.attack_damage)
		"increase_moving_speed":
			player.move_speed += 10
		"drain_blood":
			print("아직 구현되지 않음")
# =============== 캐릭터 특성 ==================
		"combo2":
			upgrade_preload["combo2"][1] = 0
			upgrade_preload["combo3"][1] = 5
		"combo3":
			upgrade_preload["combo3"][1] = 0
		_:
			print("ERROR -> 아무것도 선택되지 않음")
			pass
	
	# 업그레이드 버튼 초기화 (count 갯수의 선택 창들을 모두 제거)
	for child in upgrade_container.get_children():
		child.queue_free()
	
	selectUI_panel.visible = false
	emit_signal("pause", false)
