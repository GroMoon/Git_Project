extends RefCounted
## 던전 구성 : 방을 순서대로 진행하고 마지막 방에서 보스와 싸운다.
##   waves   : 방마다 웨이브 목록, 웨이브 = [[종류, x, 깊이, (엘리트)], ...]
##             (플레이어와 너무 가까운 위치는 소환 시 바깥으로 밀어냄)
##   hazards : 용암 웅덩이 등 바닥 위험 지대 [Rect2(x, 깊이, 너비, 깊이폭)] — 밟으면 화상 + 튕겨 나감
##   theme   : 배경 종류 ("crypt" = 지하묘지 타일셋, "cave" = 용암 동굴 타일셋)

const PAR_TIME := 300.0		# 랭크 계산 기준 클리어 시간(초)

## 지하묘지 B1F (기존 dungeon_B1F 에셋)
const ROOMS := [
	{"name": "묘지 입구", "width": 2200.0, "waves": [
		[["goblin", 900.0, 480.0], ["goblin", 980.0, 620.0], ["mushroom", 1150.0, 540.0], ["goblin", 1300.0, 600.0]],
		[["goblin", 1500.0, 470.0], ["mushroom", 1650.0, 620.0], ["goblin", 1750.0, 540.0], ["mushroom", 1850.0, 480.0]],
	]},
	{"name": "뼈의 회랑", "width": 2600.0, "waves": [
		[["skeleton", 900.0, 500.0], ["flyingeye", 1000.0, 620.0], ["skeleton", 1200.0, 600.0], ["goblin", 1300.0, 470.0]],
		[["flyingeye", 1500.0, 480.0], ["skeleton", 1700.0, 560.0], ["flyingeye", 1800.0, 640.0],
		 ["mushroom", 1900.0, 500.0], ["goblin", 1600.0, 650.0]],
	]},
	{"name": "포자의 굴", "width": 2400.0, "waves": [
		[["mushroom", 900.0, 480.0], ["mushroom", 1000.0, 640.0], ["goblin", 1150.0, 560.0, true], ["flyingeye", 1250.0, 500.0]],
		[["skeleton", 1500.0, 520.0, true], ["mushroom", 1700.0, 600.0], ["goblin", 1650.0, 470.0], ["flyingeye", 1800.0, 560.0]],
	]},
	{"name": "죽음의 제단", "width": 1800.0, "boss": true, "waves": [
		[["bringer", 1300.0, 560.0]],
	]},
]

## 용암 동굴 (기존 cave 에셋) — 바닥 용암 웅덩이 + 보스 파이어 웜
const CAVE_ROOMS := [
	{"name": "용암 동굴 입구", "width": 2200.0,
	 "hazards": [Rect2(1150, 590, 256, 100)],
	 "waves": [
		[["goblin", 900.0, 480.0], ["flyingeye", 1000.0, 600.0], ["goblin", 1150.0, 500.0], ["flyingeye", 1300.0, 560.0]],
		[["goblin", 1600.0, 620.0], ["mushroom", 1700.0, 480.0], ["flyingeye", 1800.0, 560.0], ["goblin", 1900.0, 650.0]],
	]},
	{"name": "불꽃 갱도", "width": 2600.0,
	 "hazards": [Rect2(900, 440, 192, 90), Rect2(1700, 600, 320, 90)],
	 "waves": [
		[["skeleton", 950.0, 620.0], ["mushroom", 1100.0, 500.0], ["skeleton", 1250.0, 560.0], ["goblin", 1350.0, 650.0]],
		[["mushroom", 1600.0, 480.0], ["skeleton", 1750.0, 520.0, true], ["flyingeye", 1900.0, 600.0], ["goblin", 2000.0, 470.0]],
	]},
	{"name": "끓는 호수", "width": 2400.0,
	 "hazards": [Rect2(1000, 500, 384, 100), Rect2(1800, 600, 256, 90)],
	 "waves": [
		[["goblin", 900.0, 470.0, true], ["flyingeye", 1050.0, 640.0], ["mushroom", 1200.0, 620.0], ["flyingeye", 1300.0, 470.0]],
		[["mushroom", 1600.0, 480.0, true], ["skeleton", 1750.0, 640.0], ["goblin", 1850.0, 560.0], ["flyingeye", 1950.0, 500.0]],
	]},
	{"name": "화염 둥지", "width": 1900.0, "boss": true,
	 "hazards": [Rect2(120, 600, 192, 90), Rect2(1550, 440, 256, 90)],
	 "waves": [
		[["fireworm", 1350.0, 560.0]],
	]},
]

const DUNGEONS := {
	"crypt": {"name": "지하묘지 B1F", "theme": "crypt", "rooms": ROOMS,
		"boss": "브링어 오브 데스", "desc": "해골과 고블린이 들끓는 지하묘지\n낫을 든 사신이 기다린다",
		"image": "res://dynamic/4_world/dungeon_B1F/dungeon_B1F_illust.webp"},
	"cave": {"name": "용암 동굴", "theme": "cave", "rooms": CAVE_ROOMS,
		"boss": "파이어 웜", "desc": "바닥 곳곳에 용암이 끓는 동굴\n적을 용암에 밀어 넣어라",
		"image": "res://dynamic/4_world/cave/cave_illust.png"},
}
const DUNGEON_ORDER := ["crypt", "cave"]

## 하위 호환 (기존 코드·테스트용) : 기본 던전 이름
const DUNGEON_NAME := "지하묘지 B1F"

static func get_dungeon(id: String) -> Dictionary:
	return DUNGEONS.get(id, DUNGEONS["crypt"])

## 클리어 랭크 : 시간 40% + 최대 콤보 30% + 피격 횟수 30%
static func calc_rank(clear_time: float, max_combo: int, hits_taken: int) -> String:
	var time_score := clampf(1.0 - (clear_time - PAR_TIME * 0.5) / PAR_TIME, 0.0, 1.0)
	var combo_score := clampf(max_combo / 60.0, 0.0, 1.0)
	var damage_score := clampf(1.0 - hits_taken / 30.0, 0.0, 1.0)
	var total := time_score * 0.4 + combo_score * 0.3 + damage_score * 0.3
	for grade in [[0.92, "SSS"], [0.85, "SS"], [0.75, "S"], [0.6, "A"], [0.45, "B"], [0.3, "C"], [0.15, "D"]]:
		if total >= grade[0]:
			return grade[1]
	return "F"
