extends Node2D
## 보스 주문 : 지정 위치 바닥에 위험 범위 표시 → 이펙트가 나타나 타격(띄움)
## 기본값은 브링어 오브 데스의 어둠의 손. 파이어 웜의 용암 분출은 options로 바꿔 쓴다.

const Combat      = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

var warn_time := 0.75				# 예고 시간
var hit_frames := [7, 10]			# 타격 판정 프레임 구간
var sprite_offset := Vector2(2, -45)
var sprite_scale := 3.0
var zone_size := Vector2(110, 60)	# 바닥 예고 원 크기
var sound : AudioStream = null		# 타격 순간 소리

var stage : Node = null
var caster : Node2D = null
var sheet : Dictionary
var attack : Dictionary
var power := 2000.0
var facing := 1
var z := 0.0

var _sprite : AnimatedSprite2D
var _t := 0.0
var _casting := false
var _hit_done := false

func _ready():
	var fx = caster.fx
	if fx:
		fx.spawn_telegraph(Rect2(position - zone_size * 0.5, zone_size), warn_time, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteSheet.build("boss_spell_" + sheet.path, {"spell": sheet})
	_sprite.offset = sprite_offset
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_sprite.visible = false
	_sprite.animation_finished.connect(queue_free)
	add_child(_sprite)

func _physics_process(delta):
	_t += delta
	if not _casting:
		if _t >= warn_time:
			_casting = true
			_sprite.visible = true
			_sprite.play("spell")
			if sound and caster and caster.fx:
				caster.fx.play_sound(sound, 0.1, -4.0)
		return
	if _hit_done or _sprite.frame < hit_frames[0] or _sprite.frame > hit_frames[1]:
		return
	var player: Node2D = stage.player if stage else null
	if player and player.can_be_hit() and Combat.overlaps(self, attack, player):
		_hit_done = true
		player.receive_hit(attack, self, Combat.roll_damage(power, attack))
