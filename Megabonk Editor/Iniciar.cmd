@echo off
cd /d "%~dp0"
if not exist "MegabonkEditor.exe" (
 "%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /platform:x64 /out:MegabonkEditor.exe /reference:System.Windows.Forms.dll /reference:System.Drawing.dll Editor.cs
 if errorlevel 1 (
  echo Falha ao compilar o editor.
  pause
  exit /b 1
 )
)
start "" "%~dp0MegabonkEditor.exe"
