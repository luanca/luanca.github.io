<#
  Install-SMXVpn.ps1
  Bootstrap para rodar em terminal remoto (PowerShell como administrador).
  Baixa o SMX-VPN-GPO.ps1 e a chave, e executa o script com -Install.

  Exemplos:
    .\Install-SMXVpn.ps1 -RunNow
    .\Install-SMXVpn.ps1 -Key 'BASE64DA-CHAVE' -RunNow      # chave informada na hora (não baixada)
    .\Install-SMXVpn.ps1 -ScriptSha256 'HASH' -RunNow        # só instala se o hash do script conferir
#>
param(
    [string]$Key,                 # conteúdo (Base64) do vpn.key; se informado, NÃO baixa a chave
    [string]$ScriptSha256,        # hash SHA-256 esperado do SMX-VPN-GPO.ps1 (recomendado)
    [switch]$RunNow               # inicia a tarefa logo após instalar
)

# ====== AJUSTE AQUI ======
$BaseUrl   = 'https://luanca.github.io/externa/smx/vpn'
$ScriptUrl = "$BaseUrl/SMX-VPN-GPO.ps1"
$KeyUrl    = "$BaseUrl/vpn.key"
$TaskName  = 'SMX VPN Auto'
# =========================

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Precisa de administrador (cria tarefa como SYSTEM e grava em ProgramData)
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Execute este script em um PowerShell como Administrador.'
}

$InstallDir = Join-Path $env:ProgramData 'SMX-VPN'
$ScriptPath = Join-Path $InstallDir 'SMX-VPN-GPO.ps1'
$KeyPath    = Join-Path $InstallDir 'vpn.key'
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

function Get-Bytes([string]$Url) {
    $wc = New-Object Net.WebClient
    $wc.Headers.Add('Cache-Control', 'no-cache')
    $nocache = "?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    return $wc.DownloadData($Url + $nocache)
}

# 1) Script principal
Write-Host "Baixando $ScriptUrl ..."
$scriptBytes = Get-Bytes $ScriptUrl
$hash = [BitConverter]::ToString(
    [Security.Cryptography.SHA256]::Create().ComputeHash($scriptBytes)).Replace('-', '')
Write-Host "SHA-256 do script: $hash"
if ($ScriptSha256 -and ($hash -ne $ScriptSha256.Trim().ToUpper())) {
    throw 'Hash do script NÃO confere. Instalação abortada.'
}
# Regrava em UTF-8 com BOM, para o Windows PowerShell 5.1 ler os acentos corretamente
$text = [Text.Encoding]::UTF8.GetString($scriptBytes).TrimStart([char]0xFEFF)
[IO.File]::WriteAllText($ScriptPath, $text, (New-Object Text.UTF8Encoding $true))

# 2) Chave
if ($Key) {
    $keyText = $Key.Trim()
    Write-Host 'Usando a chave informada no parâmetro -Key.'
} else {
    Write-Host "Baixando $KeyUrl ..."
    $keyText = [Text.Encoding]::ASCII.GetString((Get-Bytes $KeyUrl)).Trim()
}
if (([Convert]::FromBase64String($keyText)).Length -ne 64) { throw 'Chave inválida (esperado 64 bytes em Base64).' }
[IO.File]::WriteAllText($KeyPath, $keyText, [Text.Encoding]::ASCII)

# 3) Instala (cria a tarefa e restringe o acesso à chave)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Install
if ($LASTEXITCODE -ne 0) { throw "Falha ao executar o -Install (exit $LASTEXITCODE)." }

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) { throw "Tarefa '$TaskName' não foi criada. Veja $InstallDir\smx-vpn.log" }
Write-Host "Tarefa '$TaskName' instalada."

# 4) Opcional: executa agora
if ($RunNow) {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host 'Tarefa iniciada. Acompanhe em C:\ProgramData\SMX-VPN\smx-vpn.log'
}