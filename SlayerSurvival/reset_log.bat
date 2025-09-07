@echo off
chcp 65001 >nul
echo === 로그 파일 초기화 시작 ===

echo log.txt 파일 삭제 중...
if exist "log.txt" (
    del "log.txt"
    echo ✓ log.txt 파일이 삭제되었습니다.
) else (
    echo ! log.txt 파일이 존재하지 않습니다.
)

echo === 로그 파일 초기화 완료 ===
pause
