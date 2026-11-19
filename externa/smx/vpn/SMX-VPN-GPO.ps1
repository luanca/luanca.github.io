<#
  SMX-VPN-GPO.ps1  -  versão para implantação via GPO

  Dois modos:
    -Install   Copia o script para C:\ProgramData\SMX-VPN e registra a tarefa agendada
               (conta SYSTEM) que dispara quando a rede conecta, na inicialização e no logon (com atraso de 30 s).
               É o que a GPO (Script de Inicialização do computador) deve chamar.
    (sem args) Verifica o domínio e, se necessário, reconfigura e conecta a VPN.

  Credenciais: o site hospeda apenas o arquivo criptografado (credenciais.enc, gerado por
  Encrypt-VpnCredential.ps1). A chave (vpn.key) fica na pasta da GPO, ao lado deste script;
  o -Install a copia para C:\ProgramData\SMX-VPN com ACL restrita a SYSTEM/Administradores.
  A senha é descriptografada só em memória (nunca gravada em disco nem no log).
#>
param(
    [switch]$Install
)

# ====== AJUSTE AQUI ======
$Domain   = 'SMX.LOGISTICS'   # domínio interno a ser testado
$VpnName  = 'SMX VPN'
$OvpnUrl  = 'https://luanca.github.io/externa/smx/vpn/sslvpn-luan.santos%40smx.logistics-client-config.ovpn'
$CredUrl  = 'https://luanca.github.io/externa/smx/vpn/credenciais.enc'
$Sccli    = 'C:\Program Files (x86)\Sophos\Connect\sccli.exe'
$TaskName = 'SMX VPN Auto'
# =========================

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InstallDir = Join-Path $env:ProgramData 'SMX-VPN'
$LogFile    = Join-Path $InstallDir 'smx-vpn.log'
$OvpnFile   = Join-Path $InstallDir 'client-config.ovpn'
$KeyFile    = Join-Path $InstallDir 'vpn.key'
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

function Write-Log([string]$Message) {
    "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message | Add-Content -Path $LogFile
}

# ---------------------------------------------------------------
# MODO INSTALL (chamado pela GPO)
# ---------------------------------------------------------------
if ($Install) {
    $target = Join-Path $InstallDir 'SMX-VPN-GPO.ps1'
    if ($PSCommandPath -ne $target) { Copy-Item $PSCommandPath $target -Force }

    # Copia a chave (que está ao lado deste script na pasta da GPO) e restringe o acesso
    $srcKey = Join-Path (Split-Path -Parent $PSCommandPath) 'vpn.key'
    if (Test-Path $srcKey) {
        if ($srcKey -ne $KeyFile) { Copy-Item $srcKey $KeyFile -Force }
        & icacls.exe $KeyFile /inheritance:r /grant:r '*S-1-5-18:(F)' '*S-1-5-32-544:(F)' | Out-Null
        Write-Log "Chave instalada em $KeyFile."
    } elseif (-not (Test-Path $KeyFile)) {
        Write-Log "AVISO: vpn.key não encontrada ao lado do script nem em $InstallDir."
    }

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$target`""

    # Gatilho 1: rede conectada (NetworkProfile, evento 10000)
    $class = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
    $netTrigger = New-CimInstance -CimClass $class -ClientOnly
    $netTrigger.Enabled = $true
    $netTrigger.Subscription = @'
<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and EventID=10000]]</Select></Query></QueryList>
'@
    # Gatilho 2: inicialização (cobre rede já conectada no boot)
    $bootTrigger = New-ScheduledTaskTrigger -AtStartup
    # Gatilho 3: logon de qualquer usuário. O atraso dá tempo ao cliente Sophos Connect de
    # iniciar na sessão (é nesse momento que a VPN costuma cair), para só então reconectar.
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn
    $logonTrigger.Delay = 'PT30S'

    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $action `
        -Trigger @($netTrigger, $bootTrigger, $logonTrigger) -Principal $principal -Settings $settings -Force | Out-Null
    Write-Log "Tarefa '$TaskName' instalada/atualizada."
    return
}

# ---------------------------------------------------------------
# MODO EXECUÇÃO
# ---------------------------------------------------------------
function Test-Domain([string]$Name) {
    try {
        $null = Resolve-DnsName -Name $Name -ErrorAction Stop -QuickTimeout
        return [bool](Test-Connection -ComputerName $Name -Count 1 -Quiet -ErrorAction SilentlyContinue)
    } catch { return $false }
}

function Wait-Domain([string]$Name, [int]$TimeoutSec) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        if (Test-Domain $Name) { return $true }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
    return $false
}

# 1) Domínio já disponível?
Write-Log "Rede conectada. Testando $Domain..."
if (Wait-Domain $Domain 15) {
    Write-Log "$Domain disponível. Nada a fazer."
    return
}
Write-Log "$Domain indisponível. Iniciando conexão da VPN."

if (-not (Test-Path $Sccli)) { Write-Log "ERRO: sccli.exe não encontrado em $Sccli"; return }

function Get-VpnCredential([string]$Base64, [string]$KeyPath) {
    $key    = [Convert]::FromBase64String((Get-Content $KeyPath -Raw).Trim())   # 64 bytes
    $encKey = [byte[]]$key[0..31]
    $macKey = [byte[]]$key[32..63]

    $blob = [Convert]::FromBase64String($Base64.Trim().TrimStart([char]0xFEFF))
    if ($blob.Length -lt 65) { throw 'Arquivo de credenciais inválido.' }
    $iv     = [byte[]]$blob[0..15]
    $mac    = [byte[]]$blob[($blob.Length - 32)..($blob.Length - 1)]
    $cipher = [byte[]]$blob[16..($blob.Length - 33)]

    # Verifica integridade/chave antes de descriptografar (comparação em tempo constante)
    $calc = [Security.Cryptography.HMACSHA256]::new($macKey).ComputeHash([byte[]]($iv + $cipher))
    $diff = 0
    for ($i = 0; $i -lt 32; $i++) { $diff = $diff -bor ($calc[$i] -bxor $mac[$i]) }
    if ($diff -ne 0) { throw 'HMAC inválido: chave errada ou arquivo adulterado.' }

    $aes = [Security.Cryptography.Aes]::Create()
    $aes.Key = $encKey; $aes.IV = $iv; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'
    $plain = $aes.CreateDecryptor().TransformFinalBlock($cipher, 0, $cipher.Length)
    [Text.Encoding]::UTF8.GetString($plain) | ConvertFrom-Json
}

# 2) Baixa credenciais criptografadas, descriptografa em memória, e baixa o .ovpn
$nocache = "?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"   # evita cache do GitHub Pages
try {
    $raw  = (Invoke-WebRequest -Uri ($CredUrl + $nocache) -UseBasicParsing).Content
    if ($raw -is [byte[]]) { $raw = [Text.Encoding]::UTF8.GetString($raw) }
    if (-not (Test-Path $KeyFile)) { throw "Chave não encontrada em $KeyFile." }
    $cred = Get-VpnCredential $raw $KeyFile
    $user = $cred.user
    $pass = $cred.password
    if (-not $user -or -not $pass) { throw 'JSON sem "user" ou "password".' }
    Write-Log "Credenciais obtidas (usuário: $user)."

    Invoke-WebRequest -Uri ($OvpnUrl + $nocache) -OutFile $OvpnFile -UseBasicParsing
    Write-Log "Arquivo da VPN baixado."
} catch {
    Write-Log "ERRO ao baixar credenciais/arquivo da VPN: $($_.Exception.Message)"
    return
}

# 3) Chamadas ao sccli
function Invoke-Sccli([string[]]$Arguments, [string]$Label) {
    $ErrorActionPreference = 'Continue'   # disable/remove podem falhar legitimamente
    $out = & $Sccli @Arguments 2>&1 | Out-String
    Write-Log ("{0} (exit {1}): {2}" -f $Label, $LASTEXITCODE, $out.Trim())
}

try {
    Invoke-Sccli @('disable', '-n', $VpnName) 'disable'
    Invoke-Sccli @('remove',  '-n', $VpnName) 'remove'
    Invoke-Sccli @('add', '-f', $OvpnFile, '-n', $VpnName) 'add'

    $ErrorActionPreference = 'Continue'
    $out = & $Sccli enable -n $VpnName -u $user -p $pass 2>&1 | Out-String
    Write-Log ("enable (exit {0}): {1}" -f $LASTEXITCODE, ($out.Trim() -replace [regex]::Escape($pass), '***'))
}
finally {
    Remove-Item $OvpnFile -Force -ErrorAction SilentlyContinue
    $pass = $null; $cred = $null; $raw = $null
}

# 4) Verifica se deu certo
if (Wait-Domain $Domain 60) {
    Write-Log "SUCESSO: $Domain respondeu após conectar a VPN."
} else {
    Write-Log "FALHA: $Domain continua sem resposta após a VPN."
    exit 1
}