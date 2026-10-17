#!/bin/bash
# 자동 플레이 스모크 테스트 실행 + 로그 필터링
# 사용법: dev/run_autoplay.sh [--windowed] -- --char=wizard --seconds=120 ...
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
cd "$(dirname "$0")/.." || exit 1
HEADLESS="--headless"
if [ "$1" == "--windowed" ]; then HEADLESS=""; shift; fi
if [ "$1" == "--" ]; then shift; fi
LOG=$(mktemp)
perl -e 'alarm shift; exec @ARGV' ${TIMEOUT:-600} "$GODOT" $HEADLESS --fixed-fps 60 res://dev/autoplay.tscn -- "$@" > "$LOG" 2>&1
grep -E "^\[autoplay\]|SCRIPT ERROR|^ERROR|^\s+at: .*\.gd|GDScript backtrace|^\s+\[[0-9]+\] " "$LOG" \
	| grep -vE "invalid UID|Case mismatch|resource_format_text|_start_game \(res://dev/autoplay.gd|addons/dialogic/Core|subsystem_styles|custom_samplers|resources still in use|backtrace \(most recent call first\):$" \
	| awk '!seen[$0]++' | head -${MAX_LINES:-80}
rm -f "$LOG"
