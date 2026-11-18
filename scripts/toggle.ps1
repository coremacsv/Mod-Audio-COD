<#
  Footstep EQ for Warzone - accende/spegne il preset (effetto immediato).
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
        if (-not $apo) { Say 'Equalizer APO non e'' installato. Esegui prima Installa.bat.' Yellow; Wait-End; exit 1 }
        $ConfigDir = $apo.ConfigPath
    }
    if (-not (Test-Path (Join-Path $ConfigDir $script:PresetName))) {
        Say 'Il preset non e'' installato. Esegui prima Installa.bat.' Yellow; Wait-End; exit 1
    }

    $state = Get-IncludeState (Read-Shared (Join-Path $ConfigDir 'config.txt'))
    if ($state -eq 'active') {
        Set-IncludeState $ConfigDir 'disabled'
        Say ''; Say '  Footstep EQ: SPENTO' Yellow
    } else {
        Set-IncludeState $ConfigDir 'active'
        Say ''; Say '  Footstep EQ: ACCESO' Green
    }
    if ($NoPause) { return }
    Start-Sleep -Seconds 3
} catch {
    Say "ERRORE: $($_.Exception.Message)" Red
    Wait-End; exit 1
}
