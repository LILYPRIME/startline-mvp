@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\scripts\auto-backup.ps1"

