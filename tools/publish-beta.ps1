$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$credentialOutput = "protocol=https`nhost=github.com`n`n" | git -c safe.directory='C:/Users/mathe/Desktop/prototipo de jogo' credential fill
if ($LASTEXITCODE -ne 0) { throw 'Falha na autenticacao do GitHub' }
$passwordLine = $credentialOutput | Where-Object { $_.StartsWith('password=') } | Select-Object -First 1
if (-not $passwordLine) { throw 'Credencial GitHub nao encontrada' }
$githubToken = $passwordLine.Substring(9)
$headers = @{ Authorization = "Bearer $githubToken"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'Chaosbound-Beta-Export' }
$api = 'https://api.github.com/repos/Theuus12/chaosboundprototipe'
$releaseData = @{
    tag_name = 'v0.3.0-beta'
    target_commitish = 'main'
    name = 'Chaosbound Prototype - Beta 0.3.0 (Windows)'
    body = "Beta 0.3.0 para Windows 64 bits. Extraia o ZIP e abra Chaosbound-Beta.exe.`n`nMapa 360x360, minimapa, colinas, totens gratuitos com buffs separados dos cristais, escudo e pulos extras. Seis monstros a cada dois segundos, teto de 50 no normal e 100 em hordas. Altar invoca o Rei Ossuario de 50000 HP; sua derrota libera olhos infernais. Goblins ate cinco minutos; depois esqueletos e liches. Arco dispara salvas simultaneas.`n`nWASD: andar; mouse: camera; Espaco: pular; E: interagir; Esc: inventario/pausa. Arte e balanceamento experimentais."
    draft = $true
    prerelease = $true
} | ConvertTo-Json
$release = Invoke-RestMethod -Uri "$api/releases" -Headers $headers -Method Post -Body $releaseData -ContentType 'application/json; charset=utf-8'
$filename = 'Chaosbound-Beta-0.3.0-Windows-x64.zip'
$uploadUri = $release.upload_url.Split('{')[0] + '?name=' + $filename
$asset = Invoke-RestMethod -Uri $uploadUri -Headers $headers -Method Post -InFile (Join-Path $projectRoot "builds/$filename") -ContentType 'application/zip' -TimeoutSec 180
$published = Invoke-RestMethod -Uri "$api/releases/$($release.id)" -Headers $headers -Method Patch -Body '{"draft":false}' -ContentType 'application/json'
[PSCustomObject]@{ Release=$published.html_url; Download=$asset.browser_download_url; Bytes=$asset.size }
