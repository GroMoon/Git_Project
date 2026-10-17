extends Node2D
## 보스 주문 : 지정 위치 바닥에 위험 범위 표시 → 포털에서 어둠의 손이 내려와 타격(띄움)

const Combat      = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

const WARN_TIME := 0.75		# 예고 시간
const HIT_FRAMES := [7, 10]	# 손이 바닥에 닿아 있는 프레임 구간

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
	var fx = get_tree().get_first_node_in_group("combat_fx")
	if fx:
		fx.spawn_telegraph(Rect2(position.x - 55.0, position.y - 30.0, 110.0, 60.0), WARN_TIME, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteSheet.build("boss_spell", {"spell": sheet})
	_sprite.offset = Vector2(2, -45)
	_sprite.scale = Vector2(3.0, 3.0)
	_sprite.visible = false
	_sprite.animation_finished.connect(queue_free)
	add_child(_sprite)

func _physics_process(delta):
	_t += delta
	if not _casting:
		if _t >= WARN_TIME:
			_casting = true
			_sprite.visible = true
			_sprite.play("spell")
		return
	if _hit_done or _sprite.frame < HIT_FRAMES[0] or _sprite.frame > HIT_FRAMES[1]:
		return
	var player: Node2D = stage.player if stage else null
	if player and player.can_be_hit() and Combat.overlaps(self, attack, player):
		_hit_done = true
		player.receive_hit(attack, self, Combat.roll_damage(power, attack))
