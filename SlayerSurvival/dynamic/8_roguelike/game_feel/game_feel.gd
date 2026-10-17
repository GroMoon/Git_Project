extends Node

## 손맛(게임 필) 담당 오토로드
## - 화면 흔들림(trauma 방식), 히트스톱, 파티클 버스트, 화면 플래시, 피격 플래시 셰이더
## - 효과음: 코드로 합성한 짧은 효과음 + 동시 재생 제한 (호드 상황에서 소리 폭주 방지)

const MAX_SHAKE_OFFSET = 14.0		# 최대 흔들림(px)
const SHAKE_DECAY      = 2.2		# 초당 trauma 감소량
const HITSTOP_COOLDOWN = 0.12		# 히트스톱 연속 발동 방지(실시간 초)

var flash_shader = preload("res://static/shader/flash.gdshader")
var outline_shader = preload("res://static/shader/red_outline.gdshader")	# 엘리트 빨간 테두리 (flash 지원)

var trauma := 0.0
var shake_time := 0.0
var hitstop_until := 0.0		# 히트스톱 종료 시각(실시간 ms)
var hitstop_ready_at := 0.0		# 다음 히트스톱 가능 시각(실시간 ms)
var flash_layer: CanvasLayer
var flash_rect: ColorRect

const SFX_VOICES = 12
const MIX_RATE   = 22050
const COIN_SOUND = preload("res://static/audio/sfx/button_sounds/store(coin_sound).wav")
const UI_HOVER_SOUND = preload("res://static/audio/sfx/button_sounds/button_sound_1.mp3")

var sfx_streams := {}
var sfx_players: Array = []
var sfx_next_voice := 0
var sfx_last_play := {}			# 이름 -> 마지막 재생 시각(ms)
var pickup_chain := 0			# 연속 획득 시 음이 올라감
var pickup_last_msec := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_sfx()
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
	if not OptionsManager.screen_shake:
		return
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
	if item.material is ShaderMaterial and item.material.shader == outline_shader:
		# 엘리트 테두리 머티리얼은 씬 안에서 공유되므로 개체별로 복제 (한 마리만 번쩍이도록)
		item.material = item.material.duplicate()
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
	if mat.shader != flash_shader and mat.shader != outline_shader:
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

# ================= 효과음 =================
func _init_sfx():
	for i in SFX_VOICES:
		var p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_players.append(p)
	sfx_streams["pickup"]    = _make_wav(_tone(1250.0, 1900.0, 0.07, 0.22, 0.6))
	sfx_streams["hit"]       = _make_wav(_noise(0.035, 0.18, 0.55))
	sfx_streams["explosion"] = _make_wav(_noise(0.4, 0.55, 0.12))
	sfx_streams["levelup"]   = _make_wav(_arpeggio([523.0, 659.0, 784.0, 1046.0], 0.075, 0.25))
	sfx_streams["chest"]     = _make_wav(_arpeggio([784.0, 988.0, 1175.0, 1568.0, 1976.0, 2349.0], 0.06, 0.2))
	sfx_streams["coin"]      = COIN_SOUND
	sfx_streams["ui_hover"]  = UI_HOVER_SOUND
	sfx_streams["ui_click"]  = _make_wav(_tone(900.0, 620.0, 0.05, 0.3, 0.5))
	sfx_streams["ui_open"]   = _make_wav(_noise(0.18, 0.18, 0.08))

# 같은 이름의 효과음은 min_interval 초 안에 한 번만 (호드 상황 보호)
func allow_sfx(sfx_name: String, min_interval: float) -> bool:
	var now = Time.get_ticks_msec()
	if now - sfx_last_play.get(sfx_name, -100000) < int(min_interval * 1000.0):
		return false
	sfx_last_play[sfx_name] = now
	return true

func play_sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0, min_interval: float = 0.04):
	if not sfx_streams.has(sfx_name) or not allow_sfx(sfx_name, min_interval):
		return
	var p: AudioStreamPlayer = sfx_players[sfx_next_voice]
	sfx_next_voice = (sfx_next_voice + 1) % sfx_players.size()
	p.stream = sfx_streams[sfx_name]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

# 경험치 획득음: 연달아 먹으면 음이 점점 올라감
func play_pickup():
	var now = Time.get_ticks_msec()
	pickup_chain = mini(pickup_chain + 1, 16) if now - pickup_last_msec < 350 else 0
	pickup_last_msec = now
	play_sfx("pickup", pow(2.0, pickup_chain / 24.0), -6.0, 0.03)

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 32767.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.data = data
	return w

# 주파수가 미끄러지는 사각파+사인파 (square_mix: 사각파 비율)
func _tone(f_from: float, f_to: float, duration: float, volume: float, square_mix: float) -> PackedFloat32Array:
	var n = int(duration * MIX_RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var phase = 0.0
	for i in n:
		var t = float(i) / n
		phase += lerp(f_from, f_to, t) / MIX_RATE
		var sine = sin(phase * TAU)
		var square = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		var env = (1.0 - t) * (1.0 - t)
		out[i] = (sine * (1.0 - square_mix) + square * square_mix) * env * volume
	return out

# 감쇠하는 노이즈 (smooth: 0~1, 낮을수록 묵직한 소리)
func _noise(duration: float, volume: float, smooth: float) -> PackedFloat32Array:
	var n = int(duration * MIX_RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var y = 0.0
	for i in n:
		var t = float(i) / n
		y += smooth * (randf_range(-1.0, 1.0) - y)
		out[i] = clamp(y * 2.5, -1.0, 1.0) * pow(1.0 - t, 2.5) * volume
	return out

func _arpeggio(freqs: Array, note_time: float, volume: float) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	for f in freqs:
		out.append_array(_tone(f, f * 1.01, note_time, volume, 0.5))
	out.append_array(_tone(freqs[-1], freqs[-1], note_time * 3.0, volume * 0.8, 0.35))
	return out
