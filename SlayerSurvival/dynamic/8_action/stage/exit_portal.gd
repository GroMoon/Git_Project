extends Node2D
## 다음 방으로 가는 포털 (기존 portal 시트 재사용, 배경이 검은색이라 가산 합성)
## 방을 클리어하면 열리고, 플레이어가 가까이 오면 stage가 다음 방으로 넘긴다.

const SpriteSheet = preload("res://dynamic/8_action/core/sprite_sheet.gd")
const SHEET := "res://dynamic/4_world/portal/protal.PNG"

var is_open := false
var _sprite : AnimatedSprite2D
var _t := 0.0

func _ready():
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteSheet.build("exit_portal", {"idle": {
		"path": SHEET, "frame_width": 325, "frame_height": 325, "fps": 10.0, "loop": true,
		"cells": [[0, 0], [0, 1], [0, 2], [1, 2], [1, 1], [1, 0], [2, 0], [2, 1], [2, 2]]}})
	_sprite.offset = Vector2(0, -108)		# 받침대 바닥이 원점
	_sprite.scale = Vector2(0.6, 0.6)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sprite.material = additive
	_sprite.play("idle")
	add_child(_sprite)
	set_open(false)

func set_open(value: bool):
	is_open = value
	visible = value
	if value:
		scale = Vector2(0.2, 0.2)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta):
	_t += delta
	if is_open:
		_sprite.modulate = Color(1, 1, 1, 0.85 + 0.15 * sin(_t * 4.0))

## 플레이어가 포털 앞에 섰는지
func is_player_inside(player: Node2D) -> bool:
	return is_open and absf(player.position.x - position.x) < 70.0 and absf(player.position.y - position.y) < 60.0
