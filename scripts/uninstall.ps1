<#
  Footstep EQ for Warzone - disinstallazione.
  Rimuove il preset e la sua riga dal config di Equalizer APO.
  Equalizer APO resta installato (si rimuove da Impostazioni > App).
#>
param(
    [string]$ConfigDir,
    [switch]$NoPause,
    [switch]$Fast
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$script:NoPause = $NoPause

if (-not $ConfigDir -and -not (Test-Admin)) { Restart-Elevated $PSCommandPath }

try {
    if (-not $ConfigDir) {
        $apo = Get-ApoInfo
        if (-not $apo) { Say 'Equalizer APO non e'' installato: non c''e'' niente da rimuovere.' Green; Wait-End; exit 0 }
        $ConfigDir = $apo.ConfigPath
    }

    $backup = Backup-Config $ConfigDir
    if ($backup) { Say "Backup della configurazione: $backup" DarkGray }

    if (Test-Path (Join-Path $ConfigDir 'config.txt')) { Set-IncludeState $ConfigDir 'removed' }
    $preset = Join-Path $ConfigDir $script:PresetName
    if (Test-Path $preset) { Remove-Item $preset -Force }

    Say ''
    Say 'Footstep EQ rimosso. Le altre impostazioni di Equalizer APO sono rimaste com''erano.' Green
    Say 'Per togliere anche Equalizer APO: Impostazioni > App > App installate > Equalizer APO > Disinstalla.'
    Wait-End
} catch {
    Say "ERRORE: $($_.Exception.Message)" Red
    Wait-End; exit 1
}
