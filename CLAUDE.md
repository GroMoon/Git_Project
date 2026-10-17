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

## Checks
- Script/import errors: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path SlayerSurvival --editor --quit`
- Smoke test (after Phase 0-2 lands): `/Applications/Godot.app/Contents/MacOS/Godot --headless --path SlayerSurvival res://dev/autoplay.tscn`
