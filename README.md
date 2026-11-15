# Octo DLL Installer

An **install / update tool** for the **OctoWoW** client DLLs. It puts in the DLLs you don't have yet, and brings the ones you have up to the newest version, straight from their authors' release pages.
Tick what you want, press **Install / update**. No add-ons needed. Run it again any time to update.

![The installer window](images/window.png)

## How to use

1. **Download** the zip from the [latest release](https://github.com/bdot89/OctoDLLInstaller/releases/latest) and unzip it anywhere.
2. **Close the game** completely.
3. Double-click **`Install or update DLLs.bat`**. The window opens.
4. Check the **game folder** is right (the folder with `WoW.exe` in it). If it isn't, press **Browse** and pick it.
5. **Tick** the DLLs you want. The top list, **For our addons**, is ticked to start with; the **Optional extras** under it are up to you.
6. Press **Install / update**. When it says *Done*, start the game from **OctoLauncher** as usual.

**To update later**, just run it again: DLLs you don't have are installed, older ones are updated, and the newest ones are left alone.
**Check for updates** only tells you what would change. It changes nothing. **Right-click** a DLL to open its page.

![After a check: what's newest and what would change](images/check.png)

## For our addons (ticked to start with)

| DLL | What it does | Used by |
| --- | --- | --- |
| [ClassicAPI](https://github.com/brues-code/ClassicAPI) | Newer game functions for add-ons: auras, casts, items, loot, the combat log | pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoArenaFrames, KillShot, UpsiAuras |
| [SuperWoW](https://github.com/balakethelock/SuperWoW) | Unit GUIDs, cast events, focus and mouseover casting | nearly all of them |
| [nampower](https://github.com/brues-code/nampower) | Faster spell casting (less delay between casts) and spell events for add-ons | pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoRank, OctoArenaFrames, UpsiAuras, HoryRogue |
| [UnitXP_SP3](https://github.com/brues-code/UnitXP_SP3) | Distances, line of sight, better camera and targeting options | pfUI Octo, WhoDidIt |
| [WeirdUtils](https://codeberg.org/MarcelineVQ/WeirdUtils) | World markers, minimap icons, a transmog fix, a bigger cursor and more | pfUI Octo, OctoBG |
| [DmorphHelper](https://github.com/bdot89/DmorphOcto) | Weapon glows, your own skin / face / hair, sizes and more. Comes with DmorphOcto and is put in by DmorphOcto's own installer, only when DmorphOcto is in your AddOns folder | DmorphOcto |

## Optional extras (unticked)

From the [Vanilla Addon Index](https://vanilla-addon-index.github.io/?type=dll)'s DLL list. When a DLL comes with an addon, the addon goes into `Interface\AddOns` too.

| DLL | What it does |
| --- | --- |
| [AuctionQueryThrottle](https://github.com/brues-code/AuctionQueryThrottle) | No 5-second wait between auction house searches |
| [Interact](https://github.com/lookino/Interact) | An interact key, with its key binding addon. **Careful:** v1.0.4 crashed OctoWoW on every key press when we tried it |
| [LockPort](https://octowow.st/git/OEVG/LockPort) | Warlock summoning with Auto Summon, with the LockPort addon |
| [OctoBus](https://octowow.st/git/OEVG/Octobus) | Zeppelin and boat timers: [ZepSense.dll](https://github.com/Phridgey/OctoBus) and the OctoBus addon |
| [TotemCircles](https://octowow.st/git/veber01/Octo-TotemCircles) | Totem ranges as circles on the ground, with its addon |
| [PerfBoost](https://github.com/RetroCro/TurtleWoW-Mods) | More FPS by drawing far-away things less, with PerfBoostSettings. An old archived copy, never tried on OctoWoW |
| [WoWTranslate](https://github.com/jhinzuo2/wow-translate) | Chat translation (Chinese, Japanese, Korean, Russian and English) through Google Translate, with its addon and `cacert.pem` |
| [WowPresence](https://octowow.st/git/Dusk/WowPresence) | Your character and zone in Discord, with `WowPresence.exe`. Needs your own Discord Application ID in `WowPresence\discord_application_id` |

**Left out of the index's list, and why**

- **VanillaHelpers, VanillaMultiMonitorFix, DXVK, VanillaFixes**: OctoLauncher puts these in and keeps them up to date itself.
- **LeviFix**: OctoLauncher already has this fix.
- **No1600x1200**: clashes with VanillaMultiMonitorFix, which OctoLauncher puts in.
- **Vanilla Tweaks, Modernization Tool**: they change `WoW.exe` or set up the whole client. They aren't DLLs for `dlls.txt`.
- **GlueXML, RaidVisuals**: MPQ patches, not DLLs. GlueXML's `patch-Z.mpq` would also take the place of DMorph's ported pack.
- **HearthDB**: only its source code, no DLL to download.
- **PandaConquest**: an addon, no DLL in it.

## Safe by design

- A DLL is only replaced when the download is different, and **never** when the one you have is newer.
- Your old DLLs and addons are kept in **`DLL-backups`** inside the game folder.
- New DLLs are added to **`dlls.txt`** (the list the launcher loads). The first time, your old list is saved as `dlls.txt.pfui-backup`.
- Every download is checked to be a real Windows DLL before it's used.

**No `dlls.txt` yet?** Start the game once from OctoLauncher with the **vanillaHelpers** mod ticked, close it, then run the installer again.

**Undo:** copy the old DLL back from `DLL-backups`, or rename `dlls.txt.pfui-backup` back to `dlls.txt`.

## SuperWoW and Windows Defender

Windows Defender and other antivirus programs often flag **SuperWoW**. It changes how the game runs, which looks like what cheats and viruses do.
It's a well-known OctoWoW / Turtle WoW mod, but only allow it if you trust it. The tool's **Antivirus help** button shows these steps too.

**The easy way: allow what was blocked**

1. Open **Windows Security** (Start menu > type *Windows Security*).
2. **Virus & threat protection** > **Protection history**.
3. Click the newest **SuperWoW** item > **Actions** > **Allow on device**.
4. Press **Install / update** in the tool again.

**If it keeps getting blocked: exclude the game folder**

1. **Windows Security** > **Virus & threat protection**.
2. Under *Virus & threat protection settings* click **Manage settings**.
3. Scroll to **Exclusions** > **Add or remove exclusions**.
4. **Add an exclusion** > **Folder** > pick your game folder (the one with `WoW.exe`).
5. Press **Install / update** again. The tool downloads into the game folder, so the exclusion covers the download too.

**Another antivirus** (Avast, Norton, McAfee ...): look in its *Quarantine* or *Exceptions*, restore `SuperWoWhook.dll`, or add the game folder as an exception.

## Nothing opens?

Right-click **`Install or update DLLs.bat`** > **Run as administrator**, or right-click `installer\OctoDLLInstaller.ps1` > **Run with PowerShell**.

---

The DLLs and addons belong to their authors; this tool only downloads them from their own pages (PerfBoost, whose page is gone, from an archive copy).
