extends Node2D
## 적 투사체 : 일정 높이로 가로 직진, 플레이어와 겹치면 타격 후 터짐
## 기본 : 시트 앞쪽 4프레임 = 비행, 뒤쪽 4프레임 = 터짐
## sheet 옵션 : "fly_count", "burst_path"(폭발 시트가 따로 있을 때), "burst_frame_width", "burst_count",
##              "scale", "burst_sound"

const Combat      = preload("res://dynamic/8_action/core/combat.gd")
const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")

var attack : Dictionary
var owner_enemy : Node2D
var power   := 1000.0
var speed   := 360.0
var facing  := 1
var z       := 48.0
var max_distance := 620.0
var hits_enemies := false		# 동료가 쏜 투사체면 적을 맞힘
var sheet   : Dictionary

var stage : Node = null
var _travelled := 0.0
var _bursting := false
var _sprite : AnimatedSprite2D

func _ready():
	_sprite = AnimatedSprite2D.new()
	var frame_w: int = sheet.frame_width
	var separate_burst: bool = sheet.has("burst_path")
	var burst := {"path": sheet.get("burst_path", sheet.path), "frame_width": sheet.get("burst_frame_width", frame_w),
		"start": 0 if separate_burst else 4, "count": sheet.get("burst_count", 4), "fps": 16.0, "loop": false}
	_sprite.sprite_frames = SpriteSheet.build("projectile_" + sheet.path, {
		"fly"  : {"path": sheet.path, "frame_width": frame_w, "count": sheet.get("fly_count", 4), "fps": 12.0, "loop": true},
		"burst": burst,
	})
	var sprite_scale: float = sheet.get("scale", 2.2)
	_sprite.position = Vector2(0, -z)
	_sprite.scale = Vector2(sprite_scale * facing, sprite_scale)
	_sprite.play("fly")
	_sprite.animation_finished.connect(queue_free)
	add_child(_sprite)

func _physics_process(delta):
	if _bursting:
		return
	var step: float = speed * delta
	position.x += facing * step
	_travelled += step
	if hits_enemies:
		for enemy in get_tree().get_nodes_in_group("action_enemy"):
			if enemy.can_be_hit() and Combat.overlaps(self, attack, enemy):
				enemy.receive_hit(attack, self, Combat.roll_damage(power, attack))
				_burst()
				return
	else:
		var player: Node2D = stage.player if stage else null
		if player and player.can_be_hit() and Combat.overlaps(self, attack, player):
			player.receive_hit(attack, self, Combat.roll_damage(power, attack))
			_burst()
			return
	if _travelled >= max_distance or (stage and position.x != stage.clamp_to_floor(position).x):
		_burst()

func _burst():
	_bursting = true
	_sprite.play("burst")
	if sheet.has("burst_sound") and stage and stage.fx:
		stage.fx.play_sound(load(sheet.burst_sound), 0.1, -6.0)
