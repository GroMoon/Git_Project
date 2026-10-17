extends Node

## 손맛(게임 필) 담당 오토로드
## - 화면 흔들림(trauma 방식), 히트스톱, 파티클 버스트, 화면 플래시, 피격 플래시 셰이더

const MAX_SHAKE_OFFSET = 14.0		# 최대 흔들림(px)
const SHAKE_DECAY      = 2.2		# 초당 trauma 감소량
const HITSTOP_COOLDOWN = 0.12		# 히트스톱 연속 발동 방지(실시간 초)

var flash_shader = preload("res://static/shader/flash.gdshader")

var trauma := 0.0
var shake_time := 0.0
var hitstop_until := 0.0		# 히트스톱 종료 시각(실시간 ms)
var hitstop_ready_at := 0.0		# 다음 히트스톱 가능 시각(실시간 ms)
var flash_layer: CanvasLayer
var flash_rect: ColorRect

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 화면 플래시용 오버레이
	flash_layer = CanvasLayer.new()
	flash_layer.layer = 90
	add_child(flash_layer)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	flash_layer.add_child(flash_rect)

func _process(delta):
	_process_hitstop()
	_process_shake(delta)

# ================= 화면 흔들림 =================
# amount: 0.0 ~ 1.0 (0.2 약함, 0.5 강함, 1.0 최대)
func shake(amount: float):
	trauma = min(trauma + amount, 1.0)

func _process_shake(delta):
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	if get_tree().paused:
		return
	if trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_time += delta * 40.0
	trauma = max(trauma - SHAKE_DECAY * delta, 0.0)
	var power = trauma * trauma
	camera.offset = Vector2(
		sin(shake_time * 1.1) * cos(shake_time * 0.37),
		cos(shake_time * 0.9) * sin(shake_time * 0.53)
	) * MAX_SHAKE_OFFSET * power

# ================= 히트스톱 =================
# duration: 실시간 초 (0.03 ~ 0.1 권장)
func hitstop(duration: float, time_scale: float = 0.05):
	var now = Time.get_ticks_msec() / 1000.0
	if now < hitstop_ready_at:
		return
	hitstop_until = max(hitstop_until, now + duration)
	hitstop_ready_at = now + duration + HITSTOP_COOLDOWN
	Engine.time_scale = time_scale

func _process_hitstop():
	if hitstop_until <= 0.0:
		return
	if Time.get_ticks_msec() / 1000.0 >= hitstop_until:
		hitstop_until = 0.0
		Engine.time_scale = 1.0

# 씬 전환 시 등 강제 초기화
func reset():
	hitstop_until = 0.0
	Engine.time_scale = 1.0
	trauma = 0.0

# ================= 화면 플래시 =================
func flash_screen(color: Color = Color(1, 1, 1, 0.5), duration: float = 0.25):
	flash_rect.color = color
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(flash_rect, "color:a", 0.0, duration)

# ================= 파티클 =================
# 원샷 파티클 버스트 (적 사망, 폭발 등)
func burst(pos: Vector2, color: Color = Color(1, 0.35, 0.3), count: int = 10, speed: float = 140.0, size: float = 3.0):
	var scene = get_tree().current_scene
	if scene == null:
		return
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = count
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 220)
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.damping_min = 80.0
	p.damping_max = 140.0
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var ramp = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	ramp.add_point(0.25, color)
	p.color_ramp = ramp
	p.z_index = 20
	p.global_position = pos
	scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# ================= 피격 플래시 =================
# 대상 CanvasItem에 흰색 플래시 머티리얼을 붙임 (없을 때만)
func ensure_flash_material(item: CanvasItem):
	if item.material is ShaderMaterial and item.material.shader == flash_shader:
		return
	if item.material != null:
		return
	var mat = ShaderMaterial.new()
	mat.shader = flash_shader
	item.material = mat

func hit_flash(item: CanvasItem, duration: float = 0.12):
	if item == null or not (item.material is ShaderMaterial):
		return
	var mat: ShaderMaterial = item.material
	if mat.shader != flash_shader:
		return
	mat.set_shader_parameter("flash", 1.0)
	var tween = item.create_tween()
	tween.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, duration)

# 스쿼시 & 스트레치 (피격 시 찌그러짐)
func squash(item: Node2D, base_scale: Vector2, amount: float = 0.25, duration: float = 0.15):
	if item == null:
		return
	item.scale = base_scale * Vector2(1.0 + amount, 1.0 - amount)
	var tween = item.create_tween()
	tween.tween_property(item, "scale", base_scale, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
