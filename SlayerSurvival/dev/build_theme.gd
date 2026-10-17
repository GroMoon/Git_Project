extends SceneTree

## 게임 전역 UI 테마 생성기 → res://static/ui/game_theme.tres
## 실행: Godot --headless --path . -s res://dev/build_theme.gd
## 스타일: 액션 모드와 같은 방식 — 어두운 칸 + 얇은 회색 테두리, 선택/마우스 올림 시 금색 테두리

const FONT = "res://static/font/DNFBitBitTTF.ttf"

const TEXT       = Color(0.92, 0.92, 0.95)
const TEXT_DIM   = Color(0.75, 0.75, 0.82)
const GOLD       = Color(1.0, 0.85, 0.4)
const GOLD_LIGHT = Color(1.0, 0.88, 0.5)
const DISABLED   = Color(0.5, 0.5, 0.55)
const FILL       = Color(0.08, 0.07, 0.11, 0.95)
const FILL_HOVER = Color(0.13, 0.11, 0.17, 0.97)
const EDGE       = Color(0.35, 0.33, 0.42)
const EDGE_GOLD  = Color(1.0, 0.8, 0.3)
const OUTLINE    = Color(0, 0, 0)

func _init():
	var t = Theme.new()
	t.default_font = load(FONT)
	t.default_font_size = 18

	# ---------- 버튼 ----------
	for type in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", type, _box(FILL, EDGE, 2, 16, 8))
		t.set_stylebox("hover", type, _box(FILL_HOVER, EDGE_GOLD, 3, 16, 8))
		t.set_stylebox("pressed", type, _box(Color(0.05, 0.04, 0.07, 0.97), EDGE_GOLD, 3, 16, 8))
		t.set_stylebox("hover_pressed", type, _box(Color(0.05, 0.04, 0.07, 0.97), EDGE_GOLD, 3, 16, 8))
		t.set_stylebox("disabled", type, _box(Color(0.08, 0.08, 0.09, 0.8), Color(0.25, 0.25, 0.28), 2, 16, 8))
		t.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), EDGE_GOLD, 3, 16, 8))
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, GOLD)
		t.set_color("font_pressed_color", type, GOLD)
		t.set_color("font_hover_pressed_color", type, GOLD)
		t.set_color("font_focus_color", type, GOLD)
		t.set_color("font_disabled_color", type, DISABLED)
		t.set_color("font_outline_color", type, OUTLINE)
		t.set_constant("outline_size", type, 5)
		t.set_constant("h_separation", type, 8)

	# ---------- 판넬 (카드) ----------
	t.set_stylebox("panel", "Panel", _box(FILL, EDGE, 2, 18, 14))
	t.set_stylebox("panel", "PanelContainer", _box(FILL, EDGE, 2, 18, 14))
	t.set_stylebox("panel", "PopupPanel", _box(FILL, EDGE, 2, 10, 8))
	t.set_stylebox("panel", "PopupMenu", _box(FILL, EDGE, 2, 10, 8))
	t.set_stylebox("hover", "PopupMenu", _box(FILL_HOVER, Color(0, 0, 0, 0), 0, 0, 0))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_stylebox("panel", "TooltipPanel", _box(Color(0.05, 0.045, 0.07, 0.97), EDGE, 2, 10, 6))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 15)

	# ---------- 라벨 (모두 검은 외곽선) ----------
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_constant("outline_size", "Label", 5)
	_label_variation(t, "TitleLabel", 44, GOLD, 6)
	_label_variation(t, "HeaderLabel", 26, GOLD_LIGHT, 5)
	_label_variation(t, "BodyLabel", 18, TEXT, 5)
	_label_variation(t, "DimLabel", 16, TEXT_DIM, 5)
	_label_variation(t, "ValueLabel", 18, Color.WHITE, 5)
	_label_variation(t, "HintLabel", 18, Color(1, 1, 1, 0.75), 5)
	_label_variation(t, "RoleLabel", 17, Color(0.7, 0.85, 1.0), 5)
	_label_variation(t, "SkillLabel", 15, Color(0.6, 1.0, 0.7), 5)

	# ---------- 큰 버튼 ----------
	t.set_type_variation("BigButton", "Button")
	t.set_font_size("font_size", "BigButton", 26)
	t.set_type_variation("TabButton", "Button")
	t.set_font_size("font_size", "TabButton", 19)

	# ---------- 슬롯 / 명판 ----------
	t.set_type_variation("SlotPanel", "PanelContainer")
	t.set_stylebox("panel", "SlotPanel", _box(Color(0.08, 0.07, 0.1, 0.9), EDGE, 2, 3, 3))
	t.set_type_variation("SlotGold", "PanelContainer")
	t.set_stylebox("panel", "SlotGold", _box(Color(0.08, 0.07, 0.1, 0.9), EDGE_GOLD, 3, 3, 3))
	t.set_type_variation("SlotRed", "PanelContainer")
	t.set_stylebox("panel", "SlotRed", _box(Color(0.08, 0.07, 0.1, 0.9), Color(0.9, 0.2, 0.2), 3, 3, 3))
	t.set_type_variation("PlatePanel", "PanelContainer")
	t.set_stylebox("panel", "PlatePanel", _box(Color(0, 0, 0, 0.55), Color(0, 0, 0, 0), 0, 12, 4))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", _box(FILL, EDGE, 2, 16, 14))
	t.set_type_variation("CardActive", "PanelContainer")
	t.set_stylebox("panel", "CardActive", _box(FILL, EDGE_GOLD, 4, 16, 14))

	# ---------- 슬라이더 ----------
	t.set_stylebox("slider", "HSlider", _box(Color(0.15, 0.14, 0.18), Color(0, 0, 0), 2, 0, 4))
	t.set_stylebox("grabber_area", "HSlider", _box(Color(1.0, 0.8, 0.3), Color(0, 0, 0), 2, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(Color(1.0, 0.88, 0.5), Color(0, 0, 0), 2, 0, 4))

	# ---------- 체크 ----------
	for type in ["CheckBox", "CheckButton"]:
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			t.set_stylebox(st, type, StyleBoxEmpty.new())
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, GOLD)
		t.set_color("font_pressed_color", type, GOLD)

	# ---------- 진행 바 ----------
	var bg = _box(Color(0.12, 0.1, 0.14, 0.9), Color(0, 0, 0, 0.8), 2, 0, 0)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", _box(Color(0.3, 0.55, 1.0), Color(0, 0, 0, 0), 0, 0, 0))
	t.set_color("font_color", "ProgressBar", TEXT)

	# ---------- 스크롤 ----------
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, _box(Color(0.06, 0.05, 0.08, 0.8), Color(0, 0, 0, 0), 0, 0, 0))
		t.set_stylebox("grabber", type, _box(EDGE, Color(0, 0, 0, 0), 0, 0, 0))
		t.set_stylebox("grabber_highlight", type, _box(EDGE_GOLD, Color(0, 0, 0, 0), 0, 0, 0))
		t.set_stylebox("grabber_pressed", type, _box(EDGE_GOLD, Color(0, 0, 0, 0), 0, 0, 0))

	# ---------- 입력 ----------
	t.set_stylebox("normal", "LineEdit", _box(FILL, EDGE, 2, 10, 6))
	t.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), EDGE_GOLD, 3, 10, 6))
	t.set_color("font_color", "LineEdit", TEXT)

	var err = ResourceSaver.save(t, "res://static/ui/game_theme.tres")
	print("theme saved: ", error_string(err))
	quit()

func _box(bg: Color, border: Color, border_width: int, content_h: int, content_v: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.content_margin_left = content_h
	sb.content_margin_right = content_h
	sb.content_margin_top = content_v
	sb.content_margin_bottom = content_v
	return sb

func _label_variation(t: Theme, name: String, size: int, color: Color, outline: int):
	t.set_type_variation(name, "Label")
	t.set_font_size("font_size", name, size)
	t.set_color("font_color", name, color)
	t.set_color("font_outline_color", name, OUTLINE)
	t.set_constant("outline_size", name, outline)
