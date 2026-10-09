@echo off
rem ============================================================
rem  PHAT_HANH.bat - day ban moi len GitHub (can cai Git for Windows)
rem  Lan dau: git se hoi dang nhap GitHub (cua so trinh duyet).
rem ============================================================
cd /d "%~dp0"
if not exist ".git" (
  git init -q
  git branch -M main
  git remote add origin https://github.com/lehoangtuat/DiaChinhVL.git
  git pull -q origin main --allow-unrelated-histories
)
set /p PB=<version.txt
echo Phat hanh phien ban: %PB%
git add -A
git commit -q -m "Phien ban %PB%"
git push -u origin main
echo.
echo XONG. Nguoi dung vao Tro giup - Kiem tra cap nhat de nhan ban %PB%.
pause
