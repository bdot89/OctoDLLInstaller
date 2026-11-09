# Octo DLL Installer (9 Nov 2026) - an install / update tool for the client DLLs,
# for players without pfUI Octo. User: "a file that opens a UI on your
# computer. Here you can select in a tick box which DLLs you want. Then press a
# button to install them the same way ours does. It should be really easy to
# do and clear what you need to do to get it to work."
#
# Installs exactly as pfUI Octo's tools\install_dlls.ps1 does: the newest
# release from each author's page, checked to be a Windows DLL, copied only
# when it differs (the old one kept in <game>\DLL-backups), never over a newer
# build you already have, and added to dlls.txt (backed up once to
# dlls.txt.pfui-backup). Start it with "Install or update DLLs.bat".
param([string]$GameDir = "", [switch]$NoWindow, [string]$Snapshot = "", [switch]$SnapshotCheck)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{ "User-Agent" = "Octo-DLL-Installer" }

$DLLS = @(
  @{ Name = "ClassicAPI"; Repo = "brues-code/ClassicAPI"; File = "ClassicAPI.dll"
     About = "Newer game functions for add-ons: auras, casts, items, loot, the combat log." },
  @{ Name = "SuperWoW"; Repo = "balakethelock/SuperWoW"; File = "SuperWoWhook.dll"
     About = "Unit GUIDs, cast events, focus and mouseover casting." },
  @{ Name = "nampower"; Repo = "brues-code/nampower"; File = "nampower.dll"
     About = "Faster spell casting (less delay between casts) and spell events for add-ons." },
  @{ Name = "UnitXP_SP3"; Repo = "brues-code/UnitXP_SP3"; File = "UnitXP_SP3.dll"
     About = "Distances, line of sight and better camera / targeting options." },
  @{ Name = "WeirdUtils"; Repo = "MarcelineVQ/WeirdUtils"; File = "weirdutils_noperf.dll"; Api = "https://codeberg.org/api/v1/repos/"; Site = "codeberg.org/"
     About = "World markers, minimap icons, a transmog fix, a bigger cursor and more." }
)

# ------------------------------------------------------------------ helpers
function Test-Dll([string]$path) {
  if (-not (Test-Path $path)) { return $false }
  if ((Get-Item $path).Length -lt 10000) { return $false }
  $fs = [IO.File]::OpenRead($path)
  try { $a = $fs.ReadByte(); $b = $fs.ReadByte() } finally { $fs.Close() }
  return ($a -eq 0x4D -and $b -eq 0x5A)
}
function Get-BuildDate([string]$path) {
  try {
    $b = [IO.File]::ReadAllBytes($path)
    $pe = [BitConverter]::ToInt32($b, 60)
    if ($pe -lt 0 -or $pe + 12 -gt $b.Length) { return $null }
    $ts = [BitConverter]::ToUInt32($b, $pe + 8)
    if ($ts -eq 0) { return $null }
    return ([DateTime]'1970-01-01').AddSeconds($ts)
  } catch { return $null }
}
function Test-GameDir([string]$dir) { return ($dir -and (Test-Path (Join-Path $dir "WoW.exe"))) }

# the game folder: last used, above this folder, or a usual place
$memo = Join-Path $env:APPDATA "OctoDLLInstaller.txt"
function Find-GameDir {
  if (Test-Path $memo) {
    $m = (Get-Content $memo -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (Test-GameDir $m) { return $m }
  }
  $dir = [IO.Path]::GetFullPath($PSScriptRoot)
  while ($dir) {
    if (Test-GameDir $dir) { return $dir }
    $parent = [IO.Path]::GetDirectoryName($dir)
    if ($parent -eq $dir) { $dir = $null } else { $dir = $parent }
  }
  foreach ($d in @("C:\Games\OctoWoW", "D:\Games\OctoWoW", "C:\OctoWoW", "D:\OctoWoW",
                   (Join-Path ${env:ProgramFiles(x86)} "OctoWoW"), (Join-Path $env:ProgramFiles "OctoWoW"),
                   (Join-Path $env:USERPROFILE "Games\OctoWoW"), (Join-Path $env:USERPROFILE "Desktop\OctoWoW"))) {
    if (Test-GameDir $d) { return $d }
  }
  return ""
}

# what the game folder holds for one DLL, as a short line
function Get-Have($d, [string]$game) {
  if (-not (Test-GameDir $game)) { return "" }
  $target = Join-Path $game $d.File
  if (-not (Test-Path $target)) { return "not installed" }
  $fv = (Get-Item $target).VersionInfo.FileVersion
  $bd = Get-BuildDate $target
  # (some builds carry a made-up date in their header, 1993 for WeirdUtils: not shown)
  $s = if ($fv) { "v" + ($fv -replace ',', '.' -replace '\s', '') } elseif ($bd -and $bd.Year -ge 2010) { "built " + $bd.ToString("d MMM yyyy") } else { "installed" }
  $list = Join-Path $game "dlls.txt"
  if ((Test-Path $list) -and -not (@(Get-Content $list | Where-Object { $_.Trim() -ieq $d.File }).Count -gt 0)) { $s += " (not in dlls.txt)" }
  return $s
}

# install / update one DLL; $say writes a line to the log -> "changed" / "same" / "kept" / "skipped"
function Install-One($d, [string]$game, [System.Collections.ArrayList]$lines, [string]$temp, [string]$stamp, [bool]$check, $say) {
  $name, $file = $d.Name, $d.File
  try {
    $api = if ($d.Api) { $d.Api } else { "https://api.github.com/repos/" }
    $rel = Invoke-RestMethod -Uri ($api + $d.Repo + "/releases/latest") -Headers $headers -TimeoutSec 30
  } catch {
    & $say ("{0}: couldn't reach its download page ({1}). Check your internet and try again." -f $name, $_.Exception.Message) "warn"
    return "skipped"
  }
  $tag = $rel.tag_name
  if ($tag -notmatch '\d' -and $rel.name) { $tag = ($rel.name -replace ("^" + $name + "\s*"), "") }
  $asset = $rel.assets | Where-Object { $_.name -ieq $file } | Select-Object -First 1
  $zip = $null
  if (-not $asset) { $zip = $rel.assets | Where-Object { $_.name -like "*.zip" -and $_.name -notlike "*Symbol*" } | Select-Object -First 1 }
  if (-not $asset -and -not $zip) { & $say ("{0} {1}: the release has no {2} - left as it is." -f $name, $tag, $file) "warn"; return "skipped" }
  $got = Join-Path $temp $file
  $inside = $true
  try {
    if ($asset) {
      Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $got -Headers $headers -UseBasicParsing -TimeoutSec 120
    } else {
      $zpath = Join-Path $temp ($name + ".zip")
      Invoke-WebRequest -Uri $zip.browser_download_url -OutFile $zpath -Headers $headers -UseBasicParsing -TimeoutSec 120
      $zdir = Join-Path $temp $name
      Expand-Archive -Path $zpath -DestinationPath $zdir -Force
      $inside = Get-ChildItem -Path $zdir -Recurse -Filter $file | Select-Object -First 1
      if ($inside) { Copy-Item $inside.FullName $got -Force }
    }
  } catch {
    $why = $_.Exception.Message
    $site = if ($d.Site) { $d.Site } else { "github.com/" }
    if ($why -match "virus|unwanted") { $why = "your antivirus blocked the download. Press 'Antivirus help' below to see how to allow it, then press Install / update again" }
    & $say ("{0} {1}: skipped - {2}" -f $name, $tag, $why.Trim()) "warn"
    return "skipped"
  }
  if (-not $inside) { & $say ("{0} {1}: the download has no {2} - left as it is." -f $name, $tag, $file) "warn"; return "skipped" }
  if (-not (Test-Dll $got)) { & $say ("{0} {1}: the download is not a DLL - left as it is." -f $name, $tag) "warn"; return "skipped" }

  $target = Join-Path $game $file
  $same = (Test-Path $target) -and ((Get-FileHash $got).Hash -eq (Get-FileHash $target).Hash)
  $listed = @($lines | Where-Object { $_.Trim() -ieq $file }).Count -gt 0
  $mine = ""
  if (-not $same -and (Test-Path $target)) {
    $fv = (Get-Item $target).VersionInfo.FileVersion
    $rv = ($tag -replace '^[vV]', '')
    $a, $b = $null, $null
    if ([Version]::TryParse(($fv -replace ',', '.' -replace '\s', ''), [ref]$a) -and [Version]::TryParse($rv, [ref]$b)) {
      if ($a -ge $b) { $mine = "your $fv is the same or newer" }
    } else {
      $have, $new = (Get-BuildDate $target), (Get-BuildDate $got)
      if ($have -and $new -and $have -gt $new) { $mine = "yours is a newer build (" + $have.ToString("d MMM yyyy") + ")" }
    }
  }
  $result = "same"
  if ($mine -ne "") {
    & $say ("{0} {1}: kept - {2}." -f $name, $tag, $mine) "ok"
    $result = "kept"
  } elseif ($same) {
    & $say ("{0} {1}: already the newest." -f $name, $tag) "ok"
  } elseif ($check) {
    & $say ("{0} {1}: would be {2}." -f $name, $tag, $(if (Test-Path $target) { "updated" } else { "installed" })) "info"
    $result = "changed"
  } else {
    $backups = Join-Path $game "DLL-backups"
    $bak = $null
    if (Test-Path $target) {
      if (-not (Test-Path $backups)) { New-Item -ItemType Directory -Path $backups | Out-Null }
      $bak = Join-Path $backups ("{0}.{1}.bak" -f $file, $stamp)
      Copy-Item $target $bak -Force
    }
    try { Copy-Item $got $target -Force } catch { throw "Couldn't copy $file into the game folder. Close the game completely and try again." }
    try { Unblock-File $target } catch { }
    & $say ("{0} {1}: {2}." -f $name, $tag, $(if ($bak) { "updated (the old one is in DLL-backups)" } else { "installed" })) "good"
    $result = "changed"
  }
  if (-not $listed) {
    if ($check) { & $say ("{0}: would be added to dlls.txt." -f $file) "info" }
    else { [void]$lines.Add($file); & $say ("{0}: added to dlls.txt." -f $file) "good" }
    $script:listChanged = $true
  }
  return $result
}

# the whole run for the ticked DLLs; returns the summary line
function Invoke-Install([string]$game, $picked, [bool]$check, $say) {
  if (-not (Test-GameDir $game)) { throw "Pick your game folder first - the one with WoW.exe in it." }
  if (-not $check) {
    $running = @(Get-Process -Name "WoW" -ErrorAction SilentlyContinue | Where-Object {
      $path = $null
      try { $path = $_.Path } catch { }
      (-not $path) -or ([IO.Path]::GetDirectoryName($path) -ieq $game)
    })
    if ($running.Count -gt 0) { throw "The game is running. Close it completely, then press the button again." }
  }
  $list = Join-Path $game "dlls.txt"
  if (-not (Test-Path $list)) {
    throw "There's no dlls.txt in your game folder. Start the game once from OctoLauncher with the vanillaHelpers mod ticked (that makes it), close the game, then press the button again."
  }
  $lines = New-Object System.Collections.ArrayList
  foreach ($l in [IO.File]::ReadAllLines($list)) { [void]$lines.Add($l) }
  $script:listChanged = $false
  # downloads go to a folder inside the game folder (removed after), so an
  # antivirus exclusion for the game folder covers them too (SuperWoW)
  $temp = Join-Path $game ("DLL-download-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
  New-Item -ItemType Directory -Path $temp | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $changed = 0
  try {
    foreach ($d in $picked) {
      & $say ("Getting {0}..." -f $d.Name) "dim"
      $r = @(Install-One $d $game $lines $temp $stamp $check $say)
      if ($r.Count -gt 0 -and $r[$r.Count - 1] -eq "changed") { $changed++ }
    }
    # the full weirdutils.dll never loads beside the noperf build
    if (@($picked | Where-Object { $_.Name -eq "WeirdUtils" }).Count -gt 0) {
      $old = @("weirdutils.dll", "weirdutils_octo.dll")
      if (@($lines | Where-Object { $old -contains $_.Trim().ToLower() }).Count -gt 0) {
        if ($check) { & $say "An old WeirdUtils DLL: would be taken out of dlls.txt (weirdutils_noperf.dll replaces it)." "info" }
        else {
          $keep = New-Object System.Collections.ArrayList
          foreach ($l in $lines) { if ($old -notcontains $l.Trim().ToLower()) { [void]$keep.Add($l) } }
          $lines = $keep
          $script:listChanged = $true
          & $say "An old WeirdUtils DLL: taken out of dlls.txt (weirdutils_noperf.dll replaces it)." "good"
        }
      }
    }
    if ($script:listChanged -and -not $check) {
      $backup = "$list.pfui-backup"
      if (-not (Test-Path $backup)) { Copy-Item $list $backup }
      [IO.File]::WriteAllLines($list, [string[]]$lines.ToArray())
    }
  } finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
  }
  if ($check) { return "Check done - nothing was changed." }
  if ($changed -gt 0 -or $script:listChanged) {
    return "Done! Start the game from OctoLauncher as usual. If it won't start, copy the old DLL back from the DLL-backups folder, or put dlls.txt.pfui-backup back as dlls.txt."
  }
  return "Everything you ticked is already the newest - nothing to do."
}

if ($NoWindow) { return }

# ------------------------------------------------------------------ the window
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
# started hidden from the .bat: a problem opening the window is shown, not swallowed
trap {
  if ($Snapshot) { Write-Host ("Snapshot failed: " + $_.Exception.Message + " @ line " + $_.InvocationInfo.ScriptLineNumber); exit 1 }
  [void][Windows.Forms.MessageBox]::Show("The installer couldn't start:`n`n" + $_.Exception.Message, "Octo DLL Installer", "OK", "Error")
  exit 1
}

$bg = [Drawing.Color]::FromArgb(24, 25, 30)
$panel = [Drawing.Color]::FromArgb(34, 36, 43)
$fg = [Drawing.Color]::FromArgb(230, 230, 235)
$dim = [Drawing.Color]::FromArgb(150, 152, 165)
$accent = [Drawing.Color]::FromArgb(80, 200, 255)
$green = [Drawing.Color]::FromArgb(80, 220, 120)
$gold = [Drawing.Color]::FromArgb(255, 200, 70)
$red = [Drawing.Color]::FromArgb(255, 95, 95)
$font = New-Object Drawing.Font("Segoe UI", 10)
$bold = New-Object Drawing.Font("Segoe UI Semibold", 10)

$form = New-Object Windows.Forms.Form
$form.Text = "Octo DLL Installer"
$form.Size = New-Object Drawing.Size(820, 740)
$form.StartPosition = "CenterScreen"
$form.BackColor = $bg
$form.ForeColor = $fg
$form.Font = $font
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

function Label($text, $x, $y, $w, $h, $color, $f) {
  $l = New-Object Windows.Forms.Label
  $l.Text = $text
  $l.Location = New-Object Drawing.Point($x, $y)
  $l.Size = New-Object Drawing.Size($w, $h)
  $l.ForeColor = $(if ($color) { $color } else { $fg })
  if ($f) { $l.Font = $f }
  $form.Controls.Add($l)
  return $l
}
function Button($text, $x, $y, $w, $color) {
  $b = New-Object Windows.Forms.Button
  $b.Text = $text
  $b.Location = New-Object Drawing.Point($x, $y)
  $b.Size = New-Object Drawing.Size($w, 34)
  $b.FlatStyle = "Flat"
  $b.FlatAppearance.BorderColor = $color
  $b.ForeColor = $color
  $b.BackColor = $panel
  $b.Font = $bold
  $form.Controls.Add($b)
  return $b
}

Label "Octo DLL Installer" 20 14 500 34 $accent (New-Object Drawing.Font("Segoe UI Semibold", 18)) | Out-Null
Label "Install / update tool: puts the OctoWoW client DLLs in, or brings the ones you have up to the newest version." 22 50 770 22 $dim | Out-Null
Label ("1.  Close the game completely.`n" +
       "2.  Check the game folder below is right (the folder with WoW.exe in it). Use Browse if it isn't.`n" +
       "3.  Tick the DLLs you want.`n" +
       "4.  Press Install / update. Then start the game from OctoLauncher as usual.") 22 82 770 84 $fg | Out-Null

Label "Game folder" 22 172 120 22 $dim $bold | Out-Null
$dirBox = New-Object Windows.Forms.TextBox
$dirBox.Location = New-Object Drawing.Point(22, 196)
$dirBox.Size = New-Object Drawing.Size(620, 26)
$dirBox.BackColor = $panel
$dirBox.ForeColor = $fg
$dirBox.BorderStyle = "FixedSingle"
$form.Controls.Add($dirBox)
$browse = Button "Browse..." 652 192 130 $accent
$dirState = Label "" 22 224 760 22 $dim

$dllHead = Label "DLLs" 22 252 300 22 $dim $bold
$view = New-Object Windows.Forms.ListView
$view.Location = New-Object Drawing.Point(22, 276)
$view.Size = New-Object Drawing.Size(760, 190)
$view.View = "Details"
$view.CheckBoxes = $true
$view.FullRowSelect = $true
$view.BackColor = $panel
$view.ForeColor = $fg
$view.BorderStyle = "FixedSingle"
$view.HeaderStyle = "Nonclickable"
[void]$view.Columns.Add("DLL", 120)
[void]$view.Columns.Add("You have", 170)
[void]$view.Columns.Add("What it does", 466)
foreach ($d in $DLLS) {
  $item = New-Object Windows.Forms.ListViewItem($d.Name)
  [void]$item.SubItems.Add("")
  [void]$item.SubItems.Add($d.About)
  $item.Checked = $true
  $item.Tag = $d
  $item.ToolTipText = $d.About
  [void]$view.Items.Add($item)
}
$view.ShowItemToolTips = $true
$form.Controls.Add($view)

$all = Button "Tick all" 22 474 110 $dim
$none = Button "Untick all" 140 474 110 $dim
$checkBtn = Button "Check for updates" 432 474 170 $accent
$install = Button "Install / update" 612 474 170 $green

Label "Progress" 22 516 300 22 $dim $bold | Out-Null
$log = New-Object Windows.Forms.RichTextBox
$log.Location = New-Object Drawing.Point(22, 540)
$log.Size = New-Object Drawing.Size(760, 92)
$log.BackColor = $panel
$log.ForeColor = $fg
$log.BorderStyle = "None"
$log.ReadOnly = $true
$log.Font = New-Object Drawing.Font("Consolas", 9)
$form.Controls.Add($log)
Label "Your old DLLs are kept in DLL-backups in the game folder. Antivirus often blocks SuperWoW: see Antivirus help." 22 642 600 34 $dim | Out-Null
$avBtn = Button "Antivirus help" 632 638 150 $gold
$AVHELP = @"
Windows Defender (and other antivirus programs) often block SuperWoW. It changes how the game runs, which looks like what cheats and viruses do. It's a well-known OctoWoW / Turtle WoW mod, but only allow it if you trust it.

The easy way - allow what was blocked:
  1. Open Windows Security (the button below does it).
  2. Virus & threat protection > Protection history.
  3. Click the newest SuperWoW item > Actions > Allow on device.
  4. Press Install / update here again.

If it keeps getting blocked - exclude the game folder:
  1. Windows Security > Virus & threat protection.
  2. Under 'Virus & threat protection settings' click Manage settings.
  3. Scroll to Exclusions > Add or remove exclusions.
  4. Add an exclusion > Folder > pick your game folder (the one with WoW.exe).
  5. Press Install / update here again. (This tool downloads into the game folder, so the exclusion covers it.)

Another antivirus (Avast, Norton, McAfee ...): find its Quarantine or Exceptions, restore SuperWoWhook.dll or add the game folder as an exception.

Open Windows Security now?
"@
$avBtn.Add_Click({
  $r = [Windows.Forms.MessageBox]::Show($form, $AVHELP, "Antivirus help - allowing SuperWoW", "YesNo", "Information")
  if ($r -eq "Yes") { try { Start-Process "windowsdefender://threat" } catch { Start-Process "ms-settings:windowsdefender" } }
})

function Say([string]$text, [string]$kind) {
  $c = switch ($kind) { "good" { $green } "warn" { $gold } "bad" { $red } "info" { $accent } "dim" { $dim } default { $fg } }
  $log.SelectionStart = $log.TextLength
  $log.SelectionLength = 0
  $log.SelectionColor = $c
  $log.AppendText($text + "`r`n")
  $log.ScrollToCaret()
  [System.Windows.Forms.Application]::DoEvents()
}

function Refresh-State {
  $g = $dirBox.Text.Trim()
  if (Test-GameDir $g) {
    if (Test-Path (Join-Path $g "dlls.txt")) {
      $dirState.Text = "OK - WoW.exe and dlls.txt found."
      $dirState.ForeColor = $green
    } else {
      $dirState.Text = "WoW.exe found, but no dlls.txt: start the game once from OctoLauncher with vanillaHelpers ticked, close it, then come back."
      $dirState.ForeColor = $gold
    }
  } elseif ($g) {
    $dirState.Text = "No WoW.exe in this folder. Press Browse and pick the folder WoW.exe is in."
    $dirState.ForeColor = $red
  } else {
    $dirState.Text = "Press Browse and pick your OctoWoW folder (the one with WoW.exe in it)."
    $dirState.ForeColor = $gold
  }
  foreach ($it in $view.Items) { $it.SubItems[1].Text = (Get-Have $it.Tag $g) }
}

$browse.Add_Click({
  $dlg = New-Object Windows.Forms.FolderBrowserDialog
  $dlg.Description = "Pick your OctoWoW folder - the one with WoW.exe in it."
  if ($dirBox.Text -and (Test-Path $dirBox.Text)) { $dlg.SelectedPath = $dirBox.Text }
  if ($dlg.ShowDialog($form) -eq "OK") { $dirBox.Text = $dlg.SelectedPath; Refresh-State }
})
$dirBox.Add_Leave({ Refresh-State })
$all.Add_Click({ foreach ($it in $view.Items) { $it.Checked = $true } })
$none.Add_Click({ foreach ($it in $view.Items) { $it.Checked = $false } })

function Run([bool]$check) {
  $picked = @($view.Items | Where-Object { $_.Checked } | ForEach-Object { $_.Tag })
  if ($picked.Count -eq 0) { Say "Tick at least one DLL first." "warn"; return }
  $log.Clear()
  foreach ($b in @($install, $checkBtn, $browse, $all, $none, $avBtn)) { $b.Enabled = $false }
  $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
  try {
    $g = $dirBox.Text.Trim()
    Say ("Game folder: " + $g) "dim"
    $msg = Invoke-Install $g $picked $check ${function:Say}
    Say "" ""
    Say $msg $(if ($check) { "info" } else { "good" })
    try { Set-Content -Path $memo -Value $g } catch { }
  } catch {
    Say ("Not done: " + $_.Exception.Message) "bad"
  } finally {
    foreach ($b in @($install, $checkBtn, $browse, $all, $none, $avBtn)) { $b.Enabled = $true }
    $form.Cursor = [Windows.Forms.Cursors]::Default
    Refresh-State
  }
}
$install.Add_Click({ Run $false })
$checkBtn.Add_Click({ Run $true })

$dirBox.Text = $(if ($GameDir) { $GameDir } else { Find-GameDir })
Refresh-State
Say "Ready. Close the game, tick what you want and press Install / update." "dim"
# (the Install button has the focus, so the folder text doesn't start highlighted)
$form.Add_Shown({ $form.ActiveControl = $install })
if ($Snapshot) {
  # (screenshots for the README: the window shown for a moment on top, with
  # -SnapshotCheck after a "Check for updates", and copied from the screen)
  $form.StartPosition = "Manual"
  $form.Location = New-Object Drawing.Point(40, 40)
  $form.TopMost = $true
  $form.ShowInTaskbar = $false
  $form.Show()
  for ($i = 0; $i -lt 10; $i++) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
  if ($SnapshotCheck) { Run $true }
  for ($i = 0; $i -lt 10; $i++) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
  # the screen is copied in real pixels: scaled displays (150% ...) make the
  # window that much bigger there
  Add-Type -Namespace Octo -Name Gdi -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr h);
[DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int i);
'@
  [double]$scale = [Octo.Gdi]::GetDeviceCaps([Octo.Gdi]::GetDC([IntPtr]::Zero), 118)
  $scale = $scale / [Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
  if ($scale -lt 1) { $scale = 1.0 }
  # (Windows 11 puts an invisible 7 px border left, right and below: left out)
  [int]$edge = 7 * $scale
  [int]$w = $form.Width * $scale - 2 * $edge
  [int]$h = $form.Height * $scale - $edge
  [int]$x = $form.Left * $scale + $edge
  [int]$y = $form.Top * $scale
  $bmp = New-Object Drawing.Bitmap($w, $h)
  $gr = [Drawing.Graphics]::FromImage($bmp)
  $gr.CopyFromScreen((New-Object Drawing.Point($x, $y)), (New-Object Drawing.Point(0, 0)), (New-Object Drawing.Size($w, $h)))
  $gr.Dispose()
  $bmp.Save($Snapshot, [Drawing.Imaging.ImageFormat]::Png)
  $form.Close()
  return
}
[void]$form.ShowDialog()
