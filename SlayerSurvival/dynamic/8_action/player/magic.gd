extends RefCounted
## 위자드 마법 오브젝트 모음 (코드 드로잉 + 기존 Lightning 시트)
## 모두 caster.deal_hits(self, ...)로 피해를 주므로 콤보/흡혈/히트스탑이 플레이어 공격으로 처리된다.
## 공통 속성 : position(바닥), z(높이), facing  → Combat.overlaps 판정용

const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

## 가산 합성 머티리얼 (빛나는 마법 표현)
class Glow:
	static func additive() -> CanvasItemMaterial:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return mat

## 마력탄 : 앞으로 날아가 처음 맞은 적(관통이면 여러 적)에게 피해
class Bolt extends Node2D:
	var caster : Node2D
	var attack : Dictionary
	var facing := 1
	var z := 70.0
	var speed := 900.0
	var max_distance := 560.0
	var pierce := false
	var radius := 14.0
	var color := Color(0.75, 0.5, 1.0)
	var _travelled := 0.0
	var _log := []
	var _trail : Array[Vector2] = []
	func _ready():
		material = Glow.additive()
	func _physics_process(delta):
		var step: float = speed * delta
		position.x += facing * step
		_travelled += step
		_trail.push_front(Vector2(position.x, position.y - z))
		if _trail.size() > 8:
			_trail.pop_back()
		var hit: int = caster.deal_hits(self, attack, _log, 99 if pierce else 1)
		if (hit > 0 and not pierce) or _travelled >= max_distance or position.x != caster.stage.clamp_to_floor(position).x:
			var fx = caster.fx
			if fx:
				fx.spawn_spark(Vector2(position.x, position.y - z), "blunt", facing, color)
			queue_free()
			return
		queue_redraw()
	func _draw():
		for i in _trail.size():
			var p := _trail[i] - Vector2(position.x, position.y)
			draw_circle(p, radius * (1.0 - i / 9.0), Color(color, 0.35 * (1.0 - i / 9.0)))
		draw_circle(Vector2(0, -z), radius * 1.4, Color(color, 0.5))
		draw_circle(Vector2(0, -z), radius, Color(1, 1, 1, 0.95))

## 그라비티 홀 : 주변 적을 계속 빨아들이다가 마지막에 폭발 (마법사의 몰이 스킬)
class Vortex extends Node2D:
	var caster : Node2D
	var pulse_attack : Dictionary
	var burst_attack : Dictionary
	var facing := 1
	var z := 40.0
	var life := 1.6
	var radius := 260.0
	var pulse_interval := 0.14
	var _t := 0.0
	var _pulse_t := 0.0
	func _ready():
		material = Glow.additive()
	func _physics_process(delta):
		_t += delta
		_pulse_t -= delta
		if _pulse_t <= 0.0 and _t < life:
			_pulse_t = pulse_interval
			caster.deal_hits(self, pulse_attack, [])
		if _t >= life:
			var fx = caster.fx
			if fx:
				fx.spawn_shockwave(position, radius * 1.1, Color(0.7, 0.45, 1.0))
				fx.flash_screen(Color(0.7, 0.5, 1.0, 0.35), 0.2)
				fx.play_hit_sound("heavy")
			caster.deal_hits(self, burst_attack, [])
			queue_free()
			return
		queue_redraw()
	func _draw():
		var grow := minf(1.0, _t / 0.25)
		draw_set_transform(Vector2(0, -z), 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * 0.32 * grow, Color(0.25, 0.05, 0.4, 0.6))
		for i in 5:
			var spin: float = -_t * 9.0 + i * TAU / 5.0
			var r: float = radius * (0.3 + 0.14 * i) * grow
			draw_arc(Vector2.ZERO, r, spin, spin + 2.2, 20, Color(0.75, 0.45, 1.0, 0.55), 6.0 - i)
		draw_circle(Vector2.ZERO, radius * 0.12 * grow, Color(1, 0.9, 1, 0.9))

## 낙뢰 : 기존 위자드 Lightning 시트를 대상 위치에 떨어뜨림
class LightningStrike extends Node2D:
	const SHEET := "res://dynamic/1_player/characters/Wizard/Lightning/Lightning.png"
	var caster : Node2D
	var attack : Dictionary
	var facing := 1
	var z := 0.0
	var _done := false
	var _sprite : AnimatedSprite2D
	func _ready():
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = SpriteSheet.build("wizard_lightning", {"strike": {
			"path": SHEET, "frame_width": 64, "frame_height": 160, "fps": 22.0, "loop": false}})
		_sprite.offset = Vector2(0, -80)
		_sprite.scale = Vector2(2.0, 2.2)
		_sprite.material = Glow.additive()
		_sprite.animation_finished.connect(queue_free)
		_sprite.play("strike")
		add_child(_sprite)
	func _physics_process(_delta):
		if not _done and _sprite.frame >= 2:
			_done = true
			caster.deal_hits(self, attack, [])
			var fx = caster.fx
			if fx:
				fx.spawn_shockwave(position, 110.0, Color(0.6, 0.85, 1.0))

## 메테오 : 하늘에서 떨어져 바닥에서 폭발
class Meteor extends Node2D:
	var caster : Node2D
	var attack : Dictionary
	var facing := 1
	var z := 620.0
	var fall_time := 0.38
	var delay := 0.0
	var _t := 0.0
	var _start_z := 620.0
	func _ready():
		_start_z = z
		material = Glow.additive()
		var fx = caster.fx
		if fx:
			fx.spawn_telegraph(Rect2(position.x - 60.0, position.y - 34.0, 120.0, 68.0), delay + fall_time, true)
	func _physics_process(delta):
		_t += delta
		if _t < delay:
			return
		var p := minf(1.0, (_t - delay) / fall_time)
		z = lerpf(_start_z, 0.0, p * p)
		if p >= 1.0:
			z = 0.0
			var fx = caster.fx
			if fx:
				fx.spawn_shockwave(position, 150.0, Color(1.0, 0.55, 0.2))
				fx.spawn_spark(position + Vector2(0, -30), "heavy", 1, Color(1.0, 0.6, 0.25))
			caster.deal_hits(self, attack, [])
			queue_free()
			return
		queue_redraw()
	func _draw():
		if _t < delay:
			return
		var head := Vector2(-z * 0.35, -z)
		for i in 6:
			var tail := head + Vector2(i * 9.0, -i * 22.0)
			draw_circle(tail, 22.0 - i * 3.0, Color(1.0, 0.5 - i * 0.06, 0.15, 0.5 - i * 0.07))
		draw_circle(head, 20.0, Color(1.0, 0.8, 0.4, 0.95))
		draw_circle(head, 11.0, Color(1, 1, 0.9, 1.0))
