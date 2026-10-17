extends Node2D

class_name WeaponBase

## 자동 무기 공통 처리
## - 플레이어 자식으로 붙지만 top_level 로 동작 (플레이어 스케일 영향 X)
## - 쿨타임마다 fire() 호출, 레벨별 스탯은 UpgradeDB 에서 조회
## - 투사체 등은 world() (게임 루트)에 생성

const ENEMY_MASK = 4		# 적 CharacterBody2D 레이어 (enemy)

var id := ""
var level := 1
var evolved := false				# 진화 여부 (최대 레벨 + 짝 패시브 → 보물상자)
var player: CharacterBase
var cooldown_left := 0.3

func setup(p: CharacterBase, weapon_id: String):
	player = p
	id = weapon_id
	name = "weapon_" + weapon_id
	top_level = true

func set_level(new_level: int):
	level = new_level
	on_level_changed()

# 레벨이 바뀔 때 (하위 클래스에서 구현)
func on_level_changed():
	pass

# 실제 발사 (하위 클래스에서 구현). 발사했으면 true, 대상이 없으면 false
func fire() -> bool:
	return false

func _physics_process(delta):
	if player == null or not is_instance_valid(player):
		return
	global_position = player.global_position
	if player.is_dead:
		return
	cooldown_left -= delta
	if cooldown_left <= 0.0:
		if fire():
			cooldown_left = get_cooldown()
		else:
			cooldown_left = 0.2		# 대상이 없으면 잠시 후 재시도

# ================= 스탯 =================
func stat(key: String, default_value = 0.0):
	return UpgradeDB.stat(id, level, key, default_value, evolved)

# 진화
func evolve():
	evolved = true
	on_level_changed()

func get_cooldown() -> float:
	return max(float(stat("cooldown", 1.0)) * player.get_cooldown_mult(), 0.1)

func get_damage() -> float:
	return float(stat("damage", 1.0)) * player.might

func get_amount() -> int:
	return int(stat("amount", 1)) + player.amount_bonus

func get_area() -> float:
	return float(stat("area", 1.0)) * player.area_mult

# ================= 유틸 =================
# 투사체/이펙트를 놓을 월드 노드 (게임 루트)
func world() -> Node:
	return player.get_parent()

# 적에게 피해 (치명타 판정 + 통계 기록)
# source: 넉백 기준 (Node2D 또는 Vector2 위치, 없으면 플레이어)
func hit(enemy: Node, damage: float = -1.0, knockback_mult: float = 1.0, source = null):
	if enemy == null or not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	if damage < 0.0:
		damage = get_damage()
	var rolled = player.roll_damage(damage)
	enemy.take_damage(rolled[0], source if source != null else player, knockback_mult, rolled[1])
	RunStats.add_damage(id, rolled[0])

# 반경 내 적 전부에게 피해
func hit_radius(center: Vector2, radius: float, damage: float = -1.0, knockback_mult: float = 1.0, source = null) -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if center.distance_to(enemy.global_position) <= radius:
			hit(enemy, damage, knockback_mult, source if source != null else center)
			count += 1
	return count

# 범위 내 적을 가까운 순으로
func enemies_by_distance(max_range: float = 600.0) -> Array:
	var list = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var d = global_position.distance_to(enemy.global_position)
		if d <= max_range:
			list.append([d, enemy])
	list.sort_custom(func(a, b): return a[0] < b[0])
	return list.map(func(x): return x[1])

# 일시정지를 존중하는 대기 (게임 트리 pause 시 같이 멈춤)
func wait(seconds: float):
	await get_tree().create_timer(seconds, false, true).timeout
