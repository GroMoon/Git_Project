extends WeaponBase

## 고블린 폭탄: 적 무리 쪽으로 포물선 투척 → 짧은 도화선 → 큰 폭발 (강한 넉백 + 화면 흔들림)

const RANGE        = 320.0
const BLAST_RADIUS = 72.0
const FLIGHT_TIME  = 0.45
const FUSE_TIME    = 0.25
const SHEET        = "res://dynamic/2_enemy/Goblin/Sprites/Bomb_sprite.png"

var frames: SpriteFrames

func _ready():
	frames = WeaponFx.frames(SHEET, Vector2i(100, 100), {
		"fly":  [0, 3, 12, true],
		"fuse": [9, 3, 16, true],
		"boom": [12, 7, 16, false],
	})

func fire() -> bool:
	var targets = enemies_by_distance(RANGE)
	if targets.is_empty():
		return false
	for i in get_amount():
		# 무작위 적 근처로 (가까운 적일수록 잘 뽑힘)
		var idx = int(pow(randf(), 1.6) * targets.size())
		var target = targets[idx]
		var dest = target.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		_throw(dest, i * 0.12)
	return true

func _throw(dest: Vector2, delay: float):
	if delay > 0.0:
		await wait(delay)
		if not is_instance_valid(self) or player.is_dead:
			return
	var bomb = AnimatedSprite2D.new()
	bomb.sprite_frames = frames
	bomb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bomb.scale = Vector2(1.6, 1.6)
	bomb.z_index = 7
	bomb.global_position = global_position
	world().add_child(bomb)
	bomb.play("fly")
	# 포물선: 위치는 직선 보간 + 높이 오프셋
	var start = global_position
	var tween = bomb.create_tween()
	tween.tween_method(func(t):
		bomb.global_position = start.lerp(dest, t) + Vector2(0, -sin(t * PI) * 70.0)
		bomb.rotation = t * TAU, 0.0, 1.0, FLIGHT_TIME)
	tween.tween_callback(func():
		bomb.rotation = 0.0
		bomb.play("fuse"))
	tween.tween_interval(FUSE_TIME)
	tween.tween_callback(func(): _explode(bomb))

func _explode(bomb: AnimatedSprite2D):
	if not is_instance_valid(bomb):
		return
	var pos = bomb.global_position
	var area = get_area()
	bomb.scale = Vector2(1.6, 1.6) * area
	bomb.play("boom")
	bomb.animation_finished.connect(bomb.queue_free)
	if is_instance_valid(self) and player != null:
		hit_radius(pos, BLAST_RADIUS * area, get_damage(), 2.6)
	GameFeel.shake(0.22)
	GameFeel.play_sfx("explosion", randf_range(0.8, 1.0), -4.0, 0.07)
	GameFeel.burst(pos, Color(1.0, 0.55, 0.15), 16, 220.0, 3.5)
