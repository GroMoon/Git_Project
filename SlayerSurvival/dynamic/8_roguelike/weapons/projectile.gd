extends Area2D

class_name Projectile

## 범용 투사체: 직선 이동, 적 충돌 시 on_hit 콜백, 관통 횟수, 수명
## on_hit(enemy) 가 false 를 반환하면 관통 횟수를 소모하지 않음(튕김 등 직접 처리)

var velocity := Vector2.ZERO
var lifetime := 1.5
var pierce := 1						# 맞힐 수 있는 적 수 (0이 되면 소멸)
var on_hit: Callable				# func(enemy) -> bool
var on_expire: Callable				# func(position)
var rotate_to_velocity := true
var hit_enemies := {}
var sprite: AnimatedSprite2D
var done := false

static func create(sprite_frames: SpriteFrames, anim: String, radius: float, sprite_scale: float = 1.0) -> Projectile:
	var p = Projectile.new()
	p.collision_layer = 0
	p.collision_mask = WeaponBase.ENEMY_MASK
	p.monitorable = false
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	p.add_child(shape)
	p.sprite = AnimatedSprite2D.new()
	p.sprite.sprite_frames = sprite_frames
	p.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.sprite.scale = Vector2(sprite_scale, sprite_scale)
	p.add_child(p.sprite)
	p.sprite.play(anim)
	p.z_index = 6
	return p

func _ready():
	body_entered.connect(_on_body_entered)
	if rotate_to_velocity and velocity != Vector2.ZERO:
		rotation = velocity.angle()

func _physics_process(delta):
	if done:
		return
	global_position += velocity * delta
	if rotate_to_velocity and velocity != Vector2.ZERO:
		rotation = velocity.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		expire()

func _on_body_entered(body):
	if done or not body.is_in_group("enemy"):
		return
	var key = body.get_instance_id()
	if hit_enemies.has(key):
		return
	hit_enemies[key] = true
	var consume = true
	if on_hit.is_valid():
		var result = on_hit.call(body)
		if result == false:
			consume = false
	if consume:
		pierce -= 1
		if pierce <= 0:
			expire()

func expire():
	if done:
		return
	done = true
	if on_expire.is_valid():
		on_expire.call(global_position)
	queue_free()
