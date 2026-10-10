@echo off
title Cap nhat DiaChinhVL
rem Cap nhat DiaChinhVL tu GitHub (thay nguyen file DiaChinhVL.mvba)
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CapNhat_DiaChinhVL.ps1"
