extends RefCounted
## 액션 모드 전용 입력 (던파 기본 키 배치 + 게임패드)
## project.godot을 건드리지 않고 런타임에 InputMap에 추가한다.
## 키 설정 화면에서 바꾼 키는 user://action_keys.cfg 에 저장되어 다음 실행에도 유지된다.

const CONFIG_PATH := "user://action_keys.cfg"

const BINDINGS := {
	"act_left"     : [KEY_LEFT],
	"act_right"    : [KEY_RIGHT],
	"act_up"       : [KEY_UP],
	"act_down"     : [KEY_DOWN],
	"act_attack"   : [KEY_X],
	"act_jump"     : [KEY_C],
	"act_backstep" : [KEY_Z],
	"act_skill_1"  : [KEY_A],
	"act_skill_2"  : [KEY_S],
	"act_skill_3"  : [KEY_D],
	"act_skill_4"  : [KEY_F],
	"act_respawn"  : [KEY_F1],		# 디버그 : 현재 웨이브 다시 소환
	"act_debug_skip": [KEY_F2],		# 디버그 : 다음 방으로
	"act_restart"  : [KEY_R],
	"act_menu"     : [KEY_ESCAPE],
}

## 게임패드 (Xbox 배치 기준) : X 공격 / A 점프 / B 백스텝 / Y·LB·RB·RT 스킬 / Start 일시정지
const PAD_BUTTONS := {
	"act_attack"   : [JOY_BUTTON_X],
	"act_jump"     : [JOY_BUTTON_A],
	"act_backstep" : [JOY_BUTTON_B],
	"act_skill_1"  : [JOY_BUTTON_Y],
	"act_skill_2"  : [JOY_BUTTON_LEFT_SHOULDER],
	"act_skill_3"  : [JOY_BUTTON_RIGHT_SHOULDER],
	"act_left"     : [JOY_BUTTON_DPAD_LEFT],
	"act_right"    : [JOY_BUTTON_DPAD_RIGHT],
	"act_up"       : [JOY_BUTTON_DPAD_UP],
	"act_down"     : [JOY_BUTTON_DPAD_DOWN],
	"act_menu"     : [JOY_BUTTON_START],
	"act_restart"  : [JOY_BUTTON_BACK],
}
const PAD_AXES := {
	"act_left"    : [JOY_AXIS_LEFT_X, -1.0],
	"act_right"   : [JOY_AXIS_LEFT_X, 1.0],
	"act_up"      : [JOY_AXIS_LEFT_Y, -1.0],
	"act_down"    : [JOY_AXIS_LEFT_Y, 1.0],
	"act_skill_4" : [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}

## 키 설정 화면에서 바꿀 수 있는 동작 [action, 표시 이름]
const REBINDABLE := [
	["act_attack", "공격"], ["act_jump", "점프"], ["act_backstep", "백스텝"],
	["act_skill_1", "스킬 1"], ["act_skill_2", "스킬 2"], ["act_skill_3", "스킬 3"], ["act_skill_4", "스킬 4"],
	["act_left", "왼쪽"], ["act_right", "오른쪽"], ["act_up", "위 (안쪽)"], ["act_down", "아래 (앞쪽)"],
]

const KEY_SYMBOLS := {KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓", KEY_ESCAPE: "ESC"}

static func ensure_actions() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.5)
		for keycode in BINDINGS[action]:
			_add_key(action, keycode)
		for button in PAD_BUTTONS.get(action, []):
			var pad_event := InputEventJoypadButton.new()
			pad_event.button_index = button
			InputMap.action_add_event(action, pad_event)
		if PAD_AXES.has(action):
			var axis_event := InputEventJoypadMotion.new()
			axis_event.axis = PAD_AXES[action][0]
			axis_event.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, axis_event)
	_load_saved_keys()

## 동작에 지정된 키보드 키 (없으면 KEY_NONE)
static func get_key(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return KEY_NONE

## 화면 표시용 키 이름 (← → 등 기호 포함)
static func key_name(action: String) -> String:
	var keycode := get_key(action)
	if keycode == KEY_NONE:
		return "-"
	return KEY_SYMBOLS.get(keycode, OS.get_keycode_string(keycode))

## 키 변경 : 다른 동작이 이미 그 키를 쓰고 있으면 서로 맞바꾼다
static func rebind(action: String, keycode: int) -> void:
	var old_key := get_key(action)
	for entry in REBINDABLE:
		var other: String = entry[0]
		if other != action and get_key(other) == keycode:
			_set_key(other, old_key)
	_set_key(action, keycode)
	save_keys()

static func reset_defaults() -> void:
	for entry in REBINDABLE:
		_set_key(entry[0], BINDINGS[entry[0]][0])
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)

static func save_keys() -> void:
	var config := ConfigFile.new()
	for entry in REBINDABLE:
		config.set_value("keys", entry[0], get_key(entry[0]))
	config.save(CONFIG_PATH)

static func _load_saved_keys() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for entry in REBINDABLE:
		var keycode: int = config.get_value("keys", entry[0], KEY_NONE)
		if keycode != KEY_NONE:
			_set_key(entry[0], keycode)

static func _set_key(action: String, keycode: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	if keycode != KEY_NONE:
		_add_key(action, keycode)

static func _add_key(action: String, keycode: int) -> void:
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)
