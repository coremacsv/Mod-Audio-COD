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
    $f.Text            = 'Footstep EQ - Guida'
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

function Ask-YesNo([string]$Text, [string]$Caption = 'Footstep EQ') {
    $owner = if ($script:Guide) { $script:Guide.Form } else { $null }
    [System.Windows.Forms.MessageBox]::Show($owner, $Text, $Caption, 'YesNo', 'Question') -eq 'Yes'
}

function Show-Info([string]$Text, [string]$Caption = 'Footstep EQ', [string]$Icon = 'Information') {
    $owner = if ($script:Guide) { $script:Guide.Form } else { $null }
    [void][System.Windows.Forms.MessageBox]::Show($owner, $Text, $Caption, 'OK', $Icon)
}
