extends RefCounted
## 전투 공통 유틸 : 공격 데이터 기본값 + 2.5D 타격 판정
##
## 좌표계
##   position.x : 가로 위치
##   position.y : 깊이(바닥 라인) — 화면 아래쪽일수록 앞
##   z          : 높이 (0 = 바닥)

const ATTACK_DEFAULTS := {
	"damage"    : 1.0,		# 공격력 배율
	"reach"     : 90.0,		# 판정 앞쪽 끝 (바라보는 방향 기준, px)
	"back"      : 0.0,		# 판정 뒤쪽 끝 (몸 뒤로 얼마나 판정이 있는지, px)
	"depth"     : 36.0,		# 깊이(Y) 판정 반경
	"z_min"     : -10.0,	# 높이 판정 하한 (공격자 z 기준)
	"z_max"     : 110.0,	# 높이 판정 상한 (공격자 z 기준)
	"hitstun"   : 0.35,		# 지상 경직 시간(초)
	"knockback" : 90.0,		# 수평 밀림 속도
	"launch"    : 0.0,		# 띄우기 속도 (0 = 지상 경직)
	"juggle"    : 160.0,	# 공중에 뜬 대상을 다시 띄우는 속도
	"pull"      : -1.0,		# 0 이상이면 대상을 공격자 앞 pull(px) 위치로 끌어옴 (몰이)
	"vacuum"    : -1.0,		# 0 이상이면 대상을 (자기 쪽 그대로) 공격자 몸 vacuum(px) 거리까지 빨아들임
	"align"     : 0.35,		# 타격 시 대상 깊이를 공격자 라인으로 맞추는 비율 (0~1)
	"knockdown" : false,	# 지상 히트여도 넘어뜨림
	"hitstop"   : 0.05,		# 히트스탑(초)
	"shake"     : 2.0,		# 화면 흔들림 세기
	"spark"     : "slash",	# 이펙트 종류 : slash / heavy / blunt
	"sound"     : "",		# 타격음 키 (CombatFX.SOUNDS)
}

## 기본값 위에 params를 덮어쓴 공격 데이터를 만든다
static func attack(params: Dictionary) -> Dictionary:
	var data := ATTACK_DEFAULTS.duplicate()
	data.merge(params, true)
	return data

## attacker의 공격 판정(atk)이 target 몸통과 겹치는지 (x 폭, 깊이, 높이 3축)
static func overlaps(attacker: Node2D, atk: Dictionary, target: Node2D) -> bool:
	# 가로 : 공격자가 바라보는 방향을 + 로 환산
	var dx: float = (target.position.x - attacker.position.x) * attacker.facing
	if dx + target.body_radius < -atk.back or dx - target.body_radius > atk.reach:
		return false
	# 깊이
	if absf(target.position.y - attacker.position.y) > atk.depth + target.depth_radius:
		return false
	# 높이
	var z0: float = attacker.z + atk.z_min
	var z1: float = attacker.z + atk.z_max
	return target.z <= z1 and target.z + target.get_hurt_height() >= z0

## 공격력 * 배율 * 랜덤 편차
static func roll_damage(power: float, atk: Dictionary) -> int:
	return maxi(1, roundi(power * atk.damage * randf_range(0.92, 1.08)))
