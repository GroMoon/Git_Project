extends WeaponBase

## 눈알 탄환: 이동(바라보는) 방향으로 관통 탄환을 연사

const SPEED       = 560.0
const LIFETIME    = 0.9
const BURST_DELAY = 0.07
const SHEET       = "res://dynamic/2_enemy/FlyingEye/Sprites/projectile_sprite.png"

var frames: SpriteFrames
var aim := Vector2.RIGHT

func _ready():
	frames = WeaponFx.frames(SHEET, Vector2i(48, 48), {"fly": [0, 3, 14, true]})

func _physics_process(delta):
	# 마지막 이동 방향 기억 (멈춰 있으면 바라보는 방향)
	if player and is_instance_valid(player):
		if player.velocity.length() > 1.0:
			aim = player.velocity.normalized()
		elif aim == Vector2.ZERO:
			aim = Vector2.LEFT if player.animated_sprite.flip_h else Vector2.RIGHT
	super._physics_process(delta)

func fire() -> bool:
	_burst(get_amount(), aim)
	return true

func _burst(count: int, dir: Vector2):
	for i in count:
		if not is_instance_valid(self) or player.is_dead:
			return
		# 약간 퍼지게 + 진행 방향 옆으로 오프셋
		var spread = dir.rotated(randf_range(-0.08, 0.08))
		var side = dir.orthogonal() * randf_range(-10, 10)
		var p = Projectile.create(frames, "fly", 9.0, 0.9)
		p.global_position = global_position + side + dir * 10.0
		p.velocity = spread * SPEED
		p.lifetime = LIFETIME
		p.pierce = int(stat("pierce", 2))
		p.on_hit = func(enemy):
			hit(enemy, get_damage(), 0.6, p.global_position)
			return true
		world().add_child(p)
		if i < count - 1:
			await wait(BURST_DELAY)
