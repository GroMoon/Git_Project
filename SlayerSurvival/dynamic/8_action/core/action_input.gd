extends RefCounted
## 액션 모드 전용 입력 등록 (던파 기본 키 배치)
## project.godot을 건드리지 않고 런타임에 InputMap에 추가한다.

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

const PAD_BUTTONS := {
	"act_attack"   : [JOY_BUTTON_X],
	"act_jump"     : [JOY_BUTTON_A],
	"act_backstep" : [JOY_BUTTON_B],
	"act_left"     : [JOY_BUTTON_DPAD_LEFT],
	"act_right"    : [JOY_BUTTON_DPAD_RIGHT],
	"act_up"       : [JOY_BUTTON_DPAD_UP],
	"act_down"     : [JOY_BUTTON_DPAD_DOWN],
}

static func ensure_actions() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.5)
		for keycode in BINDINGS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
		for button in PAD_BUTTONS.get(action, []):
			var pad_event := InputEventJoypadButton.new()
			pad_event.button_index = button
			InputMap.action_add_event(action, pad_event)
