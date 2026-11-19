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
#
# 1.1.0 (15 Nov 2026), user: "add onto the DLL list
# https://vanilla-addon-index.github.io/?type=dll ... Keep ours needed for our
# addons flagged and easy to see but have everything optional there".
# Two lists: the DLLs our addons use (ticked to start with; the first five are
# installed exactly as 1.0.0 did, DmorphHelper by DmorphOcto's own installer)
# and optional extras from the index's DLL list (unticked). An extra can bring
# its addon (copied into Interface\AddOns, the old one kept in
# DLL-backups\AddOns) and files it needs beside the DLL. What the index lists
# but this leaves out, and why, is in README.txt.
param([string]$GameDir = "", [switch]$NoWindow, [string]$Snapshot = "", [switch]$SnapshotCheck)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{ "User-Agent" = "Octo-DLL-Installer" }
$VERSION = "1.3.0"
$OCTOGIT = "https://octowow.st/git/api/v1/repos/"

# Fields: Name, File (the DLL in the game folder), About, and where it comes from:
#   Repo (+ Api / Site when not GitHub)  the newest release: the DLL itself, or a .zip holding it
#   Archive                              a repository download (.zip) holding the DLL
#   Url (+ Tag)                          the DLL itself, from a plain link
# Ours = used by our addons (first list, ticked; Used = which ones); Helper = a DLL
# one of our addons brings with its own installer (Source, Script inside it).
# Addon = the addon (its .toc name) that comes in the download, or from AddonZip.
# Extras = files beside the DLL (Path in the game folder; Url when not in the
# download; Keep = never replaced once there). Warn = shown in gold. Page = its page.
$DLLS = @(
  # ---- used by our addons ----
  @{ Name = "ClassicAPI"; Repo = "brues-code/ClassicAPI"; File = "ClassicAPI.dll"; Ours = $true
     Used = "pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoArenaFrames, KillShot, UpsiAuras"
     About = "Newer game functions for add-ons: auras, casts, items, loot, the combat log." },
  @{ Name = "SuperWoW"; Repo = "balakethelock/SuperWoW"; File = "SuperWoWhook.dll"; Ours = $true
     Used = "nearly all: pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoRank, OctoArenaFrames, OctoKicks, KillShot, OctoOmniCC, UpsiAuras, HoryRogue, shootyepgp"
     About = "Unit GUIDs, cast events, focus and mouseover casting." },
  @{ Name = "nampower"; Repo = "brues-code/nampower"; File = "nampower.dll"; Ours = $true
     Used = "pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoRank, OctoArenaFrames, UpsiAuras, HoryRogue"
     About = "Faster spell casting (less delay between casts) and spell events for add-ons." },
  @{ Name = "UnitXP_SP3"; Repo = "brues-code/UnitXP_SP3"; File = "UnitXP_SP3.dll"; Ours = $true
     Used = "pfUI Octo, WhoDidIt"
     About = "Distances, line of sight and better camera / targeting options." },
  @{ Name = "WeirdUtils"; Repo = "MarcelineVQ/WeirdUtils"; File = "weirdutils_noperf.dll"; Api = "https://codeberg.org/api/v1/repos/"; Site = "codeberg.org/"; Ours = $true
     Used = "pfUI Octo, OctoBG"
     About = "World markers, minimap icons, a transmog fix, a bigger cursor and more." },
  @{ Name = "DmorphHelper"; File = "DmorphHelper.dll"; Helper = "DmorphOcto"; Source = "helper\DmorphHelper.dll"; Script = "tools\install_helper.ps1"; Ours = $true
     Used = "DmorphOcto"; Page = "https://github.com/bdot89/DmorphOcto"
     About = "Weapon glows, your own skin / face / hair, sizes and more in DmorphOcto. Comes with DmorphOcto and is put in by its own installer." },
  # ---- optional extras: the Vanilla Addon Index's DLL list ----
  @{ Name = "AuctionQueryThrottle"; Repo = "brues-code/AuctionQueryThrottle"; File = "AuctionQueryThrottle.dll"; From = "brues-code, GitHub"
     About = "No 5-second wait between auction house searches: the next one goes as soon as the server answers." },
  @{ Name = "Interact"; Repo = "lookino/Interact"; File = "Interact.dll"; Addon = "Interact"; From = "lookino, GitHub"
     Warn = "v1.0.4 crashed OctoWoW on every key press when we tried it (29 Oct 2026)."
     About = "An interact key: one key to talk to, loot or use what's in front of you. Comes with its key binding addon." },
  @{ Name = "LockPort"; Archive = "https://octowow.st/git/OEVG/LockPort/archive/main.zip"; File = "LockPort.dll"; Addon = "LockPort"; From = "OEVG, octowow.st"
     Page = "https://octowow.st/git/OEVG/LockPort"
     About = "For warlocks: summons the people who type 123, with Auto Summon. Comes with the LockPort addon." },
  @{ Name = "OctoBus"; Repo = "Phridgey/OctoBus"; File = "ZepSense.dll"; Addon = "OctoBus"; AddonZip = "https://octowow.st/git/OEVG/Octobus/archive/main.zip"; From = "Phridgey / OEVG"
     Page = "https://octowow.st/git/OEVG/Octobus"
     About = "Zeppelin and boat timers for Orgrimmar. ZepSense.dll lets the OctoBus addon see the transports; the addon comes with it." },
  @{ Name = "TotemCircles"; Repo = "veber01/Octo-TotemCircles"; Api = $OCTOGIT; Site = "octowow.st/git/"; File = "TotemCircles.dll"; Addon = "TotemCircles"; From = "veber01, octowow.st"
     About = "For shamans: shows your totems' ranges as circles on the ground. Comes with the TotemCircles addon." },
  @{ Name = "PerfBoost"; Url = "https://github.com/RetroCro/TurtleWoW-Mods/raw/main/Archive/DLL%20BACKUP/perf_boost.dll"; Tag = "(archived copy)"; File = "perf_boost.dll"
     Addon = "PerfBoostSettings"; AddonZip = "https://github.com/RetroCro/TurtleWoW-Mods/raw/main/Archive/DLL%20BACKUP/perfboostsettings.zip"; From = "avitasia (archive)"
     Page = "https://github.com/RetroCro/TurtleWoW-Mods"
     Warn = "An old archived copy (its own page is gone), never tried on OctoWoW."
     About = "More FPS: draws far-away players, creatures and spell effects less, with city and combat settings. Comes with PerfBoostSettings." },
  @{ Name = "WoWTranslate"; Repo = "jhinzuo2/wow-translate"; File = "WoWTranslate.dll"; Addon = "WoWTranslate"; From = "jhinzuo2, GitHub"
     Extras = @(@{ Path = "cacert.pem"; Url = "https://curl.se/ca/cacert.pem"; Keep = $true; Text = "BEGIN CERTIFICATE" })
     About = "Translates chat between Chinese (also Japanese, Korean, Russian) and English, both ways, through Google Translate. Comes with its addon." },
  @{ Name = "WowPresence"; Repo = "Dusk/WowPresence"; Api = $OCTOGIT; Site = "octowow.st/git/"; File = "WowPresence.dll"; From = "Dusk, octowow.st"
     Extras = @(@{ Path = "WowPresence.exe" }, @{ Path = "WowPresence\discord_application_id"; Keep = $true }, @{ Path = "WowPresence\discord_broadcast_flags"; Keep = $true })
     Remind = @{ File = "WowPresence\discord_application_id"; Ok = '^\d{15,22}$'
                 Text = "put your own Discord Application ID in WowPresence\discord_application_id in the game folder (how: right-click WowPresence here > Open its page)." }
     About = "Shows your character and zone in Discord. Needs your own Discord Application ID (its page says how)." }
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

# a DLL's page (right-click > Open its page)
function Get-Page($d) {
  if ($d.Page) { return $d.Page }
  if ($d.Repo) { return ($(if ($d.Site) { "https://" + $d.Site } else { "https://github.com/" }) + $d.Repo) }
  return ""
}
# a failed download in plain words
function Get-Why($err) {
  $why = $err.Exception.Message
  if ($why -match "virus|unwanted") { $why = "your antivirus blocked the download. Press 'Antivirus help' below to see how to allow it, then press Install / update again" }
  return $why.Trim()
}
# download a .zip and unpack it into $dir
function Get-Zip([string]$url, [string]$dir) {
  $zpath = $dir + ".zip"
  Invoke-WebRequest -Uri $url -OutFile $zpath -Headers $headers -UseBasicParsing -TimeoutSec 120
  Expand-Archive -Path $zpath -DestinationPath $dir -Force
  return $dir
}
function Find-Toc([string]$dir, [string]$addon) {
  if (-not $dir -or -not (Test-Path $dir)) { return $null }
  return (Get-ChildItem -Path $dir -Recurse -File -Filter ($addon + ".toc") | Select-Object -First 1)
}
function Get-TocVersion([string]$toc) {
  if (-not $toc -or -not (Test-Path $toc)) { return "" }
  $l = Get-Content $toc -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*##\s*Version\s*:' } | Select-Object -First 1
  if ($l) { return ($l -replace '^\s*##\s*Version\s*:\s*', '').Trim() }
  return ""
}
# what of a download goes into an addon's folder: not its tests, sources or notes
function Test-AddonFile([string]$rel) {
  $parts = $rel -split '[\\/]'
  for ($i = 0; $i -lt $parts.Count - 1; $i++) {
    if ($parts[$i] -match '^(tests?|native|screenshots|.*_src|\.git.*)$') { return $false }
  }
  return ($parts[$parts.Count - 1] -notmatch '(?i)\.(dll|exe|md|c|h|sh|pem|zip)$|^SHA256SUMS|^\.git|^Makefile$')
}

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
  if ($d.Helper -and -not (Test-Path (Join-Path $game ("Interface\AddOns\" + $d.Helper))) -and -not (Test-Path $target)) { return "needs " + $d.Helper }
  $addonThere = $true
  if ($d.Addon) { $addonThere = Test-Path (Join-Path $game ("Interface\AddOns\{0}\{0}.toc" -f $d.Addon)) }
  if (-not (Test-Path $target)) { if ($d.Addon -and $addonThere) { return "addon only" } else { return "not installed" } }
  $fv = (Get-Item $target).VersionInfo.FileVersion
  $bd = Get-BuildDate $target
  # (some builds carry a made-up date in their header, 1993 for WeirdUtils: not shown)
  $s = if ($fv) { "v" + ($fv -replace ',', '.' -replace '\s', '') } elseif ($bd -and $bd.Year -ge 2010) { "built " + $bd.ToString("d MMM yyyy") } else { "installed" }
  $list = Join-Path $game "dlls.txt"
  if ((Test-Path $list) -and -not (@(Get-Content $list | Where-Object { $_.Trim() -ieq $d.File }).Count -gt 0)) { $s += " (not in dlls.txt)" }
  if (-not $addonThere) { $s += " (no addon)" }
  return $s
}

# copy the addon that comes with a DLL into Interface\AddOns -> "changed" / "same" / "kept" / "skipped"
function Install-Addon($d, [string]$from, [string]$game, [string]$stamp, [bool]$check, $say) {
  $addon = $d.Addon
  $toc = Find-Toc $from $addon
  if (-not $toc) { & $say ("{0}: the download has no {1} addon - left as it is." -f $d.Name, $addon) "warn"; return "skipped" }
  $src = $toc.Directory.FullName
  $dst = Join-Path $game ("Interface\AddOns\" + $addon)
  $files = @(Get-ChildItem -Path $src -Recurse -File | Where-Object { Test-AddonFile ($_.FullName.Substring($src.Length + 1)) })
  $differ = @($files | Where-Object {
    $t = Join-Path $dst $_.FullName.Substring($src.Length + 1)
    (-not (Test-Path $t)) -or ((Get-FileHash $_.FullName).Hash -ne (Get-FileHash $t).Hash)
  })
  $ver = Get-TocVersion $toc.FullName
  # (Interact's says "GIT": only a number is shown)
  $label = if ($ver -match '\d') { "{0} addon {1}" -f $addon, $ver } else { "{0} addon" -f $addon }
  if ($differ.Count -eq 0) { & $say ("{0}: already the newest." -f $label) "ok"; return "same" }
  $mineToc = Join-Path $dst ($addon + ".toc")
  $there = Test-Path $mineToc
  if ($there) {
    $mine = Get-TocVersion $mineToc
    $a, $b = $null, $null
    if ($ver -and $mine -and [Version]::TryParse($mine, [ref]$a) -and [Version]::TryParse($ver, [ref]$b) -and $a -gt $b) {
      & $say ("{0}: kept - your {1} is newer." -f $label, $mine) "ok"
      return "kept"
    }
  }
  if ($check) {
    & $say ("{0}: would be {1}." -f $label, $(if ($there) { "updated" } else { "installed in Interface\AddOns" })) "info"
    return "changed"
  }
  if (Test-Path $dst) {
    $bak = Join-Path $game ("DLL-backups\AddOns\{0}.{1}" -f $addon, $stamp)
    $bakDir = Split-Path $bak
    if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir | Out-Null }
    Copy-Item -Path $dst -Destination $bak -Recurse -Force
  }
  try {
    foreach ($f in $files) {
      $t = Join-Path $dst $f.FullName.Substring($src.Length + 1)
      $tdir = Split-Path $t
      if (-not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
      Copy-Item $f.FullName $t -Force
    }
  } catch { throw "Couldn't copy the $addon addon into Interface\AddOns. Close the game completely and try again." }
  & $say ("{0}: {1}." -f $label, $(if ($there) { "updated (the old one is in DLL-backups\AddOns)" } else { "installed in Interface\AddOns" })) "good"
  return "changed"
}

# files a DLL needs beside it (WowPresence's helper program and settings,
# WoWTranslate's certificate list) -> $true when one was (or would be) put in
function Install-Extras($d, [string]$from, [string]$game, [string]$temp, [string]$stamp, [bool]$check, $say) {
  $did = $false
  foreach ($x in $d.Extras) {
    $dst = Join-Path $game $x.Path
    if ($x.Keep -and (Test-Path $dst)) { continue }
    $src = $null
    if ($x.Url) {
      $src = Join-Path $temp ([IO.Path]::GetFileName($x.Path))
      try { Invoke-WebRequest -Uri $x.Url -OutFile $src -Headers $headers -UseBasicParsing -TimeoutSec 120 }
      catch { & $say ("{0}: couldn't get {1} - {2}" -f $d.Name, $x.Path, (Get-Why $_)) "warn"; continue }
      if ($x.Text -and -not ([IO.File]::ReadAllText($src).Contains($x.Text))) {
        & $say ("{0}: the {1} download isn't what it should be - left out." -f $d.Name, $x.Path) "warn"; continue
      }
    } elseif ($from) {
      $f = Get-ChildItem -Path $from -Recurse -File | Where-Object { $_.FullName.EndsWith("\" + $x.Path, [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
      if ($f) { $src = $f.FullName }
    }
    if (-not $src) { & $say ("{0}: the download has no {1} - left as it is." -f $d.Name, $x.Path) "warn"; continue }
    $was = Test-Path $dst
    if ($was -and ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash)) { continue }
    if ($check) { & $say ("{0}: would be {1}." -f $x.Path, $(if ($was) { "updated" } else { "put in the game folder" })) "info"; $did = $true; continue }
    if ($was) {
      $backups = Join-Path $game "DLL-backups"
      if (-not (Test-Path $backups)) { New-Item -ItemType Directory -Path $backups | Out-Null }
      Copy-Item $dst (Join-Path $backups ("{0}.{1}.bak" -f [IO.Path]::GetFileName($x.Path), $stamp)) -Force
    }
    $tdir = Split-Path $dst
    if (-not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
    try { Copy-Item $src $dst -Force } catch { & $say ("{0}: couldn't copy {1}. Close the game (and {1}) and try again." -f $d.Name, $x.Path) "warn"; continue }
    try { Unblock-File $dst } catch { }
    & $say ("{0}: {1}." -f $x.Path, $(if ($was) { "updated (the old one is in DLL-backups)" } else { "put in the game folder" })) "good"
    $did = $true
  }
  return $did
}

# install / update one DLL; $say writes a line to the log -> "changed" / "same" / "kept" / "skipped"
function Install-One($d, [string]$game, [System.Collections.ArrayList]$lines, [string]$temp, [string]$stamp, [bool]$check, $say) {
  $name, $file = $d.Name, $d.File
  $got = Join-Path $temp $file
  $pkg = $null         # the unpacked download, for an addon or files that come with the DLL
  $byVersion = $true   # the release's number is the DLL's (not for repository downloads / plain links)
  $inside = $true
  $tag = ""
  if ($d.Url) {
    $tag, $byVersion = $d.Tag, $false
    try { Invoke-WebRequest -Uri $d.Url -OutFile $got -Headers $headers -UseBasicParsing -TimeoutSec 120 }
    catch { & $say ("{0}: skipped - {1}" -f $name, (Get-Why $_)) "warn"; return "skipped" }
  } elseif ($d.Archive) {
    $byVersion = $false
    try { $pkg = @(Get-Zip $d.Archive (Join-Path $temp $name))[-1] }
    catch { & $say ("{0}: skipped - {1}" -f $name, (Get-Why $_)) "warn"; return "skipped" }
    $inside = Get-ChildItem -Path $pkg -Recurse -Filter $file | Select-Object -First 1
    if ($inside) { Copy-Item $inside.FullName $got -Force }
  } else {
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
    try {
      if ($asset) {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $got -Headers $headers -UseBasicParsing -TimeoutSec 120
      } else {
        $pkg = @(Get-Zip $zip.browser_download_url (Join-Path $temp $name))[-1]
        $inside = Get-ChildItem -Path $pkg -Recurse -Filter $file | Select-Object -First 1
        if ($inside) { Copy-Item $inside.FullName $got -Force }
      }
    } catch {
      & $say ("{0} {1}: skipped - {2}" -f $name, $tag, (Get-Why $_)) "warn"
      return "skipped"
    }
  }
  $label = ("{0} {1}" -f $name, $tag).Trim()
  if (-not $inside) { & $say ("{0}: the download has no {1} - left as it is." -f $label, $file) "warn"; return "skipped" }
  if (-not (Test-Dll $got)) { & $say ("{0}: the download is not a DLL - left as it is." -f $label) "warn"; return "skipped" }

  $target = Join-Path $game $file
  $same = (Test-Path $target) -and ((Get-FileHash $got).Hash -eq (Get-FileHash $target).Hash)
  $listed = @($lines | Where-Object { $_.Trim() -ieq $file }).Count -gt 0
  $mine = ""
  if (-not $same -and (Test-Path $target)) {
    $fv = (Get-Item $target).VersionInfo.FileVersion
    $rv = ($tag -replace '^[vV]', '')
    $a, $b = $null, $null
    if ($byVersion -and [Version]::TryParse(($fv -replace ',', '.' -replace '\s', ''), [ref]$a) -and [Version]::TryParse($rv, [ref]$b)) {
      if ($a -ge $b) { $mine = "your $fv is the same or newer" }
    } else {
      $have, $new = (Get-BuildDate $target), (Get-BuildDate $got)
      if ($have -and $new -and $have -gt $new) { $mine = "yours is a newer build (" + $have.ToString("d MMM yyyy") + ")" }
    }
  }
  $result = "same"
  if ($mine -ne "") {
    & $say ("{0}: kept - {1}." -f $label, $mine) "ok"
    $result = "kept"
  } elseif ($same) {
    & $say ("{0}: already the newest." -f $label) "ok"
  } elseif ($check) {
    & $say ("{0}: would be {1}." -f $label, $(if (Test-Path $target) { "updated" } else { "installed" })) "info"
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
    & $say ("{0}: {1}." -f $label, $(if ($bak) { "updated (the old one is in DLL-backups)" } else { "installed" })) "good"
    $result = "changed"
  }
  if (-not $listed) {
    if ($check) { & $say ("{0}: would be added to dlls.txt." -f $file) "info" }
    else { [void]$lines.Add($file); & $say ("{0}: added to dlls.txt." -f $file) "good" }
    $script:listChanged = $true
  }
  if ($d.Addon) {
    $from = $pkg
    if ($d.AddonZip) {
      try { $from = @(Get-Zip $d.AddonZip (Join-Path $temp ($name + "-addon")))[-1] }
      catch { & $say ("{0} addon: skipped - {1}" -f $d.Addon, (Get-Why $_)) "warn"; $from = $null }
    }
    if ($from) {
      $r = @(Install-Addon $d $from $game $stamp $check $say)
      if ($r.Count -gt 0 -and $r[$r.Count - 1] -eq "changed") { $result = "changed" }
    }
  }
  if ($d.Extras) {
    $r = @(Install-Extras $d $pkg $game $temp $stamp $check $say)
    if ($r.Count -gt 0 -and $r[$r.Count - 1] -eq $true) { $result = "changed" }
  }
  if ($d.Remind -and -not $check) {
    $rf = Join-Path $game $d.Remind.File
    $txt = if (Test-Path $rf) { ([IO.File]::ReadAllText($rf)).Trim() } else { "" }
    if ($txt -notmatch $d.Remind.Ok) { & $say ("{0}: {1}" -f $name, $d.Remind.Text) "warn" }
  }
  return $result
}

# a DLL that one of our addons brings, put in by that addon's own installer
# (DmorphOcto's tools\install_helper.ps1 puts DmorphHelper.dll after
# VanillaHelpers.dll in dlls.txt and turns on the HD skin a ported pack needs).
# Run after dlls.txt is written, so the line it adds stays.
function Install-Helper($d, [string]$game, [string]$stamp, [bool]$check, $say) {
  $adir = Join-Path $game ("Interface\AddOns\" + $d.Helper)
  $src = Join-Path $adir $d.Source
  $script = Join-Path $adir $d.Script
  if (-not (Test-Path $src) -or -not (Test-Path $script)) {
    & $say ("{0}: the {1} addon isn't in this game folder - skipped (it comes with {1})." -f $d.Name, $d.Helper) "dim"
    return "skipped"
  }
  $file = $d.File
  $target = Join-Path $game $file
  $list = Join-Path $game "dlls.txt"
  $listed = (Test-Path $list) -and (@(Get-Content $list | Where-Object { $_.Trim() -ieq $file }).Count -gt 0)
  $same = (Test-Path $target) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $target).Hash)
  $ver = Get-TocVersion (Join-Path $adir ($d.Helper + ".toc"))
  $label = if ($ver) { "{0} (from {1} {2})" -f $d.Name, $d.Helper, $ver } else { $d.Name }
  if ($same -and $listed) { & $say ("{0}: already the newest." -f $label) "ok"; return "same" }
  if (-not $same -and (Test-Path $target)) {
    $have, $new = (Get-BuildDate $target), (Get-BuildDate $src)
    if ($have -and $new -and $have -gt $new) { & $say ("{0}: kept - yours is a newer build ({1})." -f $label, $have.ToString("d MMM yyyy")) "ok"; return "kept" }
  }
  if ($check) {
    & $say ("{0}: would be {1} by {2}'s own installer." -f $label, $(if (Test-Path $target) { "updated" } else { "installed" }), $d.Helper) "info"
    return "changed"
  }
  $was = Test-Path $target
  if ($was -and -not $same) {
    $backups = Join-Path $game "DLL-backups"
    if (-not (Test-Path $backups)) { New-Item -ItemType Directory -Path $backups | Out-Null }
    Copy-Item $target (Join-Path $backups ("{0}.{1}.bak" -f $file, $stamp)) -Force
  }
  $out = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -GameDir $game)
  $ok = ($LASTEXITCODE -eq 0)
  foreach ($l in $out) {
    $t = ([string]$l).Trim()
    if ($t -match '^(Copied|Added|Turned|warning|Not done)') { & $say ("  " + $t) $(if ($ok) { "dim" } else { "warn" }) }
  }
  if (-not $ok) { & $say ("{0}: not done - see the line above." -f $label) "warn"; return "skipped" }
  & $say ("{0}: {1} by {2}'s own installer." -f $label, $(if ($was -and -not $same) { "updated (the old one is in DLL-backups)" } elseif ($was) { "added to dlls.txt" } else { "installed" }), $d.Helper) "good"
  return "changed"
}

# ------------------------------------------------------------------ a fresh install (1.2.0)
# (18 Nov 2026, user: a friend's fresh install "had issues getting the dlls to work and getting the link
# working in launcher".) VanillaFixes (hannesmann/vanillafixes) is what loads dlls.txt: OctoLauncher starts
# the game through VanillaFixes.exe + VfPatcher.dll when its vanillaFixes mod is on. Only those two files
# are taken from its release - never its d3d9.dll / dxvk.conf (OctoLauncher's DXVK is newer).
# (the -dxvk zip: on our test PC Windows Defender blocked the plain zip's extra DLL and the whole unpack with
# it; only the two files are ever taken out of the zip, nothing else is unpacked)
$VFPINNED = "https://github.com/hannesmann/vanillafixes/releases/download/v1.5.3/vanillafixes-1.5.3-dxvk.zip"
function Install-VanillaFixes([string]$game, [string]$temp, [bool]$check, $say) {
  $missing = @("VanillaFixes.exe", "VfPatcher.dll" | Where-Object { -not (Test-Path (Join-Path $game $_)) })
  if ($missing.Count -eq 0) { & $say "VanillaFixes: there (it is what loads dlls.txt; OctoLauncher keeps it up to date)." "ok"; return $false }
  if ($check) { & $say ("VanillaFixes: missing ({0}) - would be installed." -f ($missing -join ", ")) "info"; return $true }
  & $say "Getting VanillaFixes (it loads the DLLs in dlls.txt)..." "dim"
  $url = $null
  try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/hannesmann/vanillafixes/releases/latest" -Headers $headers -TimeoutSec 30
    $a = @($rel.assets | Where-Object { $_.name -match '^vanillafixes-[\d.]+-dxvk\.zip$' }) | Select-Object -First 1
    if ($a) { $url = $a.browser_download_url }
  } catch { }
  if (-not $url) { $url = $VFPINNED }
  $zpath = Join-Path $temp "vanillafixes.zip"
  try { Invoke-WebRequest -Uri $url -OutFile $zpath -Headers $headers -UseBasicParsing -TimeoutSec 120 }
  catch { & $say ("VanillaFixes: not done - " + (Get-Why $_)) "bad"; return $false }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = $null
  try {
    $zip = [IO.Compression.ZipFile]::OpenRead($zpath)
    foreach ($f in $missing) {
      $e = $zip.Entries | Where-Object { $_.Name -ieq $f } | Select-Object -First 1
      if (-not $e) { & $say ("VanillaFixes: {0} was not in the download." -f $f) "bad"; return $false }
      $t = Join-Path $game $f
      [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $t, $true)
      try { Unblock-File $t } catch { }
    }
  } catch {
    & $say ("VanillaFixes: not done - " + (Get-Why $_)) "bad"
    return $false
  } finally {
    if ($zip) { $zip.Dispose() }
  }
  & $say "VanillaFixes: installed. In OctoLauncher turn its vanillaFixes mod on, so the game starts through it." "good"
  return $true
}

# the DLLs OctoLauncher itself puts in (kept in a new dlls.txt when they are in the folder)
$LAUNCHERDLLS = @("VanillaHelpers.dll", "nampower.dll", "UnitXP_SP3.dll", "VanillaMultiMonitorFix.dll", "transmogfix.dll", "ClassicAPI.dll")
function New-DllList([string]$game) {
  $lines = New-Object System.Collections.ArrayList
  [void]$lines.Add("# DLLs VanillaFixes loads (made by the Octo DLL Installer; OctoLauncher adds its own mods here too)")
  foreach ($f in $LAUNCHERDLLS) { if (Test-Path (Join-Path $game $f)) { [void]$lines.Add($f) } }
  return ,$lines
}

# VanillaFixes asks you to confirm whenever the list of DLLs changes. OctoLauncher writes dlls.txt.cache
# (each DLL's full path, one a line) after it changes dlls.txt, so it does not ask about its own changes;
# this does the same after ours.
function Write-DllCache([string]$game) {
  $names = @(Get-Content (Join-Path $game "dlls.txt") | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith("#") })
  $cache = Join-Path $game "dlls.txt.cache"
  if ($names.Count -eq 0) { Remove-Item $cache -ErrorAction SilentlyContinue; return }
  $body = ($names | ForEach-Object { if ([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $game $_ } }) -join "`r`n"
  [IO.File]::WriteAllText($cache, $body)
}

# antivirus programs often delete a DLL a moment after it is copied in: every file this run looked after
# (the ticked DLLs that are in dlls.txt, and VanillaFixes) that is not in the folder any more is named
function Test-Removed([string]$game, $files, $say) {
  Start-Sleep -Milliseconds 1500
  $listed = @(Get-Content (Join-Path $game "dlls.txt") | ForEach-Object { $_.Trim().ToLower() })
  $gone = @()
  foreach ($f in $files) {
    if ($listed -contains $f.ToLower() -and -not (Test-Path (Join-Path $game $f))) { $gone += $f }
  }
  foreach ($f in @("VanillaFixes.exe", "VfPatcher.dll")) { if (-not (Test-Path (Join-Path $game $f))) { $gone += $f } }
  if ($gone.Count -gt 0) {
    & $say ("Missing from the game folder: {0}. Your antivirus most likely removed them - press Antivirus help below, restore them (or use OctoLauncher's Restore blocked files), then press Install / update again." -f ($gone -join ", ")) "bad"
  }
  return $gone.Count
}

# (1.3.0) a "Play OctoWoW" desktop shortcut that starts the game through VanillaFixes.exe (it finds WoW.exe in
# its own folder - nothing has to be dragged onto it). Starting WoW.exe itself loads no DLLs.
# $script:DESKTOP can be set for tests. Returns $true when it made or fixed the shortcut.
function New-PlayShortcut([string]$game, [bool]$check, $say) {
  $vf = Join-Path $game "VanillaFixes.exe"
  if (-not (Test-Path $vf)) { return $false }
  $desk = $script:DESKTOP
  if (-not $desk) { $desk = [Environment]::GetFolderPath("Desktop") }
  if (-not $desk -or -not (Test-Path $desk)) { return $false }
  $lnk = Join-Path $desk "Play OctoWoW.lnk"
  $sh = New-Object -ComObject WScript.Shell
  if (Test-Path $lnk) {
    $old = $sh.CreateShortcut($lnk)
    if ($old.TargetPath -ieq $vf) { return $false }
  }
  if ($check) { & $say "Desktop shortcut ""Play OctoWoW"" (starts the game through VanillaFixes): would be made." "info"; return $false }
  $s = $sh.CreateShortcut($lnk)
  $s.TargetPath = $vf
  $s.WorkingDirectory = $game
  $wow = Join-Path $game "WoW.exe"
  if (Test-Path $wow) { $s.IconLocation = "$wow,0" }
  $s.Description = "Starts OctoWoW through VanillaFixes, so the DLLs in dlls.txt load"
  $s.Save()
  & $say "Desktop shortcut ""Play OctoWoW"" made: it starts the game through VanillaFixes, so your DLLs load." "good"
  return $true
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
  $script:listChanged = $false
  $fresh = -not (Test-Path $list)
  if ($fresh) {
    # (1.2.0) a fresh install has no dlls.txt until the game was started once: make it instead of stopping
    $lines = New-DllList $game
    $script:listChanged = $true
    & $say $(if ($check) { "dlls.txt: none yet - would be made." } else { "dlls.txt: none yet - making it." }) $(if ($check) { "info" } else { "good" })
  } else {
    $lines = New-Object System.Collections.ArrayList
    foreach ($l in [IO.File]::ReadAllLines($list)) { [void]$lines.Add($l) }
  }
  # downloads go to a folder inside the game folder (removed after), so an
  # antivirus exclusion for the game folder covers them too (SuperWoW)
  $temp = Join-Path $game ("DLL-download-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
  New-Item -ItemType Directory -Path $temp | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $changed = 0
  $later = New-Object System.Collections.ArrayList
  try {
    if (@(Install-VanillaFixes $game $temp $check $say)[-1] -eq $true) { $changed++ }
    foreach ($d in $picked) {
      if ($d.Helper) { [void]$later.Add($d); continue }
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
      if (-not $fresh -and -not (Test-Path $backup)) { Copy-Item $list $backup }
      [IO.File]::WriteAllLines($list, [string[]]$lines.ToArray())
    }
    foreach ($d in $later) {
      & $say ("Checking {0}..." -f $d.Name) "dim"
      $r = @(Install-Helper $d $game $stamp $check $say)
      if ($r.Count -gt 0 -and $r[$r.Count - 1] -eq "changed") { $changed++ }
    }
    if (-not $check -and (Test-Path $list)) { try { Write-DllCache $game } catch { } }
  } finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
  }
  # pfUI Octo itself comes through OctoLauncher's Addons tab (it updates it from there)
  if (-not (Test-Path (Join-Path $game "Interface\AddOns\pfUI\pfUI.toc"))) {
    & $say "pfUI Octo is not installed yet: in OctoLauncher open Addons > Add custom git addon and paste https://github.com/bdot89/pfUI" "info"
  }
  $made = $false
  try { $made = @(New-PlayShortcut $game $check $say)[-1] -eq $true } catch { & $say ("Could not make the desktop shortcut: {0}" -f $_.Exception.Message) "dim" }
  if ($check) { return "Check done - nothing was changed." }
  $gone = @(Test-Removed $game @($picked | ForEach-Object { $_.File }) $say)[-1]
  if ($gone -gt 0) { return "Not finished: your antivirus removed some files (named above). Restore them, then press Install / update again." }
  $how = "From now on start the game with OctoLauncher's Play (its vanillaFixes mod on) or the ""Play OctoWoW"" desktop shortcut (= VanillaFixes.exe) - never WoW.exe itself, which loads no DLLs."
  if ($changed -gt 0 -or $script:listChanged -or $made) {
    return "Done! $how If it won't start, copy the old DLL back from the DLL-backups folder, or put dlls.txt.pfui-backup back as dlls.txt."
  }
  return "Everything you ticked is already the newest - nothing to do. $how"
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

$W = 920   # width of the lists, the log and the rows of buttons
$form = New-Object Windows.Forms.Form
$form.Text = "Octo DLL Installer"
$form.ClientSize = New-Object Drawing.Size((22 + $W + 22), 700)
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

Label "Octo DLL Installer" 20 14 222 34 $accent (New-Object Drawing.Font("Segoe UI Semibold", 18)) | Out-Null
Label ("v" + $VERSION) 244 26 80 20 $dim | Out-Null
Label "Install / update tool: puts the OctoWoW client DLLs in, or brings the ones you have up to the newest version." 22 50 $W 22 $dim | Out-Null
Label ("1.  Close the game completely.`n" +
       "2.  Check the game folder below is right (the folder with WoW.exe in it). Use Browse if it isn't.`n" +
       "3.  Tick the DLLs you want: the ones our addons use are ticked already, the extras under them are up to you.`n" +
       "4.  Press Install / update. Then start the game from OctoLauncher as usual.") 22 82 $W 84 $fg | Out-Null

Label "Game folder" 22 172 120 22 $dim $bold | Out-Null
$dirBox = New-Object Windows.Forms.TextBox
$dirBox.Location = New-Object Drawing.Point(22, 196)
$dirBox.Size = New-Object Drawing.Size(($W - 140), 26)
$dirBox.BackColor = $panel
$dirBox.ForeColor = $fg
$dirBox.BorderStyle = "FixedSingle"
$form.Controls.Add($dirBox)
$browse = Button "Browse..." (22 + $W - 130) 192 130 $accent
$dirState = Label "" 22 224 $W 22 $dim

# the two lists: the DLLs our addons use, then the extras
$oursHead = Label "For our addons" 22 0 150 22 $green $bold
$oursHint = Label "pfUI Octo, OctoBG, DmorphOcto and the rest use these - ticked to start with." 172 0 ($W - 150) 22 $dim
$moreHead = Label "Optional extras" 22 0 150 22 $accent $bold
$moreHint = Label "From the Vanilla Addon Index's DLL list. Tick only what you want. Right-click one to open its page." 172 0 ($W - 150) 22 $dim
$menu = New-Object Windows.Forms.ContextMenuStrip
$openItem = $menu.Items.Add("Open its page")
$openItem.Add_Click({
  $it = $menu.Tag
  if ($it -and $it.Tag) { $p = Get-Page $it.Tag; if ($p) { try { Start-Process $p } catch { } } }
})
function New-List($third, [int]$thirdW, $entries) {
  $v = New-Object Windows.Forms.ListView
  $v.Location = New-Object Drawing.Point(22, 0)
  $v.Size = New-Object Drawing.Size($W, 100)
  $v.View = "Details"
  $v.CheckBoxes = $true
  $v.FullRowSelect = $true
  $v.BackColor = $panel
  $v.ForeColor = $fg
  $v.BorderStyle = "FixedSingle"
  $v.HeaderStyle = "Nonclickable"
  $v.ShowItemToolTips = $true
  [void]$v.Columns.Add("DLL", 170)
  [void]$v.Columns.Add("You have", 165)
  [void]$v.Columns.Add($third, $thirdW)
  [void]$v.Columns.Add("What it does", ($W - 22 - 170 - 165 - $thirdW))
  foreach ($d in $entries) {
    $item = New-Object Windows.Forms.ListViewItem($d.Name)
    $item.UseItemStyleForSubItems = $false
    [void]$item.SubItems.Add("")
    if ($d.Ours) { $s = $item.SubItems.Add($d.Used); $s.ForeColor = $green }
    else { $s = $item.SubItems.Add($d.From); $s.ForeColor = $dim }
    $s = $item.SubItems.Add($(if ($d.Warn) { "(!) " + $d.Warn + " " + $d.About } else { $d.About }))
    if ($d.Warn) { $s.ForeColor = $gold }
    $tip = $d.About
    if ($d.Warn) { $tip = "Careful: " + $d.Warn + "`n" + $tip }
    if ($d.Ours) { $tip += "`nUsed by: " + $d.Used }
    $item.ToolTipText = $tip + "`nRight-click: open its page."
    $item.Checked = [bool]$d.Ours
    $item.Tag = $d
    [void]$v.Items.Add($item)
  }
  $v.Add_MouseUp({
    param($s, $e)
    if ($e.Button -ne [Windows.Forms.MouseButtons]::Right) { return }
    $hit = $s.HitTest($e.Location)
    if ($hit.Item) { $menu.Tag = $hit.Item; $openItem.Text = "Open " + $hit.Item.Tag.Name + "'s page"; $menu.Show($s, $e.Location) }
  })
  $form.Controls.Add($v)
  return $v
}
$viewOurs = New-List "Used by" 220 @($DLLS | Where-Object { $_.Ours })
$viewMore = New-List "From" 150 @($DLLS | Where-Object { -not $_.Ours })
$views = @($viewOurs, $viewMore)

$all = Button "Tick ours only" 22 0 150 $dim
$none = Button "Untick all" 180 0 110 $dim
$checkBtn = Button "Check for updates" (22 + $W - 350) 0 170 $accent
$install = Button "Install / update" (22 + $W - 170) 0 170 $green

$progHead = Label "Progress" 22 0 300 22 $dim $bold
$log = New-Object Windows.Forms.RichTextBox
$log.Location = New-Object Drawing.Point(22, 0)
$log.Size = New-Object Drawing.Size($W, 92)
$log.BackColor = $panel
$log.ForeColor = $fg
$log.BorderStyle = "None"
$log.ReadOnly = $true
$log.Font = New-Object Drawing.Font("Consolas", 9)
$form.Controls.Add($log)
$footer = Label "Your old DLLs and addons are kept in DLL-backups in the game folder. Antivirus often blocks SuperWoW: see Antivirus help." 22 0 ($W - 170) 34 $dim
$avBtn = Button "Antivirus help" (22 + $W - 150) 0 150 $gold

# the window's height from the lists' rows; on a small screen the extras list
# and the log give up room first, then the window scrolls
function Get-ListHeight($v, [int]$rows) {
  $top, $rh = 26, 20
  try {
    [void]$v.Handle
    $r = $v.GetItemRect(0)
    if ($r.Height -ge 12) { $top, $rh = $r.Top, $r.Height }
  } catch { }
  return ($top + $rh * $rows + 4)
}
function Set-Layout([int]$moreRows, [int]$logH) {
  $y = 254
  $oursHead.Top = $y; $oursHint.Top = $y; $y += 24
  $viewOurs.Top = $y; $viewOurs.Height = Get-ListHeight $viewOurs $viewOurs.Items.Count; $y += $viewOurs.Height + 12
  $moreHead.Top = $y; $moreHint.Top = $y; $y += 24
  $viewMore.Top = $y; $viewMore.Height = Get-ListHeight $viewMore $moreRows; $y += $viewMore.Height + 8
  foreach ($b in @($all, $none, $checkBtn, $install)) { $b.Top = $y }
  $y += 42
  $progHead.Top = $y; $y += 24
  $log.Top = $y; $log.Height = $logH; $y += $logH + 10
  $footer.Top = $y + 4; $avBtn.Top = $y; $y += 44
  return $y
}
$need = Set-Layout $viewMore.Items.Count 92
$edge = $form.Height - $form.ClientSize.Height
$room = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height - $edge - 8
if ($need -gt $room) { $need = Set-Layout ([Math]::Max(3, $viewMore.Items.Count - [Math]::Ceiling(($need - $room) / 20))) 92 }
if ($need -gt $room) { $need = Set-Layout 3 60 }
if ($need -gt $room) { $form.AutoScroll = $true; $form.AutoScrollMinSize = New-Object Drawing.Size(0, $need); $need = $room }
$form.ClientSize = New-Object Drawing.Size((22 + $W + 22), $need)

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
      $dirState.Text = "WoW.exe found, no dlls.txt yet (a fresh install) - Install / update makes it, and sets up VanillaFixes if needed."
      $dirState.ForeColor = $green
    }
  } elseif ($g) {
    $dirState.Text = "No WoW.exe in this folder. Press Browse and pick the folder WoW.exe is in."
    $dirState.ForeColor = $red
  } else {
    $dirState.Text = "Press Browse and pick your OctoWoW folder (the one with WoW.exe in it)."
    $dirState.ForeColor = $gold
  }
  foreach ($v in $views) {
    foreach ($it in $v.Items) {
      $have = Get-Have $it.Tag $g
      $it.SubItems[1].Text = $have
      $it.SubItems[1].ForeColor = $(if ($have -match "^(not installed|needs )") { $dim } elseif ($have -match "not in dlls|no addon|addon only") { $gold } else { $fg })
      # (a DLL that comes with one of our addons can't go in without that addon)
      if ($have -like "needs *") { $it.Checked = $false }
    }
  }
}

$browse.Add_Click({
  $dlg = New-Object Windows.Forms.FolderBrowserDialog
  $dlg.Description = "Pick your OctoWoW folder - the one with WoW.exe in it."
  if ($dirBox.Text -and (Test-Path $dirBox.Text)) { $dlg.SelectedPath = $dirBox.Text }
  if ($dlg.ShowDialog($form) -eq "OK") { $dirBox.Text = $dlg.SelectedPath; Refresh-State }
})
$dirBox.Add_Leave({ Refresh-State })
$all.Add_Click({
  foreach ($it in $viewOurs.Items) { $it.Checked = -not ($it.SubItems[1].Text -like "needs *") }
  foreach ($it in $viewMore.Items) { $it.Checked = $false }
})
$none.Add_Click({ foreach ($v in $views) { foreach ($it in $v.Items) { $it.Checked = $false } } })

function Run([bool]$check) {
  $picked = @(foreach ($v in $views) { foreach ($it in $v.Items) { if ($it.Checked) { $it.Tag } } })
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
