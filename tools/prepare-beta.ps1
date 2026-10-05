$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem
$templatesDir = Join-Path $PSScriptRoot 'templates'
New-Item -ItemType Directory -Path $templatesDir -Force | Out-Null
$archive = [System.IO.Compression.ZipFile]::OpenRead((Join-Path $PSScriptRoot 'export-templates.tpz'))
try {
    $entry = $archive.Entries | Where-Object { $_.Name -eq 'windows_release_x86_64.exe' } | Select-Object -First 1
    if (-not $entry) { throw 'Template Windows 64 bits nao encontrado' }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $templatesDir $entry.Name), $true)
} finally { $archive.Dispose() }
$outputDir = Join-Path $projectRoot 'builds/beta'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
& (Join-Path $PSScriptRoot 'godot/Godot_v4.7.2-stable_win64_console.exe') --headless --path $projectRoot --export-release 'Windows Beta' (Join-Path $outputDir 'Chaosbound-Beta.exe')
if ($LASTEXITCODE -ne 0) { throw 'Falha na exportacao' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/BETA_LEIA-ME.txt') -Destination (Join-Path $outputDir 'LEIA-ME.txt')
Compress-Archive -Path (Join-Path $outputDir '*') -DestinationPath (Join-Path $projectRoot 'builds/Chaosbound-Beta-0.3.0-Windows-x64.zip') -Force
Get-ChildItem -LiteralPath $outputDir | Select-Object Name, Length
