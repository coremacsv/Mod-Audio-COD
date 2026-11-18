# Effetti grafici per la console in stile "terminale hacker".
# Sono solo effetti visivi: mostrano dati REALI (dispositivi trovati,
# avanzamento del download, hash, curva del preset).

$script:FxFast = $false   # true = niente animazioni (test automatici)

function Initialize-Fx([string]$Title = 'MOD AUDIO COD') {
    try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
    try {
        $Host.UI.RawUI.WindowTitle     = "$Title  ·  by Lozy"
        $Host.UI.RawUI.BackgroundColor = 'Black'
        $Host.UI.RawUI.ForegroundColor = 'Green'
    } catch {}
    if (-not $script:FxFast) { Clear-Host }
}

function Get-FxWidth {
    try { [Math]::Max(60, [Math]::Min(110, $Host.UI.RawUI.WindowSize.Width - 2)) } catch { 90 }
}

function Start-FxSleep([int]$Ms) { if (-not $script:FxFast -and $Ms -gt 0) { Start-Sleep -Milliseconds $Ms } }

# Testo scritto carattere per carattere.
function Write-Type([string]$Text, [string]$Color = 'Green', [int]$DelayMs = 8, [switch]$NoNewline) {
    if ($script:FxFast) { Write-Host $Text -ForegroundColor $Color -NoNewline:$NoNewline; return }
    foreach ($ch in $Text.ToCharArray()) { Write-Host $ch -ForegroundColor $Color -NoNewline; Start-Sleep -Milliseconds $DelayMs }
    if (-not $NoNewline) { Write-Host '' }
}

# Tema dei colori: 'install' (verde/ciano) o 'attack' (rosso, per il disinstallatore).
$script:Themes = @{
    install = @{ Text = 'Green'; Dim = 'DarkGreen'; Accent = 'Cyan';   Banner = 'Green'; Shadow = 'DarkGreen'; Matrix = @('DarkGreen', 'DarkGreen', 'Green') }
    attack  = @{ Text = 'Green'; Dim = 'DarkRed';   Accent = 'Red';    Banner = 'Red';   Shadow = 'DarkRed';   Matrix = @('DarkRed', 'Red', 'DarkGreen', 'DarkRed') }
}
$script:Theme = $script:Themes.install
function Set-FxTheme([ValidateSet('install', 'attack')][string]$Name) { $script:Theme = $script:Themes[$Name] }

# Pioggia di caratteri esadecimali.
function Show-Matrix([int]$Lines = 14) {
    if ($script:FxFast) { return }
    $w = Get-FxWidth
    $chars = '0123456789ABCDEF'.ToCharArray()
    $rnd = New-Object Random
    for ($i = 0; $i -lt $Lines; $i++) {
        $sb = New-Object Text.StringBuilder
        for ($j = 0; $j -lt $w; $j++) {
            if ($rnd.Next(100) -lt 55) { [void]$sb.Append($chars[$rnd.Next($chars.Length)]) } else { [void]$sb.Append(' ') }
        }
        $pal = $script:Theme.Matrix
        Write-Host $sb.ToString() -ForegroundColor $pal[$rnd.Next($pal.Count)]
        Start-Sleep -Milliseconds 35
    }
    Clear-Host
}

# Lettere giganti (font "ANSI Shadow").
$script:Glyphs = @{
    'M' = @('███╗   ███╗', '████╗ ████║', '██╔████╔██║', '██║╚██╔╝██║', '██║ ╚═╝ ██║', '╚═╝     ╚═╝')
    'O' = @(' ██████╗ ', '██╔═══██╗', '██║   ██║', '██║   ██║', '╚██████╔╝', ' ╚═════╝ ')
    'D' = @('██████╗ ', '██╔══██╗', '██║  ██║', '██║  ██║', '██████╔╝', '╚═════╝ ')
    'A' = @(' █████╗ ', '██╔══██╗', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝')
    'U' = @('██╗   ██╗', '██║   ██║', '██║   ██║', '██║   ██║', '╚██████╔╝', ' ╚═════╝ ')
    'I' = @('██╗', '██║', '██║', '██║', '██║', '╚═╝')
    'C' = @(' ██████╗', '██╔════╝', '██║     ', '██║     ', '╚██████╗', ' ╚═════╝')
    ' ' = @('   ', '   ', '   ', '   ', '   ', '   ')
}
function Get-BigText([string]$Text) {
    0..5 | ForEach-Object {
        $row = $_
        -join ($Text.ToUpper().ToCharArray() | ForEach-Object { $script:Glyphs[[string]$_][$row] })
    }
}

function Show-Banner([string]$Title = 'MOD AUDIO COD',
                     [string]$Subtitle = 'A U D I O   O V E R R I D E   T O O L K I T',
                     [string]$Tagline = 'per Call of Duty: Warzone  ·  non modifica i file di gioco  ·  open source') {
    Write-Host ''
    Write-Host '  ' -NoNewline
    Write-Host ' by ' -NoNewline -ForegroundColor Black -BackgroundColor Magenta
    Write-Host ' Lozy ' -NoNewline -ForegroundColor White -BackgroundColor DarkMagenta
    Write-Type '  ░▒▓ release v1.0' DarkMagenta 6
    Write-Host ''
    foreach ($l in (Get-BigText $Title)) {
        # I bordi (╗║╝═╚╔) in colore scuro, i blocchi pieni nel colore del tema.
        Write-Host '  ' -NoNewline
        foreach ($ch in $l.ToCharArray()) {
            Write-Host $ch -NoNewline -ForegroundColor $(if ($ch -eq '█') { $script:Theme.Banner } else { $script:Theme.Shadow })
        }
        Write-Host ''
        Start-FxSleep 40
    }
    Write-Host ''
    Write-Type "   ▓▒░  $Subtitle  ░▒▓" $script:Theme.Accent 4
    Write-Host "   $Tagline" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ('   ' + ('═' * ((Get-FxWidth) - 6))) -ForegroundColor $script:Theme.Dim
    Write-Host ''
}

# Riga di stato: [ TAG ] testo .......... RISULTATO
function Write-Status([string]$Tag, [string]$Text, [string]$Result = '', [string]$ResultColor = 'Green') {
    $tagColor = switch ($Tag) { 'OK' { 'Green' } 'ERR' { 'Red' } '!!' { 'Yellow' } '>>' { $script:Theme.Accent } 'XX' { 'Red' } default { $script:Theme.Dim } }
    Write-Host '  [' -NoNewline -ForegroundColor DarkGray
    Write-Host ($Tag.PadLeft(2).PadRight(3)) -NoNewline -ForegroundColor $tagColor
    Write-Host '] ' -NoNewline -ForegroundColor DarkGray
    if ($Result) {
        $w = Get-FxWidth
        $dots = [Math]::Max(3, $w - 10 - $Text.Length - $Result.Length)
        Write-Type $Text $script:Theme.Text 6 -NoNewline
        Write-Host (' ' + ('.' * $dots) + ' ') -NoNewline -ForegroundColor $script:Theme.Dim
        Write-Host $Result -ForegroundColor $ResultColor
    } else {
        Write-Type $Text $script:Theme.Text 6
    }
}

function Write-Section([string]$Title) {
    Write-Host ''
    Write-Host "  ┌─[ $Title ]" -ForegroundColor $script:Theme.Accent
    Start-FxSleep 120
}

# Raffica di righe "da attacco hacker". SOLO SCENOGRAFIA: non fa niente,
# serve a dare l'effetto al disinstallatore. Le azioni vere sono quelle [OK].
function Show-Breach([int]$Count = 8) {
    $rnd = New-Object Random
    $hex = { param($n) -join (1..$n | ForEach-Object { '0123456789ABCDEF'[$rnd.Next(16)] }) }
    $lines = @(
        @('XX', 'Red',       { "INTRUSIONE NEL SOTTOSISTEMA AUDIO · PID $($rnd.Next(1000, 9999))" }),
        @('>>', 'DarkRed',   { "bypass firewall DSP ........ 0x$(& $hex 8)" }),
        @('!!', 'Yellow',    { "ACCESSO ROOT CONCESSO · sessione $(& $hex 4)-$(& $hex 4)" }),
        @('XX', 'Red',       { "iniezione payload di rimozione → 0x$(& $hex 8)" }),
        @('>>', 'DarkGray',  { "dump audiodg.exe @0x$(& $hex 8): $((1..8 | ForEach-Object { & $hex 2 }) -join ' ')" }),
        @('XX', 'Red',       { "aggancio hook APO {EACD2258-FCAC-4FF4-B36D-419E924A6D79}" }),
        @('!!', 'Yellow',    { "CANALE 7.1 COMPROMESSO · sovrascrittura buffer $($rnd.Next(64, 512)) KB" }),
        @('>>', 'DarkRed',   { "decrittazione chiave di registro ▓▓▓▓▓▓▓▒▒░ $(& $hex 6)" }),
        @('XX', 'Red',       { "neutralizzazione filtri EQ: $($rnd.Next(4, 12)) bersagli agganciati" }),
        @('>>', 'DarkGreen', { "tunnel crittografato aperto · $(& $hex 2):$(& $hex 2):$(& $hex 2):$(& $hex 2)" })
    )
    for ($i = 0; $i -lt $Count; $i++) {
        $l = $lines[$rnd.Next($lines.Count)]
        Write-Host '  [' -NoNewline -ForegroundColor DarkGray
        Write-Host ($l[0].PadLeft(2).PadRight(3)) -NoNewline -ForegroundColor $l[1]
        Write-Host '] ' -NoNewline -ForegroundColor DarkGray
        Write-Host (& $l[2]) -ForegroundColor $(if ($l[1] -eq 'Yellow') { 'Yellow' } elseif ($i % 3 -eq 0) { 'Red' } else { 'DarkRed' })
        Start-FxSleep (40 + $rnd.Next(80))
    }
}

# Scritta che "sfarfalla" tra rosso e bianco.
function Write-Glitch([string]$Text) {
    if ($script:FxFast) { Write-Host "  $Text" -ForegroundColor Red; return }
    foreach ($c in 'Red', 'White', 'DarkRed', 'Red', 'Yellow', 'Red') {
        Write-Host "`r  $Text" -NoNewline -ForegroundColor $c
        Start-Sleep -Milliseconds 70
    }
    Write-Host ''
}
# Barra di avanzamento su una sola riga (si sovrascrive).
function Write-Bar([int]$Percent, [string]$Label = '') {
    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))
    $len = 36
    $full = [int]($len * $Percent / 100)
    $bar = ('█' * $full) + ('░' * ($len - $full))
    Write-Host ("`r  [>>] [{0}] {1,3}%  {2}   " -f $bar, $Percent, $Label) -NoNewline -ForegroundColor Cyan
}

$script:SpinFrames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$script:SpinIndex = 0
function Write-Spin([string]$Text) {
    $script:SpinIndex = ($script:SpinIndex + 1) % $script:SpinFrames.Count
    Write-Host ("`r  [{0} ] {1}   " -f $script:SpinFrames[$script:SpinIndex], $Text) -NoNewline -ForegroundColor Yellow
}
function Stop-Spin([string]$Text, [string]$Result = 'FATTO', [string]$Color = 'Green') {
    Write-Host ("`r" + (' ' * ((Get-FxWidth) - 1)) + "`r") -NoNewline
    Write-Status 'OK' $Text $Result $Color
}

# ---------------------------------------------------------------------------
#  Curva di risposta del preset (calcolata davvero dai filtri del file).
# ---------------------------------------------------------------------------
function Get-BiquadDb([string]$Type, [double]$F0, [double]$GainDb, [double]$Q, [double]$F, [double]$Fs = 48000) {
    $A = [Math]::Pow(10, $GainDb / 40); $w0 = 2 * [Math]::PI * $F0 / $Fs
    $cs = [Math]::Cos($w0); $alpha = [Math]::Sin($w0) / (2 * $Q); $sa = 2 * [Math]::Sqrt($A) * $alpha
    switch ($Type) {
        'PK'  { $b0 = 1 + $alpha * $A; $b1 = -2 * $cs; $b2 = 1 - $alpha * $A; $a0 = 1 + $alpha / $A; $a1 = -2 * $cs; $a2 = 1 - $alpha / $A }
        'LSC' { $b0 = $A * (($A + 1) - ($A - 1) * $cs + $sa); $b1 = 2 * $A * (($A - 1) - ($A + 1) * $cs); $b2 = $A * (($A + 1) - ($A - 1) * $cs - $sa)
                $a0 = ($A + 1) + ($A - 1) * $cs + $sa; $a1 = -2 * (($A - 1) + ($A + 1) * $cs); $a2 = ($A + 1) + ($A - 1) * $cs - $sa }
        'HSC' { $b0 = $A * (($A + 1) + ($A - 1) * $cs + $sa); $b1 = -2 * $A * (($A - 1) + ($A + 1) * $cs); $b2 = $A * (($A + 1) + ($A - 1) * $cs - $sa)
                $a0 = ($A + 1) - ($A - 1) * $cs + $sa; $a1 = 2 * (($A - 1) - ($A + 1) * $cs); $a2 = ($A + 1) - ($A - 1) * $cs - $sa }
        default { return 0 }
    }
    $w = 2 * [Math]::PI * $F / $Fs
    $nr = $b0 + $b1 * [Math]::Cos($w) + $b2 * [Math]::Cos(2 * $w); $ni = -($b1 * [Math]::Sin($w) + $b2 * [Math]::Sin(2 * $w))
    $dr = $a0 + $a1 * [Math]::Cos($w) + $a2 * [Math]::Cos(2 * $w); $di = -($a1 * [Math]::Sin($w) + $a2 * [Math]::Sin(2 * $w))
    10 * [Math]::Log10(($nr * $nr + $ni * $ni) / ($dr * $dr + $di * $di))
}

function Get-PresetFilters([string]$PresetText) {
    [regex]::Matches($PresetText, '(?m)^\s*Filter:\s*ON\s+(PK|LSC|HSC)\s+Fc\s+([\d.]+)\s*Hz\s+Gain\s+(-?[\d.]+)\s*dB\s+Q\s+([\d.]+)') | ForEach-Object {
        [pscustomobject]@{
            Type = $_.Groups[1].Value
            F0   = [double]::Parse($_.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
            Gain = [double]::Parse($_.Groups[3].Value, [Globalization.CultureInfo]::InvariantCulture)
            Q    = [double]::Parse($_.Groups[4].Value, [Globalization.CultureInfo]::InvariantCulture)
        }
    }
}

function Get-ResponseDb($Filters, [double]$F) {
    $sum = 0.0
    foreach ($flt in $Filters) { $sum += Get-BiquadDb $flt.Type $flt.F0 $flt.Gain $flt.Q $F }
    $sum
}

function Show-EqCurve([string]$PresetText) {
    $filters = @(Get-PresetFilters $PresetText)
    if ($filters.Count -eq 0) { return }
    $cols = 48
    $freqs = 0..($cols - 1) | ForEach-Object { 20 * [Math]::Pow(1000, $_ / ($cols - 1)) }   # 20 Hz -> 20 kHz
    $gains = $freqs | ForEach-Object { Get-ResponseDb $filters $_ }
    $rows = @(6, 4, 2, 0, -2, -4, -6)
    Write-Host ''
    Write-Host '        CURVA EQ APPLICATA (dB)' -ForegroundColor Cyan
    foreach ($r in $rows) {
        $line = New-Object Text.StringBuilder
        foreach ($g in $gains) {
            if ($r -eq 0)                    { [void]$line.Append('━') }
            elseif ($r -gt 0 -and $g -ge $r - 1) { [void]$line.Append('█') }
            elseif ($r -lt 0 -and $g -le $r + 1) { [void]$line.Append('█') }
            else                             { [void]$line.Append(' ') }
        }
        $color = if ($r -gt 0) { 'Green' } elseif ($r -lt 0) { 'Magenta' } else { 'DarkGray' }
        Write-Host ('   {0,3} │' -f $r) -NoNewline -ForegroundColor DarkGray
        Write-Host $line.ToString() -ForegroundColor $color
        Start-FxSleep 60
    }
    Write-Host '       └' -NoNewline -ForegroundColor DarkGray
    Write-Host ('─' * $cols) -ForegroundColor DarkGray
    Write-Host '        20Hz      BASSI         MEDI          PASSI      ACUTI 20kHz' -ForegroundColor DarkGray
    Write-Host '                 (esplosioni ↓)              (passi ↑)' -ForegroundColor DarkGray
}
