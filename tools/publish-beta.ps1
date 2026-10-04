$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$credentialOutput = "protocol=https`nhost=github.com`n`n" | git credential fill
if ($LASTEXITCODE -ne 0) { throw 'Falha na autenticacao do GitHub' }
$passwordLine = $credentialOutput | Where-Object { $_.StartsWith('password=') } | Select-Object -First 1
if (-not $passwordLine) { throw 'Credencial GitHub nao encontrada' }
$githubToken = $passwordLine.Substring(9)
$headers = @{ Authorization = "Bearer $githubToken"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'Chaosbound-Beta-Export' }
$api = 'https://api.github.com/repos/Theuus12/chaosboundprototipe'
$releaseData = @{
    tag_name = 'v0.2.0-beta'
    target_commitish = 'main'
    name = 'Chaosbound Prototype - Beta 0.2.0 (Windows)'
    body = "Beta publica para Windows 64 bits. Baixe o ZIP, extraia e abra Chaosbound-Beta.exe. Nao precisa instalar a Godot.`n`nWASD: andar; mouse: camera; Espaco: pular; Esc: inventario e pausa; Enter: reiniciar apos morrer.`n`nInclui arco, corte e aura, progressao por XP, buffs, raridades, sorte, ima e dificuldade de sobrevivencia. Arte provisoria e balanceamento experimental. Executavel sem assinatura digital. Feedback pode ser enviado nas Issues deste repositorio."
    draft = $true
    prerelease = $true
} | ConvertTo-Json
$release = Invoke-RestMethod -Uri "$api/releases" -Headers $headers -Method Post -Body $releaseData -ContentType 'application/json; charset=utf-8'
$filename = 'Chaosbound-Beta-0.2.0-Windows-x64.zip'
$uploadUri = $release.upload_url.Split('{')[0] + '?name=' + $filename
$asset = Invoke-RestMethod -Uri $uploadUri -Headers $headers -Method Post -InFile (Join-Path $projectRoot "builds/$filename") -ContentType 'application/zip' -TimeoutSec 180
$published = Invoke-RestMethod -Uri "$api/releases/$($release.id)" -Headers $headers -Method Patch -Body '{"draft":false}' -ContentType 'application/json'
[PSCustomObject]@{ Release=$published.html_url; Download=$asset.browser_download_url; Bytes=$asset.size }
