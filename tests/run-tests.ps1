<#
  Test automatici di Mod Audio COD. Non modificano il sistema: lavorano in una
  cartella temporanea e non scaricano niente da Internet.
    powershell -ExecutionPolicy Bypass -File tests\run-tests.ps1
#>
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $root 'scripts'
. (Join-Path $scripts 'common.ps1')
. (Join-Path $scripts 'fx.ps1')
$script:FxFast = $true

$pass = 0; $fail = 0
function Check([string]$Name, [scriptblock]$Test) {
    try {
        $r = & $Test
        if ($r -eq $false) { throw 'condizione falsa' }
        Write-Host "  [PASS] $Name" -ForegroundColor Green; $script:pass++
    } catch {
        Write-Host "  [FAIL] $Name -> $($_.Exception.Message)" -ForegroundColor Red; $script:fail++
    }
}
function New-Sandbox([string]$ConfigText) {
    $d = Join-Path $env:TEMP ('fseq-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory $d | Out-Null
    if ($null -ne $ConfigText) { [IO.File]::WriteAllText((Join-Path $d 'config.txt'), $ConfigText) }
    $d
}
function Run([string]$Script, [string]$Dir) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts $Script) -ConfigDir $Dir -NoPause -Fast 2>&1 | Out-String
    [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
}
function Cfg([string]$Dir) { [IO.File]::ReadAllText((Join-Path $Dir 'config.txt')) }
function CountLines([string]$Text, [string]$Pattern) { @([regex]::Matches($Text, $Pattern)).Count }

Write-Host "`n== Sintassi e codifica ==" -ForegroundColor Cyan
Get-ChildItem $scripts -Filter *.ps1 | ForEach-Object {
    $f = $_
    Check "sintassi $($f.Name)" { $e = $null; [void][Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$e); $e.Count -eq 0 }
    Check "BOM UTF-8 $($f.Name)" { $b = [IO.File]::ReadAllBytes($f.FullName); $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF }
}
Get-ChildItem $root -Filter *.bat | ForEach-Object { $f = $_; Check "CRLF $($f.Name)" { [IO.File]::ReadAllText($f.FullName) -notmatch "[^\r]\n" } }
Check 'hash Equalizer APO compilato' { $script:ApoSha256 -match '^[0-9A-F]{64}$' }

Write-Host "`n== Funzioni del config ==" -ForegroundColor Cyan
Check 'stato: missing / active / disabled' {
    (Get-IncludeState "a`r`nb") -eq 'missing' -and
    (Get-IncludeState "x`r`nInclude: warzone_passi.txt`r`n") -eq 'active' -and
    (Get-IncludeState "x`n#Include: warzone_passi.txt") -eq 'disabled'
}
Check 'riga Device nel formato di Equalizer APO' {
    (New-DeviceLine @([pscustomobject]@{ Device = 'Realtek(R) Audio'; Connection = 'Altoparlanti'; Guid = '{abc}' },
                      [pscustomobject]@{ Device = 'USB'; Connection = 'Cuffie'; Guid = '{def}' })) -eq
    'Device: Realtek(R) Audio Altoparlanti {abc}; USB Cuffie {def}'
}

Write-Host "`n== Configurazione di esempio di Equalizer APO ==" -ForegroundColor Cyan
$sample = "Preamp: -6 dB`r`nInclude: example.txt`r`nGraphicEQ: 25 0; 40 0; 63 0; 100 0; 160 0; 250 0; 400 0; 630 0; 1000 0; 1600 0; 2500 0; 4000 0; 6300 0; 10000 0; 16000 0`r`n"
$s1 = New-Sandbox $sample
Check 'config di esempio: viene disattivato' { Disable-ApoSampleConfig $s1 }
Check 'config di esempio: nessuna riga attiva rimasta' { @((Cfg $s1) -split "\r?\n" | Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') }).Count -eq 0 }
Check 'config di esempio: righe conservate come commento' { (Cfg $s1) -match '#.*Include: example\.txt' }
$s2 = New-Sandbox "Preamp: -6 dB`r`nInclude: mio_preset.txt`r`n"
Check 'config personalizzato con Preamp -6: NON toccato' { -not (Disable-ApoSampleConfig $s2) -and (Cfg $s2) -match '(?m)^Preamp: -6 dB' }
$s3 = New-Sandbox ($sample + "Include: warzone_passi.txt`r`n")
Check 'config di esempio + nostro preset: disattiva solo l''esempio' { (Disable-ApoSampleConfig $s3) -and (Get-IncludeState (Cfg $s3)) -eq 'active' }
Check 'GraphicEQ non piatto: NON toccato' { -not (Disable-ApoSampleConfig (New-Sandbox "GraphicEQ: 25 3; 40 0")) }

Write-Host "`n== Install / toggle / uninstall (sandbox) ==" -ForegroundColor Cyan
$orig = "# commento utente`r`nInclude: altro_preset.txt`r`nPreamp: -3 dB`r`n"
$sb = New-Sandbox $orig
$devs = @(Get-ApoPlaybackDevices)
if ($devs.Count -eq 0) {
    Write-Host '  [SKIP] nessuna uscita con Equalizer APO su questo PC: test di installazione saltati' -ForegroundColor Yellow
} else {
    $r = Run 'install.ps1' $sb
    Check 'install: esce con codice 0' { $r.Code -eq 0 }
    Check 'install: riga Include aggiunta una volta' { (CountLines (Cfg $sb) '(?m)^Include: warzone_passi\.txt\s*$') -eq 1 }
    Check 'install: avvisa degli altri preset attivi' { $r.Out -match 'Altro preset attivo: altro_preset\.txt' }
    Check 'install: righe utente conservate' { $c = Cfg $sb; $c.Contains('# commento utente') -and $c.Contains('Include: altro_preset.txt') -and $c.Contains('Preamp: -3 dB') }
    Check 'install: preset con riga Device reale' { (Get-Content (Join-Path $sb 'warzone_passi.txt') -Raw) -match '(?m)^Device: .+\{[0-9a-f-]{36}\}' }
    Check 'install: nessun segnaposto rimasto' { -not (Get-Content (Join-Path $sb 'warzone_passi.txt') -Raw).Contains('{{') }
    Check 'install: backup creato' { @(Get-ChildItem (Join-Path $sb 'footstep-eq-backup')).Count -ge 1 }
    $r = Run 'install.ps1' $sb
    Check 'install x2: nessun duplicato' { (CountLines (Cfg $sb) 'warzone_passi\.txt') -eq 1 }
    1..12 | ForEach-Object { [void](Backup-Config $sb) }
    Check 'backup: ne tiene al massimo 10' { @(Get-ChildItem (Join-Path $sb 'footstep-eq-backup')).Count -eq 10 }
    Set-IncludeState $sb 'removed'
    Check 'togliendo la riga del preset il config torna identico all''originale' { (Cfg $sb).Trim() -eq $orig.Trim() }

    $sb2 = New-Sandbox $null
    $r = Run 'install.ps1' $sb2
    Check 'install senza config.txt: lo crea' { $r.Code -eq 0 -and (Get-IncludeState (Cfg $sb2)) -eq 'active' }
    $sb3 = New-Sandbox "Include: a.txt`nInclude: b.txt"
    [void](Run 'install.ps1' $sb3)
    Check 'config con fine riga LF: righe conservate' { $c = Cfg $sb3; $c.Contains('Include: a.txt') -and $c.Contains('Include: b.txt') -and (Get-IncludeState $c) -eq 'active' }
}

Write-Host "`n== Rimozione di Equalizer APO (solo prova, nessuna modifica) ==" -ForegroundColor Cyan
$bkSrc = New-Sandbox "Include: x.txt"
New-Item -ItemType Directory (Join-Path $bkSrc 'sub') | Out-Null
[IO.File]::WriteAllText((Join-Path $bkSrc 'sub\preset.txt'), 'ciao')
$bkRoot = New-Sandbox $null
$bkDest = Backup-ConfigFolder $bkSrc $bkRoot
Check 'backup cartella config: copia completa' { (Test-Path (Join-Path $bkDest 'config.txt')) -and (Test-Path (Join-Path $bkDest 'sub\preset.txt')) }
$fakeDir = New-Sandbox $null
[IO.File]::WriteAllText((Join-Path $fakeDir 'altro-programma.exe'), 'x')
Check 'cartella condivisa senza programmi APO: NON installato' { -not (Test-ApoInstallDir $fakeDir) }
[IO.File]::WriteAllText((Join-Path $fakeDir 'EqualizerAPO.dll'), 'x')
Check 'solo EqualizerAPO.dll in attesa di riavvio: NON installato' { -not (Test-ApoInstallDir $fakeDir) }
[IO.File]::WriteAllText((Join-Path $fakeDir 'DeviceSelector.exe'), 'x')
Check 'con DeviceSelector.exe: installato' { Test-ApoInstallDir $fakeDir }
Check 'cartella inesistente: NON installato' { -not (Test-ApoInstallDir (Join-Path $fakeDir 'non-esiste')) }

$apoNow = Get-ApoInfo
if (-not $apoNow -and (Get-ApoLeftovers).RegKey) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'remove-apo.ps1') -DryRun -NoPause -Fast 2>&1 | Out-String
    Check 'residui (prova): propone di cancellare la chiave rimasta' { $LASTEXITCODE -eq 0 -and $out -match 'Cancellerei la chiave di registro' }
    Check 'residui (prova): chiave non toccata' { (Get-ApoLeftovers).RegKey }
}
if ($apoNow) {
    $cfgBefore = Read-Shared (Join-Path $apoNow.ConfigPath 'config.txt')
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'remove-apo.ps1') -DryRun -NoPause -Fast 2>&1 | Out-String
    Check 'rimozione (prova): esce con codice 0' { $LASTEXITCODE -eq 0 }
    Check 'rimozione (prova): usa il disinstallatore ufficiale con /S e _?=' { $out -match 'Uninstall\.exe /S _\?=' }
    Check 'rimozione (prova): Equalizer APO ancora installato' { [bool](Get-ApoInfo) }
    Check 'rimozione (prova): config non toccato' { (Read-Shared (Join-Path $apoNow.ConfigPath 'config.txt')) -eq $cfgBefore }
} else {
    Write-Host '  [SKIP] Equalizer APO non installato: prova di rimozione saltata' -ForegroundColor Yellow
}

Write-Host "`n== Download verificato (file locale, niente Internet) ==" -ForegroundColor Cyan
$src = Join-Path (New-Sandbox $null) 'finto-installer.exe'
[IO.File]::WriteAllBytes($src, [byte[]](1..200))
$goodHash = (Get-FileHash $src -Algorithm SHA256).Hash
$uri = ([Uri]$src).AbsoluteUri
$d1 = Join-Path (New-Sandbox $null) 'ok.exe'
Check 'hash corretto: file accettato' { (Save-VerifiedFile $uri $d1 $goodHash 200) -and (Test-Path $d1) }
$d2 = Join-Path (New-Sandbox $null) 'ko.exe'
Check 'hash sbagliato: file rifiutato e cancellato' { -not (Save-VerifiedFile $uri $d2 ('0' * 64) 200) -and -not (Test-Path $d2) }
$d3 = Join-Path (New-Sandbox $null) 'nohash.exe'
Check 'hash vuoto: niente download' { -not (Save-VerifiedFile $uri $d3 '' 200) -and -not (Test-Path $d3) }
$d4 = Join-Path (New-Sandbox $null) 'missing.exe'
Check 'URL inesistente: gestito' { -not (Save-VerifiedFile (([Uri](Join-Path $env:TEMP 'non-esiste-xyz.exe')).AbsoluteUri) $d4 $goodHash 200) }

Write-Host "`n== Curva EQ ==" -ForegroundColor Cyan
$presetText = Get-Content (Join-Path $root 'presets\warzone_passi.txt') -Raw
$flt = @(Get-PresetFilters $presetText)
Check 'filtri letti dal preset (6)' { $flt.Count -eq 6 }
Check 'bassi tagliati (60 Hz < -3 dB)' { (Get-ResponseDb $flt 60) -lt -3 }
Check 'zona passi alzata (3 kHz > +3 dB)' { (Get-ResponseDb $flt 3000) -gt 3 }
Check 'filtro neutro = 0 dB' { [Math]::Abs((Get-BiquadDb 'PK' 1000 0 1 1000)) -lt 0.001 }
Check 'picco +4 dB alla sua frequenza' { [Math]::Abs((Get-BiquadDb 'PK' 2500 4 1.2 2500) - 4) -lt 0.05 }

Get-ChildItem $env:TEMP -Directory -Filter 'fseq-test-*' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ("`nRisultato: {0} superati, {1} falliti" -f $pass, $fail) -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })
exit $fail
