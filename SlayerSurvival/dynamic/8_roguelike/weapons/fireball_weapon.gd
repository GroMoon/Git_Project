extends WeaponBase

## 화염구: 가까운 적들을 향해 발사, 명중/수명 종료 시 폭발 범위 피해

const SPEED        = 380.0
const RANGE        = 520.0
const BLAST_RADIUS = 46.0
const MOVE_SHEET   = "res://dynamic/2_enemy/Boss_FireWorm/Sprites/Fire Ball/Move.png"
const BLAST_SHEET  = "res://dynamic/2_enemy/Boss_FireWorm/Sprites/Fire Ball/Explosion.png"

var move_frames: SpriteFrames
var blast_frames: SpriteFrames

func _ready():
	move_frames  = WeaponFx.frames(MOVE_SHEET, Vector2i(46, 46), {"fly": [0, 6, 12, true]})
	blast_frames = WeaponFx.frames(BLAST_SHEET, Vector2i(46, 46), {"boom": [0, 7, 18, false]})

func fire() -> bool:
	var targets = enemies_by_distance(RANGE)
	if targets.is_empty():
		return false
	var count = get_amount()
	for i in count:
		var target = targets[i % targets.size()]
		var dir = (target.global_position - global_position).normalized()
		# 같은 대상을 여러 발이 노리면 살짝 퍼지게
		if i >= targets.size():
			dir = dir.rotated(randf_range(-0.35, 0.35))
		_launch(dir)
	return true

func _launch(dir: Vector2):
	var p = Projectile.create(move_frames, "fly", 10.0, 1.3)
	p.global_position = global_position + dir * 12.0
	p.velocity = dir * SPEED
	p.lifetime = RANGE / SPEED
	p.pierce = 1
	p.on_hit = func(_enemy): return true
	p.on_expire = _explode
	world().add_child(p)

func _explode(pos: Vector2):
	var area = get_area()
	WeaponFx.play_once(world(), blast_frames, "boom", pos, 1.6 * area)
	hit_radius(pos, BLAST_RADIUS * area, get_damage(), 1.2)
	GameFeel.shake(0.06)
