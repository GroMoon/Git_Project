extends Node

const CHARACTER_DATA_PATH = "res://player_data.json"
var character_data = {}

func _ready():
	load_character_data()

func load_character_data():
	# 1) 먼저 읽기 시도도
	var character_data_file = FileAccess.open(CHARACTER_DATA_PATH, FileAccess.READ)
	# 2) 파일이 없으면? -> 기본 생성 + 저장 후 다시 읽기 시도도
	if not character_data_file:
		# print(1)
		create_default_character_data()
		save_character_data()
		# 다시 읽기 재시도
		character_data_file = FileAccess.open(CHARACTER_DATA_PATH, FileAccess.READ)
		if not character_data_file:
			print("Error: cannot read file after creating default. Check path or permission.")
			return

	# 3) 정상적으로 열렸으면 JSON 파싱싱
	var json = JSON.new()							# 데이터 파싱 or 문자열 변환
	# 데이터를 파싱 하고 실패하면 오류 구문 출력 		(!)오류인지 확인하는 구문이 아니라 파싱까지 하는 함수
	if json.parse(character_data_file.get_as_text()) != OK:
		print("Error: Failed to parse JSON from character_data")
		#json.close()
		return

	character_data_file.close()
	character_data = json.get_data()
	print(character_data)

func save_character_data():
	var character_data_file = FileAccess.open(CHARACTER_DATA_PATH, FileAccess.WRITE)
	if not character_data_file:
		print("Error: Unable to open character_data_file for writing.")
		return
	var json_string = JSON.stringify(character_data, "", false)			# 캐릭터 데이터 변수를 JSON 형식의 문자열로 변환 
	character_data_file.store_string(json_string)						# 데이터 저장
	
# 디폴트 데이터
func create_default_character_data():
	character_data = {
		"GOLD": {"gold": 0},
		"CHARACTER_STORE_UPGRADES": {
			"health": 0,
			"shield": 0.5,
			"respawn": 0,
			"double_splash": 0,
			"speed": 0,
			"spell_cooldown": 0,
			"spell_size": 0.05
		}
	}
