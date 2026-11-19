OCTO DLL INSTALLER
==================

An install / update tool for the OctoWoW client DLLs: it puts in the ones you
don't have and brings the ones you have up to the newest version, straight
from their authors' release pages. You don't need pfUI or any add-on for this.

FRESH INSTALL - THE WHOLE SETUP, IN ORDER
  1. Install the game with OctoLauncher and let it finish.
  2. In OctoLauncher's Settings / Mods, make sure vanillaFixes is ON. VanillaFixes
     is what loads the DLLs: with it off, none of them load. Leave vanillaHelpers,
     nampower, unitXp and dxvk on too.
  3. Close the game completely.
  4. Run this tool (HOW TO USE below) and press Install / update. On a fresh
     install it also makes dlls.txt, puts in VanillaFixes if it is missing
     (VanillaFixes.exe + VfPatcher.dll only), and puts in SuperWoW, which the
     launcher doesn't install.
  5. If it says a file is missing afterwards, your antivirus removed it: see
     SUPERWOW AND WINDOWS DEFENDER below, or use OctoLauncher's "Restore blocked
     files", then press Install / update again.
  6. Add pfUI Octo in the launcher: OctoLauncher > Addons > Add custom git addon >
     paste  https://github.com/bdot89/pfUI  > Install. The launcher keeps it up
     to date from then on. Use exactly that link.
  7. Start the game from OctoLauncher. The first time after new DLLs went in,
     VanillaFixes may ask you to confirm the DLL list: say yes.

HOW TO USE
  1. Close the game completely.
  2. Double-click "Install or update DLLs.bat". A window opens.
  3. Check the game folder at the top is right: the folder with WoW.exe in it.
     If it isn't, press Browse and pick it.
  4. Tick the DLLs you want. The top list ("For our addons") is ticked to start
     with; the "Optional extras" under it are up to you.
  5. Press Install / update. When it says Done, start the game from OctoLauncher
     as usual. Run it again any time to update.

"Check for updates" only tells you what would change. It changes nothing.
Right-click a DLL in the window to open its page.

FOR OUR ADDONS (ticked to start with)
  ClassicAPI    newer game functions for add-ons (auras, casts, items, loot, combat log)
  SuperWoW      unit GUIDs, cast events, focus, mouseover casting
  nampower      faster spell casting and spell events for add-ons
  UnitXP_SP3    distances, line of sight, camera and targeting options
  WeirdUtils    world markers, minimap icons, transmog fix, bigger cursor and more
  DmorphHelper  weapon glows, your own skin / face / hair and more in DmorphOcto.
                It comes with DmorphOcto and is put in by DmorphOcto's own
                installer (only when DmorphOcto is in your AddOns folder).

OPTIONAL EXTRAS (from the Vanilla Addon Index's DLL list, unticked)
  AuctionQueryThrottle  no 5-second wait between auction house searches
  Interact      an interact key (+ its addon). Careful: v1.0.4 crashed OctoWoW
                on every key press when we tried it.
  LockPort      warlock summoning with Auto Summon (+ the LockPort addon)
  OctoBus       zeppelin and boat timers: ZepSense.dll + the OctoBus addon
  TotemCircles  totem ranges as circles on the ground (+ its addon)
  PerfBoost     more FPS by drawing far-away things less (+ PerfBoostSettings).
                An old archived copy, never tried on OctoWoW.
  WoWTranslate  chat translation Chinese / Japanese / Korean / Russian <-> English
                through Google Translate (+ its addon and cacert.pem)
  WowPresence   your character and zone in Discord (+ WowPresence.exe). Needs your
                own Discord Application ID in WowPresence\discord_application_id.
  An addon that comes with a DLL goes into Interface\AddOns; the old one is kept
  in DLL-backups\AddOns.

LEFT OUT OF THE INDEX'S LIST, AND WHY
  VanillaHelpers, VanillaMultiMonitorFix, DXVK
                OctoLauncher puts these in and keeps them up to date itself.
  VanillaFixes  also the launcher's, but the tool puts it in when it is missing
                (only VanillaFixes.exe and VfPatcher.dll, never its older DXVK).
  LeviFix       OctoLauncher already has this fix.
  No1600x1200   clashes with VanillaMultiMonitorFix, which OctoLauncher puts in.
  Vanilla Tweaks, Modernization Tool
                they change WoW.exe / set up the whole client: not DLLs for dlls.txt.
  GlueXML, RaidVisuals
                MPQ patches, not DLLs (GlueXML's patch-Z.mpq would also take the
                place of DMorph's ported pack).
  HearthDB      only its source code, no DLL to download.
  PandaConquest an addon, no DLL in it.

GOOD TO KNOW
  - Each DLL is only replaced when the download is different, and never when the
    one you have is newer.
  - Your old DLLs and addons are kept in the DLL-backups folder inside the game folder.
  - New DLLs are added to dlls.txt (the list the launcher loads). The first time,
    a copy of your old list is saved as dlls.txt.pfui-backup.
  - No dlls.txt yet (a fresh install)? The tool makes it, keeping the launcher's
    own DLLs that are already in the folder.
  - After changing dlls.txt it writes dlls.txt.cache the way OctoLauncher does, so
    VanillaFixes doesn't keep asking about the new DLLs.
  - After installing it checks nothing it put in was removed by your antivirus.
  - Antivirus programs often block SuperWoW (see below). If it is skipped, the
    other DLLs still install.

SUPERWOW AND WINDOWS DEFENDER
  Windows Defender and other antivirus programs often flag SuperWoW. It changes
  how the game runs, which looks like what cheats and viruses do. It's a
  well-known OctoWoW / Turtle WoW mod, but only allow it if you trust it.
  The tool's "Antivirus help" button shows these steps too.

  The easy way - allow what was blocked:
    1. Open Windows Security (Start menu > type "Windows Security").
    2. Virus & threat protection > Protection history.
    3. Click the newest SuperWoW item > Actions > Allow on device.
    4. Press Install / update in the tool again.

  If it keeps getting blocked - exclude the game folder:
    1. Windows Security > Virus & threat protection.
    2. Under "Virus & threat protection settings" click Manage settings.
    3. Scroll to Exclusions > Add or remove exclusions.
    4. Add an exclusion > Folder > pick your game folder (the one with WoW.exe).
    5. Press Install / update again. The tool downloads into the game folder, so the
       exclusion covers the download too.

  Another antivirus (Avast, Norton, McAfee ...): look in its Quarantine or
  Exceptions, restore SuperWoWhook.dll or add the game folder as an exception.

UNDO
  Copy the old DLL back from DLL-backups into the game folder, or rename
  dlls.txt.pfui-backup back to dlls.txt. To drop one DLL, take its line out of
  dlls.txt.

Nothing opens? Right-click "Install or update DLLs.bat" > Run as administrator, or run
installer\OctoDLLInstaller.ps1 with PowerShell.
