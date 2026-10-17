extends Node2D
## 2.5D 액터 베이스 (플레이어 / 적 공통)
##   position = 바닥 위치 (x, 깊이)   z = 높이
##   부모 노드(Actors)가 y_sort 되므로 깊이에 따라 자동으로 앞뒤가 정렬된다.

signal died(actor)

const FLASH_SHADER = preload("res://dynamic/8_action/core/flash.gdshader")
const GRAVITY := 1700.0

## 기본 파라미터
@export var max_hp        := 10000.0
@export var body_radius   := 20.0				# 몸통 가로 반폭
@export var body_height   := 90.0				# 몸통 높이
@export var depth_radius  := 10.0				# 깊이 두께
@export var sprite_scale  := 2.2
@export var sprite_offset := Vector2.ZERO		# 시트 프레임 안에서 발 위치 보정 (시트 px)
@export var shadow_size   := Vector2(64, 18)
@export var sheet_faces_left := false			# 시트 원본이 왼쪽을 보고 있으면 true

var hp         := 10000.0
var z          := 0.0				# 높이
var z_velocity := 0.0
var facing     := 1					# 1 = 오른쪽, -1 = 왼쪽
var stage      : Node = null		# 방 경계/카메라/FX 제공 (action_stage.gd)

## 하위 노드 (코드로 생성)
var visual : Node2D
var sprite : AnimatedSprite2D
var shadow : Node2D

## 피격 연출
var _flash_time   := 0.0
var _flash_color  := Color.WHITE
var _shake_time   := 0.0
var _shake_power  := 0.0

class GroundShadow extends Node2D:
	var size := Vector2(64, 18)
	func _draw():
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, size.y / size.x))
		draw_circle(Vector2.ZERO, size.x * 0.5, Color(0, 0, 0, 0.35))
		draw_circle(Vector2.ZERO, size.x * 0.32, Color(0, 0, 0, 0.25))

func _ready():
	hp = max_hp
	_build_nodes()

func _build_nodes():
	shadow = GroundShadow.new()
	shadow.size = shadow_size
	shadow.z_index = -1				# 그림자는 모든 액터 아래
	add_child(shadow)

	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)

	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.offset = sprite_offset
	var flash_material := ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	sprite.material = flash_material
	visual.add_child(sprite)
	_update_visual()

## 매 프레임 호출 : 높이/방향/피격 연출 반영
func _update_visual():
	# 누운 자세일수록 몸 두께만큼 띄워서 바닥에 파묻히지 않게
	visual.position = Vector2(0, -z - absf(sin(visual.rotation)) * body_radius * 0.9)
	visual.scale = Vector2(sprite_scale * facing * (-1 if sheet_faces_left else 1), sprite_scale)
	# 높이에 따라 그림자 축소
	var shadow_scale := clampf(1.0 - z / 400.0, 0.45, 1.0)
	shadow.scale = Vector2(shadow_scale, shadow_scale)
	# 피격 흔들림 (히트스탑 중에도 보이도록)
	if _shake_time > 0.0:
		visual.position.x += randf_range(-_shake_power, _shake_power)
	# 피격 플래시
	var flash := clampf(_flash_time / 0.08, 0.0, 1.0)
	sprite.material.set_shader_parameter("flash", flash)
	sprite.material.set_shader_parameter("flash_color", _flash_color)

func _tick_effects(delta: float):
	_flash_time = maxf(0.0, _flash_time - delta)
	_shake_time = maxf(0.0, _shake_time - delta)

func flash(duration := 0.08, color := Color.WHITE):
	_flash_time = duration
	_flash_color = color

func hit_shake(duration := 0.12, power := 3.0):
	_shake_time = duration
	_shake_power = power

## 높이 물리. 이번 프레임에 착지했으면 true
func update_air(delta: float, gravity_scale := 1.0) -> bool:
	if z <= 0.0 and z_velocity <= 0.0:
		return false
	z_velocity -= GRAVITY * gravity_scale * delta
	z += z_velocity * delta
	if z <= 0.0:
		z = 0.0
		z_velocity = 0.0
		return true
	return false

func is_airborne() -> bool:
	return z > 0.0 or z_velocity > 0.0

## 바닥 이동 + 방 경계 클램프
func move_ground(velocity: Vector2, delta: float):
	position += velocity * delta
	if stage:
		position = stage.clamp_to_floor(position)

## 피격 판정용 몸통 높이 (다운 상태에서는 낮아짐)
func get_hurt_height() -> float:
	return body_height

## 타격 이펙트 위치 (월드 좌표)
func get_hit_point(from_facing: int) -> Vector2:
	return Vector2(position.x - from_facing * body_radius * 0.4, position.y - z - body_height * 0.55)

## 애니메이션 재생 (루프용)
func play_anim(anim: String):
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)

## 특정 프레임 고정 표시 (공격 모션처럼 코드가 프레임을 직접 넘길 때)
func show_frame(anim: String, frame: int):
	if sprite.is_playing():
		sprite.stop()
	if sprite.animation != anim:
		sprite.animation = anim
	var count := sprite.sprite_frames.get_frame_count(anim)
	sprite.frame = clampi(frame, 0, count - 1)

func is_dead() -> bool:
	return hp <= 0.0
