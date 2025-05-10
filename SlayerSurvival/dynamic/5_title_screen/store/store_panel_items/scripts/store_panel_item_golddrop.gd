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
	"max_level": 5
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# 레벨 표시
	level_label.text = "Level: " + str(StoreData.store_data["STORE_ITEM_GOLD_DROP"]["level"])
	# 레벨 별 데미지 증가 코스트 표시	
	golddrop_cost(StoreData.store_data["STORE_ITEM_GOLD_DROP"]["level"])
	
	# Connect to store reset signal
	get_parent().get_parent().get_parent().get_parent().connect("reset_store", Callable(self, "_on_reset_store"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func golddrop_upgrade(item_level):
	match item_level:
		"0":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"] += 10
		"1":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"] += 10
		"2":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"] += 10
		"3":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"] += 10
		"4":
			Global.character_data["CHARACTER_STORE_UPGRADES"]["gold_drop"] += 10
		"Max":
			pass

func golddrop_cost(item_level):
	match item_level:
		"0":
			cost.text = "100"
		"1":
			cost.text = "200"
		"2":
			cost.text = "300"
		"3":
			cost.text = "400"
		"4":
			cost.text = "500"
		"Max":
			cost.text = "Max"

func golddrop_level():
	match item["level"]:
		"0":
			item["level"] = "1"
		"1":
			item["level"] = "2"
		"2":
			item["level"] = "3"
		"3":
			item["level"] = "4"
		"4":
			item["level"] = "Max"
		"Max":
			pass

func save_golddrop_data():
	StoreData.store_data["STORE_ITEM_GOLD_DROP"]["level"] = item["level"]
	StoreData.save_store_data()

func _on_buy_button_pressed():
	if Global.character_data["GOLD"]["gold"] >= int(cost.text):
		
		var purchase_amount = int(cost.text)
		Global.character_data["GOLD"]["gold"] -= purchase_amount
		Global.emit_signal("purchase")
		
		# 구매 금액 누적
		StoreData.store_data["STORE_ITEM_GOLD_DROP"]["used_gold"] += purchase_amount
		
		golddrop_upgrade(item["level"])
		golddrop_level()
		
		save_golddrop_data()
		Global.save_character_data()
		
		level_label.text = "Level: " + str(item["level"])
		golddrop_cost(item["level"])

func _on_reset_store():
	item["level"] = "0"
	level_label.text = "Level: " + str(item["level"])
	golddrop_cost(item["level"])
