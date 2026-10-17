class_name WeaponFx

## 스프라이트 시트 → SpriteFrames 변환 (코드로 이펙트를 만들 때 사용, 결과는 캐시)

static var _frames_cache := {}

# texture_path: 가로로 나열된 시트, frame_size: 한 칸 크기
# anims: {"이름": [시작 인덱스, 개수, fps, loop]}
static func frames(texture_path: String, frame_size: Vector2i, anims: Dictionary) -> SpriteFrames:
	var key = texture_path + str(frame_size) + str(anims)
	if _frames_cache.has(key):
		return _frames_cache[key]
	var tex: Texture2D = load(texture_path)
	var sf = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim_name in anims.keys():
		var a = anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, a[2])
		sf.set_animation_loop(anim_name, a[3])
		for i in range(a[0], a[0] + a[1]):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
			sf.add_frame(anim_name, atlas)
	_frames_cache[key] = sf
	return sf

# 원샷 애니메이션 이펙트 (재생 후 자동 삭제)
static func play_once(parent: Node, sprite_frames: SpriteFrames, anim: String, pos: Vector2, scale: float = 1.0, z: int = 5) -> AnimatedSprite2D:
	var s = AnimatedSprite2D.new()
	s.sprite_frames = sprite_frames
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.global_position = pos
	s.scale = Vector2(scale, scale)
	s.z_index = z
	parent.add_child(s)
	s.play(anim)
	s.animation_finished.connect(s.queue_free)
	return s
