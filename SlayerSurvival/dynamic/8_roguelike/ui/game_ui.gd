class_name GameUI

## 게임 UI 공용 헬퍼 (액션 모드와 같은 스타일)
## - 어두운 반투명 배경 + 가운데 정렬 금색 제목
## - 텍스트 메뉴 "▶ 항목 ◀" (TextMenu), 아래쪽 조작 안내 줄
## - 얇은 회색 테두리 카드, 선택하면 금색 테두리 + 살짝 커짐, 나머지는 어둡게

const GOLD       = Color(1.0, 0.85, 0.4)
const GOLD_LIGHT = Color(1.0, 0.88, 0.5)
const TEXT       = Color(0.92, 0.92, 0.95)
const TEXT_DIM   = Color(0.75, 0.75, 0.82)
const RED        = Color(1.0, 0.45, 0.4)
const GREEN      = Color(0.6, 1.0, 0.7)
const BLUE       = Color(0.7, 0.85, 1.0)
const INACTIVE   = Color(0.55, 0.55, 0.6)
const CLICK_SOUND = preload("res://static/audio/sfx/button_sounds/button_sound_1.mp3")

const PORTRAITS = {
	"fantasy_warrior": preload("res://dynamic/1_player/selcet_character/character_img/fantasy_warrior_pixelart.webp"),
	"medieval_king":   preload("res://dynamic/1_player/selcet_character/character_img/medieval_king_pixelart.webp"),
	"wizard":          preload("res://dynamic/1_player/selcet_character/character_img/wizard_pixelart.webp"),
}
const CHARACTER_NAMES = {
	"fantasy_warrior": ["Fantasy Warrior", "Fantasy Warrior"],
	"medieval_king":   ["Medieval King", "Medieval King"],
	"wizard":          ["Wizard", "Wizard"],
}
const MAP_NAMES = {
	"cave":        ["용암 동굴", "Lava Cave"],
	"dungeon_B1F": ["지하묘지 B1F", "Dungeon B1F"],
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

# 메뉴 이동/결정 효과음 (일시정지 중에도 재생: GameFeel 은 PROCESS_MODE_ALWAYS)
static func click():
	GameFeel.play_sfx("ui_hover", 1.0, -6.0, 0.03)

# ================= 기본 위젯 =================
static func label(text: String, variation: String = "BodyLabel", align = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# 화면 폭 전체에 가운데 정렬된 라벨
static func centered(text: String, variation: String, y: float, height: float = 40.0) -> Label:
	var l = label(text, variation, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, y)
	l.size = Vector2(1280, height)
	return l

# 아래쪽 조작 안내 줄
static func hint(text: String, y: float = 664.0) -> Label:
	return centered(text, "HintLabel", y, 30.0)

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
	b.focus_entered.connect(click)

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

# 얇은 구분선
static func divider(width: float = 300.0) -> Control:
	var c = ColorRect.new()
	c.color = Color(0.35, 0.33, 0.42, 0.8)
	c.custom_minimum_size = Vector2(width, 2)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# 화면 전체를 어둡게 하는 배경
static func dim_backdrop(alpha: float = 0.65) -> ColorRect:
	var r = ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.position = Vector2.ZERO
	r.size = Vector2(1280, 720)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r

# 카드 선택 상태 표시 (선택: 금색 테두리 + 커짐, 나머지: 어둡게)
static func set_card_active(card: PanelContainer, active: bool, grow: float = 1.04):
	card.theme_type_variation = "CardActive" if active else "CardPanel"
	card.modulate = Color.WHITE if active else INACTIVE
	card.pivot_offset = card.size / 2.0
	var tw = card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE * (grow if active else 0.97), 0.12)

# 아이콘 슬롯 (badge: 오른쪽 아래 작은 글자, style: SlotPanel / SlotGold / SlotRed)
# p: 이미 만든 판넬에 채울 때 (InfoSlot 등)
static func slot(icon: Texture2D, badge: String = "", style: String = "SlotPanel", size: float = 52.0, p: PanelContainer = null) -> PanelContainer:
	if p == null:
		p = panel(style)
	else:
		p.theme_type_variation = style
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
		empty.modulate = Color(1, 1, 1, 0.4)
		return empty
	var lv = player.get_upgrade_level(id)
	var max_lv = UpgradeDB.max_level(id)
	var evolved = player.weapons.has(id) and player.weapons[id].evolved
	var badge = "EVO" if evolved else ("MAX" if lv >= max_lv else str(lv))
	var style = "SlotRed" if evolved else ("SlotGold" if lv >= max_lv else "SlotPanel")
	var s = InfoSlot.new()
	s.player = player
	s.upgrade_id = id
	slot(UpgradeDB.icon(id, player.character_name), badge, style, size, s)
	s.tooltip_text = UpgradeDB.display_name(id, player.character_name)		# 비어 있으면 툴팁이 뜨지 않음 (실제 내용은 InfoSlot 이 그림)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	return s

# 레벨 표시: "Lv 3", 최대 레벨이면 "MAX", 진화했으면 "EVO"
static func level_text(lv: int, max_lv: int, evolved: bool = false) -> String:
	if evolved:
		return "EVO"
	return "MAX" if lv >= max_lv else "Lv %d" % lv

# 무기/패시브 정보 창 내용 (InfoSlot 툴팁)
static func upgrade_info(player, id: String) -> Control:
	var ch = player.character_name
	var lv = player.get_upgrade_level(id)
	var max_lv = UpgradeDB.max_level(id)
	var weapon = player.weapons.get(id)
	var evolved = weapon != null and weapon.evolved
	var box = vbox(4)
	box.custom_minimum_size = Vector2(270, 0)
	var add = func(text: String, variation: String, color = null) -> Label:
		var l = label(text, variation)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(270, 0)
		if color != null:
			l.add_theme_color_override("font_color", color)
		box.add_child(l)
		return l
	# 이름 + 레벨
	var title = UpgradeDB.evolved_name(id, ch) if evolved else UpgradeDB.display_name(id, ch)
	var head = add.call("%s   %s" % [title, level_text(lv, max_lv, evolved) if evolved or lv >= max_lv else "Lv %d / %d" % [lv, max_lv]], "HeaderLabel", RED if evolved else GOLD)
	head.add_theme_font_size_override("font_size", 19)
	add.call(t("무기", "Weapon") if UpgradeDB.is_weapon(id) else t("패시브", "Passive"), "RoleLabel")
	# 설명 (패시브는 레벨당 효과)
	var base_desc = UpgradeDB.level_desc(id, 1, ch)
	if UpgradeDB.is_passive(id):
		base_desc = t("레벨당 ", "Per level: ") + base_desc
	add.call(base_desc, "BodyLabel").add_theme_font_size_override("font_size", 15)
	# 무기 스탯 (현재 보너스 포함)
	if weapon != null:
		var parts = []
		if id == "signature":
			parts.append(t("피해 %d", "DMG %d") % int(player.attack_damage))
			parts.append(t("%d회 공격", "%d hits") % int(player.attack_times))
			parts.append(t("쿨타임 %.1f초", "CD %.1fs") % player.get_attack_wait_time())
		else:
			parts.append(t("피해 %d", "DMG %d") % int(round(weapon.get_damage())))
			if UpgradeDB.get_entry(id).get("stats", {}).has("amount"):
				parts.append(t("개수 %d", "x%d") % weapon.get_amount())
			if UpgradeDB.get_entry(id).get("stats", {}).has("cooldown"):
				parts.append(t("쿨타임 %.1f초", "CD %.1fs") % weapon.get_cooldown())
		add.call("   ".join(parts), "ValueLabel", Color(1.0, 0.8, 0.45)).add_theme_font_size_override("font_size", 15)
	# 다음 레벨
	if lv < max_lv:
		add.call(t("다음 (Lv %d) : ", "Next (Lv %d): ") % (lv + 1) + UpgradeDB.level_desc(id, lv + 1, ch), "SkillLabel")
	# 진화
	var evo_line = ""
	if evolved:
		evo_line = t("진화 완료 : ", "Evolved: ") + UpgradeDB.evolved_desc(id)
	elif UpgradeDB.is_weapon(id) and UpgradeDB.can_evolve(id):
		var partner = UpgradeDB.evolve_partner(id)
		var have = player.passives.has(partner)
		evo_line = t("진화 : 최대 레벨 + %s%s → 보물상자", "Evolve: max level + %s%s → chest") % [
			UpgradeDB.display_name(partner, ch), t(" (보유)", " (owned)") if have else ""]
	elif UpgradeDB.is_passive(id):
		var users = UpgradeDB.weapon_ids().filter(func(w): return UpgradeDB.evolve_partner(w) == id)
		if not users.is_empty():
			evo_line = t("진화 재료 : ", "Evolves: ") + ", ".join(users.map(func(w): return UpgradeDB.display_name(w, ch)))
	if evo_line != "":
		box.add_child(divider(270))
		add.call(evo_line, "DimLabel", Color(1.0, 0.6, 0.5)).add_theme_font_size_override("font_size", 14)
	return box

# 등장 연출: 페이드 인
static func fade_in(c: CanvasItem, duration: float = 0.2, delay: float = 0.0):
	c.modulate.a = 0.0
	var tw = c.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "modulate:a", 1.0, duration)

# 기존 씬 버튼의 개별 스타일을 지워 전역 테마를 쓰게 함
static func use_theme_button(b: Button, font_size: int = -1):
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.remove_theme_stylebox_override(st)
	if font_size > 0:
		b.add_theme_font_size_override("font_size", font_size)
	b.focus_mode = Control.FOCUS_ALL

# 제목 라벨을 금색 + 외곽선으로 (LabelSettings 를 쓰는 라벨도 처리)
static func style_title(l: Label, font_size: int = -1):
	if l.label_settings:
		var ls: LabelSettings = l.label_settings.duplicate()
		ls.font_color = GOLD
		ls.outline_color = Color.BLACK
		ls.outline_size = max(ls.outline_size, 8)
		if font_size > 0:
			ls.font_size = font_size
		l.label_settings = ls
	else:
		l.theme_type_variation = "TitleLabel"
		if font_size > 0:
			l.add_theme_font_size_override("font_size", font_size)

# 초 → "M:SS"
static func format_time(seconds: float) -> String:
	var s = int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
