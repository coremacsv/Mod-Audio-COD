<#
  Footstep EQ for Warzone - installer guidato.

  Cosa fa, da solo:
    1. controlla se Equalizer APO è installato;
    2. se manca, lo scarica dalla pagina ufficiale, verifica che il file sia
       quello originale (SHA-256) e avvia l'installazione;
    3. mostra una finestra-guida che dice cosa cliccare a ogni passaggio;
    4. se serve, apre la scelta del dispositivo e attende che l'utente scelga
       le cuffie;
    5. installa il preset per i passi solo sulle cuffie scelte;
    6. propone il riavvio se serve.
  Non modifica alcun file del gioco.

  Parametri (per sviluppatori/test):
    -ConfigDir <cartella>  usa questa cartella config invece di quella di Equalizer APO
    -DemoGuide             anteprima di console e guida, senza modificare nulla
    -Fast                  niente animazioni
    -NoPause               nessuna finestra/attesa finale
#>
param(
    [string]$ConfigDir,
    [switch]$DemoGuide,
    [switch]$Fast,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
. (Join-Path $PSScriptRoot 'fx.ps1')
. (Join-Path $PSScriptRoot 'gui.ps1')
$script:NoPause = $NoPause
$script:FxFast  = [bool]$Fast

$Total = 4
function Step([int]$n) { "Passaggio $n di $Total" }

# ---------------------------------------------------------------------------
#  Testi della finestra-guida
# ---------------------------------------------------------------------------
$SmartScreen = "Se compare un avviso blu «PC protetto da Windows»:`nclicca «Ulteriori informazioni» → «Esegui comunque»."
$T = @{
    Check    = @('Controllo il PC…', 'Sto controllando se Equalizer APO è già installato e su quali uscite audio è attivo.')
    Download = @('Scarico Equalizer APO', "Sto scaricando Equalizer APO $($script:ApoVersion) dalla pagina ufficiale (circa 12 MB).`n`nNon devi fare niente: aspetta qualche secondo.")
    Verify   = @('Verifico il file', 'Controllo che il file scaricato sia quello originale e non sia stato modificato.')
    Setup    = @('Installa Equalizer APO', "$SmartScreen`n`nPoi, nell'installazione:`n• clicca «Next», lascia la cartella proposta`n• clicca «Install»")
    Devices  = @('Scegli le tue cuffie', "Nella finestra «Device Selector»:`n`n• In «Playback devices» spunta SOLO l'uscita dove colleghi le cuffie per giocare (di solito quella con «Default device»)`n• NON spuntare monitor (AMD / NVIDIA / Intel) né microfoni`n• Premi «OK», poi di nuovo «OK» quando compare «No problems were detected»")
    Finish   = @('Ultimo clic', "Nell'installazione clicca «Finish» / «Fine».`n`nSe chiede di riavviare, scegli di riavviare PIÙ TARDI («I want to manually reboot later»): ci penso io alla fine.")
    Preset   = @('Installo il preset', 'Sto attivando il preset per i passi sulle cuffie che hai scelto.')
}

function Get-SelectorExe([string]$InstallPath) {
    @('DeviceSelector.exe', 'Configurator.exe') |
        ForEach-Object { Join-Path $InstallPath $_ } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
}
function Test-ProcessRunning([string[]]$Names) { [bool](Get-Process -Name $Names -ErrorAction SilentlyContinue) }

function Write-Devices($Devices) {
    foreach ($d in $Devices) {
        Write-Host '        ├─ ' -NoNewline -ForegroundColor DarkGreen
        Write-Host ("{0} " -f $d.Connection) -NoNewline -ForegroundColor White
        Write-Host ("[{0}] " -f $d.Device) -NoNewline -ForegroundColor Gray
        Write-Host $d.Guid -ForegroundColor DarkGray
        Start-FxSleep 80
    }
}

# ---------------------------------------------------------------------------
#  Anteprima (nessuna modifica al sistema)
# ---------------------------------------------------------------------------
if ($DemoGuide) {
    Initialize-Fx 'FOOTSTEP//EQ  ::  anteprima'
    Show-Matrix; Show-Banner
    Write-Section 'RICOGNIZIONE'
    Set-GuideStep $T.Check[0] $T.Check[1] 'Anteprima 1 di 6'
    Write-Status '>>' 'Scansione endpoint audio di Windows' '6 TROVATI'
    Write-Status '!!' 'Equalizer APO' 'NON RILEVATO' Yellow
    Write-Section 'DOWNLOAD'
    Set-GuideStep $T.Download[0] $T.Download[1] 'Anteprima 2 di 6'
    0..100 | Where-Object { $_ % 4 -eq 0 } | ForEach-Object { Set-GuideProgress $_; Write-Bar $_ ([string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:0.0} / 12.0 MB", 12.0 * $_ / 100)); Start-FxSleep 60 }
    Write-Host ''
    Set-GuideStep $T.Verify[0] $T.Verify[1] 'Anteprima 3 di 6'
    Write-Status 'OK' 'Firma SHA-256 7403BE74…055AFA' 'CORRISPONDE'
    Write-Section 'INSTALLAZIONE'
    Set-GuideStep $T.Setup[0] $T.Setup[1] 'Anteprima 4 di 6'
    1..25 | ForEach-Object { Write-Spin 'TOCCA A TE → nell''installazione clicca «Next», poi «Install»'; Update-Guide; Start-FxSleep 100 }
    Stop-Spin 'Equalizer APO installato'
    Set-GuideStep $T.Devices[0] $T.Devices[1] 'Anteprima 5 di 6'
    1..25 | ForEach-Object { Write-Spin 'TOCCA A TE → spunta le cuffie con cui giochi e premi «OK»'; Update-Guide; Start-FxSleep 100 }
    Stop-Spin 'Uscita selezionata' '1 CANALE'
    Write-Devices @([pscustomobject]@{ Connection = 'Altoparlanti'; Device = 'Realtek(R) Audio'; Guid = '{00000000-0000-0000-0000-000000000000}' })
    Write-Section 'INIEZIONE PRESET'
    Set-GuideStep $T.Preset[0] $T.Preset[1] 'Anteprima 6 di 6'
    Write-Status 'OK' 'Backup configurazione' 'SALVATO'
    Write-Status 'OK' 'Preset warzone_passi.txt' 'ATTIVO'
    Show-EqCurve (Get-Content (Join-Path $script:ProjectRoot "presets\$($script:PresetName)") -Raw -Encoding UTF8)
    Close-Guide
    Write-Host ''; Write-Type '  >>> ANTEPRIMA COMPLETATA. Nessuna modifica è stata fatta.' Cyan 10
    Wait-End
    exit 0
}

# ---------------------------------------------------------------------------
#  Permessi di amministratore
# ---------------------------------------------------------------------------
if (-not $ConfigDir -and -not (Test-Admin)) {
    Initialize-Fx 'FOOTSTEP//EQ'
    Show-Banner
    Write-Status '!!' 'Servono i permessi di amministratore' 'PREMI «SÌ»' Yellow
    Start-FxSleep 900
    Restart-Elevated $PSCommandPath
}

# ---------------------------------------------------------------------------
#  Installazione
# ---------------------------------------------------------------------------
$needReboot = $false
try {
    Initialize-Fx 'FOOTSTEP//EQ  ::  audio override toolkit'
    Show-Matrix; Show-Banner
    Set-GuideStep $T.Check[0] $T.Check[1] (Step 1)

    Write-Section 'RICOGNIZIONE'
    $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    Write-Status '>>' "Sistema: $os" 'OK'
    $allOut = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render' -ErrorAction SilentlyContinue |
               Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceState -eq 1 })
    Write-Status '>>' 'Scansione uscite audio di Windows' ("{0} TROVATE" -f $allOut.Count)

    # --- 1. Equalizer APO --------------------------------------------------
    $apo = $null
    if ($ConfigDir) {
        Write-Status '!!' "[TEST] cartella config: $ConfigDir" 'SANDBOX' Magenta
    } else {
        $apo = Get-ApoInfo
        if ($apo) {
            Write-Status 'OK' 'Equalizer APO' 'RILEVATO' Green
            Write-Host "        └─ $($apo.InstallPath)" -ForegroundColor DarkGray
        } else {
            Write-Status '!!' 'Equalizer APO' 'NON RILEVATO' Yellow

            $is64 = [Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITECTURE -ne 'ARM64'
            $setup = $null
            if ($is64) {
                Write-Section 'DOWNLOAD'
                Set-GuideStep $T.Download[0] $T.Download[1] (Step 1)
                Write-Status '>>' "Sorgente: downloads.sourceforge.net · v$($script:ApoVersion)"
                $dir = Join-Path $env:TEMP ('footstep-eq-' + [guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path $dir | Out-Null
                $dest = Join-Path $dir $script:ApoFile
                $mb = $script:ApoSizeBytes / 1MB
                $ok = Save-VerifiedFile $script:ApoUrl $dest $script:ApoSha256 $script:ApoSizeBytes `
                        -OnProgress { param($p) Set-GuideProgress $p; Write-Bar $p ([string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:0.0} / {1:0.0} MB", $mb * $p / 100, $mb)) } `
                        -Pump { Update-Guide }
                Write-Host ''
                Set-GuideStep $T.Verify[0] $T.Verify[1] (Step 1)
                if ($ok) {
                    $short = $script:ApoSha256.Substring(0, 8) + '…' + $script:ApoSha256.Substring($script:ApoSha256.Length - 6)
                    Write-Status 'OK' "Firma SHA-256 $short" 'CORRISPONDE'
                    $setup = $dest
                } else {
                    Write-Status 'ERR' 'Download o verifica del file' 'FALLITO' Red
                }
            }
            if (-not $setup) {
                Close-Guide
                Show-Info ("Non riesco a scaricare Equalizer APO in automatico.`n`n" +
                           "Ti apro la pagina ufficiale: scaricalo e installalo, spunta le tue cuffie nel Device Selector, " +
                           "riavvia il PC ed esegui di nuovo Installa.bat.") 'Footstep EQ' 'Warning'
                Start-Process $script:ApoDownload
                exit 1
            }

            # Avvia l'installazione e segue i passaggi, aggiornando guida e console.
            Write-Section 'INSTALLAZIONE'
            Write-Status '!!' 'Se appare l''avviso blu di Windows: «Ulteriori informazioni» → «Esegui comunque»' '' Yellow
            Set-GuideStep $T.Setup[0] $T.Setup[1] (Step 2)
            $proc = Start-Process $setup -PassThru
            $phase = @{ Current = 'Setup'; Label = 'TOCCA A TE → nell''installazione clicca «Next», poi «Install»' }
            [void](Wait-Until -Condition { $proc.HasExited } -Tick {
                $selectorOpen = Test-ProcessRunning 'DeviceSelector', 'Configurator'
                if ($selectorOpen -and $phase.Current -ne 'Devices') {
                    Stop-Spin 'File di Equalizer APO copiati'
                    $phase.Current = 'Devices'; $phase.Label = 'TOCCA A TE → spunta le cuffie con cui giochi e premi «OK»'
                    Set-GuideStep $T.Devices[0] $T.Devices[1] (Step 3)
                } elseif (-not $selectorOpen -and $phase.Current -eq 'Devices') {
                    Stop-Spin 'Scelta del dispositivo' 'CONFERMATA'
                    $phase.Current = 'Finish'; $phase.Label = 'TOCCA A TE → clicca «Finish» per chiudere l''installazione'
                    Set-GuideStep $T.Finish[0] $T.Finish[1] (Step 3)
                }
                Write-Spin $phase.Label
            })
            Stop-Spin 'Installazione di Equalizer APO' 'COMPLETATA'
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue

            $apo = Get-ApoInfo
            if (-not $apo) { throw "L'installazione di Equalizer APO non è stata completata." }
            Write-Host "        └─ $($apo.InstallPath)" -ForegroundColor DarkGray
            $needReboot = $true
        }
        $ConfigDir = $apo.ConfigPath
    }

    # --- 2. Cuffie selezionate? -------------------------------------------
    Write-Section 'AGGANCIO CUFFIE'
    $devices = @(Get-ApoPlaybackDevices)
    if ($devices.Count -eq 0 -and $apo) {
        Write-Status '!!' 'Equalizer APO non è attivo su nessuna uscita' 'SERVE LA TUA SCELTA' Yellow
        $exe = Get-SelectorExe $apo.InstallPath
        if (-not $exe) { throw 'Non trovo il Device Selector di Equalizer APO.' }
        Set-GuideStep $T.Devices[0] $T.Devices[1] (Step 3)
        # Va avviato dalla sua cartella, altrimenti non trova i file grafici (errore "Qt platform plugin").
        $sel = Start-Process $exe -WorkingDirectory $apo.InstallPath -PassThru
        [void](Wait-Until -Condition { $sel.HasExited } -Tick { Write-Spin 'TOCCA A TE → spunta le cuffie con cui giochi e premi «OK»' })
        Stop-Spin 'Scelta del dispositivo' 'CONFERMATA'
        $devices = @(Get-ApoPlaybackDevices)
        $needReboot = $true
    }
    if ($devices.Count -eq 0) {
        throw "Non hai selezionato nessuna uscita audio. Esegui di nuovo Installa.bat e spunta le tue cuffie in «Playback devices»."
    }
    Write-Status 'OK' 'Uscite agganciate' ("{0} CANALE/I" -f $devices.Count)
    Write-Devices $devices

    # --- 3. Preset ---------------------------------------------------------
    Write-Section 'INIEZIONE PRESET'
    Set-GuideStep $T.Preset[0] ($T.Preset[1] + "`n`n" + (($devices | ForEach-Object { "• $($_.Connection) ($($_.Device))" }) -join "`n")) (Step 4)
    if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null }
    $backup = Backup-Config $ConfigDir
    Write-Status 'OK' 'Backup configurazione esistente' $(if ($backup) { 'SALVATO' } else { 'NON NECESSARIO' })
    $template = Get-Content (Join-Path $script:ProjectRoot "presets\$($script:PresetName)") -Raw -Encoding UTF8
    $preset = $template.Replace('{{DEVICE_LINE}}', (New-DeviceLine $devices))
    Write-Shared (Join-Path $ConfigDir $script:PresetName) $preset
    Write-Status 'OK' "Preset $($script:PresetName)" 'SCRITTO'
    Set-IncludeState $ConfigDir 'active'
    Write-Status 'OK' 'Attivazione in config.txt' 'ATTIVO'
    # Avvisa se ci sono altri preset attivi che potrebbero sommarsi a questo.
    $others = @([regex]::Matches((Read-Shared (Join-Path $ConfigDir 'config.txt')), '(?m)^\s*Include:\s*(.+?)\s*$') |
                ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne $script:PresetName })
    foreach ($o in $others) { Write-Status '!!' "Altro preset attivo: $o (se agisce sulle stesse cuffie, gli effetti si sommano)" '' Yellow }
    Show-EqCurve $preset
    Close-Guide

    # --- 4. Fine -------------------------------------------------------------
    Write-Host ''
    Write-Host ('   ' + ('═' * ((Get-FxWidth) - 6))) -ForegroundColor DarkGreen
    Write-Type '   >>> OVERRIDE AUDIO COMPLETATO' Cyan 12
    Write-Host '   Nel gioco: Musica 0 · Effetti al massimo · Audio Mix «Cuffie»' -ForegroundColor Gray
    Write-Host '   Accendi/spegni il preset con «Attiva-Disattiva.bat».' -ForegroundColor Gray
    Write-Host ''

    $tips = "Consigli nel gioco (Impostazioni › Audio):`n• Musica: 0`n• Effetti: al massimo`n• Audio Mix: Cuffie`n`n" +
            "Per accendere/spegnere il preset usa «Attiva-Disattiva.bat»."
    if ($needReboot -and -not $NoPause) {
        if (Ask-YesNo ("✅ Fatto! Il preset è installato.`n`nPer attivare Equalizer APO serve un riavvio.`n" +
                       "Salva il tuo lavoro: vuoi riavviare adesso? (il PC si riavvia tra 15 secondi)`n`n$tips")) {
            Write-Status '!!' 'Riavvio del PC' 'TRA 15 SECONDI' Yellow
            shutdown.exe /r /t 15 /c "Footstep EQ: riavvio per attivare Equalizer APO"
        } else {
            Write-Status '!!' 'Ricordati di riavviare il PC prima di giocare' '' Yellow
        }
    } elseif (-not $NoPause) {
        Show-Info "✅ Fatto! Il preset è attivo da subito, non serve riavviare.`n`n$tips"
    }
    Wait-End
} catch {
    Close-Guide
    Write-Host ''
    Write-Status 'ERR' $_.Exception.Message '' Red
    $msg = "Qualcosa è andato storto:`n$($_.Exception.Message)`n`nNessun file del gioco è stato toccato."
    if (-not $NoPause) { Show-Info $msg 'Footstep EQ' 'Error' }
    Wait-End
    exit 1
}
