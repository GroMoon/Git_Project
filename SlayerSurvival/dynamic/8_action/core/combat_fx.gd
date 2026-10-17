extends Node2D
## 전투 연출 담당 (스테이지에 1개)
##   히트스탑, 화면 흔들림, 타격 스파크, 데미지 숫자, 콤보 카운트, 타격음
## 액터들은 group "combat_fx" 로 찾아서 사용한다.

signal combo_changed(count: int)

const HitSpark     = preload("res://dynamic/8_action/core/hit_spark.gd")
const DamageNumber = preload("res://dynamic/8_action/core/damage_number.gd")
const SkillEffects = preload("res://dynamic/8_action/core/skill_effects.gd")

const COMBO_WINDOW := 1.6	# 이 시간 안에 다음 타격이 없으면 콤보 종료
const HITSTOP_SCALE := 0.03	# 히트스탑 중 시간 배율

const SWING_SOUNDS := {
	"warrior_1": preload("res://static/audio/sfx/weapon/warrior/warrior_1.mp3"),
	"warrior_2": preload("res://static/audio/sfx/weapon/warrior/warrior_2.mp3"),
	"warrior_3": preload("res://static/audio/sfx/weapon/warrior/warrior_3.mp3"),
	"king_1"   : preload("res://static/audio/sfx/weapon/king/king_1.mp3"),
	"king_2"   : preload("res://static/audio/sfx/weapon/king/king_2.mp3"),
	"king_3"   : preload("res://static/audio/sfx/weapon/king/king_3.mp3"),
	"wizard_1" : preload("res://static/audio/sfx/weapon/wizard/wizard_1.mp3"),
}

var camera: Camera2D

var combo     := 0
var max_combo := 0
var total_hits := 0
var _combo_timer := 0.0

var _hitstop_until := 0
var _slowmo_until := 0
var _slowmo_scale := 1.0
var _shake := 0.0
var _last_ticks := 0
var _hit_sounds := {}
var _whoosh : AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _screen_flash : ColorRect
var _zoom_tween : Tween

func _ready():
	add_to_group("combat_fx")
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50
	_last_ticks = Time.get_ticks_msec()
	# 타격음은 코드로 합성 (짧고 묵직한 노이즈 + 저음)
	_hit_sounds = {
		"slash" : synth_hit(0.13, 260.0, 0.75, 32.0),
		"heavy" : synth_hit(0.30, 85.0, 0.55, 13.0),
		"blunt" : synth_hit(0.12, 150.0, 0.45, 28.0),
	}
	_whoosh = synth_whoosh(0.24)
	for i in 10:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	# 화면 번쩍임용 레이어 (HUD 아래)
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 5
	add_child(flash_layer)
	_screen_flash = SkillEffects.ScreenFlash.new()
	_screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash.visible = false
	flash_layer.add_child(_screen_flash)

func _exit_tree():
	Engine.time_scale = 1.0

func _process(delta):
	var now := Time.get_ticks_msec()
	var real_dt := (now - _last_ticks) / 1000.0
	_last_ticks = now
	# 히트스탑 / 슬로우 모션 해제 (실시간 기준)
	if _hitstop_until > 0 and now >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = _slowmo_scale if _slowmo_until > now else 1.0
	if _slowmo_until > 0 and now >= _slowmo_until:
		_slowmo_until = 0
		_slowmo_scale = 1.0
		if _hitstop_until == 0:
			Engine.time_scale = 1.0
	# 화면 흔들림 (실시간 기준 → 히트스탑 중에도 흔들림)
	if camera:
		if _shake > 0.05:
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-0.7, 0.7)) * _shake
			_shake = move_toward(_shake, 0.0, real_dt * maxf(18.0, _shake * 9.0))
		else:
			_shake = 0.0
			camera.offset = Vector2.ZERO
	# 콤보 타이머 (게임 시간 기준)
	if combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(0)

## 순간 정지. 겹치면 더 긴 쪽으로
func hitstop(duration: float):
	if duration <= 0.0:
		return
	var until := Time.get_ticks_msec() + int(duration * 1000.0)
	_hitstop_until = maxi(_hitstop_until, until)
	Engine.time_scale = HITSTOP_SCALE

## 슬로우 모션 (보스 처치 등) : 실시간 duration 동안 time_scale 유지
func slow_motion(time_scale: float, duration: float):
	_slowmo_scale = time_scale
	_slowmo_until = Time.get_ticks_msec() + int(duration * 1000.0)
	if _hitstop_until == 0:
		Engine.time_scale = time_scale

func shake(strength: float):
	_shake = maxf(_shake, strength)

## 공격 1회(판정 1개)가 적중했을 때 : 대상 수에 따라 히트스탑을 조금 늘린다
func on_attack_landed(atk: Dictionary, target_count: int):
	hitstop(atk.hitstop + minf(0.03, 0.006 * (target_count - 1)))
	shake(atk.shake + minf(4.0, 0.5 * (target_count - 1)))
	play_hit_sound(atk.spark)

func play_hit_sound(kind: String):
	play_sound(_hit_sounds.get(kind, _hit_sounds["slash"]), 0.12, -2.0)

func add_combo(count := 1):
	combo += count
	total_hits += count
	max_combo = maxi(max_combo, combo)
	_combo_timer = COMBO_WINDOW
	combo_changed.emit(combo)

func reset_combo():
	if combo > 0:
		combo = 0
		combo_changed.emit(0)

func spawn_spark(pos: Vector2, kind := "slash", dir := 1, color := Color(1.0, 0.9, 0.55)):
	var spark := HitSpark.new()
	spark.kind = kind
	spark.dir = dir
	spark.color = color
	spark.position = pos
	add_child(spark)

func spawn_damage(value: int, pos: Vector2, style := "normal"):
	var number := DamageNumber.new()
	number.value = value
	number.position = pos + Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
	match style:
		"critical":
			number.color = Color(1.0, 0.55, 0.15)
			number.font_size = 34
		"player":
			number.color = Color(1.0, 0.25, 0.2)
			number.font_size = 24
		_:
			number.color = Color(1.0, 0.93, 0.5)
	add_child(number)

## 판정 텍스트 (COUNTER!, BACK ATTACK, GUARD, ARMOR BREAK 등)
func spawn_text(text: String, pos: Vector2, color := Color(1.0, 0.75, 0.2), font_size := 22):
	var label := DamageNumber.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.position = pos
	add_child(label)

## 잔상 : sprite(AnimatedSprite2D)의 현재 프레임을 복사
func spawn_afterimage(sprite: AnimatedSprite2D, color := Color(0.4, 0.8, 1.0)):
	var ghost := SkillEffects.Afterimage.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.offset = sprite.offset
	ghost.self_modulate = color
	ghost.z_index = -48		# 액터들 바로 위 (FX 기준 상대값)
	add_child(ghost)
	ghost.global_transform = sprite.global_transform

func spawn_whirl(target: Node2D, duration: float, radius := 130.0):
	var whirl := SkillEffects.Whirl.new()
	whirl.target = target
	whirl.life = duration
	whirl.radius = radius
	add_child(whirl)

func spawn_shockwave(ground_pos: Vector2, radius := 280.0, color := Color(1.0, 0.7, 0.35)):
	var wave := SkillEffects.Shockwave.new()
	wave.position = ground_pos
	wave.radius = radius
	wave.color = color
	add_child(wave)

## 바닥 위험 범위 (월드 좌표 rect = x범위 × 깊이범위)
func spawn_telegraph(rect: Rect2, duration: float, ellipse := false):
	var zone := SkillEffects.Telegraph.new()
	zone.rect = rect
	zone.life = maxf(0.1, duration)
	zone.ellipse = ellipse
	zone.z_index = -55		# 바닥 바로 위 (그림자/액터 아래)
	add_child(zone)

func flash_screen(color := Color(1, 1, 1, 0.7), duration := 0.18):
	_screen_flash.start(color, duration)

## 카메라 순간 확대 (필살기 임팩트)
func zoom_punch(amount := 0.12, duration := 0.35):
	if camera == null:
		return
	if _zoom_tween:
		_zoom_tween.kill()
	camera.zoom = Vector2.ONE * (1.0 + amount)
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(camera, "zoom", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## 대시/백스텝/스킬 시전 바람 소리
func play_whoosh(volume_db := -9.0):
	play_sound(_whoosh, 0.12, volume_db)

func play_swing(key: String):
	if SWING_SOUNDS.has(key):
		play_sound(SWING_SOUNDS[key], 0.06, -4.0)

func play_sound(stream: AudioStream, pitch_jitter := 0.0, volume_db := 0.0):
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()

## 바람 가르는 소리 합성 : 컷오프가 올라갔다 내려가는 로우패스 노이즈, 사인 엔벨로프
static func synth_whoosh(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var low := 0.0
	for i in sample_count:
		var p := float(i) / sample_count
		var cutoff := 0.04 + 0.35 * sin(p * PI)
		low = lerpf(low, randf_range(-1.0, 1.0), cutoff)
		var sample := low * sin(p * PI) * 1.4
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 26000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

## 짧은 타격음 합성 : 저음(피치 하강) + 로우패스 노이즈, 지수 감쇠
static func synth_hit(duration: float, base_freq: float, noise_amount: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	var noise_lp := 0.0
	for i in sample_count:
		var t := float(i) / rate
		var envelope := exp(-t * decay) * minf(1.0, t * 800.0)
		var freq := base_freq * (1.0 - 0.55 * t / duration)
		phase += TAU * freq / rate
		noise_lp = lerpf(noise_lp, randf_range(-1.0, 1.0), 0.45)
		var sample := (sin(phase) * (1.0 - noise_amount) + noise_lp * noise_amount * 1.6) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
