extends Node

## 한 판(런) 동안의 통계: 무기별 누적 피해 등 (결과 화면용)

var damage_by_source := {}
var run_started_msec := 0

func reset():
	damage_by_source.clear()
	run_started_msec = Time.get_ticks_msec()

func add_damage(source_id: String, amount: float):
	damage_by_source[source_id] = damage_by_source.get(source_id, 0.0) + amount

# 기존 Area2D 공격(고유 무기, 그림자, 펫)의 출처 구분
func source_of(attacker: Node) -> String:
	var n = String(attacker.name)
	if n.begins_with("shadow"):
		return "shadow"
	if n.contains("pet"):
		return "pet"
	return "signature"
