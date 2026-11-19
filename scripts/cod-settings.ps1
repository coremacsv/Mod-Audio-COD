# Impostazioni audio di Call of Duty / Warzone consigliate per il preset.
#
# Il gioco salva le impostazioni in file di testo nella cartella dell'utente:
#   %LOCALAPPDATA%\Activision\Call of Duty\players\s.1.0.codNN.txt           (sistema)
#   %LOCALAPPDATA%\Activision\Call of Duty\players\<id>\g*.codNN.*.l.txt     (profilo)
# Sono le stesse impostazioni del menu Audio: non sono file del gioco.
# Il programma cambia solo il VALORE delle voci elencate qui sotto, poi
# rilegge i file per verificare. Le voci che non sono nei file (es.
# Compensazione udito asimmetrico) vanno controllate a mano nel gioco.

$script:CodDefaultPlayersDir = Join-Path $env:LOCALAPPDATA 'Activision\Call of Duty\players'

# File: 's' = file di sistema, 'g' = file del profilo, 'sg' = entrambi, '' = solo a mano.
$script:CodAudioSettings = @(
    [pscustomobject]@{ Section = 'VOLUMI';            Label = 'Volume di gioco generale';                 Show = '80';                               Files = 'sg'; Key = 'Volume';                   Value = '0.800000' }
    [pscustomobject]@{ Section = 'VOLUMI';            Label = 'Volume musica in gioco';                   Show = '0';                                Files = 'sg'; Key = 'MusicVolume';              Value = '0.000000' }
    [pscustomobject]@{ Section = 'VOLUMI';            Label = 'Volume dialoghi';                          Show = '50';                               Files = 'sg'; Key = 'VoiceVolume';              Value = '0.500000' }
    [pscustomobject]@{ Section = 'VOLUMI';            Label = 'Volume effetti';                           Show = '100';                              Files = 'sg'; Key = 'EffectsVolume';            Value = '1.000000' }
    [pscustomobject]@{ Section = 'VOLUMI';            Label = 'Volume musica filmati';                    Show = '0';                                Files = 'sg'; Key = 'CinematicVolume';          Value = '0.000000' }
    [pscustomobject]@{ Section = 'DISPOSITIVO AUDIO'; Label = 'Dispositivo suoni del gioco altoparlanti/cuffie'; Show = 'Dispositivo sistema predefinito'; Files = 's'; Key = 'SoundOutputDevice'; Value = '' }
    [pscustomobject]@{ Section = 'DISPOSITIVO AUDIO'; Label = 'Uscita altoparlanti';                      Show = 'Stereo';                           Files = 's';  Key = 'AudioWantedChannelsNumber'; Value = '2' }
    [pscustomobject]@{ Section = 'DISPOSITIVO AUDIO'; Label = 'Modalità cuffie migliorata';               Show = 'No';                               Files = 'g';  Key = 'ImmerseSpatialAudio';      Value = 'false' }
    [pscustomobject]@{ Section = 'GLOBALE';           Label = 'Mix audio';                                Show = 'Cuffie';                           Files = 'g';  Key = 'AudioMixPreset';           Value = 'headphones_rex' }
    [pscustomobject]@{ Section = 'GLOBALE';           Label = 'Audio mono';                               Show = 'No';                               Files = 'g';  Key = 'MonoSound';                Value = 'false' }
    [pscustomobject]@{ Section = 'GLOBALE';           Label = 'Disattiva audio quando ridotto a icona';   Show = 'No';                               Files = 'g';  Key = 'MuteAudioWhileOutOfFocus'; Value = 'false' }
    [pscustomobject]@{ Section = 'GLOBALE';           Label = 'Disattiva musica su licenza';              Show = 'No';                               Files = 'g';  Key = 'MuteLicensedMusic';        Value = 'false' }
    [pscustomobject]@{ Section = 'GLOBALE';           Label = 'Compensazione udito asimmetrico';          Show = 'No';                               Files = '';   Key = '';                         Value = '' }
    [pscustomobject]@{ Section = 'FUNZIONALITÀ';      Label = 'Riduci audio acufene';                     Show = 'No';                               Files = 'g';  Key = 'AltShellShock';            Value = 'false' }
    [pscustomobject]@{ Section = 'FUNZIONALITÀ';      Label = 'Avvisi per colpi alla testa e uccisioni';  Show = 'Sì';                               Files = '';   Key = '';                         Value = '' }
)

# Trova i file di impostazioni della versione piu' recente del gioco.
function Find-CodSettingsFiles([string]$PlayersDir = $script:CodDefaultPlayersDir) {
    if (-not (Test-Path $PlayersDir)) { return $null }
    $sys = Get-ChildItem $PlayersDir -File -Filter 's.1.0.cod*.txt' -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match '^s\.1\.0\.cod(\d+)\.txt$' } |
           Sort-Object { [int]([regex]::Match($_.Name, 'cod(\d+)').Groups[1].Value) }, LastWriteTime -Descending |
           Select-Object -First 1
    if (-not $sys) { return $null }
    $ver = [regex]::Match($sys.Name, 'cod(\d+)').Groups[1].Value
    $prof = @(Get-ChildItem $PlayersDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem $_.FullName -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^g(\.p)?\.cod$ver\.[\d.]+\.l\.txt$" }
    })
    [pscustomobject]@{ Version = "cod$ver"; System = $sys.FullName; Profiles = @($prof | ForEach-Object FullName) }
}

# True se Call of Duty e' in esecuzione (salverebbe sopra le modifiche alla chiusura).
function Test-CodRunning {
    [bool](Get-Process -ErrorAction SilentlyContinue | Where-Object {
        ($_.Name -match '^(cod|cod\d+|BlackOps\w*|ModernWarfare\w*|Warzone\w*)$') -or ($_.Path -match '\\Call of Duty\\')
    })
}

# --- Compensazione udito asimmetrico --------------------------------------
# Non e' nei file di testo: e' nel file binario del profilo (g.codNN.1.0.b).
# Trovata confrontando il file con l'opzione su No e su Si': e' salvata come
#   7E 3A 97 94 00 98 E1 13 BD 01 01 <valore>    (00 = No, 01 = Si)
# Il programma la LEGGE soltanto: non modifica mai il file binario.
$script:CodHearingSignature = [byte[]](0x7E, 0x3A, 0x97, 0x94, 0x00, 0x98, 0xE1, 0x13, 0xBD, 0x01, 0x01)

function Find-ByteSequence([byte[]]$Bytes, [byte[]]$Seq) {
    $hits = New-Object Collections.Generic.List[int]
    for ($i = 0; $i -le $Bytes.Length - $Seq.Length - 1; $i++) {
        if ($Bytes[$i] -ne $Seq[0]) { continue }
        $ok = $true
        for ($j = 1; $j -lt $Seq.Length; $j++) { if ($Bytes[$i + $j] -ne $Seq[$j]) { $ok = $false; break } }
        if ($ok) { $hits.Add($i) }
    }
    , $hits.ToArray()
}

# Restituisce 'No', 'Si' o $null (non trovata) per ogni file binario del profilo.
function Get-CodHearingCompensation([string]$PlayersDir = $script:CodDefaultPlayersDir, [string]$Version) {
    if (-not (Test-Path $PlayersDir)) { return @() }
    $pattern = if ($Version) { "^g(\.p)?\.$Version\.[\d.]+\.b$" } else { '^g(\.p)?\.cod\d+\.[\d.]+\.b$' }
    Get-ChildItem $PlayersDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem $_.FullName -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $pattern -and $_.Name -notmatch '\.(l|pm)\.' }
    } | ForEach-Object {
        $bytes = [IO.File]::ReadAllBytes($_.FullName)
        $hits = Find-ByteSequence $bytes $script:CodHearingSignature
        $val = $null
        if ($hits.Count -eq 1) {
            switch ($bytes[$hits[0] + $script:CodHearingSignature.Length]) { 0 { $val = 'No' } 1 { $val = 'Si' } }
        }
        [pscustomobject]@{ File = $_.FullName; Value = $val }
    }
}

# Regex di una riga "Chiave@...=valore // commento".
function Get-CodLineRegex([string]$Key) { "(?m)^(?<pre>$([regex]::Escape($Key))@[^=\r\n]*=[ \t]*)(?<val>[^\r\n]*?)(?<post>[ \t]*//[^\r\n]*)?(?=\r?$)" }

function Get-CodValue([string]$Text, [string]$Key) {
    $m = [regex]::Match($Text, (Get-CodLineRegex $Key))
    if ($m.Success) { $m.Groups['val'].Value.Trim() } else { $null }
}

function Set-CodValue([string]$Text, [string]$Key, [string]$Value) {
    $rx = New-Object regex (Get-CodLineRegex $Key)
    $rx.Replace($Text, { param($m)
        $pre = $m.Groups['pre'].Value.TrimEnd() + $(if ($Value -ne '') { ' ' } else { '' })
        $pre + $Value + $m.Groups['post'].Value
    }.GetNewClosure(), 1)
}

function Test-CodValueEqual([string]$Actual, [string]$Want) {
    if ($null -eq $Actual) { return $false }
    $a = $Actual.Trim(); $w = $Want.Trim()
    $da = 0.0; $dw = 0.0
    $inv = [Globalization.CultureInfo]::InvariantCulture
    if ([double]::TryParse($a, [Globalization.NumberStyles]::Float, $inv, [ref]$da) -and
        [double]::TryParse($w, [Globalization.NumberStyles]::Float, $inv, [ref]$dw)) { return [Math]::Abs($da - $dw) -lt 0.0001 }
    $a -ieq $w
}

# Applica (se non -CheckOnly) e verifica. Restituisce una riga per voce con
# Status: OK (impostata e verificata), FAIL (non riuscita), MISSING (voce o
# file non trovati), MANUAL (non presente nei file: va fatta a mano).
function Invoke-CodAudioSetup([string]$PlayersDir = $script:CodDefaultPlayersDir, [switch]$CheckOnly) {
    $files = Find-CodSettingsFiles $PlayersDir
    $texts = @{}
    if ($files) {
        foreach ($f in @($files.System) + $files.Profiles) { $texts[$f] = [IO.File]::ReadAllText($f) }
    }
    $changed = @{}
    # Protezione per i test automatici: mai scrivere sulle vere impostazioni del gioco.
    if ($env:MODAUDIOCOD_TEST -eq '1' -and -not $CheckOnly -and $files -and
        ([IO.Path]::GetFullPath($PlayersDir).TrimEnd('\') -ieq [IO.Path]::GetFullPath($script:CodDefaultPlayersDir).TrimEnd('\'))) {
        throw 'TEST: scrittura sulle vere impostazioni di Warzone bloccata.'
    }
    if ($files -and -not $CheckOnly) {
        foreach ($s in $script:CodAudioSettings | Where-Object Files) {
            $targets = @()
            if ($s.Files -match 's') { $targets += $files.System }
            if ($s.Files -match 'g') { $targets += $files.Profiles }
            foreach ($f in $targets) {
                $cur = Get-CodValue $texts[$f] $s.Key
                if ($null -ne $cur -and -not (Test-CodValueEqual $cur $s.Value)) {
                    $texts[$f] = Set-CodValue $texts[$f] $s.Key $s.Value
                    $changed[$f] = $true
                }
            }
        }
        foreach ($f in $changed.Keys) {
            # Stessa codifica del file originale (UTF-8 senza BOM) e scrittura sicura:
            # prima su un file temporaneo, poi sostituzione.
            $tmp = "$f.modaudiocod-tmp"
            [IO.File]::WriteAllText($tmp, $texts[$f], (New-Object Text.UTF8Encoding($false)))
            Move-Item $tmp $f -Force
        }
    }

    # Verifica: rilegge i file dal disco.
    $fresh = @{}
    if ($files) { foreach ($f in $texts.Keys) { $fresh[$f] = [IO.File]::ReadAllText($f) } }
    $hearing = @(if ($files) { Get-CodHearingCompensation $PlayersDir $files.Version })
    foreach ($s in $script:CodAudioSettings) {
        $status = 'MANUAL'; $detail = ''
        if ($s.Label -like 'Compensazione udito*') {
            # Solo lettura: VERIFIED se su No, FAIL se attiva, MANUAL se non trovata.
            $known = @($hearing | Where-Object Value)
            if ($known.Count -gt 0 -and $known.Count -eq $hearing.Count) {
                if (@($known | Where-Object Value -eq 'Si').Count) { $status = 'FAIL'; $detail = 'ATTIVA: mettila su No nel gioco' }
                else { $status = 'VERIFIED' }
            }
        } elseif ($s.Files) {
            if (-not $files) { $status = 'MISSING'; $detail = 'file del gioco non trovati' }
            else {
                $targets = @()
                if ($s.Files -match 's') { $targets += $files.System }
                if ($s.Files -match 'g') { $targets += $files.Profiles }
                $vals = @($targets | ForEach-Object { Get-CodValue $fresh[$_] $s.Key } | Where-Object { $null -ne $_ })
                if ($vals.Count -eq 0) { $status = 'MISSING'; $detail = 'voce non trovata nei file' }
                elseif (@($vals | Where-Object { -not (Test-CodValueEqual $_ $s.Value) }).Count -gt 0) { $status = 'FAIL'; $detail = "valore attuale: $($vals -join ', ')" }
                else { $status = 'OK' }
            }
        }
        [pscustomobject]@{ Section = $s.Section; Label = $s.Label; Show = $s.Show; Status = $status; Detail = $detail }
    }
}
