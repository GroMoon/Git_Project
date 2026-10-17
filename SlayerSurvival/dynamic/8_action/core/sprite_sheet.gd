extends RefCounted
## 스프라이트 시트를 잘라 SpriteFrames를 만든다 (같은 key는 한 번만 생성해 공유)
##
## defs = {
##   "idle": {"path": "res://...png", "frame_width": 162, "fps": 10.0, "loop": true},
##   # 격자형 시트 : "frame_height", "row", "start", "count" 또는 "cells": [[row, col], ...] 지정 가능
##
## 셀 목록 헬퍼 : cells_range(2, 0, 9, 8) → 2행 0열부터 9칸 (8열마다 다음 줄로)
static func cells_range(row: int, col: int, count: int, columns: int) -> Array:
	var cells := []
	for i in count:
		var index := row * columns + col + i
		cells.append([index / columns, index % columns])
	return cells
## }

static var _cache := {}

static func build(key: String, defs: Dictionary) -> SpriteFrames:
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in defs:
		var def: Dictionary = defs[anim_name]
		var texture: Texture2D = load(def["path"])
		var frame_h: int = def.get("frame_height", texture.get_height())
		var frame_w: int = def.get("frame_width", frame_h)
		var row: int = def.get("row", 0)
		var start: int = def.get("start", 0)
		var count: int = def.get("count", texture.get_width() / frame_w - start)
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def.get("fps", 10.0))
		frames.set_animation_loop(anim_name, def.get("loop", true))
		# "cells" : [[row, col], ...] 로 격자 시트의 칸을 직접 지정 (여러 줄에 걸친 애니메이션)
		var cells: Array = def.get("cells", [])
		if cells.is_empty():
			for i in count:
				cells.append([row, start + i])
		for cell in cells:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(cell[1] * frame_w, cell[0] * frame_h, frame_w, frame_h)
			frames.add_frame(anim_name, atlas)
	_cache[key] = frames
	return frames

static func clear_cache():
	_cache.clear()
