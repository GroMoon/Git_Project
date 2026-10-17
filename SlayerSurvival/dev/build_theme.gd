extends SceneTree

## 게임 전역 UI 테마 생성기 → res://static/ui/game_theme.tres
## 실행: Godot --headless --path . -s res://dev/build_theme.gd
## (static/ui/*.png 는 dev/gen_ui_art.py 로 생성, 먼저 에디터 import 필요)

const UI = "res://static/ui/"
const FONT = "res://static/font/DNFBitBitTTF.ttf"

const TEXT       = Color(0.95, 0.92, 0.85)
const TEXT_DIM   = Color(0.72, 0.68, 0.62)
const GOLD       = Color(1.0, 0.85, 0.45)
const GOLD_LIGHT = Color(1.0, 0.93, 0.7)
const DISABLED   = Color(0.5, 0.5, 0.55)

func _init():
	var t = Theme.new()
	t.default_font = load(FONT)
	t.default_font_size = 18

	# ---------- 버튼 ----------
	for type in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", type, _tex("button_normal", 8, 18, 8))
		t.set_stylebox("hover", type, _tex("button_hover", 8, 18, 8))
		t.set_stylebox("pressed", type, _tex("button_pressed", 8, 18, 8))
		t.set_stylebox("hover_pressed", type, _tex("button_pressed", 8, 18, 8))
		t.set_stylebox("disabled", type, _tex("button_disabled", 8, 18, 8))
		t.set_stylebox("focus", type, _tex("button_focus", 8, 18, 8))
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, GOLD_LIGHT)
		t.set_color("font_pressed_color", type, GOLD)
		t.set_color("font_hover_pressed_color", type, GOLD)
		t.set_color("font_focus_color", type, GOLD_LIGHT)
		t.set_color("font_disabled_color", type, DISABLED)
		t.set_color("font_outline_color", type, Color(0.05, 0.03, 0.05))
		t.set_constant("outline_size", type, 4)
		t.set_constant("h_separation", type, 8)

	# ---------- 판넬 ----------
	t.set_stylebox("panel", "Panel", _tex("panel", 12, 22, 18))
	t.set_stylebox("panel", "PanelContainer", _tex("panel", 12, 22, 18))
	t.set_stylebox("panel", "PopupPanel", _tex("panel_small", 6, 10, 8))
	t.set_stylebox("panel", "PopupMenu", _tex("panel_small", 6, 10, 8))
	t.set_stylebox("hover", "PopupMenu", _flat(Color(0.4, 0.3, 0.2, 0.8), Color(0, 0, 0, 0), 0))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD_LIGHT)
	t.set_stylebox("panel", "TooltipPanel", _tex("panel_small", 6, 10, 6))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 15)

	# ---------- 라벨 ----------
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0.05, 0.03, 0.05))
	_label_variation(t, "TitleLabel", 46, GOLD, 10)
	_label_variation(t, "HeaderLabel", 24, GOLD, 6)
	_label_variation(t, "BodyLabel", 17, TEXT, 3)
	_label_variation(t, "DimLabel", 14, TEXT_DIM, 3)
	_label_variation(t, "ValueLabel", 17, GOLD_LIGHT, 3)

	# ---------- 큰 메뉴 버튼 ----------
	t.set_type_variation("BigButton", "Button")
	t.set_font_size("font_size", "BigButton", 26)
	t.set_type_variation("TabButton", "Button")
	t.set_font_size("font_size", "TabButton", 19)

	# ---------- 슬롯 / 명판 ----------
	t.set_type_variation("SlotPanel", "PanelContainer")
	t.set_stylebox("panel", "SlotPanel", _tex("slot", 8, 4, 4))
	t.set_type_variation("SlotGold", "PanelContainer")
	t.set_stylebox("panel", "SlotGold", _tex("slot_gold", 8, 4, 4))
	t.set_type_variation("SlotRed", "PanelContainer")
	t.set_stylebox("panel", "SlotRed", _tex("slot_red", 8, 4, 4))
	t.set_type_variation("PlatePanel", "PanelContainer")
	t.set_stylebox("panel", "PlatePanel", _tex("panel_small", 6, 14, 6))

	# ---------- 슬라이더 ----------
	var track = _flat(Color(0.08, 0.06, 0.1), Color(0.44, 0.29, 0.14), 2)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", _flat(Color(0.78, 0.58, 0.26), Color(0.44, 0.29, 0.14), 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color(0.97, 0.8, 0.45), Color(0.44, 0.29, 0.14), 2))
	t.set_icon("grabber", "HSlider", load(UI + "grabber.png"))
	t.set_icon("grabber_highlight", "HSlider", load(UI + "grabber_hover.png"))
	t.set_icon("grabber_disabled", "HSlider", load(UI + "grabber.png"))

	# ---------- 체크 ----------
	for type in ["CheckBox", "CheckButton"]:
		t.set_icon("checked", type, load(UI + "check_on.png"))
		t.set_icon("unchecked", type, load(UI + "check_off.png"))
		t.set_icon("checked_disabled", type, load(UI + "check_on.png"))
		t.set_icon("unchecked_disabled", type, load(UI + "check_off.png"))
		t.set_stylebox("normal", type, StyleBoxEmpty.new())
		t.set_stylebox("hover", type, StyleBoxEmpty.new())
		t.set_stylebox("pressed", type, StyleBoxEmpty.new())
		t.set_stylebox("hover_pressed", type, StyleBoxEmpty.new())
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, GOLD_LIGHT)
		t.set_color("font_pressed_color", type, GOLD)

	# ---------- 진행 바 ----------
	t.set_stylebox("background", "ProgressBar", _tex("bar_frame", 6, 4, 4))
	var fill = _flat(Color(0.35, 0.6, 1.0), Color(0, 0, 0, 0), 0)
	fill.set_expand_margin_all(-4)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", TEXT)

	# ---------- 스크롤 ----------
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, _flat(Color(0.06, 0.05, 0.08, 0.8), Color(0.3, 0.2, 0.1), 1))
		t.set_stylebox("grabber", type, _flat(Color(0.6, 0.45, 0.2), Color(0.3, 0.2, 0.1), 1))
		t.set_stylebox("grabber_highlight", type, _flat(Color(0.85, 0.65, 0.3), Color(0.3, 0.2, 0.1), 1))
		t.set_stylebox("grabber_pressed", type, _flat(Color(0.95, 0.75, 0.35), Color(0.3, 0.2, 0.1), 1))

	# ---------- 입력 ----------
	t.set_stylebox("normal", "LineEdit", _tex("slot", 8, 10, 6))
	t.set_stylebox("focus", "LineEdit", _tex("button_focus", 8, 10, 6))
	t.set_color("font_color", "LineEdit", TEXT)

	var err = ResourceSaver.save(t, "res://static/ui/game_theme.tres")
	print("theme saved: ", error_string(err))
	quit()

func _tex(name: String, margin: int, content_h: int, content_v: int) -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	sb.texture = load(UI + name + ".png")
	sb.set_texture_margin_all(margin)
	sb.content_margin_left = content_h
	sb.content_margin_right = content_h
	sb.content_margin_top = content_v
	sb.content_margin_bottom = content_v
	return sb

func _flat(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	return sb

func _label_variation(t: Theme, name: String, size: int, color: Color, outline: int):
	t.set_type_variation(name, "Label")
	t.set_font_size("font_size", name, size)
	t.set_color("font_color", name, color)
	t.set_color("font_outline_color", name, Color(0.05, 0.03, 0.05))
	t.set_constant("outline_size", name, outline)
