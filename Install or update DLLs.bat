@echo off
rem Octo DLL Installer (install / update tool): opens its window (installer\OctoDLLInstaller.ps1)
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0installer\OctoDLLInstaller.ps1"
