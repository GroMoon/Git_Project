extends VBoxContainer

class_name TextMenu

## 액션 모드식 텍스트 메뉴: 가운데 정렬 항목, 선택한 항목은 "▶ 항목 ◀" 금색
## - ↑ ↓ (W S) 선택, Enter / Space 결정, ← → (A D) 값 변경 (설정 항목)
## - 마우스: 올리면 선택, 클릭하면 결정 (값 항목은 클릭 시 다음 값)
## 항목 텍스트는 Callable 로 받아 refresh() 때마다 최신 값으로 다시 씀
## 텍스트에 탭("이름\t값")이 있으면 두 칸으로 표시 (이름은 오른쪽 정렬, 값은 왼쪽 정렬 → 설정 목록이 세로로 맞춰짐)

signal activated(index: int)

const COLUMN_WIDTH = 220.0

var items: Array = []			# {text: Callable, on_activate: Callable, on_change: Callable(dir)}
var lines: Array = []			# Button (클릭 영역)
var parts: Array = []			# [▶, 이름, 값, ◀] 라벨
var selected := 0
var font_size := 28
var line_height := 56.0
var active := true

func _init(size: int = 28, height: float = 56.0):
	font_size = size
	line_height = height
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# text: String 또는 Callable(-> String)
func add_item(text, on_activate: Callable = Callable(), on_change: Callable = Callable()):
	var text_fn: Callable = text if text is Callable else func(): return text
	items.append({"text": text_fn, "on_activate": on_activate, "on_change": on_change})
	var line = Button.new()
	line.flat = true
	line.focus_mode = Control.FOCUS_NONE
	line.custom_minimum_size = Vector2(0, line_height)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		line.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var row = HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(row)
	var labels = []
	for t in ["▶", "", "", "◀"]:
		var l = Label.new()
		l.text = t
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.05))
		l.add_theme_constant_override("outline_size", 5)
		row.add_child(l)
		labels.append(l)
	parts.append(labels)
	var index = lines.size()
	line.mouse_entered.connect(func():
		if active and selected != index:
			select(index))
	line.pressed.connect(func():
		if not active:
			return
		select(index, false)
		if items[index]["on_change"].is_valid() and not items[index]["on_activate"].is_valid():
			change(1)
		else:
			activate())
	add_child(line)
	lines.append(line)
	refresh()

func clear_items():
	for l in lines:
		l.queue_free()
	lines.clear()
	parts.clear()
	items.clear()
	selected = 0

func select(index: int, sound: bool = true):
	if lines.is_empty():
		return
	selected = wrapi(index, 0, lines.size())
	if sound:
		GameUI.click()
	refresh()

func activate():
	if selected >= items.size():
		return
	GameUI.click()
	var cb: Callable = items[selected]["on_activate"]
	if cb.is_valid():
		cb.call()
	activated.emit(selected)
	if is_inside_tree():
		refresh()

func change(dir: int):
	var cb: Callable = items[selected]["on_change"]
	if cb.is_valid():
		GameUI.click()
		cb.call(dir)
		refresh()

func refresh():
	for i in lines.size():
		var on = i == selected
		var cols = String(items[i]["text"].call()).split("\t")
		var two = cols.size() > 1
		var l: Array = parts[i]
		if two:
			# 두 칸 항목: 칸 폭 고정 → 이름 오른쪽 끝 / 값 왼쪽 끝이 세로로 맞음. 화살표는 글자에 붙여 표시
			l[1].text = ("▶  " + cols[0]) if on else cols[0]
			l[2].text = (cols[1] + "  ◀") if on else cols[1]
		else:
			l[1].text = cols[0]
		l[2].visible = two
		l[1].get_parent().add_theme_constant_override("separation", 40 if two else 14)
		l[0].visible = not two
		l[3].visible = not two
		l[1].custom_minimum_size.x = COLUMN_WIDTH if two else 0.0
		l[1].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if two else HORIZONTAL_ALIGNMENT_CENTER
		l[2].custom_minimum_size.x = COLUMN_WIDTH if two else 0.0
		# 한 칸 항목: 화살표는 투명도만 바꿔 자리를 유지 (항목이 좌우로 흔들리지 않음)
		l[0].modulate.a = 1.0 if on else 0.0
		l[3].modulate.a = 1.0 if on else 0.0
		var color = GameUI.GOLD if on else Color(0.85, 0.85, 0.9)
		for label in l:
			label.add_theme_color_override("font_color", color)

# 키 입력 처리. 처리했으면 true
func handle_input(event: InputEvent) -> bool:
	if not active or event.is_echo() or lines.is_empty():
		return false
	if event.is_action_pressed("up") or event.is_action_pressed("ui_up"):
		select(selected - 1)
	elif event.is_action_pressed("down") or event.is_action_pressed("ui_down"):
		select(selected + 1)
	elif event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		change(-1)
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		change(1)
	elif event.is_action_pressed("ui_accept"):
		activate()
	else:
		return false
	return true
