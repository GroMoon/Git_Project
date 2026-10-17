extends WeaponBase

## 회전 칼날: 플레이어 주위를 공전하며 닿는 적에게 피해 (적마다 재타격 간격 존재)

const ORBIT_RADIUS  = 78.0
const BLADE_RADIUS  = 15.0
const REHIT_TIME    = 0.45		# 같은 적 재타격 간격(초)
const SHEET         = "res://dynamic/2_enemy/Skeleton/Sprites/Sword_sprite.png"

var frames: SpriteFrames
var blades: Array = []
var angle := 0.0
var last_hit := {}				# enemy_id -> 마지막 타격 시각

func _ready():
	frames = WeaponFx.frames(SHEET, Vector2i(92, 102), {"spin": [0, 3, 14, true]})

func on_level_changed():
	_rebuild_blades.call_deferred()

func _rebuild_blades():
	for b in blades:
		b.queue_free()
	blades.clear()
	for i in get_amount():
		var blade = Area2D.new()
		blade.collision_layer = 0
		blade.collision_mask = ENEMY_MASK
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = BLADE_RADIUS
		shape.shape = circle
		blade.add_child(shape)
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(1.1, 1.1)
		sprite.modulate = Color(0.85, 0.95, 1.0)
		sprite.play("spin")
		blade.add_child(sprite)
		blade.z_index = 6
		add_child(blade)
		blades.append(blade)

func _physics_process(delta):
	if player == null or not is_instance_valid(player):
		return
	global_position = player.global_position
	if player.is_dead:
		return
	# 플레이어의 투사체/범위 보너스가 바뀌면 다시 구성
	if blades.size() != get_amount():
		_rebuild_blades()
	angle += float(stat("speed", 3.0)) * delta
	var radius = ORBIT_RADIUS * get_area()
	var now = Time.get_ticks_msec() / 1000.0
	for i in blades.size():
		var blade: Area2D = blades[i]
		var a = angle + TAU * i / blades.size()
		blade.position = Vector2(cos(a), sin(a)) * radius
		for body in blade.get_overlapping_bodies():
			if not body.is_in_group("enemy"):
				continue
			var key = body.get_instance_id()
			if now - last_hit.get(key, -10.0) >= REHIT_TIME:
				last_hit[key] = now
				hit(body, get_damage(), 0.7, blade.global_position)
	# 오래된 기록 정리
	if last_hit.size() > 400:
		last_hit.clear()
