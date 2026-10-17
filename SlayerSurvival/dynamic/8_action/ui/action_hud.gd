extends CanvasLayer
## 액션 모드 HUD : HP/MP 바, 스킬 슬롯, 콤보 카운터, 몬스터 HP 바, 미니맵, 화면 전환, 결과창

const FONT  = preload("res://static/font/DNFBitBitTTF.ttf")
const ICONS = preload("res://static/png/icon/spritesheet.png")

const HELP_TEXT := "← → ↑ ↓ 이동    →→ 대시    X 공격(연타 콤보)    C 점프    Z 백스텝    A S D F 스킬    ESC 메뉴"

var _hp_bar   : Control
var _hp_label : Label
var _mp_bar   : Control
var _name_label : Label
var _mp_ratio := 1.0
var _combo_root  : Control
var _combo_label : Label
var _combo_sub   : Label
var _enemy_label : Label
var _center_label : Label
var _banner_label : Label
var _target_bar   : Control
var _target_name  : Label
var _target_lines : Label
var _hp_ratio := 1.0
var _hp_ratio_late := 1.0		# 깎인 체력이 천천히 따라오는 잔상 바

var _party_label : Label
var _minimap : Control
var _go_arrow : Label
var _fade_rect : ColorRect
var _result_panel : Control

## 마지막으로 때린 적 (던파식 상단 몬스터 HP 바) — 보스방에서는 보스로 고정
var target : Node = null
var boss_lock : Node = null
var _target_show_time := 0.0
const TARGET_SHOW := 3.0
const LINE_COLORS := [Color(0.85, 0.12, 0.1), Color(0.95, 0.5, 0.1), Color(0.9, 0.8, 0.15),
	Color(0.3, 0.75, 0.25), Color(0.2, 0.5, 0.9), Color(0.6, 0.3, 0.85)]

## 미니맵 : 방 진행도 (현재 방 노랑, 클리어 회색, 보스방 붉은 테두리)
class Minimap extends Control:
	var rooms : Array = []
	var current := 0
	var cleared := {}
	func _draw():
		var cell := Vector2(26, 18)
		for i in rooms.size():
			var pos := Vector2(i * (cell.x + 8), 0)
			if i > 0:
				draw_line(pos + Vector2(-8, cell.y * 0.5), pos + Vector2(0, cell.y * 0.5), Color(0.6, 0.6, 0.6), 2.0)
			var fill := Color(0.15, 0.15, 0.18)
			if cleared.has(i):
				fill = Color(0.45, 0.45, 0.5)
			if i == current:
				fill = Color(1.0, 0.8, 0.25)
			draw_rect(Rect2(pos, cell), fill)
			var border := Color(0.9, 0.2, 0.2) if rooms[i].get("boss", false) else Color(0, 0, 0)
			draw_rect(Rect2(pos, cell), border, false, 2.0)

class HpBar extends Control:
	var hud
	func _draw():
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect.grow(3.0), Color(0, 0, 0, 0.75))
		draw_rect(rect, Color(0.18, 0.05, 0.05))
		draw_rect(Rect2(0, 0, size.x * hud._hp_ratio_late, size.y), Color(1.0, 0.85, 0.5))
		draw_rect(Rect2(0, 0, size.x * hud._hp_ratio, size.y), Color(0.85, 0.12, 0.1))
		draw_rect(Rect2(0, 0, size.x * hud._hp_ratio, size.y * 0.35), Color(1, 1, 1, 0.18))

class TargetBar extends Control:
	var hud
	func _draw():
		var t = hud.target
		if t == null or not is_instance_valid(t):
			return
		var rect := Rect2(Vector2.ZERO, size)
		var armored: bool = t.has_super_armor()
		draw_rect(rect.grow(3.0), Color(1.0, 0.8, 0.25, 0.9) if armored else Color(0, 0, 0, 0.75))
		draw_rect(rect, Color(0.12, 0.05, 0.05))
		var lines: int = maxi(1, t.bar_lines)
		var per_line: float = t.max_hp / lines
		var hp: float = maxf(0.0, t.hp)
		var line := clampi(ceili(hp / per_line), 0, lines)
		if line <= 0:
			return
		var colors: Array = hud.LINE_COLORS
		if line > 1:
			draw_rect(rect, colors[(line - 2) % colors.size()].darkened(0.35))
		var fill := (hp - (line - 1) * per_line) / per_line
		draw_rect(Rect2(0, 0, size.x * fill, size.y), colors[(line - 1) % colors.size()])
		draw_rect(Rect2(0, 0, size.x * fill, size.y * 0.35), Color(1, 1, 1, 0.2))

class MpBar extends Control:
	var hud
	func _draw():
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.75))
		draw_rect(rect, Color(0.05, 0.06, 0.18))
		draw_rect(Rect2(0, 0, size.x * hud._mp_ratio, size.y), Color(0.2, 0.45, 1.0))
		draw_rect(Rect2(0, 0, size.x * hud._mp_ratio, size.y * 0.35), Color(1, 1, 1, 0.2))

## 스킬 슬롯 : 아이콘 + 키 + 쿨타임 (위에서 아래로 걷히는 어두운 막) + MP 부족 시 푸른 틴트
class SkillSlot extends Control:
	var player
	var slot : Dictionary
	var icon : AtlasTexture
	var font : Font
	var _flash := 0.0
	func _process(delta):
		_flash = maxf(0.0, _flash - delta * 4.0)
		queue_redraw()
	func pulse():
		_flash = 1.0
	func _draw():
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect.grow(3.0), Color(0, 0, 0, 0.8))
		draw_rect(rect, Color(0.12, 0.1, 0.1))
		draw_texture_rect(icon, rect.grow(-4.0), false)
		if player == null or not is_instance_valid(player):
			return
		var move_id: String = slot.move
		var skill: Dictionary = player.moves[move_id].skill
		var remain: float = player.get_cooldown(move_id)
		if remain > 0.0:
			var ratio: float = remain / skill.cooldown
			draw_rect(Rect2(0, 0, size.x, size.y * ratio), Color(0, 0, 0, 0.7))
			var sec: String = ("%.1f" % remain) if remain < 10.0 else str(int(remain))
			draw_string_outline(font, Vector2(0, size.y * 0.62), sec, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, 5, Color.BLACK)
			draw_string(font, Vector2(0, size.y * 0.62), sec, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color.WHITE)
		elif player.mp < skill.mp:
			draw_rect(rect, Color(0.1, 0.2, 0.6, 0.55))
		if _flash > 0.0:
			draw_rect(rect, Color(1, 1, 1, 0.6 * _flash))
		draw_string_outline(font, Vector2(4, 16), slot.key, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.BLACK)
		draw_string(font, Vector2(4, 16), slot.key, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.9, 0.5))

func _ready():
	layer = 10
	_hp_bar = HpBar.new()
	_hp_bar.hud = self
	_hp_bar.position = Vector2(28, 30)
	_hp_bar.size = Vector2(360, 22)
	add_child(_hp_bar)
	_hp_label = _make_label(18, Color.WHITE)
	_hp_label.position = Vector2(34, 31)
	add_child(_hp_label)
	_mp_bar = MpBar.new()
	_mp_bar.hud = self
	_mp_bar.position = Vector2(28, 58)
	_mp_bar.size = Vector2(300, 10)
	add_child(_mp_bar)
	_name_label = _make_label(20, Color(1.0, 0.85, 0.45))
	_name_label.position = Vector2(28, 4)
	add_child(_name_label)

	_enemy_label = _make_label(22, Color(0.9, 0.9, 0.95))
	_enemy_label.position = Vector2(560, 18)
	add_child(_enemy_label)

	# 콤보 카운터 (오른쪽)
	_combo_root = Control.new()
	_combo_root.position = Vector2(1090, 150)
	add_child(_combo_root)
	_combo_label = _make_label(64, Color(1.0, 0.82, 0.25))
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.size = Vector2(200, 70)
	_combo_label.position = Vector2(-200, -40)
	_combo_root.add_child(_combo_label)
	_combo_sub = _make_label(24, Color(1.0, 0.95, 0.8))
	_combo_sub.position = Vector2(6, -6)
	_combo_sub.text = "HIT"
	_combo_root.add_child(_combo_sub)
	_combo_root.modulate.a = 0.0

	var help := _make_label(16, Color(1, 1, 1, 0.75))
	help.text = HELP_TEXT
	help.position = Vector2(0, 688)
	help.size = Vector2(1280, 24)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(help)

	# 상단 몬스터 HP 바
	_target_bar = TargetBar.new()
	_target_bar.hud = self
	_target_bar.position = Vector2(400, 74)
	_target_bar.size = Vector2(520, 16)
	add_child(_target_bar)
	_target_name = _make_label(18, Color(1.0, 0.9, 0.75))
	_target_name.position = Vector2(400, 50)
	add_child(_target_name)
	_target_lines = _make_label(18, Color(1.0, 0.9, 0.75))
	_target_lines.position = Vector2(820, 50)
	_target_lines.size = Vector2(100, 24)
	_target_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_target_lines)
	_set_target_visible(false)

	_banner_label = _make_label(54, Color(1.0, 0.88, 0.4))
	_banner_label.position = Vector2(0, 180)
	_banner_label.size = Vector2(1280, 80)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.modulate.a = 0.0
	add_child(_banner_label)

	_party_label = _make_label(16, Color(0.6, 1.0, 0.65))
	_party_label.position = Vector2(28, 74)
	add_child(_party_label)

	_minimap = Minimap.new()
	_minimap.position = Vector2(1100, 22)
	_minimap.size = Vector2(160, 20)
	add_child(_minimap)

	_go_arrow = _make_label(40, Color(0.5, 0.9, 1.0))
	_go_arrow.text = "GO ▶"
	_go_arrow.position = Vector2(1110, 330)
	_go_arrow.visible = false
	add_child(_go_arrow)

	_center_label = _make_label(40, Color.WHITE)
	_center_label.position = Vector2(0, 300)
	_center_label.size = Vector2(1280, 120)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.visible = false
	add_child(_center_label)

func _process(delta):
	_hp_ratio_late = move_toward(_hp_ratio_late, _hp_ratio, delta * 0.6)
	_hp_bar.queue_redraw()
	if _go_arrow.visible:
		_go_arrow.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 150.0)
	if boss_lock != null and is_instance_valid(boss_lock):
		target = boss_lock
		_target_show_time = TARGET_SHOW
	# 몬스터 HP 바
	if target != null:
		_target_show_time -= delta
		if not is_instance_valid(target) or _target_show_time <= 0.0:
			target = null
			_set_target_visible(false)
		else:
			var lines: int = maxi(1, target.bar_lines)
			var line := clampi(ceili(maxf(0.0, target.hp) / (target.max_hp / lines)), 0, lines)
			_target_lines.text = "x%d" % line if lines > 1 else ""
			_target_bar.queue_redraw()

func bind(player: Node, fx: Node):
	player.hp_changed.connect(_on_hp_changed)
	player.mp_changed.connect(_on_mp_changed)
	player.hit_landed.connect(_on_hit_landed)
	_name_label.text = player.display_name
	_update_revives(player.revives)
	player.revived.connect(_update_revives)
	_build_skill_slots(player)
	fx.combo_changed.connect(_on_combo_changed)
	_on_hp_changed(player.hp, player.max_hp)

func _on_hp_changed(hp: float, max_hp: float):
	_hp_ratio = clampf(hp / max_hp, 0.0, 1.0)
	_hp_label.text = "HP  %d / %d" % [int(hp), int(max_hp)]

func _on_combo_changed(count: int):
	if count <= 0:
		var fade := create_tween()
		fade.tween_property(_combo_root, "modulate:a", 0.0, 0.35)
		return
	_combo_label.text = str(count)
	_combo_root.modulate.a = 1.0
	# 콤보가 오를수록 색이 뜨거워짐
	var heat := clampf(count / 40.0, 0.0, 1.0)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25).lerp(Color(1.0, 0.3, 0.15), heat))
	_combo_root.scale = Vector2(1.45, 1.45)
	var pop := create_tween()
	pop.tween_property(_combo_root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_revives(count: int):
	var base: String = _name_label.text.split("   ")[0]
	_name_label.text = base + ("   부활 x%d" % count if count > 0 else "")

func _on_mp_changed(mp: float, max_mp: float):
	_mp_ratio = clampf(mp / max_mp, 0.0, 1.0)
	_mp_bar.queue_redraw()

func _build_skill_slots(player: Node):
	var slots := {}
	for i in player.skill_slots.size():
		var data: Dictionary = player.skill_slots[i]
		var skill: Dictionary = player.moves[data.move].skill
		var slot := SkillSlot.new()
		slot.player = player
		slot.slot = data
		slot.font = FONT
		slot.icon = AtlasTexture.new()
		slot.icon.atlas = ICONS
		slot.icon.region = Rect2(skill.icon.x * 16, skill.icon.y * 16, 16, 16)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.position = Vector2(28 + i * 70, 606)
		slot.size = Vector2(60, 60)
		add_child(slot)
		slots[data.move] = slot
	player.skill_used.connect(func(move_id): if slots.has(move_id): slots[move_id].pulse())

func set_enemy_count(count: int):
	_enemy_label.text = "남은 적  %d" % count

func _on_hit_landed(enemy: Node):
	if boss_lock != null and is_instance_valid(boss_lock):
		return
	if enemy != target:
		target = enemy
		_target_name.text = enemy.display_name
		_set_target_visible(true)
	_target_show_time = TARGET_SHOW

func _set_target_visible(value: bool):
	_target_bar.visible = value
	_target_name.visible = value
	_target_lines.visible = value

## 화면 중앙 상단에 잠깐 떴다 사라지는 문구 (WAVE 1, WAVE CLEAR! 등)
func show_banner(text: String):
	_banner_label.text = text
	_banner_label.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(_banner_label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.1)
	tween.tween_property(_banner_label, "modulate:a", 0.0, 0.4)

func show_center(text: String):
	_center_label.text = text
	_center_label.visible = text != ""

func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	return label

# ───────────────────────────── 던전 진행 UI ─────────────────────────────

func setup_minimap(rooms: Array):
	_minimap.rooms = rooms
	_minimap.queue_redraw()

func set_party(names: Array):
	_party_label.text = "동료 : " + ", ".join(PackedStringArray(names)) if not names.is_empty() else ""

func set_room(index: int):
	_minimap.current = index
	_minimap.queue_redraw()
	boss_lock = null
	target = null
	_set_target_visible(false)

func mark_room_cleared(index: int):
	_minimap.cleared[index] = true
	_minimap.queue_redraw()

func show_go_arrow(value: bool):
	_go_arrow.visible = value

## 보스방 : 상단 HP 바를 보스로 고정
func set_boss(enemy: Node):
	boss_lock = enemy
	target = enemy
	_target_name.text = enemy.display_name
	_target_show_time = TARGET_SHOW
	_set_target_visible(true)

## 화면 페이드 (await 가능). alpha 1 = 검은 화면
func fade(alpha: float, duration: float):
	if _fade_rect == null:
		_fade_rect = ColorRect.new()
		_fade_rect.color = Color(0, 0, 0, 0)
		_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_fade_rect)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, duration)
	await tween.finished

## 던전 클리어 결과창
func show_result(stats: Dictionary):
	_result_panel = Control.new()
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_result_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(dim)

	var title := _make_label(44, Color(1.0, 0.85, 0.35))
	title.text = "DUNGEON CLEAR!"
	title.position = Vector2(0, 110)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_panel.add_child(title)
	var sub := _make_label(22, Color(0.85, 0.85, 0.9))
	sub.text = stats.dungeon
	sub.position = Vector2(0, 168)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_panel.add_child(sub)

	var rank := _make_label(150, _rank_color(stats.rank))
	rank.text = stats.rank
	rank.position = Vector2(250, 230)
	rank.size = Vector2(380, 180)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.pivot_offset = Vector2(190, 90)
	_result_panel.add_child(rank)

	var seconds := int(stats.time)
	var lines := [
		["클리어 타임", "%d:%02d" % [seconds / 60, seconds % 60]],
		["최대 콤보", "%d" % stats.max_combo],
		["총 타격 수", "%d" % stats.total_hits],
		["처치한 적", "%d" % stats.kills],
		["피격 횟수", "%d" % stats.hits_taken],
		["획득 골드", "%d G" % stats.gold],
	]
	for i in lines.size():
		var key := _make_label(24, Color(0.85, 0.85, 0.9))
		key.text = lines[i][0]
		key.position = Vector2(680, 245 + i * 38)
		_result_panel.add_child(key)
		var value := _make_label(24, Color.WHITE)
		value.text = lines[i][1]
		value.position = Vector2(860, 245 + i * 38)
		value.size = Vector2(160, 30)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_result_panel.add_child(value)

	var hint := _make_label(22, Color(1, 1, 1, 0.8))
	hint.text = "R : 다시 도전        ESC : 메뉴"
	hint.position = Vector2(0, 520)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_panel.add_child(hint)

	# 연출 : 패널 페이드 인 → 랭크 도장 찍기
	_result_panel.modulate.a = 0.0
	rank.scale = Vector2(3.0, 3.0)
	rank.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_result_panel, "modulate:a", 1.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_property(rank, "modulate:a", 1.0, 0.01)
	tween.tween_property(rank, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _rank_color(rank: String) -> Color:
	match rank:
		"SSS", "SS", "S":
			return Color(1.0, 0.75, 0.2)
		"A":
			return Color(0.4, 0.85, 1.0)
		"B":
			return Color(0.5, 1.0, 0.5)
	return Color(0.8, 0.8, 0.8)
