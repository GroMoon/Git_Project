extends WeaponBase

## 버섯 포자: 가까운 적에게 발사, 맞히면 근처의 다른 적에게 튕겨 감

const SPEED        = 420.0
const RANGE        = 480.0
const BOUNCE_RANGE = 240.0
const SHEET        = "res://dynamic/2_enemy/Mushroom/Sprites/Projectile_sprite.png"

var frames: SpriteFrames
var pop_frames: SpriteFrames

func _ready():
	frames     = WeaponFx.frames(SHEET, Vector2i(50, 50), {"fly": [0, 4, 12, true]})
	pop_frames = WeaponFx.frames(SHEET, Vector2i(50, 50), {"pop": [4, 4, 20, false]})

func fire() -> bool:
	var targets = enemies_by_distance(RANGE)
	if targets.is_empty():
		return false
	for i in get_amount():
		var target = targets[i % targets.size()]
		var dir = (target.global_position - global_position).normalized()
		_launch(global_position, dir, int(stat("bounce", 2)))
	return true

func _launch(from: Vector2, dir: Vector2, bounces_left: int, already_hit: Dictionary = {}):
	var p = Projectile.create(frames, "fly", 9.0, 1.2)
	p.global_position = from
	p.velocity = dir * SPEED
	p.lifetime = RANGE / SPEED
	p.pierce = 1
	p.rotate_to_velocity = false
	p.hit_enemies = already_hit.duplicate()
	p.on_hit = func(enemy):
		hit(enemy, get_damage(), 0.5, p.global_position)
		WeaponFx.play_once(world(), pop_frames, "pop", enemy.global_position, 1.2)
		if bounces_left > 0:
			var next = _next_target(enemy, p.hit_enemies)
			if next:
				var new_dir = (next.global_position - enemy.global_position).normalized()
				_launch.call_deferred(enemy.global_position, new_dir, bounces_left - 1, p.hit_enemies)
		return true
	world().add_child(p)

# 이미 맞힌 적을 제외한 가장 가까운 적
func _next_target(from_enemy: Node2D, exclude: Dictionary) -> Node2D:
	var best: Node2D = null
	var best_d = BOUNCE_RANGE
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == from_enemy or exclude.has(enemy.get_instance_id()):
			continue
		var d = from_enemy.global_position.distance_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best
