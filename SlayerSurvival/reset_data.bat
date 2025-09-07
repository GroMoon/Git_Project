@echo off
chcp 65001 >nul
echo === JSON 데이터 초기화 시작 ===

echo 상점 데이터 초기화 중...
echo {"STORE_ITEM_HEALTH":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_SHIELD":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_RESPAWN":{"level":"0","max_level":2,"used_gold":0},"STORE_ITEM_DAMAGE":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_SPEED":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_COOLDOWN":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_VAMPIRE":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_GOLD_DROP":{"level":"0","max_level":5,"used_gold":0},"STORE_ITEM_GEM_DROP":{"level":"0","max_level":5,"used_gold":0}} > store_data.json
echo ✓ store_data.json 초기화 완료

echo 플레이어 데이터 초기화 중...
echo {"GOLD":{"gold":0},"CHARACTER_STORE_UPGRADES":{"health":0,"shield":0,"respawn":0,"damage":0,"speed":0,"cooldown":0,"vampire":0,"gold_drop":0,"gem_drop":0}} > player_data.json
echo ✓ player_data.json 초기화 완료

echo === JSON 데이터 초기화 완료 ===
pause
