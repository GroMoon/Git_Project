class_name RunMode

## 게임 모드
## - 클래식: 10분 보스를 잡으면 엔딩 (기존 방식)
## - 무한: 첫 보스까지는 클래식과 같고, 보스를 잡아도 게임이 계속됨
##   첫 보스 처치 후 "한계 돌파" 해금 → 최대 레벨을 넘어 계속 강화 가능
##   10분마다 보스 웨이브 (n번째 웨이브는 보스 n마리, 최대 3마리), 시간이 갈수록 적이 강해짐
## static 변수라 씬을 다시 불러와도(다시 도전) 고른 모드가 유지됨. 판마다 바뀌는 값은 reset_run() 으로 초기화

const CLASSIC = "classic"
const ENDLESS = "endless"

static var mode := CLASSIC
static var waves_cleared := 0		# 이번 판에 처치 완료한 보스 웨이브 수
static var bosses_killed := 0		# 이번 판에 처치한 보스 수

static func is_endless() -> bool:
	return mode == ENDLESS

# 한계 돌파 (최대 레벨 이후 강화): 무한 모드에서 첫 보스 웨이브를 잡은 뒤부터
static func overcap_unlocked() -> bool:
	return is_endless() and waves_cleared > 0

# 현재 단계 (1 = 첫 보스 전)
static func stage() -> int:
	return waves_cleared + 1

static func reset_run():
	waves_cleared = 0
	bosses_killed = 0

static func display_name(mode_id: String = mode) -> String:
	if mode_id == ENDLESS:
		return GameUI.t("무한 모드", "Endless")
	return GameUI.t("클래식 모드", "Classic")
