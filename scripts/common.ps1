# Funzioni condivise da install.ps1, toggle.ps1 e uninstall.ps1.
# Nota: questo file evita lettere accentate per compatibilita' con
# Windows PowerShell 5.1 (che legge gli script senza BOM come ANSI).

$script:PresetName   = 'warzone_passi.txt'
$script:IncludeLine  = "Include: $PresetName"
$script:ApoClsid     = 'EACD2258-FCAC-4FF4-B36D-419E924A6D79'
$script:ApoDownload  = 'https://sourceforge.net/projects/equalizerapo/'
$script:ProjectRoot  = Split-Path -Parent $PSScriptRoot

# Installer ufficiale di Equalizer APO (versione fissata).
# Il download automatico parte SOLO se l'hash SHA-256 del file scaricato
# corrisponde a questo valore: se e' vuoto o diverso, l'installer apre la
# pagina ufficiale e chiede di installarlo a mano.
$script:ApoVersion   = '1.4.2'
$script:ApoFile      = 'EqualizerAPO-x64-1.4.2.exe'
$script:ApoUrl       = "https://downloads.sourceforge.net/project/equalizerapo/$($script:ApoVersion)/$($script:ApoFile)"
# Calcolato il 18/11/2026 sul file servito da SourceForge (11.980.366 byte, non firmato digitalmente).
$script:ApoSha256    = '7403BE7427BBE1936A40DDED082829B6E217FC4F5990FEE5CBA501F0AE055AFA'
$script:ApoSizeBytes = 11980366

function Say([string]$Text, [string]$Color = 'Gray') {
    Write-Host $Text -ForegroundColor $Color
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Riavvia lo script corrente come amministratore, con gli stessi argomenti.
function Restart-Elevated([string]$ScriptPath, [string[]]$ExtraArgs = @()) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"") + $ExtraArgs
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList | Out-Null
    } catch {
        Say 'Servono i permessi di amministratore. Riprova e premi "Si" quando Windows lo chiede.' Yellow
        Wait-End
    }
    exit
}

function Wait-End {
    if (-not $script:NoPause) { [void](Read-Host "`nPremi INVIO per chiudere") }
}

# Restituisce cartella di installazione e cartella config di Equalizer APO, oppure $null.
function Get-ApoInfo {
    $k = Get-ItemProperty 'HKLM:\SOFTWARE\EqualizerAPO' -ErrorAction SilentlyContinue
    if (-not $k -or -not $k.InstallPath -or -not (Test-Path $k.InstallPath)) { return $null }
    $cfg = if ($k.ConfigPath) { $k.ConfigPath } else { Join-Path $k.InstallPath 'config' }
    [pscustomobject]@{ InstallPath = $k.InstallPath; ConfigPath = $cfg }
}

# Uscite audio attive su cui Equalizer APO e' installato.
function Get-ApoPlaybackDevices {
    $base = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
    Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
        if ((Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceState -ne 1) { return }
        $fx = Get-ItemProperty "$($_.PSPath)\FxProperties" -ErrorAction SilentlyContinue
        if (-not $fx) { return }
        $values = ($fx.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Value }) | Out-String
        if ($values -notmatch $script:ApoClsid) { return }
        $p = Get-ItemProperty "$($_.PSPath)\Properties" -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Guid       = $_.PSChildName
            Connection = $p.'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
            Device     = $p.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
        }
    }
}

# Lettura/scrittura di config.txt con condivisione: il servizio audio
# di Windows puo' tenere il file aperto.
function Read-Shared([string]$Path) {
    if (-not (Test-Path $Path)) { return '' }
    $fs = [IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite,Delete')
    try { (New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)).ReadToEnd() } finally { $fs.Close() }
}

function Write-Shared([string]$Path, [string]$Text) {
    $fs = [IO.File]::Open($Path, 'OpenOrCreate', 'Write', 'ReadWrite,Delete')
    try {
        $fs.SetLength(0)
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($Text)
        $fs.Write($bytes, 0, $bytes.Length)
    } finally { $fs.Close() }
}

# Scarica $Url in $Dest e verifica lo SHA-256. Se l'hash non corrisponde
# cancella il file e restituisce $false. $OnProgress riceve la percentuale.
# $Pump viene chiamato durante l'attesa (per tenere viva l'interfaccia).
function Save-VerifiedFile([string]$Url, [string]$Dest, [string]$Sha256, [long]$ExpectedBytes, [scriptblock]$OnProgress = $null, [scriptblock]$Pump = $null) {
    if (-not $Sha256) { return $false }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Headers.Add('User-Agent', 'FootstepEQ-Installer')
    try {
        $task = $wc.DownloadFileTaskAsync($Url, $Dest)
        while (-not $task.IsCompleted) {
            if ($OnProgress -and (Test-Path $Dest) -and $ExpectedBytes -gt 0) {
                & $OnProgress ([int]([Math]::Min(99, (Get-Item $Dest).Length * 100 / $ExpectedBytes)))
            }
            if ($Pump) { & $Pump }
            Start-Sleep -Milliseconds 100
        }
        if ($task.IsFaulted -or -not (Test-Path $Dest)) { return $false }
        if ($OnProgress) { & $OnProgress 100 }
    } finally { $wc.Dispose() }

    $hash = (Get-FileHash $Dest -Algorithm SHA256).Hash
    if ($hash -ne $Sha256.ToUpperInvariant()) {
        Remove-Item $Dest -Force -ErrorAction SilentlyContinue
        return $false
    }
    $true
}

function New-DeviceLine($Devices) {
    # Stesso formato che scrive l'Editor di Equalizer APO: "<dispositivo> <uscita> {GUID}"
    'Device: ' + (($Devices | ForEach-Object { "$($_.Device) $($_.Connection) $($_.Guid)" }) -join '; ')
}

function Backup-Config([string]$ConfigDir) {
    $cfg = Join-Path $ConfigDir 'config.txt'
    if (-not (Test-Path $cfg)) { return $null }
    $dir = Join-Path $ConfigDir 'footstep-eq-backup'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $dest = Join-Path $dir ("config.{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    Write-Shared $dest (Read-Shared $cfg)
    $dest
}

# Stato della riga Include nel config: 'active', 'disabled' o 'missing'.
function Get-IncludeState([string]$Text) {
    $esc = [regex]::Escape($script:IncludeLine)
    if ($Text -match "(?m)^\s*$esc\s*$") { return 'active' }
    if ($Text -match "(?m)^\s*#\s*$esc\s*$") { return 'disabled' }
    'missing'
}

function Set-IncludeState([string]$ConfigDir, [ValidateSet('active', 'disabled', 'removed')][string]$State) {
    $cfg  = Join-Path $ConfigDir 'config.txt'
    $text = Read-Shared $cfg
    $esc  = [regex]::Escape($script:IncludeLine)
    # Togli ogni riga esistente del preset (attiva o commentata).
    $lines = @($text -split "\r?\n" | Where-Object { $_ -notmatch "^\s*#?\s*$esc\s*$" })
    while ($lines.Count -gt 0 -and $lines[-1] -eq '') { $lines = @($lines | Select-Object -SkipLast 1) }
    switch ($State) {
        'active'   { $lines += $script:IncludeLine }
        'disabled' { $lines += "# $($script:IncludeLine)" }
    }
    Write-Shared $cfg (($lines -join "`r`n") + "`r`n")
}
