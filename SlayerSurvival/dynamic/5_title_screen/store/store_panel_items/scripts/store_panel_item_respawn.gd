extends Panel

@onready var name_label        = $Name_label
@onready var level_label       = $Level_label
@onready var description_label = $Description_label
@onready var cost              = $Cost/Cost_label

var item = {
	"name": "name", 
	"level":  "0",
	"description": "description",
	"cost": "100",
	"icen_path": "",
	"max_level": 2
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# 레벨 표시
	level_label.text = "Level: " + str(StoreData.store_data["STORE_ITEM_RESPAWN"]["level"])
	# 레벨 별 데미지 증가 코스트 표시	
	respawn_cost(StoreData.store_data["STORE_ITEM_RESPAWN"]["level"])
	
	# Connect to store reset signal
	get_parent().get_parent().get_parent().get_parent().get_parent().connect("reset_store", Callable(self, "_on_reset_store"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_reset_store():
	item["level"] = "0"
	level_label.text = "Level: " + str(item["level"])
	respawn_cost(item["level"])

func respawn_upgrade(item_level):
	match item_level:
		"0":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["respawn"] += 1
		"1":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["respawn"] += 1
		"Max":
			pass

func respawn_cost(item_level):
	match item_level:
		"0":
			cost.text = "10000"
		"1":
			cost.text = "20000"
		"Max":
			cost.text = "Max"

func respawn_level():
	match item["level"]:
		"0":
			item["level"] = "1"
		"1":
			item["level"] = "Max"
		"Max":
			pass

func save_respawn_data():
	StoreData.store_data["STORE_ITEM_RESPAWN"]["level"] = item["level"]
	StoreData.save_store_data()

func _on_buy_button_pressed():
	if Global.character_data["GOLD"]["gold"] >= int(cost.text):
		
		var purchase_amount = int(cost.text)
		Global.character_data["GOLD"]["gold"] -= purchase_amount
		Global.emit_signal("purchase")
		
		# 구매 금액 누적
		StoreData.store_data["STORE_ITEM_RESPAWN"]["used_gold"] += purchase_amount
		
		respawn_upgrade(item["level"])
		respawn_level()

		save_respawn_data()
		Global.save_character_data()
		
		level_label.text = "Level: " + str(item["level"])
		respawn_cost(item["level"])
