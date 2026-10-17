extends Area2D

class_name PickupBase

## 드롭 아이템 공통 처리 (경험치, 골드, 음식)
## - 드롭 시 살짝 튀어나옴
## - 자석 범위에 들어오면 잠깐 밀려났다가 가속하며 빨려 들어감

const START_SPEED = -160.0		# 흡입 시작 속도 (음수 = 살짝 반대로 튕김)
const ACCEL       = 1700.0		# 흡입 가속도 (px/s^2)

var player
var target = null
var speed  = START_SPEED
var popping = false
var collected = false

func _ready():
	player = get_parent().get_parent().get_node("player")
	_pop()

func _physics_process(delta):
	if target != null and not popping and not collected:
		if not is_instance_valid(target):
			target = null
			return
		speed += ACCEL * delta
		global_position = global_position.move_toward(target.global_position, speed * delta)

# 드롭 시 튀어나오는 연출
func _pop():
	popping = true
	var dest = global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(8.0, 26.0)
	var tween = create_tween()
	tween.tween_property(self, "global_position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var base_y = sprite.position.y
		var hop = create_tween()
		hop.tween_property(sprite, "position:y", base_y - 12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_property(sprite, "position:y", base_y, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): popping = false)

# 자석/흡입 시작 (자석 픽업 등에서 호출)
func attract(new_target: Node2D):
	if target == null:
		target = new_target
		speed = START_SPEED

# 획득 처리 (하위 클래스에서 on_collect 구현)
func _on_body_entered(_body):
	if collected:
		return
	collected = true
	on_collect()
	queue_free()

func on_collect():
	pass
