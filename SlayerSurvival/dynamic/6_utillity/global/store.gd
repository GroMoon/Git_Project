extends Node

const STORE_DATA_PATH = "res://store_data.json"

var store_data = {}

func _ready():
	load_store_data()

func load_store_data():
	var store_data_file = FileAccess.open(STORE_DATA_PATH, FileAccess.READ)
	if not store_data_file:
		create_default_store_data()
		save_store_data()
	var json = JSON.new()							# 데이터 파싱 or 문자열 변환

# 데이터를 파싱 하고 실패하면 오류 구문 출력 		(!)오류인지 확인하는 구문이 아니라 파싱까지 하는 함수
	if json.parse(store_data_file.get_as_text()) != OK:
		print("Error: Failed to parse JSON from store_data")
		#json.close()
		return

	store_data_file.close()
	store_data = json.get_data()
	print(store_data)

func save_store_data():
	var store_data_file = FileAccess.open(STORE_DATA_PATH, FileAccess.WRITE)
	
	if not store_data_file:
		print("Error: Unable to open store_data_file for writing.")
		return

	var json_string = JSON.stringify(store_data, "", false)			# 캐릭터 데이터 변수를 JSON 형식의 문자열로 변환 
	store_data_file.store_string(json_string)						# 데이터 저장
	store_data_file.close()

func create_default_store_data():
	store_data = {
		"STORE_ITEM_0": {"level": "1", "max_level": 5},
		"STORE_ITEM_1": {"level": "1", "max_level": 5},
		"STORE_ITEM_2": {"level": "1", "max_level": 5},
		"STORE_ITEM_3": {"level": "1", "max_level": 5},
		"STORE_ITEM_4": {"level": "1", "max_level": 5},
		"STORE_ITEM_9": {"level": "1", "max_level": 1},
		"STORE_ITEM_10": {"level": "1", "max_level": 1}
	}
