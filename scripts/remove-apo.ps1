<#
  Footstep EQ for Warzone - rimozione completa di Equalizer APO.

  Cosa fa:
    1. chiede conferma;
    2. salva una copia di tutti i preset (cartella config) in Documenti;
    3. avvia il disinstallatore UFFICIALE di Equalizer APO, che:
         - toglie Equalizer APO da tutte le cuffie e i microfoni,
         - cancella solo i propri file (mai l'intera cartella),
         - rimuove le sue voci dal registro;
    4. se richiesto, elimina anche la cartella config (i preset);
    5. controlla che sia tutto rimosso e propone il riavvio.

  Parametri (per sviluppatori/test):
    -DryRun   mostra cosa farebbe, senza modificare nulla
    -Fast     niente animazioni
    -NoPause  nessuna finestra/attesa finale
#>
param(
    [switch]$DryRun,
    [switch]$Fast,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
. (Join-Path $PSScriptRoot 'fx.ps1')
. (Join-Path $PSScriptRoot 'gui.ps1')
$script:NoPause = $NoPause
$script:FxFast  = [bool]$Fast

if (-not $DryRun -and -not (Test-Admin)) {
    Initialize-Fx 'FOOTSTEP//EQ  ::  rimozione'
    Show-Banner
    Write-Status '!!' 'Servono i permessi di amministratore' 'PREMI «SÌ»' Yellow
    Start-FxSleep 900
    Restart-Elevated $PSCommandPath
}

try {
    Initialize-Fx 'FOOTSTEP//EQ  ::  rimozione'
    Show-Matrix; Show-Banner
    if ($DryRun) { Write-Status '!!' 'MODALITÀ PROVA: nessuna modifica verrà fatta' 'DRY-RUN' Magenta }

    # --- 1. Ricognizione -------------------------------------------------------
    Write-Section 'RICOGNIZIONE'
    $apo = Get-ApoInfo
    if (-not $apo) {
        Write-Status 'OK' 'Equalizer APO' 'NON INSTALLATO' Green
        # Pulisce eventuali residui lasciati da una disinstallazione precedente.
        $lo = Get-ApoLeftovers
        if ($lo.RegKey -and -not $lo.UninstKey -and -not $lo.Clsid) {
            if ($DryRun) {
                Write-Status '>>' 'Cancellerei la chiave di registro rimasta (HKLM\SOFTWARE\EqualizerAPO)' 'PROVA' Magenta
            } else {
                Remove-ApoRegKey
                Write-Status 'OK' 'Chiave di registro rimasta da una vecchia installazione' 'RIMOSSA'
            }
        }
        if ($lo.PendingDll) { Write-Status '!!' 'Ultimi file di Equalizer APO: verranno cancellati al prossimo riavvio' '' Yellow }
        Write-Host ''
        Write-Type '   >>> Il PC è senza Equalizer APO.' Cyan 10
        if (-not $NoPause -and -not $DryRun) { Show-Info 'Equalizer APO non è installato: il PC è già pulito.' }
        Wait-End; exit 0
    }
    Write-Status 'OK' 'Equalizer APO' 'RILEVATO'
    Write-Host "        └─ $($apo.InstallPath)" -ForegroundColor DarkGray
    $devices = @(Get-ApoAllDevices)
    Write-Status '>>' 'Dispositivi con Equalizer APO attivo' ("{0}" -f $devices.Count)
    foreach ($d in $devices) {
        $kind = if ($d.Flow -eq 'Render') { 'uscita  ' } else { 'microfono' }
        Write-Host ("        ├─ [{0}] {1} ({2})" -f $kind, $d.Connection, $d.Device) -ForegroundColor Gray
    }
    $uninst = Get-ApoUninstaller $apo.InstallPath
    if (-not $uninst) { throw "Non trovo il disinstallatore di Equalizer APO. Rimuovilo da Impostazioni › App › App installate." }
    Write-Status 'OK' 'Disinstallatore ufficiale' 'TROVATO'

    # --- 2. Conferma ------------------------------------------------------------
    $ask = "Vuoi rimuovere completamente Equalizer APO?`n`n" +
           "• Verrà tolto da tutte le cuffie e i microfoni ($($devices.Count) dispositivi)`n" +
           "• Smetteranno di funzionare TUTTI gli equalizzatori basati su Equalizer APO (Footstep EQ, Peace, altri preset)`n" +
           "• Prima viene salvata una copia dei tuoi preset in Documenti`n`n" +
           "Nessun file del gioco viene toccato."
    if (-not $DryRun -and -not $NoPause) {
        Set-GuideStep 'Conferma la rimozione' 'Rispondi alla domanda: «Sì» per rimuovere Equalizer APO, «No» per annullare.' 'Passaggio 1 di 3'
        if (-not (Ask-YesNo $ask 'Footstep EQ - Rimozione')) {
            Close-Guide
            Write-Status '!!' 'Rimozione annullata dall''utente' 'NESSUNA MODIFICA' Yellow
            Wait-End; exit 0
        }
        $deleteConfig = Ask-YesNo ("Vuoi eliminare anche i preset salvati (cartella «config»)?`n`n" +
                                   "• «No» (consigliato): restano sul PC, utili se reinstalli Equalizer APO`n" +
                                   "• «Sì»: vengono cancellati, ma una copia resta comunque in Documenti") 'Footstep EQ - Rimozione' -DefaultNo
    } else {
        $deleteConfig = $false
    }

    # --- 3. Backup --------------------------------------------------------------
    Write-Section 'BACKUP'
    if ($DryRun) {
        Write-Status '>>' "Copierei «$($apo.ConfigPath)» in Documenti\Footstep EQ - backup" 'PROVA' Magenta
    } else {
        Set-GuideStep 'Salvo i tuoi preset' 'Sto copiando la cartella dei preset in Documenti › «Footstep EQ - backup».' 'Passaggio 2 di 3'
        $bk = Backup-ConfigFolder $apo.ConfigPath
        Write-Status 'OK' 'Copia dei preset' $(if ($bk) { 'SALVATA' } else { 'NESSUN PRESET' })
        if ($bk) { Write-Host "        └─ $bk" -ForegroundColor DarkGray }
    }

    # --- 4. Disinstallazione ufficiale -----------------------------------------
    Write-Section 'RIMOZIONE'
    # /S = senza finestre; _?= fa girare il disinstallatore dalla sua cartella
    # e permette di aspettarne la fine (altrimenti si copia in TEMP e termina subito).
    $uArgs = @('/S', "_?=$($apo.InstallPath)")
    if ($DryRun) {
        Write-Status '>>' "Avvierei: $uninst $($uArgs -join ' ')" 'PROVA' Magenta
    } else {
        Set-GuideStep 'Rimuovo Equalizer APO' "Sto avviando il disinstallatore ufficiale di Equalizer APO.`n`nNon devi fare niente: ci vuole qualche secondo, l'audio potrebbe interrompersi un attimo." 'Passaggio 3 di 3'
        $p = Start-Process $uninst -ArgumentList $uArgs -PassThru
        [void](Wait-Until -Condition { $p.HasExited } -Tick { Write-Spin 'Disinstallazione in corso…' })
        Stop-Spin 'Disinstallatore ufficiale' ("CODICE {0}" -f $p.ExitCode) $(if ($p.ExitCode -eq 0) { 'Green' } else { 'Yellow' })

        # Con _?= il disinstallatore non può cancellare se stesso: lo facciamo noi.
        Remove-Item (Join-Path $apo.InstallPath 'Uninstall.exe') -Force -ErrorAction SilentlyContinue
        if ($deleteConfig -and (Test-Path $apo.ConfigPath)) {
            Remove-Item $apo.ConfigPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Status 'OK' 'Cartella dei preset' 'ELIMINATA'
        } else {
            Write-Status 'OK' 'Cartella dei preset' 'CONSERVATA'
        }
        # Cancella la cartella di installazione SOLO se è rimasta vuota.
        if ((Test-Path $apo.InstallPath) -and -not (Get-ChildItem $apo.InstallPath -Force -ErrorAction SilentlyContinue)) {
            Remove-Item $apo.InstallPath -Force -ErrorAction SilentlyContinue
        }
        # Il disinstallatore ufficiale lascia la chiave con le impostazioni:
        # la togliamo solo se i programmi di Equalizer APO sono davvero spariti.
        $pendingDll = Test-Path (Join-Path $apo.InstallPath 'EqualizerAPO.dll')
        if (-not (Test-ApoInstallDir $apo.InstallPath) -and (Test-Path 'HKLM:\SOFTWARE\EqualizerAPO')) {
            Remove-ApoRegKey
            Write-Status 'OK' 'Impostazioni di Equalizer APO nel registro' 'RIMOSSE'
        }
    }

    # --- 5. Verifica ------------------------------------------------------------
    Write-Section 'VERIFICA'
    if ($DryRun) {
        Write-Status '>>' 'Controllerei che registro e dispositivi siano puliti' 'PROVA' Magenta
    } else {
        $left = @(Get-ApoAllDevices)
        $lo   = Get-ApoLeftovers
        $regClean = -not ($lo.RegKey -or $lo.UninstKey -or $lo.Clsid)
        Write-Status $(if ($left.Count -eq 0) { 'OK' } else { 'ERR' }) 'Dispositivi con Equalizer APO' ("{0}" -f $left.Count) $(if ($left.Count -eq 0) { 'Green' } else { 'Red' })
        Write-Status $(if ($regClean) { 'OK' } else { 'ERR' }) 'Voci nel registro di Windows' $(if ($regClean) { 'RIMOSSE' } else { 'ANCORA PRESENTI' }) $(if ($regClean) { 'Green' } else { 'Red' })
        if ($pendingDll) { Write-Status '!!' 'Ultimi file in uso dall''audio di Windows' 'CANCELLATI AL RIAVVIO' Yellow }
        if ($left.Count -gt 0 -or -not $regClean) { throw 'La rimozione non è completa. Riavvia il PC ed esegui di nuovo Rimuovi-EqualizerAPO.bat.' }
    }
    Close-Guide

    Write-Host ''
    Write-Host ('   ' + ('═' * ((Get-FxWidth) - 6))) -ForegroundColor DarkGreen
    Write-Type $(if ($DryRun) { '   >>> PROVA COMPLETATA. Nessuna modifica è stata fatta.' } else { '   >>> EQUALIZER APO RIMOSSO. Audio di Windows tornato a quello originale.' }) Cyan 10
    Write-Host '   Per reinstallare tutto in futuro: «Installa.bat».' -ForegroundColor Gray
    Write-Host ''

    if (-not $DryRun -and -not $NoPause) {
        if (Ask-YesNo ("✅ Equalizer APO è stato rimosso.`n`nPer completare la pulizia serve un riavvio.`n" +
                       "Salva il tuo lavoro: vuoi riavviare adesso? (il PC si riavvia tra 15 secondi)")) {
            Write-Status '!!' 'Riavvio del PC' 'TRA 15 SECONDI' Yellow
            shutdown.exe /r /t 15 /c "Footstep EQ: riavvio per completare la rimozione di Equalizer APO"
        } else {
            Write-Status '!!' 'Ricordati di riavviare il PC' '' Yellow
        }
    }
    Wait-End
} catch {
    Close-Guide
    Write-ErrorLog $_ 'remove-apo'
    Write-Host ''
    Write-Status 'ERR' $_.Exception.Message '' Red
    Write-Host "        └─ dettagli tecnici: $(Get-LogPath)" -ForegroundColor DarkGray
    if (-not $NoPause) { Show-Info "Qualcosa è andato storto:`n$($_.Exception.Message)" 'Footstep EQ' 'Error' }
    Wait-End
    exit 1
}
