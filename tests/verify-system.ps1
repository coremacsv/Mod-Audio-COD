<#
  Controlla lo stato REALE del PC dopo un'installazione o una rimozione.
  Non modifica niente.

    powershell -ExecutionPolicy Bypass -File tests\verify-system.ps1 -Expect Installed
    powershell -ExecutionPolicy Bypass -File tests\verify-system.ps1 -Expect Removed
#>
param(
    [Parameter(Mandatory)][ValidateSet('Installed', 'Removed')][string]$Expect,
    [switch]$AllowPendingReboot
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'scripts\common.ps1')
. (Join-Path $root 'scripts\fx.ps1')

$pass = 0; $fail = 0
function Check([string]$Name, [scriptblock]$Test, [string]$Info = '') {
    try { $ok = [bool](& $Test) } catch { $ok = $false; $Info = $_.Exception.Message }
    if ($ok) { Write-Host "  [ OK ] $Name" -ForegroundColor Green; $script:pass++ }
    else     { Write-Host "  [ERR ] $Name $(if ($Info) { "-> $Info" })" -ForegroundColor Red; $script:fail++ }
}
function Active-Lines([string]$Text) { @($Text -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }) }

Write-Host "`n== Verifica del sistema: atteso '$Expect' ==" -ForegroundColor Cyan
$apo  = Get-ApoInfo
$devs = @(Get-ApoAllDevices)
$lo   = Get-ApoLeftovers

if ($Expect -eq 'Removed') {
    Check 'Equalizer APO non installato' { -not $apo }
    Check 'Nessun dispositivo con Equalizer APO' { $devs.Count -eq 0 } "$($devs.Count) trovati"
    Check 'Chiave HKLM\SOFTWARE\EqualizerAPO rimossa' { -not $lo.RegKey }
    Check 'Voce in "App installate" rimossa' { -not $lo.UninstKey }
    Check 'Registrazione COM di Equalizer APO rimossa' { -not $lo.Clsid }
    Check 'Nessuna cartella config rimasta nei percorsi standard' {
        -not (Test-Path (Join-Path $env:ProgramFiles 'EqualizerAPO\config'))
    }
    $bk = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Footstep EQ - backup'
    Check 'Backup dei preset presente in Documenti' { (Test-Path $bk) -and @(Get-ChildItem $bk -Directory).Count -ge 1 }
} else {
    Check 'Equalizer APO installato' { [bool]$apo }
    if ($apo) {
        $render = @($devs | Where-Object Flow -eq 'Render')
        Check 'Equalizer APO attivo su almeno un''uscita audio' { $render.Count -ge 1 }
        $cfgText = Read-Shared (Join-Path $apo.ConfigPath 'config.txt')
        $active  = Active-Lines $cfgText
        Check 'Preset incluso UNA sola volta' { @($active | Where-Object { $_ -match "^Include:\s*$([regex]::Escape($script:PresetName))$" }).Count -eq 1 }
        $dupes = @($active | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
        Check 'Nessuna riga duplicata in config.txt' { $dupes.Count -eq 0 } ($dupes -join ' | ')
        $sample = @($active | Where-Object { Test-ApoSampleLine $_ })
        Check 'Configurazione di esempio di Equalizer APO non attiva' { $sample.Count -eq 0 } ($sample -join ' | ')

        $presetPath = Join-Path $apo.ConfigPath $script:PresetName
        Check 'File del preset presente' { Test-Path $presetPath }
        if (Test-Path $presetPath) {
            $installed = Read-Shared $presetPath
            $template  = Get-Content (Join-Path $root "presets\$($script:PresetName)") -Raw -Encoding UTF8
            $norm = { param($t) Active-Lines $t | Where-Object { $_ -notmatch '^Device:' -and $_ -notmatch '\{\{' } }
            Check 'Preset IDENTICO a quello di riferimento (Preamp, Channel, 6 filtri)' { -not (Compare-Object @(& $norm $installed) @(& $norm $template)) }
            $devLine = @(Active-Lines $installed | Where-Object { $_ -match '^Device:' })
            Check 'Una sola riga Device nel preset' { $devLine.Count -eq 1 }
            Check 'Il preset punta alle uscite dove Equalizer APO è attivo' { $devLine[0] -eq (New-DeviceLine $render) } "$($devLine[0])"
            $flt = @(Get-PresetFilters $installed)
            Check 'Curva: bassi tagliati e zona passi alzata' { (Get-ResponseDb $flt 60) -lt -3 -and (Get-ResponseDb $flt 3000) -gt 3 }
        }
        $bdir = Join-Path $apo.ConfigPath 'footstep-eq-backup'
        Check 'Backup del config: al massimo 10' { -not (Test-Path $bdir) -or @(Get-ChildItem $bdir).Count -le 10 }
    }
}
Check 'Nessun file temporaneo dell''installer rimasto' { @(Get-ChildItem $env:TEMP -Directory -Filter 'footstep-eq-*' -ErrorAction SilentlyContinue).Count -eq 0 }

if ($Expect -eq 'Removed' -and $lo.PendingDll) { Write-Host '  [ !! ] Alcuni file di Equalizer APO verranno cancellati al prossimo riavvio' -ForegroundColor Yellow }
Write-Host ("`nRisultato: {0} OK, {1} ERRORI" -f $pass, $fail) -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })
exit $fail
