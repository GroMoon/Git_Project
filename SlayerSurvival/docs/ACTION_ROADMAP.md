# Slayers Survival → 횡스크롤 액션 개편 로드맵

> 던전앤파이터(DnF)를 모티브로 한 2D 벨트스크롤 액션으로 디벨롭한다.
> **다음 세션에서 이어서 작업할 때는 이 문서의 「현재 진행 상황」부터 확인한다.**

## 목표

- 캐릭터를 **직접 조작**한다 (자동 공격 → 키 입력 공격)
- **기본 공격 콤보**를 이어가는 손맛: 입력 버퍼, 캔슬, 전진 스텝
- **적을 몰아잡는** 쾌감: 회전 베기로 뒤쪽 적 끌어오기, 타격 시 Y축(깊이) 정렬, 띄우기 → 공중 콤보
- **시원한 타격감**: 히트스탑, 화면 흔들림, 히트 플래시, 슬래시 이펙트, 데미지 숫자, 콤보 카운터

노션 컨셉(던전에 갇힘 → 몬스터 처치 → 몬스터가 동료(펫)가 됨 → 보스 → 던전 방 탈출)은 유지하고,
던파식 **방(Room) 단위 던전 진행**으로 재해석한다.

## 핵심 설계 결정

| 항목 | 결정 | 이유 |
|---|---|---|
| 좌표계 | 2.5D: `position` = 바닥 위치(x, 깊이 y), `z` = 높이 | 던파식 라인 이동 + 점프/띄우기 |
| 이동/충돌 | 물리 바디 없이 직접 이동 + 방 경계 클램프, 적끼리 겹침 허용 | 몰아잡기에 유리, 결정적인 판정 |
| 타격 판정 | 코드 기반 3D 박스(x 폭, 깊이, 높이) 판정 | Area2D로는 높이(z) 판정 불가 |
| 애니메이션 | 기존 스프라이트 시트를 코드로 잘라 `SpriteFrames` 생성 | 에디터 없이 데이터로 프레임/타격 타이밍 관리 |
| 히트스탑 | `Engine.time_scale` 순간 저하 (실시간 타이머로 복구) | 단일 플레이어 게임에서 가장 단순하고 확실한 손맛 |
| 기존 서바이벌 모드 | 삭제하지 않고 유지, 신규 모드는 `dynamic/8_action/`에 분리 | 단계적 전환, 회귀 위험 최소화 |
| 엔진 버전 | Godot **4.2.1** 문법 유지 (프로젝트 기준 버전) | 팀 에디터 버전과 호환 |

## 조작 (던파 기본 키 배치)

| 키 | 동작 |
|---|---|
| ← → ↑ ↓ | 이동 (↑↓ = 깊이 이동) |
| ←← / →→ (빠르게 두 번) | 대시 |
| X | 기본 공격 (연타 시 3타 콤보) / 대시 중 X = 대시 공격 / 공중 X = 점프 공격 |
| C | 점프 |
| Z | 백스텝 (Phase 3에서 스킬화 예정) |
| A S D F | 스킬 (Phase 3) |
| F1 | 테스트 룸: 적 다시 소환 |
| ESC | 메뉴로 |

## 폴더 구조 (신규)

```
dynamic/8_action/
  core/    actor.gd(2.5D 액터 베이스), attack_data.gd, combat_fx.gd(히트스탑/쉐이크/이펙트),
           action_input.gd(키 등록), sprite_sheet.gd(시트→SpriteFrames), hit_spark.gd, damage_number.gd
  player/  action_player.gd(조작/콤보 상태머신), warrior_action.gd(전사 데이터)
  enemy/   action_enemy.gd(피격 리액션/AI), enemy_defs.gd(몬스터별 데이터)
  stage/   action_stage.gd/.tscn(방, 카메라, 스폰), dungeon_backdrop.gd(던전 배경)
  ui/      action_hud.gd(HP, 콤보 카운터, 조작 안내)
```

## 단계별 계획 (체감 큰 순서)

### Phase 1 — 전투 코어: 직접 조작 + 콤보 + 타격감 ⭐ 최우선
- [x] 1-1 2.5D 액터 베이스 (바닥 위치 + 높이 z, 그림자, Y-정렬, 방향 전환)
- [x] 1-2 플레이어 조작: 8방향 이동, 점프, 대시(→→), 백스텝(Z)
- [x] 1-3 기본 공격 3타 콤보(X-X-X) — 입력 버퍼, 캔슬 프레임, 전진 스텝, 콤보 단계마다 방향 전환
- [x] 1-4 점프 공격, 대시 공격
- [x] 1-5 3D 박스 타격 판정 (스윙당 1회 판정, 다단히트)
- [x] 1-6 타격감: 히트스탑, 카메라 쉐이크, 히트 플래시/흔들림, 슬래시 스파크, 데미지 숫자, 합성 타격음
- [x] 1-7 적 피격 리액션: 경직, 넉백, 띄우기/공중 콤보(저글 감쇠), 다운/바운드/기상, Y축 정렬(몰이), 회전베기 끌어오기
- [x] 1-8 테스트 룸: 던전 배경 + 적 무리 배치 + 콤보 카운터 HUD, 메뉴 START → 액션 모드 연결

> Phase 1 검증 (헤드리스 자동 테스트, Godot 4.2.1): 3타 콤보 체인 / 18히트 콤보 / 히트스탑 동작,
> 흩어진 적 3마리가 회전베기 후 x≈970·깊이≈520 한 곳으로 모임(몰이), 띄운 적이 z≈180에서 저글 유지,
> 점프 공격·대시 공격·백스텝·적 공격(플레이어 피격) 정상.
> ⚠️ 실제 화면 플레이 확인(손맛 수치 튜닝)은 아직 — 수치는 `warrior_action.gd`의 moves에서 조정.

### Phase 2 — 적 AI & 전투 루프
- [x] 적 접근/라인 맞추기, 공격 예고(붉은 플래시) → 공격 판정, 거리별 공격 선택
- [x] 동시 공격 인원 제한(공격 토큰), 토큰 없는 적은 주변 대기 → 포위
- [x] 플레이어 피격 리액션 / 무적 시간 / 사망 / 게임오버(R 재시작)
- [x] 몬스터별 개성: 고블린(공중제비 돌진), 스켈레톤(방패 가드 → 강공격으로 가드 브레이크), 머쉬룸(포자 투사체, 거리 유지), 플라잉아이(호버링·급강하, 맞으면 추락)
- [x] 엘리트 몬스터: 크기/체력 강화, 슈퍼아머 → ARMOR BREAK, 5줄 HP 바, 엘리트 머쉬룸 포자 폭발
- [x] 던파식 판정 보너스: COUNTER!(공격 준비 중 타격 ×1.25), BACK ATTACK(등 뒤 ×1.1)
- [x] 상단 몬스터 HP 바(이름, 줄 수, 슈퍼아머 테두리), 웨이브 3종 순환(WAVE CLEAR → 다음 웨이브)
- [x] 헤드리스 스모크 테스트 `dynamic/8_action/tests/combat_smoke_test.gd` (12/12 PASS)

### Phase 3 — 스킬 시스템 (A/S/D/F)
- [x] 스킬 프레임워크 + 쿨타임 + MP(자연 회복), 스킬 슬롯 HUD(아이콘/쿨타임/MP 부족 표시)
- [x] 전사 스킬: A 어퍼 슬래시(띄우기) / S 회오리 베기(빨아들이기 몰이 + 슈퍼아머 + 이동 가능) /
      D 섬광 돌진(무적 돌진, 잔상, 경로상 적 끌고 가기) / F 파멸의 일격(화면 암전→백색 섬광, 줌, 3단 충격파)
- [x] 스킬 캔슬(평타 타격 프레임부터 → 스킬), 백스텝(Z), 스킬 선입력
- [x] 기술 데이터 확장: `frames`(시트 프레임 반복), `events`(flash/shockwave/zoom/shake/banner/whirl), `vacuum`
- [x] 스모크 테스트 23/23 PASS (회오리 베기 평균 거리 295→44px)

### Phase 4 — 던전 구조 & 보스
- [x] 방(Room) 단위 진행: 방마다 웨이브 2개 → ROOM CLEAR → 포털 개방(GO ▶) → 페이드 전환 → 다음 방
      (던전 구성은 `stage/dungeon_data.gd` — 묘지 입구 / 뼈의 회랑 / 포자의 굴 / 죽음의 제단(보스))
- [x] 미니맵(현재/클리어/보스방 표시), 방 이름 배너
- [x] 보스 Bringer of Death: 낫 휘두르기(바닥 위험 범위 예고) / 주문(발밑 어둠의 손, 예고 원) /
      2페이즈(HP 50%↓) 분노 — 빨라짐, 주문 3곳, 사라졌다 등 뒤에서 나타나 베기. 상시 슈퍼아머(25), x20 HP 바
- [x] 보스 처치 연출: 슬로우 모션 + 백색 섬광 + 강한 흔들림
- [x] 결과창: 클리어 타임 / 최대 콤보 / 총 타격 / 처치 수 / 피격 횟수 / 골드, 랭크(SSS~F) 도장 연출,
      골드는 랭크 보너스 적용 후 `Global.character_data["GOLD"]`에 저장 (상점에서 사용)
- [x] 디버그 키: F1 현재 웨이브 재소환, F2 다음 방으로
- [x] 스모크 테스트 32/32 PASS

### Phase 5 — 기존 시스템 연동
- [ ] 캐릭터 선택: Medieval King, Wizard 이식 (Wizard는 원거리 마법) ← **작업 중 (아래 「다음 세션 할 일」 참고)**
  - [x] `player/action_player.gd` : `deal_hits(source, atk, log)` 공개 함수 + 기술 `spawns` 훅(`_on_spawn`) 추가
  - [x] `player/king_action.gd` 작성 완료 (콤보/대시/점프공격 + 스킬 4종, 파싱 확인) — 아직 스테이지에 연결 안 됨
  - [x] `player/magic.gd` 작성 완료 (Bolt / Vortex / LightningStrike / Meteor, 파싱 확인) — 아직 사용처 없음
  - [ ] `player/wizard_action.gd` 작성 (아래 설계)
  - [ ] 캐릭터 선택 화면 + 메뉴 START 연결
- [x] 상점 업그레이드 연동 (`Global.character_data["CHARACTER_STORE_UPGRADES"]` → `apply_store_upgrades()`)
      health→최대HP(+1000/레벨), damage→공격력(+4%/레벨), speed→이속, cooldown→스킬 쿨타임,
      shield→피해 감소, vampire→흡혈, respawn→부활(REVIVE! 충격파), gold_drop→골드 보너스, gem_drop→MP 회복
- [x] 노션 컨셉: 몬스터 동료 — 처치한 몬스터가 확률(일반 12%/엘리트 40%)로 동료가 됨 (종류별 1, 최대 4),
      플레이어 뒤를 따라다니며 근처 적 공격(머쉬룸 동료는 포자 발사), 방 이동 시 함께 이동 (`enemy/ally_monster.gd`)
- [ ] 레벨업/성장 요소

### Phase 6 — 폴리싱
- [ ] 효과음/BGM 정리, 타격음 다양화
- [ ] 게임패드 지원, 키 설정 옵션
- [ ] 밸런스 조정, 구 서바이벌 코드 정리 여부 결정

## 현재 진행 상황

- 브랜치: `feature/action-combat` (기준: `test2`)
- **Phase 1~4 완료, Phase 5 진행 중 (상점 연동·몬스터 동료 완료 / 캐릭터 추가 작업 중)**
- 마지막 확인: 스모크 테스트 35/35 PASS (2026-10-17)

### 다음 세션 할 일 (순서대로)

1. **`player/wizard_action.gd` 작성** — `warrior_action.gd`/`king_action.gd`와 같은 형식, `_on_spawn(spawn)` 재정의
   - 시트: `Wizard/Sprites/` 231x190, 발 y=141 · 몸 중심 x≈110 → `sprite_offset (5, -46)`, `sprite_scale 1.3`
   - 애니: idle(Idle 6) run(Run 8) attack_1(Attack1 8: 지팡이 위 구체 폭발) attack_2(Attack2 8: 전방 발사)
     jump(Jump 2) fall(Fall 2) take_hit(Hit 4) death(Death 7)
   - 수치: max_hp 24000, attack_power 1150, max_mp 1400, mp_regen 55
   - X 콤보: atk1·atk2 = attack_2 프레임 [1..6], move frame 4에서 `Bolt` 발사 / atk3 = attack_1 구체 폭발(back -40, reach 200, launch 600)
   - 스킬: A 체인 라이트닝(가까운 적 3명에 `LightningStrike`, 아이콘 (4,10)) / S 그라비티 홀(전방 260px `Vortex`, vacuum 10, 아이콘 (8,8)) /
     D 블링크(steps 2400px/s 0.12s + invuln + afterimage, 도착 지점 폭발, 아이콘 (9,10)) / F 메테오 스톰(`Meteor` 6개, delay 차등, 아이콘 (11,8))
2. `core/combat_fx.gd`의 `SWING_SOUNDS`에 `king_1~3`(static/audio/sfx/weapon/king/), `wizard_1` 추가
3. **캐릭터 선택 화면** `ui/character_select.gd` + `stage/character_select.tscn`
   - 초상화: `dynamic/1_player/selcet_character/character_img/*.webp`, ←→ 선택, X/Enter 시작, ESC 메뉴
   - `action_stage.gd`에 `static var selected_character := "warrior"` 추가 → `_ready()`에서 Warrior/King/Wizard 중 생성
   - `menu.gd`의 START → 캐릭터 선택 화면으로
4. 스모크 테스트에 King/Wizard 항목 추가 (콤보 체인, 그라비티 홀 몰이, 볼트 적중)
5. 이후 Phase 5 레벨업/성장, Phase 6 폴리싱

### 다음 세션 시작 방법
- 이 문서 확인 → `git checkout feature/action-combat` → 스모크 테스트 실행으로 상태 확인:
  `Godot_v4.2.1-stable_win64_console.exe --headless --path . --script res://dynamic/8_action/tests/combat_smoke_test.gd`
- 변경 사항은 아직 커밋하지 않음 (`docs/`, `dynamic/8_action/`, `dynamic/5_title_screen/menu.gd`)
- 실행: 타이틀 메뉴 START 또는 `dynamic/8_action/stage/action_stage.tscn` 직접 실행 (F6)
- 테스트: 헤드리스 테스트 스크립트 예시는 작업 로그 참고 (`--headless --script`로 입력 시뮬레이션)

## 작업 로그

- 2026-10-17: 코드/노션 분석, 로드맵 작성, Phase 1 착수
- 2026-10-17: Phase 1 완료 — 2.5D 액터, 조작, 3타 콤보, 타격감, 피격 리액션, 테스트 룸, 메뉴 연결
- 2026-10-17: Phase 2 완료 — 몬스터 개성/엘리트/가드/카운터/포위 AI/몬스터 HP 바/웨이브, 스모크 테스트 추가
- 2026-10-17: Phase 3 완료 — 스킬 4종 + MP/쿨타임 + 스킬 HUD, 연출 이펙트(잔상/회오리/충격파/화면 섬광/줌)
- 2026-10-17: Phase 4 완료 — 4개 방 던전, 포털/미니맵/페이드, 보스 3패턴+2페이즈, 결과창/랭크/골드 저장
- 2026-10-17: Phase 5 일부 — 상점 업그레이드 연동, 몬스터 동료, King 데이터·마법 오브젝트 작성 (세션 종료, 사용량 한도)
