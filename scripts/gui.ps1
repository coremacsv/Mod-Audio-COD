# Finestra-guida sempre in primo piano che spiega all'utente cosa fare
# a ogni passaggio e si aggiorna/chiude da sola.
# Gli script sono salvati in UTF-8 con BOM, cosi' Windows PowerShell 5.1
# legge correttamente le lettere accentate.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Guide = $null

function Show-Guide {
    if ($script:Guide) { return }
    $f = New-Object System.Windows.Forms.Form
    $f.Text            = 'Mod Audio COD by Lozy - Guida'
    $f.Size            = New-Object System.Drawing.Size(460, 300)
    $f.FormBorderStyle = 'FixedToolWindow'
    $f.TopMost         = $true
    $f.ShowInTaskbar   = $true
    $f.StartPosition   = 'Manual'
    $f.BackColor       = [System.Drawing.Color]::FromArgb(24, 26, 32)
    $f.ControlBox      = $false
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $f.Location = New-Object System.Drawing.Point(($wa.Right - $f.Width - 20), ($wa.Bottom - $f.Height - 20))

    $step = New-Object System.Windows.Forms.Label
    $step.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
    $step.ForeColor = [System.Drawing.Color]::FromArgb(140, 150, 170)
    $step.Location  = New-Object System.Drawing.Point(18, 14)
    $step.AutoSize  = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 14)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(120, 200, 255)
    $title.Location  = New-Object System.Drawing.Point(16, 34)
    $title.Size      = New-Object System.Drawing.Size(420, 32)

    $body = New-Object System.Windows.Forms.Label
    $body.Font      = New-Object System.Drawing.Font('Segoe UI', 10.5)
    $body.ForeColor = [System.Drawing.Color]::White
    $body.Location  = New-Object System.Drawing.Point(18, 72)
    $body.Size      = New-Object System.Drawing.Size(420, 150)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(18, 228)
    $bar.Size     = New-Object System.Drawing.Size(410, 14)
    $bar.Visible  = $false

    $f.Controls.AddRange(@($step, $title, $body, $bar))
    $f.Show()
    $script:Guide = @{ Form = $f; Step = $step; Title = $title; Body = $body; Bar = $bar }
    Update-Guide
}

function Update-Guide { [System.Windows.Forms.Application]::DoEvents() }

function Set-GuideStep([string]$Title, [string]$Body, [string]$StepText = '') {
    if (-not $script:Guide) { Show-Guide }
    $script:Guide.Step.Text  = $StepText
    $script:Guide.Title.Text = $Title
    $script:Guide.Body.Text  = $Body
    $script:Guide.Bar.Visible = $false
    $script:Guide.Form.TopMost = $true
    Update-Guide
}

function Set-GuideProgress([int]$Percent) {
    if (-not $script:Guide) { return }
    $script:Guide.Bar.Visible = $true
    $script:Guide.Bar.Value = [Math]::Max(0, [Math]::Min(100, $Percent))
    Update-Guide
}

function Close-Guide {
    if ($script:Guide) { $script:Guide.Form.Close(); $script:Guide.Form.Dispose(); $script:Guide = $null }
}

# Attende finche' $Condition restituisce $true, mantenendo viva la guida.
# $Tick viene eseguito a ogni giro (es. spinner in console).
function Wait-Until([scriptblock]$Condition, [int]$TimeoutSec = 0, [scriptblock]$Tick = $null) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (& $Condition)) {
        Update-Guide
        if ($Tick) { & $Tick }
        Start-Sleep -Milliseconds 120
        if ($TimeoutSec -gt 0 -and $sw.Elapsed.TotalSeconds -ge $TimeoutSec) { return $false }
    }
    $true
}

function Ask-YesNo([string]$Text, [string]$Caption = 'Mod Audio COD', [switch]$DefaultNo) {
    $owner = if ($script:Guide) { $script:Guide.Form } else { $null }
    $def = if ($DefaultNo) { 'Button2' } else { 'Button1' }
    [System.Windows.Forms.MessageBox]::Show($owner, $Text, $Caption, 'YesNo', 'Question', $def) -eq 'Yes'
}

# Schermata "Impostazioni audio di Warzone" in stile menu del gioco.
# $Rows: output di Invoke-CodAudioSetup. $Mode: 'applied' | 'manual' | 'running'.
function Show-CodSettingsCard($Rows, [string]$Mode = 'applied') {
    $bg      = [Drawing.Color]::FromArgb(14, 15, 16)
    $rowBg   = [Drawing.Color]::FromArgb(30, 31, 33)
    $rowWarn = [Drawing.Color]::FromArgb(58, 30, 30)
    $txt     = [Drawing.Color]::FromArgb(214, 214, 214)
    $dim     = [Drawing.Color]::FromArgb(140, 140, 140)
    $teal    = [Drawing.Color]::FromArgb(38, 166, 178)
    $fam     = if ([Drawing.FontFamily]::Families.Name -contains 'Bahnschrift') { 'Bahnschrift' } else { 'Segoe UI' }

    $f = New-Object Windows.Forms.Form
    $f.Text = 'Mod Audio COD by Lozy - Impostazioni audio di Warzone'
    $f.BackColor = $bg; $f.StartPosition = 'CenterScreen'; $f.TopMost = $true
    $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
    $wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $f.ClientSize = New-Object Drawing.Size(820, [Math]::Min(940, $wa.Height - 60))

    $okCount  = @($Rows | Where-Object Status -eq 'OK').Count
    $failRows = @($Rows | Where-Object { $_.Status -in 'FAIL', 'MISSING' })
    $rowAmber = [Drawing.Color]::FromArgb(56, 44, 18)
    $amber    = [Drawing.Color]::FromArgb(255, 200, 80)
    $red      = [Drawing.Color]::FromArgb(255, 110, 100)
    $subVolumes = @('Volume musica in gioco', 'Volume dialoghi', 'Volume effetti', 'Volume musica filmati')
    $headline = switch ($Mode) {
        'running' { 'Warzone è aperto: imposta queste voci a mano nel gioco.' }
        'manual'  { 'File di Warzone non trovati (normale con Xbox app): imposta queste voci a mano.' }
        default   { if ($failRows.Count) { "Ho impostato $okCount voci. Quelle in ROSSO vanno cambiate a mano nel gioco." } else { "✓ Ho impostato e verificato $okCount voci. Controlla nel gioco quelle con ⚠." } }
    }

    # --- Intestazione: si capisce subito che sono le impostazioni di Warzone ---
    $title = New-Object Windows.Forms.Label
    $title.Text = 'IMPOSTAZIONI DI CALL OF DUTY: WARZONE'; $title.ForeColor = [Drawing.Color]::White
    $title.Font = New-Object Drawing.Font($fam, 17, [Drawing.FontStyle]::Bold)
    $title.Location = New-Object Drawing.Point(24, 12); $title.Size = New-Object Drawing.Size(772, 32)
    $where = New-Object Windows.Forms.Label
    $where.Text = 'Dove: nel gioco apri  Impostazioni  ›  Audio  (scheda AUDIO).   Le voci devono essere esattamente così.'
    $where.ForeColor = $dim; $where.Font = New-Object Drawing.Font($fam, 10.5)
    $where.Location = New-Object Drawing.Point(26, 46); $where.Size = New-Object Drawing.Size(772, 22)
    $top = New-Object Windows.Forms.Label
    $top.Text = $headline; $top.ForeColor = $(if ($failRows.Count -or $Mode -eq 'running') { $red } elseif ($Mode -eq 'manual') { $amber } else { $teal })
    $top.Font = New-Object Drawing.Font($fam, 11.5, [Drawing.FontStyle]::Bold)
    $top.Location = New-Object Drawing.Point(24, 72); $top.Size = New-Object Drawing.Size(772, 26)
    $f.Controls.AddRange(@($title, $where, $top))

    $tab = New-Object Windows.Forms.Label
    $tab.Text = 'A U D I O'; $tab.ForeColor = [Drawing.Color]::White; $tab.TextAlign = 'MiddleCenter'
    $tab.Font = New-Object Drawing.Font($fam, 11, [Drawing.FontStyle]::Bold)
    $tab.Location = New-Object Drawing.Point(340, 104); $tab.Size = New-Object Drawing.Size(140, 26)
    $f.Controls.Add($tab)
    $line = New-Object Windows.Forms.Panel; $line.BackColor = [Drawing.Color]::White
    $line.Location = New-Object Drawing.Point(350, 131); $line.Size = New-Object Drawing.Size(120, 2); $f.Controls.Add($line)

    $panel = New-Object Windows.Forms.Panel
    $panel.Location = New-Object Drawing.Point(0, 140); $panel.Size = New-Object Drawing.Size(820, ($f.ClientSize.Height - 140 - 64))
    $panel.AutoScroll = $true; $panel.BackColor = $bg
    $f.Controls.Add($panel)

    $y = 6; $section = ''; $subTop = $null; $subBottom = $null
    foreach ($r in $Rows) {
        if ($r.Section -ne $section) {
            $section = $r.Section
            $h = New-Object Windows.Forms.Label
            $h.Text = "$section  --"; $h.ForeColor = [Drawing.Color]::FromArgb(230, 230, 230)
            $h.Font = New-Object Drawing.Font('Consolas', 12, [Drawing.FontStyle]::Bold)
            $h.Location = New-Object Drawing.Point(24, ($y + 8)); $h.AutoSize = $true
            $panel.Controls.Add($h)
            $sep = New-Object Windows.Forms.Panel; $sep.BackColor = [Drawing.Color]::FromArgb(60, 60, 60)
            $sep.Location = New-Object Drawing.Point(24, ($y + 34)); $sep.Size = New-Object Drawing.Size(752, 1); $panel.Controls.Add($sep)
            $y += 44
        }
        $isSub = $subVolumes -contains $r.Label
        $isHearing = $r.Label -like 'Compensazione*'
        $x = if ($isSub) { 64 } else { 24 }; $w = 776 - $x
        if ($isSub -and $null -eq $subTop) { $subTop = $y }

        $row = New-Object Windows.Forms.Panel
        $bad = ($r.Status -in 'FAIL', 'MISSING') -or ($Mode -eq 'running' -and $r.Status -notin 'OK', 'VERIFIED', 'MANUAL')
        $row.BackColor = $(if ($bad) { $rowWarn } elseif ($isHearing -or $r.Status -eq 'MANUAL') { $rowAmber } else { $rowBg })
        $row.Location = New-Object Drawing.Point($x, $y); $row.Size = New-Object Drawing.Size($w, 46)

        $l = New-Object Windows.Forms.Label
        $l.Text = $r.Label; $l.ForeColor = $txt; $l.Font = New-Object Drawing.Font($fam, 12)
        $l.Location = New-Object Drawing.Point(18, 12); $l.Size = New-Object Drawing.Size((368 - ($x - 24)), 24)
        $v = New-Object Windows.Forms.Label
        $v.Text = $r.Show; $v.ForeColor = $txt; $v.Font = New-Object Drawing.Font($fam, 12)
        if ($isHearing -and $r.Status -eq 'FAIL') { $v.Text = "ATTIVA → metti $($r.Show)"; $v.ForeColor = $red }
        elseif ($isHearing -and $r.Status -eq 'VERIFIED') { $v.Text = 'No  (risulta già No)' }
        $v.Location = New-Object Drawing.Point((390 - ($x - 24)), 12); $v.Size = New-Object Drawing.Size(234, 24)
        $s = New-Object Windows.Forms.Label
        $s.Font = New-Object Drawing.Font($fam, 10, [Drawing.FontStyle]::Bold); $s.TextAlign = 'MiddleRight'
        $s.Location = New-Object Drawing.Point(($w - 124), 12); $s.Size = New-Object Drawing.Size(116, 24)
        switch ($r.Status) {
            'OK'       { $s.Text = $(if ($Mode -eq 'applied') { '✓ FATTO' } else { '✓ OK' }); $s.ForeColor = $teal }
            'VERIFIED' { $s.Text = '⚠ CONTROLLA'; $s.ForeColor = $amber }
            'MANUAL'   { $s.Text = '⚠ A MANO'; $s.ForeColor = $amber }
            default    { $s.Text = '✗ A MANO'; $s.ForeColor = $red }
        }
        $row.Controls.AddRange(@($s, $v, $l))
        $panel.Controls.Add($row)
        if ($isSub) { $subBottom = $y + 23 }
        $y += 52

        # Sotto "Volume di gioco generale": il pulsante "Mostra di più" del gioco.
        if ($r.Label -eq 'Volume di gioco generale') {
            $more = New-Object Windows.Forms.Label
            $more.Text = '└  Mostra di più      ← nel gioco clicca qui per aprire i 4 volumi qui sotto'
            $more.ForeColor = $amber; $more.Font = New-Object Drawing.Font($fam, 10.5)
            $more.Location = New-Object Drawing.Point(40, ($y - 2)); $more.Size = New-Object Drawing.Size(736, 22)
            $panel.Controls.Add($more)
            $y += 26
        }
    }
    if ($null -ne $subTop) {
        $vline = New-Object Windows.Forms.Panel; $vline.BackColor = [Drawing.Color]::FromArgb(110, 110, 110)
        $vline.Location = New-Object Drawing.Point(48, ($subTop - 4)); $vline.Size = New-Object Drawing.Size(2, ($subBottom - $subTop + 4))
        $panel.Controls.Add($vline)
    }
    $note = New-Object Windows.Forms.Label
    $note.Text = "⚠ «Compensazione udito asimmetrico» DEVE essere No (se è attiva l'audio suona tappato): controllala SEMPRE nel gioco, anche se risulta già No.`n" +
                 "Apri Warzone › Impostazioni › Audio e controlla le voci ⚠ e ✗. Le voci ✓ sono già impostate."
    $note.ForeColor = [Drawing.Color]::FromArgb(255, 200, 80); $note.Font = New-Object Drawing.Font($fam, 10)
    $note.Location = New-Object Drawing.Point(24, ($y + 10)); $note.Size = New-Object Drawing.Size(752, 66)
    $panel.Controls.Add($note)

    $btn = New-Object Windows.Forms.Button
    $btn.Text = 'HO CAPITO'; $btn.FlatStyle = 'Flat'; $btn.BackColor = $teal; $btn.ForeColor = [Drawing.Color]::Black
    $btn.Font = New-Object Drawing.Font($fam, 11, [Drawing.FontStyle]::Bold)
    $btn.Size = New-Object Drawing.Size(180, 40)
    $btn.Location = New-Object Drawing.Point(([int](($f.ClientSize.Width - 180) / 2)), ($f.ClientSize.Height - 52))
    $btn.Add_Click({ $f.Close() })
    $f.Controls.Add($btn); $f.AcceptButton = $btn
    [void]$f.ShowDialog()
    $f.Dispose()
}

function Show-Info([string]$Text, [string]$Caption = 'Mod Audio COD', [string]$Icon = 'Information') {
    $owner = if ($script:Guide) { $script:Guide.Form } else { $null }
    [void][System.Windows.Forms.MessageBox]::Show($owner, $Text, $Caption, 'OK', $Icon)
}
