# Slayers Survival

Godot 4.7 2D survivor game. Project root: `SlayerSurvival/` (open `SlayerSurvival/project.godot`).

## Ongoing work
- Roguelike overhaul on branch `feature/roguelike-overhaul`. Plan + progress log: `docs/ROGUELIKE_ROADMAP.md`.
  Continue from the first unchecked item, tick it, append a progress-log line, commit.

## Conventions
- GDScript, tabs, Korean comments (match surrounding code).
- Folders are numbered by domain: `dynamic/1_player`, `2_enemy`, `4_world`, `5_title_screen`, `6_utillity`, `7_dialogic`, `8_roguelike` (new systems).
- Main game scene: `res://test.tscn` (`test.gd` handles map/character select and spawns `player`).
- Physics layers: 1 map, 2 player, 3 enemy, 4 attack, 6 collision. Enemies are in group `enemy`; player hitboxes are Area2D in group `attack` whose parent exposes `attack_damage`.
- Pause is driven by flags in `BaseUI.gd` (`lvlup_pause_flag`, `globl_pause_flag`, ...), not by setting `get_tree().paused` directly.

## Roguelike systems (dynamic/8_roguelike)
- `UpgradeDB` (upgrades/upgrade_db.gd): all weapon/passive/evolution data, inline ko/en text.
- `WeaponBase` subclasses in weapons/; player owns them via `CharacterBase.add_upgrade(id)` / `recalc_stats()`.
- Enemies take damage through `take_damage(amount, source, knockback_mult, is_crit)` (EnemyBase and both bosses).
- Wave director: `dynamic/2_enemy/enemy_spawner/enemy_spwaner.gd` (curves, events, elites, boss at 10:00).
- Autoloads added: `GameFeel` (shake/hitstop/particles/flash/synth SFX), `RunStats` (damage per weapon).
- UI: project theme `static/ui/game_theme.tres` (rebuild: `dev/gen_ui_art.py` then `dev/build_theme.gd`), helpers in `dynamic/8_roguelike/ui/game_ui.gd`.
  Pause menu / result screen / settings window / HUD slots are built in code; the old PausePanel/DeathPanel/EndingPanel scenes stay hidden.

## Checks
- Script/import errors: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path SlayerSurvival --editor --quit`
- Smoke test: `SlayerSurvival/dev/run_autoplay.sh -- --char=warrior --seconds=180 --pick=smart` (add `--god=1` for invincible,
  `--give=fireball:3,bomb`, `--start_minute=8`; `--windowed ... --shots=10,20 --shot_dir=DIR` for screenshots; see dev/autoplay.gd header).
  Headless `fps` in the log is simulation speed (>60 means faster than real time).
