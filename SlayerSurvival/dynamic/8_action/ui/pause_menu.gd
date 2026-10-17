extends CanvasLayer
## 일시정지 메뉴 (ESC / 패드 Start) : 계속하기 / 조작 설정(키 변경) / 던전 포기
## 게임이 멈춘 동안에도 동작하도록 PROCESS_MODE_ALWAYS

signal closed

const ActionInput = preload("res://dynamic/8_action/core/action_input.gd")
const FONT = preload("res://static/font/DNFBitBitTTF.ttf")
const MENU_SCENE := "res://dynamic/5_title_screen/menu.tscn"
const ITEMS := ["계속하기", "조작 설정", "던전 포기 (메뉴로)"]

var page := "main"			# "main" / "keys"
var selected := 0
var waiting_key := false	# 키 설정에서 새 키 입력 대기 중
var _root : Control
var _lines : Array[Label] = []
var _title : Label
var _hint : Label
var _click_sound : AudioStreamPlayer

func _ready():
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_title = _label("", 40, Color(1.0, 0.85, 0.4))
	_title.position = Vector2(0, 110)
	_title.size = Vector2(1280, 50)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_title)
	_hint = _label("", 18, Color(1, 1, 1, 0.7))
	_hint.position = Vector2(0, 640)
	_hint.size = Vector2(1280, 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint)
	_click_sound = AudioStreamPlayer.new()
	_click_sound.stream = preload("res://static/audio/sfx/button_sounds/button_sound_1.mp3")
	_click_sound.bus = &"SFX"
	add_child(_click_sound)
	_show_page("main")

func _show_page(name_: String):
	page = name_
	selected = 0
	waiting_key = false
	for line in _lines:
		line.queue_free()
	_lines.clear()
	var entries := _entries()
	for i in entries.size():
		var line := _label(entries[i], 28 if page == "main" else 22, Color.WHITE)
		line.position = Vector2(0, (230 if page == "main" else 175) + i * (60 if page == "main" else 34))
		line.size = Vector2(1280, 40)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_root.add_child(line)
		_lines.append(line)
	_title.text = "일시정지" if page == "main" else "조작 설정"
	_refresh()

func _entries() -> Array:
	if page == "main":
		return ITEMS
	var rows := []
	for entry in ActionInput.REBINDABLE:
		rows.append("%s        %s" % [entry[1], ActionInput.key_name(entry[0])])
	rows.append("기본값으로 되돌리기")
	rows.append("뒤로")
	return rows

func _refresh():
	var entries := _entries()
	for i in _lines.size():
		var active := i == selected
		var text: String = entries[i]
		if active and waiting_key:
			text = "%s        [ 새 키를 누르세요 ]" % ActionInput.REBINDABLE[i][1]
		_lines[i].text = ("▶  " + text + "  ◀") if active else text
		_lines[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if active else Color(0.85, 0.85, 0.9))
	if page == "main":
		_hint.text = "↑ ↓  선택        X / Enter  결정        ESC  계속하기"
	elif waiting_key:
		_hint.text = "바꿀 키를 누르세요  (ESC 취소)"
	else:
		_hint.text = "↑ ↓  선택        X / Enter  키 변경        ESC  뒤로"

func _unhandled_input(event: InputEvent):
	if event.is_echo():
		return
	if waiting_key:
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			if event.physical_keycode != KEY_ESCAPE:
				ActionInput.rebind(ActionInput.REBINDABLE[selected][0], event.physical_keycode)
				_click_sound.play()
			waiting_key = false
			_show_entries_keep_selection()
		return
	if not (event.is_action_pressed("act_up") or event.is_action_pressed("act_down") or event.is_action_pressed("act_attack")
			or event.is_action_pressed("ui_accept") or event.is_action_pressed("act_menu")):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("act_up"):
		selected = wrapi(selected - 1, 0, _lines.size())
		_click_sound.play()
		_refresh()
	elif event.is_action_pressed("act_down"):
		selected = wrapi(selected + 1, 0, _lines.size())
		_click_sound.play()
		_refresh()
	elif event.is_action_pressed("act_menu"):
		if page == "keys":
			_show_page("main")
		else:
			close()
	else:
		activate(selected)

## 항목 실행 (테스트에서도 직접 호출)
func activate(index: int):
	_click_sound.play()
	if page == "main":
		match index:
			0:
				close()
			1:
				_show_page("keys")
			2:
				get_tree().paused = false
				get_tree().change_scene_to_file(MENU_SCENE)
		return
	var count := ActionInput.REBINDABLE.size()
	if index < count:
		selected = index
		waiting_key = true
		_refresh()
	elif index == count:
		ActionInput.reset_defaults()
		_show_entries_keep_selection()
	else:
		_show_page("main")

func _show_entries_keep_selection():
	var keep := selected
	_show_page(page)
	selected = keep
	_refresh()

func close():
	get_tree().paused = false
	closed.emit()
	queue_free()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	return label
