class_name GameUI

## 게임 UI 공용 헬퍼 (일시정지/설정/결과 화면/HUD 등에서 공통으로 사용)
## 색, 폰트 크기, 판넬/버튼 모양은 전역 테마(static/ui/game_theme.tres)를 따름

const GOLD       = Color(1.0, 0.85, 0.45)
const GOLD_LIGHT = Color(1.0, 0.93, 0.7)
const TEXT       = Color(0.95, 0.92, 0.85)
const TEXT_DIM   = Color(0.72, 0.68, 0.62)
const RED        = Color(1.0, 0.38, 0.35)
const GREEN      = Color(0.55, 0.95, 0.5)
const BLUR_SHADER = preload("res://static/shader/ui_blur.gdshader")

const PORTRAITS = {
	"fantasy_warrior": preload("res://dynamic/1_player/selcet_character/character_img/fantasy_warrior_pixelart.webp"),
	"medieval_king":   preload("res://dynamic/1_player/selcet_character/character_img/medieval_king_pixelart.webp"),
	"wizard":          preload("res://dynamic/1_player/selcet_character/character_img/wizard_pixelart.webp"),
}
const CHARACTER_NAMES = {
	"fantasy_warrior": ["전사", "Warrior"],
	"medieval_king":   ["왕", "King"],
	"wizard":          ["마법사", "Wizard"],
}
const MAP_NAMES = {
	"cave":        ["용암 동굴", "Lava Cave"],
	"dungeon_B1F": ["지하 묘지", "Dungeon B1F"],
}

static func ko() -> bool:
	return TranslationServer.get_locale().begins_with("ko")

# 한국어 / 영어 중 현재 언어 텍스트
static func t(ko_text: String, en_text: String) -> String:
	return ko_text if ko() else en_text

static func character_name(id: String) -> String:
	var n = CHARACTER_NAMES.get(id, [id, id])
	return n[0] if ko() else n[1]

static func map_name(id: String) -> String:
	var n = MAP_NAMES.get(id, [id, id])
	return n[0] if ko() else n[1]

# ================= 기본 위젯 =================
static func label(text: String, variation: String = "BodyLabel", align = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, variation: String = "BigButton", min_size: Vector2 = Vector2(300, 56)) -> Button:
	var b = Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	hook_sounds(b)
	return b

# 마우스를 올리면 포커스(키보드 선택 표시와 동일하게) + 효과음
static func hook_sounds(b: BaseButton):
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(func(): GameFeel.play_sfx("ui_hover", 1.0, -8.0, 0.05))
	b.pressed.connect(func(): GameFeel.play_sfx("ui_click", 1.0, -4.0, 0.05))

static func panel(variation: String = "") -> PanelContainer:
	var p = PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p

static func vbox(separation: int = 8) -> VBoxContainer:
	var b = VBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	return b

static func hbox(separation: int = 8) -> HBoxContainer:
	var b = HBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	return b

# 금색 장식 구분선 ◆────◆
static func divider(width: float = 300.0) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(width, 10)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var w = c.size.x
		var y = c.size.y / 2.0
		c.draw_line(Vector2(8, y), Vector2(w - 8, y), Color(0.75, 0.55, 0.25, 0.8), 2.0)
		for x in [4.0, w - 4.0]:
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 4), Vector2(x + 4, y), Vector2(x, y + 4), Vector2(x - 4, y)]), GOLD)
		c.draw_colored_polygon(PackedVector2Array([Vector2(w / 2, y - 5), Vector2(w / 2 + 5, y), Vector2(w / 2, y + 5), Vector2(w / 2 - 5, y)]), GOLD_LIGHT))
	return c

# 화면 전체를 흐리게 + 어둡게 하는 배경
static func blur_backdrop(dim: float = 0.62) -> ColorRect:
	var r = ColorRect.new()
	r.position = Vector2.ZERO
	r.size = Vector2(1280, 720)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat = ShaderMaterial.new()
	mat.shader = BLUR_SHADER
	mat.set_shader_parameter("tint", Color(0.03, 0.02, 0.05, dim))
	r.material = mat
	return r

# 아이콘 슬롯 (badge: 오른쪽 아래 작은 글자, style: SlotPanel / SlotGold / SlotRed)
static func slot(icon: Texture2D, badge: String = "", style: String = "SlotPanel", size: float = 52.0) -> PanelContainer:
	var p = panel(style)
	p.custom_minimum_size = Vector2(size, size)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(holder)
	if icon:
		var tr = TextureRect.new()
		tr.texture = icon
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
	if badge != "":
		var l = Label.new()
		l.text = badge
		l.add_theme_font_size_override("font_size", 12 if size < 40 else 14)
		l.add_theme_color_override("font_color", GOLD_LIGHT)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.offset_right = 3
		l.offset_bottom = 4
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(l)
	return p

# 무기/패시브 슬롯 (보유 장비 표시용). id == "" 이면 빈 칸
static func upgrade_slot(player, id: String, size: float = 52.0) -> PanelContainer:
	if id == "":
		var empty = slot(null, "", "SlotPanel", size)
		empty.modulate = Color(1, 1, 1, 0.45)
		return empty
	var lv = player.get_upgrade_level(id)
	var max_lv = UpgradeDB.max_level(id)
	var evolved = player.weapons.has(id) and player.weapons[id].evolved
	var badge = "EVO" if evolved else ("MAX" if lv >= max_lv else str(lv))
	var style = "SlotRed" if evolved else ("SlotGold" if lv >= max_lv else "SlotPanel")
	var s = slot(UpgradeDB.icon(id, player.character_name), badge, style, size)
	var title = UpgradeDB.evolved_name(id, player.character_name) if evolved else UpgradeDB.display_name(id, player.character_name)
	var desc = UpgradeDB.evolved_desc(id) if evolved else UpgradeDB.level_desc(id, 1, player.character_name)
	s.tooltip_text = "%s  (%s)\n%s" % [title, badge if badge != str(lv) else "Lv " + str(lv), desc]
	s.mouse_filter = Control.MOUSE_FILTER_PASS
	return s

# 버튼 여러 개 중 하나만 선택되는 그룹 (설정의 켜기/끄기 등)
static func segmented(options: Array, selected: int, on_select: Callable, min_width: float = 130.0) -> HBoxContainer:
	var row = hbox(6)
	var group = ButtonGroup.new()
	for i in options.size():
		var b = button(options[i], "TabButton", Vector2(min_width, 42))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == selected
		b.pressed.connect(func(): on_select.call(i))
		row.add_child(b)
	return row

# 등장 연출: 살짝 커지며 나타남
static func pop_in(c: Control, delay: float = 0.0, from_scale: float = 0.92):
	c.modulate.a = 0.0
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(from_scale, from_scale)
	var tw = c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.18).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# 초 → "MM:SS"
static func format_time(seconds: float) -> String:
	var s = int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]
