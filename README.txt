OCTO DLL INSTALLER
==================

An install / update tool for the OctoWoW client DLLs: it puts in the ones you
don't have and brings the ones you have up to the newest version, straight
from their authors' release pages. You don't need pfUI or any add-on for this.

HOW TO USE
  1. Close the game completely.
  2. Double-click "Install or update DLLs.bat". A window opens.
  3. Check the game folder at the top is right: the folder with WoW.exe in it.
     If it isn't, press Browse and pick it.
  4. Tick the DLLs you want (all are ticked to start with).
  5. Press Install / update. When it says Done, start the game from OctoLauncher
     as usual. Run it again any time to update.

"Check for updates" only tells you what would change. It changes nothing.

THE DLLS
  ClassicAPI   newer game functions for add-ons (auras, casts, items, loot, combat log)
  SuperWoW     unit GUIDs, cast events, focus, mouseover casting
  nampower     faster spell casting and spell events for add-ons
  UnitXP_SP3   distances, line of sight, camera and targeting options
  WeirdUtils   world markers, minimap icons, transmog fix, bigger cursor and more

GOOD TO KNOW
  - Each DLL is only replaced when the download is different, and never when the
    one you have is newer.
  - Your old DLLs are kept in the DLL-backups folder inside the game folder.
  - New DLLs are added to dlls.txt (the list the launcher loads). The first time,
    a copy of your old list is saved as dlls.txt.pfui-backup.
  - No dlls.txt yet? Start the game once from OctoLauncher with the vanillaHelpers
    mod ticked, close it, then run the tool again.
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
  dlls.txt.pfui-backup back to dlls.txt.

Nothing opens? Right-click "Install or update DLLs.bat" > Run as administrator, or run
installer\OctoDLLInstaller.ps1 with PowerShell.
