@echo off
REM Double-click to publish or update the website on GitHub Pages.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
pause
