#!/usr/bin/env bash
# Octo DLL Installer for Linux (1.4.0, 20 Nov 2026) - the same install / update
# tool as "Install or update DLLs.bat", for OctoWoW run under Wine, Proton or
# Lutris. Needs only bash, curl and unzip. Iso on the OctoWoW Discord: "I can't
# run it on linux. And we have a lot of ppl on octo that runs linux".
#
# It does what installer/OctoDLLInstaller.ps1 does: one pinned release from
# each author's page (1.5.0: its tag and the DLL's SHA-256 are written below,
# checked with sha256sum - a file with another hash is refused), copied only when it
# differs (the old one kept in <game>/DLL-backups), never over a newer build
# you already have, and added to dlls.txt (backed up once to
# dlls.txt.pfui-backup). It puts VanillaFixes in when it is missing, makes
# dlls.txt on a fresh install, and writes dlls.txt.cache like OctoLauncher.
# Instead of the Windows desktop shortcut it makes "Play OctoWoW.sh" in the
# game folder plus a .desktop launcher (plain Wine only; Lutris and Steam
# players get the steps printed instead).
#
#   bash install-linux.sh                     asks for the game folder, shows the tick list
#   bash install-linux.sh ~/Games/OctoWoW     that game folder
#   bash install-linux.sh --check             only says what would change
#   bash install-linux.sh --yes               no tick list: installs what is ticked to start with
#   bash install-linux.sh --only "SuperWoW,LockPort"   just those (names as in the list)
#   bash install-linux.sh --no-shortcut       no Play OctoWoW launcher
#
# If you change a DLL entry or an install rule here, change the Windows
# installer too (and the other way round).

set -u
VERSION="1.5.0"
UA="Octo-DLL-Installer"
OCTOGIT="https://octowow.st/git/api/v1/repos/"
GHAPI="https://api.github.com/repos/"

# ------------------------------------------------------------------ output
if [ -t 1 ]; then
  C_GOOD=$'\e[32m'; C_WARN=$'\e[33m'; C_BAD=$'\e[31m'; C_INFO=$'\e[36m'; C_DIM=$'\e[90m'; C_BOLD=$'\e[1m'; C_OFF=$'\e[0m'
else
  C_GOOD=""; C_WARN=""; C_BAD=""; C_INFO=""; C_DIM=""; C_BOLD=""; C_OFF=""
fi
say() { # kind text
  local c=""
  case "$1" in good) c=$C_GOOD ;; warn) c=$C_WARN ;; bad) c=$C_BAD ;; info) c=$C_INFO ;; dim) c=$C_DIM ;; esac
  printf '%s%s%s\n' "$c" "$2" "$C_OFF"
}
die() { say bad "Not done: $1"; exit 1; }
# questions read from the terminal, so "bash <(curl ...)" works too
ask() { # prompt -> REPLY; fails when nobody can answer (then nothing is done)
  REPLY=""
  if { exec 3</dev/tty; } 2>/dev/null; then
    read -r -e -p "$1" REPLY <&3; local r=$?; exec 3<&-; return $r
  fi
  read -r -p "$1" REPLY
}
CR=$'\r'

for t in curl unzip sha256sum; do
  command -v "$t" >/dev/null 2>&1 || die "this needs '$t'. Install it (for example: sudo apt install $t, sudo dnf install $t or sudo pacman -S $t; sha256sum is in coreutils) and run this again."
done

# ------------------------------------------------------------------ the DLLs
# Same list as the Windows installer. Kind: release (that release, by its tag:
# the DLL itself or a .zip holding it; Api for non-GitHub sites), archive (a
# repository .zip of one commit holding the DLL), url (the DLL from a plain link
# to one commit), helper (comes with one of our addons).
#
# (1.5.0, 25 Nov 2026, code review: "pulls /releases/latest of every DLL,
# checked only for MZ".) Every download is PINNED: the release tag and, with
# pin, the SHA-256 of the DLL that was tested (the same as the Windows
# installer's; our five = pfUI Octo's tools/install_dlls.ps1). A file whose hash
# differs is refused in red and never copied; a DLL with no pin is refused too.
# To move a pin: test the new release in game, then change its tag (or commit
# link) and hash here and in installer/OctoDLLInstaller.ps1, in one commit:
#   sha256sum <the dll>        (Windows: Get-FileHash <the dll> -Algorithm SHA256)
N=0
add() { # name file kind source api addon addonzip ours used about warn page tag
  D_NAME[N]=$1; D_FILE[N]=$2; D_KIND[N]=$3; D_SRC[N]=$4; D_API[N]=$5; D_ADDON[N]=$6; D_ADDONZIP[N]=$7
  D_OURS[N]=$8; D_USED[N]=$9; D_ABOUT[N]=${10}; D_WARN[N]=${11}; D_PAGE[N]=${12}; D_TAG[N]=${13}
  D_SHA[N]=""; D_ADDONSHA[N]=""
  N=$((N + 1))
}
pin() { D_SHA[N - 1]=$1; [ $# -gt 1 ] && D_ADDONSHA[N - 1]=$2; return 0; } # the DLL's sha256 [the AddonZip's, for a plain zip file]
# ---- used by our addons ----
add ClassicAPI ClassicAPI.dll release brues-code/ClassicAPI "" "" "" 1 \
  "pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoArenaFrames, KillShot, UpsiAuras" \
  "Newer game functions for add-ons: auras, casts, items, loot, the combat log." "" "https://github.com/brues-code/ClassicAPI" v1.23.9
pin 6e79a2862602cf9212319292ebfb9b6d555fb62acd0f2ea5ee9f5acc490aabc4
# (its release tag is "Release"; the release's name says 2.2)
add SuperWoW SuperWoWhook.dll release balakethelock/SuperWoW "" "" "" 1 "nearly all of our addons" \
  "Unit GUIDs, cast events, focus and mouseover casting." "" "https://github.com/balakethelock/SuperWoW" Release
pin bd214b32c878649e94ce654835946bd05e0ce7710e8f01bae10d8ab50a89351d
add nampower nampower.dll release brues-code/nampower "" "" "" 1 \
  "pfUI Octo, OctoBG, DmorphOcto, WhoDidIt, OctoRank, OctoArenaFrames, UpsiAuras, HoryRogue" \
  "Faster spell casting (less delay between casts) and spell events for add-ons." "" "https://github.com/brues-code/nampower" v4.6.1
pin 304bdb35bc00b18ee092b3bc01195319f717c37d9c6babe6775e8fe278229d22
add UnitXP_SP3 UnitXP_SP3.dll release brues-code/UnitXP_SP3 "" "" "" 1 "pfUI Octo, WhoDidIt" \
  "Distances, line of sight and better camera / targeting options." "" "https://github.com/brues-code/UnitXP_SP3" v90
pin 1d1a622fc4fd74864bdd5aa29d8c4ed2dd5cbb0340f978cbf4daca815235d10a
add WeirdUtils weirdutils_noperf.dll release MarcelineVQ/WeirdUtils "https://codeberg.org/api/v1/repos/" "" "" 1 "pfUI Octo, OctoBG" \
  "World markers, minimap icons, a transmog fix, a bigger cursor and more." "" "https://codeberg.org/MarcelineVQ/WeirdUtils" v0.7.1
pin 29fb2573c899ac378a41ff52cd652ab26494d7911ce5c524ea1f49273f492e76
add DmorphHelper DmorphHelper.dll helper DmorphOcto "" "" "" 1 "DmorphOcto" \
  "Weapon glows, your own skin / face / hair and more in DmorphOcto. Comes with DmorphOcto." "" "https://github.com/bdot89/DmorphOcto" ""
# ---- optional extras: the Vanilla Addon Index's DLL list ----
# (unticked unless you tick it, as in pfUI Octo's installer)
add AuctionQueryThrottle AuctionQueryThrottle.dll release brues-code/AuctionQueryThrottle "" "" "" 0 "" \
  "Your call (off unless ticked): lifts the game's 5-second wait between auction house searches." "" "https://github.com/brues-code/AuctionQueryThrottle" v1.2.0
pin 720b7ad72941206249df23cb9d36addafa2634f190081f7b33834b84af184f5e
add Interact Interact.dll release lookino/Interact "" Interact "" 0 "" \
  "An interact key: one key to talk to, loot or use what's in front of you (+ its addon)." \
  "v1.0.4 crashed OctoWoW on every key press when we tried it (29 Oct 2026)." "https://github.com/lookino/Interact" v1.0.4
pin ab716314eed559a10607ecdc655f71911196ffae69706cf1d373d01df86a915d
# (no releases: the repository as it was at one commit)
add LockPort LockPort.dll archive "https://octowow.st/git/OEVG/LockPort/archive/9227c16f0a6dd77cb9fef5d1e1aa8967d54da000.zip" "" LockPort "" 0 "" \
  "For warlocks: summons the people who type 123, with Auto Summon (+ the LockPort addon)." "" "https://octowow.st/git/OEVG/LockPort" "(9227c16)"
pin 96bdb518e0b58106d585b7a9c577cd3437b497f97178656b4fc7fe68acd777c8
add OctoBus ZepSense.dll release Phridgey/OctoBus "" OctoBus "https://octowow.st/git/OEVG/Octobus/archive/c3455b32169f7464068f26c043976aa888a15af1.zip" 0 "" \
  "Zeppelin and boat timers: ZepSense.dll + the OctoBus addon." "" "https://octowow.st/git/OEVG/Octobus" 1.3.1
pin 8e68dfbb64cf95fabf255b7c36679e4487db5336461fb9a1b966014df918d932
add TotemCircles TotemCircles.dll release veber01/Octo-TotemCircles "$OCTOGIT" TotemCircles "" 0 "" \
  "For shamans: your totems' ranges as circles on the ground (+ its addon)." "" "https://octowow.st/git/veber01/Octo-TotemCircles" v0.5
pin 5f8e9965d1b0e0847b7d2f31c1f08b22bf1e891df000b86aac818b74b8a0e42d
add PerfBoost perf_boost.dll url "https://github.com/RetroCro/TurtleWoW-Mods/raw/5ce2e1b43eb07d17a8d25a7ba5f610aa666c006a/Archive/DLL%20BACKUP/perf_boost.dll" "" \
  PerfBoostSettings "https://github.com/RetroCro/TurtleWoW-Mods/raw/5ce2e1b43eb07d17a8d25a7ba5f610aa666c006a/Archive/DLL%20BACKUP/perfboostsettings.zip" 0 "" \
  "More FPS: draws far-away players, creatures and effects less (+ PerfBoostSettings)." \
  "An old archived copy (its own page is gone), never tried on OctoWoW." "https://github.com/RetroCro/TurtleWoW-Mods" "(archived copy)"
pin 7019e2f31c4f56caa616f1b4b2587c56ff276f2c27c9f35535e2578eafbd4dbe 9a0e0d74e8c638589ecf7a50b83e37fbe069ff95b41083ded34e30f4e6b2e3ba
add WoWTranslate WoWTranslate.dll release jhinzuo2/wow-translate "" WoWTranslate "" 0 "" \
  "Translates chat Chinese / Japanese / Korean / Russian <-> English through Google Translate (+ its addon)." "" "https://github.com/jhinzuo2/wow-translate" v1.5
pin 81449935b0532a8aac9fd642e4e4b1dc499732ed042d34545383044e7c0d17ea
add WowPresence WowPresence.dll release Dusk/WowPresence "$OCTOGIT" "" "" 0 "" \
  "Your character and zone in Discord. Needs your own Discord Application ID." \
  "On Linux Discord only sees it through a Wine-Discord bridge (rpc-bridge / wine-discord-ipc-bridge)." "https://octowow.st/git/Dusk/WowPresence" v1.3
pin 8114de12c2a497fd0e185e94367f583f576eb650de4a1fc7011a68b88b5d51d2
# files that come beside a DLL (curl's dated certificate list for WoWTranslate, WowPresence's helper program)
CACERT_URL="https://curl.se/ca/cacert-2026-11-05.pem"
CACERT_SHA=427c064216761a1e72a8b30f0d954d08cb6e4435a82091fb865afd20c8497285
WPEXE_SHA=bbe039d4d9bf14f7ecce680556e02705cd56f3ce4c3bdf3b47c2fc397a680910
# VanillaFixes (always v1.5.3, also OctoLauncher's): only these two files are taken from its zip
VF_EXE_SHA=228d7bb5e3b5b0c2062d6c5f40c38c2a173e4c80d8a5d9e4077be800431b48a3
VF_DLL_SHA=f283b6b5ad8042e7995eff9768c150042dd47de6e5f00ffe530d2e67743df81d

# ------------------------------------------------------------------ helpers
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
# Linux folders care about upper/lower case, Wine and the game don't: find
# what is really there ("Interface/Addons", "Nampower.dll" ...)
ci_child() { # dir name -> the existing child with that name in any case, else dir/name
  local f=""
  [ -d "$1" ] && f=$(find "$1" -mindepth 1 -maxdepth 1 -iname "$2" -print -quit 2>/dev/null)
  if [ -n "$f" ]; then printf '%s' "$f"; else printf '%s/%s' "$1" "$2"; fi
}
ci_path() { # base "a/b/c" -> base/a/b/c with each part as it is really spelled
  local p=$1 part IFS=/
  for part in $2; do [ -n "$part" ] && p=$(ci_child "$p" "$part"); done
  printf '%s' "$p"
}
find_ci_r() { find "$1" -type f -iname "$2" -print -quit 2>/dev/null; } # dir name -> first file anywhere below

is_dll() { # a real Windows DLL: 10 kB or more, starting with MZ
  [ -f "$1" ] || return 1
  [ "$(wc -c <"$1")" -ge 10000 ] || return 1
  [ "$(head -c 2 "$1")" = "MZ" ]
}
pe_date() { # the build time in the DLL's header (seconds), empty when there is none
  local pe ts
  pe=$(od -An -t u4 -j 60 -N 4 "$1" 2>/dev/null | tr -d ' ')
  [ -n "$pe" ] || return 0
  ts=$(od -An -t u4 -j $((pe + 8)) -N 4 "$1" 2>/dev/null | tr -d ' ')
  [ -n "$ts" ] && [ "$ts" != 0 ] && printf '%s' "$ts"
}
sha_of() { sha256sum "$1" 2>/dev/null | cut -d ' ' -f 1; }
pinned() { # file sha256 -> 0 when the file is the tested one (no pin = refused)
  [ -n "$2" ] && [ -f "$1" ] && [ "$(sha_of "$1")" = "$(lower "$2")" ]
}
REFUSED=0
refused() { # what path want -> the red line (and counted)
  REFUSED=$((REFUSED + 1))
  say bad "$1: REFUSED - $(basename "$2") is not the tested file (SHA-256 $(sha_of "$2"), expected $3). Left as it is."
}
day() { date -u -d "@$1" "+%-d %b %Y" 2>/dev/null || printf '%s' "$1"; }

ERRF=""
fetch() { # url file -> 0 when downloaded; the reason is in why
  curl -fsSL --retry 2 --connect-timeout 20 --max-time 180 -A "$UA" -o "$2" "$1" 2>"$ERRF"
}
why() { local w; w=$(tail -n 1 "$ERRF" 2>/dev/null); printf '%s' "${w:-the download failed}"; }
get_zip() { # url dir [sha256 of the zip] -> unpacked into dir; 2 = refused (the hash differs)
  rm -rf "$2"; mkdir -p "$2"
  fetch "$1" "$2.zip" || return 1
  if [ -n "${3:-}" ] && ! pinned "$2.zip" "$3"; then
    echo "REFUSED - not the tested file (SHA-256 $(sha_of "$2.zip"), expected $3). Left as it is." >"$ERRF"; return 2
  fi
  unzip -q -o "$2.zip" -d "$2" 2>"$ERRF" || { echo "the download isn't a zip that can be opened" >"$ERRF"; return 1; }
}
json_str() { # key -> every "key": "value" in $JSON, one a line
  printf '%s' "$JSON" | grep -o "\"$1\": *\"[^\"]*\"" | sed 's/^[^:]*: *"//; s/"$//'
}
toc_version() { # toc -> its ## Version
  [ -f "$1" ] || return 0
  tr -d '\r' <"$1" | sed -n 's/^[[:space:]]*##[[:space:]]*Version[[:space:]]*:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//'
}
ver_newer() { # a b -> 0 when a is a higher version number than b
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]
}
# what of a download goes into an addon's folder: not its tests, sources or notes
addon_file() { # relative path
  local rel=$1 dir base
  dir=$(dirname "$rel"); base=$(basename "$rel")
  if [ "$dir" != "." ]; then
    printf '%s\n' "$dir" | tr '/' '\n' | grep -Eiq '^(tests?|native|screenshots|.*_src|\.git.*)$' && return 1
  fi
  printf '%s' "$base" | grep -Eiq '\.(dll|exe|md|c|h|sh|pem|zip)$|^SHA256SUMS|^\.git|^Makefile$' && return 1
  return 0
}

is_game() { [ -n "$1" ] && [ -d "$1" ] && [ -f "$(ci_child "$1" WoW.exe)" ]; }

# ------------------------------------------------------------------ the arguments
GAME=""; CHECK=0; YES=0; ONLY=""; SHORTCUT=1
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --yes|-y) YES=1 ;;
    --only) shift; ONLY=${1:-}; YES=1 ;;
    --only=*) ONLY=${1#--only=}; YES=1 ;;
    --no-shortcut) SHORTCUT=0 ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $1 (see --help)" ;;
    *) GAME=$1 ;;
  esac
  shift
done

say info "${C_BOLD}Octo DLL Installer${C_OFF}${C_INFO} v$VERSION for Linux - puts the OctoWoW client DLLs in, or brings the ones you have up to the tested versions (checked by SHA-256)."

# ------------------------------------------------------------------ the game folder
MEMO="${XDG_CONFIG_HOME:-$HOME/.config}/octo-dll-installer/gamedir"
find_game() {
  local d m
  if [ -f "$MEMO" ]; then m=$(head -n 1 "$MEMO"); is_game "$m" && { printf '%s' "$m"; return; }; fi
  d=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
  while [ -n "$d" ] && [ "$d" != "/" ]; do is_game "$d" && { printf '%s' "$d"; return; }; d=$(dirname "$d"); done
  for d in "$HOME/Games/OctoWoW" "$HOME/Games/octowow" "$HOME/OctoWoW" "$HOME/Games/octowow/drive_c/OctoWoW" \
           "$HOME/.wine/drive_c/OctoWoW" "$HOME/.wine/drive_c/Games/OctoWoW" "$HOME/.wine/drive_c/Program Files/OctoWoW" \
           "$HOME/.wine/drive_c/Program Files (x86)/OctoWoW"; do
    is_game "$d" && { printf '%s' "$d"; return; }
  done
}
[ -n "$GAME" ] || GAME=$(find_game)
while ! is_game "$GAME"; do
  [ -n "$GAME" ] && say bad "No WoW.exe in $GAME."
  ask "Your OctoWoW folder (the one with WoW.exe in it; Tab completes, Enter on nothing quits): " ||
    die "give the game folder (the one with WoW.exe in it): bash install-linux.sh /path/to/OctoWoW"
  [ -n "$REPLY" ] || exit 1
  GAME=${REPLY/#\~/$HOME}
done
GAME=$(cd "$GAME" && pwd)
say dim "Game folder: $GAME"
LIST=$(ci_child "$GAME" dlls.txt)
ADDONS=$(ci_path "$GAME" Interface/AddOns)

# what the game folder holds for one DLL, as a short line
have() { # index
  local i=$1 t s ts list
  t=$(ci_child "$GAME" "${D_FILE[i]}")
  if [ "${D_KIND[i]}" = helper ] && [ ! -d "$(ci_child "$ADDONS" "${D_SRC[i]}")" ] && [ ! -f "$t" ]; then echo "needs ${D_SRC[i]}"; return; fi
  local addon=1
  [ -n "${D_ADDON[i]}" ] && { [ -f "$(ci_path "$ADDONS" "${D_ADDON[i]}/${D_ADDON[i]}.toc")" ] || addon=0; }
  if [ ! -f "$t" ]; then if [ -n "${D_ADDON[i]}" ] && [ $addon = 1 ]; then echo "addon only"; else echo "not installed"; fi; return; fi
  ts=$(pe_date "$t")
  # (some builds carry a made-up date in their header, 1993 for WeirdUtils: not shown)
  if [ -n "$ts" ] && [ "$ts" -ge 1262304000 ]; then s="built $(day "$ts")"; else s="installed"; fi
  if [ -f "$LIST" ] && ! listed "${D_FILE[i]}"; then s="$s (not in dlls.txt)"; fi
  [ $addon = 0 ] && s="$s (no addon)"
  echo "$s"
}

# ------------------------------------------------------------------ dlls.txt
LINES=()
listed() { local l f; f=$(lower "$1"); for l in "${LINES[@]+"${LINES[@]}"}"; do [ "$(lower "$(printf '%s' "$l" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')")" = "$f" ] && return 0; done; return 1; }
FRESH=0
if [ -f "$LIST" ]; then
  while IFS= read -r l || [ -n "$l" ]; do LINES+=("${l%"$CR"}"); done <"$LIST"
else
  FRESH=1
fi

# ------------------------------------------------------------------ the tick list
PICK=()
for ((i = 0; i < N; i++)); do
  PICK[i]=${D_OURS[i]}
  [ "${D_KIND[i]}" = helper ] && [[ "$(have "$i")" == needs* ]] && PICK[i]=0
done
if [ -n "$ONLY" ]; then
  for ((i = 0; i < N; i++)); do PICK[i]=0; done
  IFS=',' read -r -a want <<<"$ONLY"
  for w in "${want[@]}"; do
    w=$(printf '%s' "$w" | tr -d ' '); found=0
    for ((i = 0; i < N; i++)); do [ "$(lower "${D_NAME[i]}")" = "$(lower "$w")" ] && { PICK[i]=1; found=1; }; done
    [ $found = 1 ] || die "there's no DLL called '$w' in the list."
  done
fi

show_list() {
  local i h mark
  echo
  say good "${C_BOLD}For our addons${C_OFF}${C_GOOD} (pfUI Octo, OctoBG, DmorphOcto and the rest use these - ticked to start with)"
  for ((i = 0; i < N; i++)); do
    [ $i = 6 ] && { echo; say info "${C_BOLD}Optional extras${C_OFF}${C_INFO} (from the Vanilla Addon Index's DLL list - tick only what you want)"; }
    h=$(have "$i"); mark="[ ]"; [ "${PICK[i]}" = 1 ] && mark="[x]"
    printf ' %2d %s %-21s %s%-30s%s %s\n' $((i + 1)) "$mark" "${D_NAME[i]}" "$C_DIM" "$h" "$C_OFF" "${D_ABOUT[i]}"
    [ -n "${D_WARN[i]}" ] && printf '%32s%s(!) %s%s\n' "" "$C_WARN" "${D_WARN[i]}" "$C_OFF"
  done
  echo
}
if [ "$YES" = 0 ]; then
  while :; do
    show_list
    if [ -f "$LIST" ]; then say good "dlls.txt found."; else say good "No dlls.txt yet (a fresh install) - it will be made, and VanillaFixes put in if needed."; fi
    say dim "Type numbers to tick / untick (like: 7 9), a = ours only, n = untick all, c = check for updates (changes nothing),"
    say dim "Enter = Install / update, q = quit."
    ask "> " || die "no answer from the keyboard - nothing was changed. (Run it in a terminal, or add --yes.)"
    case "$REPLY" in
      "") break ;;
      q|Q) exit 0 ;;
      c|C) CHECK=1; break ;;
      a|A) for ((i = 0; i < N; i++)); do PICK[i]=${D_OURS[i]}; [ "${D_KIND[i]}" = helper ] && [[ "$(have "$i")" == needs* ]] && PICK[i]=0; done ;;
      n|N) for ((i = 0; i < N; i++)); do PICK[i]=0; done ;;
      *) for w in $REPLY; do
           if [[ "$w" =~ ^[0-9]+$ ]] && [ "$w" -ge 1 ] && [ "$w" -le $N ]; then
             k=$((w - 1)); if [ "${PICK[k]}" = 1 ]; then PICK[k]=0; else PICK[k]=1; fi
           else say warn "'$w' isn't a number from the list."; fi
         done ;;
    esac
  done
fi
any=0; for ((i = 0; i < N; i++)); do [ "${PICK[i]}" = 1 ] && any=1; done
[ $any = 1 ] || die "tick at least one DLL first."

# ------------------------------------------------------------------ the game must be closed
if [ $CHECK = 0 ] && command -v pgrep >/dev/null 2>&1 && pgrep -if '[Ww][Oo][Ww]\.exe' >/dev/null 2>&1; then
  die "the game is running. Close it completely (in Wine, Lutris or Steam), then run this again."
fi

TMP="$GAME/DLL-download-$$"
mkdir -p "$TMP" || die "can't write in $GAME. Is it your folder? (Check its owner with ls -ld.)"
trap 'rm -rf "$TMP"' EXIT
ERRF="$TMP/curl-error.txt"
STAMP=$(date +%Y%m%d-%H%M%S)
CHANGED=0; LISTCHANGED=0; REFUSED=0
echo

backup() { # file [subfolder name] -> copied into DLL-backups
  local b; b=$(ci_child "$GAME" DLL-backups); mkdir -p "$b"
  if [ -d "$1" ]; then mkdir -p "$b/AddOns"; cp -a "$1" "$b/AddOns/$2.$STAMP"
  else cp -p "$1" "$b/$(basename "$1").$STAMP.bak"; fi
}

# ---- VanillaFixes: what loads dlls.txt. Only VanillaFixes.exe + VfPatcher.dll,
# never its d3d9.dll / dxvk.conf (your Wine / Proton has its own DXVK).
VFPINNED="https://github.com/hannesmann/vanillafixes/releases/download/v1.5.3/vanillafixes-1.5.3-dxvk.zip"
vanillafixes() {
  local missing=() f url z
  for f in VanillaFixes.exe VfPatcher.dll; do [ -f "$(ci_child "$GAME" "$f")" ] || missing+=("$f"); done
  if [ ${#missing[@]} = 0 ]; then say ok "VanillaFixes: there (it is what loads dlls.txt)."; return; fi
  if [ $CHECK = 1 ]; then say info "VanillaFixes: missing (${missing[*]}) - would be installed."; return; fi
  say dim "Getting VanillaFixes (it loads the DLLs in dlls.txt)..."
  # (1.5.0) always the pinned release, each file checked against its SHA-256
  url=$VFPINNED
  z="$TMP/vanillafixes.zip"
  fetch "$url" "$z" || { say bad "VanillaFixes: not done - $(why)"; return; }
  for f in "${missing[@]}"; do
    unzip -q -o -j -C "$z" "*$f" -d "$TMP/vf" 2>/dev/null
    local got; got=$(find_ci_r "$TMP/vf" "$f")
    [ -n "$got" ] || { say bad "VanillaFixes: $f was not in the download."; return; }
    local want=$VF_DLL_SHA; [ "$f" = VanillaFixes.exe ] && want=$VF_EXE_SHA
    pinned "$got" "$want" || { refused VanillaFixes "$got" "$want"; return; }
    cp "$got" "$GAME/$f" || { say bad "VanillaFixes: couldn't copy $f into the game folder."; return; }
  done
  say good "VanillaFixes: installed. If you use OctoLauncher, turn its vanillaFixes mod on, so the game starts through it."
  CHANGED=$((CHANGED + 1))
}

# ---- the addon that comes with a DLL, into Interface/AddOns
install_addon() { # index from-dir
  local i=$1 addon=${D_ADDON[i]} toc src dst rel f t ver label mine there=0 differ=0
  toc=$(find_ci_r "$2" "$addon.toc")
  [ -n "$toc" ] || { say warn "${D_NAME[i]}: the download has no $addon addon - left as it is."; return 1; }
  src=$(dirname "$toc")
  dst=$(ci_child "$ADDONS" "$addon")
  ver=$(toc_version "$toc")
  if [[ "$ver" =~ [0-9] ]]; then label="$addon addon $ver"; else label="$addon addon"; fi
  while IFS= read -r f; do
    rel=${f#"$src"/}; addon_file "$rel" || continue
    t="$dst/$rel"; [ -f "$t" ] && cmp -s "$f" "$t" || { differ=1; break; }
  done < <(find "$src" -type f)
  [ $differ = 0 ] && { say ok "$label: already this version."; return 1; }
  [ -f "$(ci_child "$dst" "$addon.toc")" ] && there=1
  if [ $there = 1 ]; then
    mine=$(toc_version "$(ci_child "$dst" "$addon.toc")")
    if [ -n "$ver" ] && [ -n "$mine" ] && ver_newer "$mine" "$ver"; then say ok "$label: kept - your $mine is newer."; return 1; fi
  fi
  if [ $CHECK = 1 ]; then say info "$label: would be $([ $there = 1 ] && echo updated || echo "installed in Interface/AddOns")."; return 0; fi
  [ -d "$dst" ] && backup "$dst" "$addon"
  mkdir -p "$ADDONS"
  while IFS= read -r f; do
    rel=${f#"$src"/}; addon_file "$rel" || continue
    mkdir -p "$(dirname "$dst/$rel")" && cp "$f" "$dst/$rel" || { say bad "Couldn't copy the $addon addon into Interface/AddOns."; return 1; }
  done < <(find "$src" -type f)
  say good "$label: $([ $there = 1 ] && echo "updated (the old one is in DLL-backups/AddOns)" || echo "installed in Interface/AddOns")."
  return 0
}

# ---- files a DLL needs beside it (WoWTranslate's certificates, WowPresence's program and settings)
put_extra() { # name src path-in-game keep
  local dst was=0; dst=$(ci_path "$GAME" "$3")
  [ "$4" = 1 ] && [ -f "$dst" ] && return 1
  [ -f "$dst" ] && was=1
  [ $was = 1 ] && cmp -s "$2" "$dst" && return 1
  if [ $CHECK = 1 ]; then say info "$3: would be $([ $was = 1 ] && echo updated || echo "put in the game folder")."; return 0; fi
  [ $was = 1 ] && backup "$dst"
  mkdir -p "$(dirname "$dst")" && cp "$2" "$dst" || { say warn "$1: couldn't copy $3."; return 1; }
  say good "$3: $([ $was = 1 ] && echo "updated (the old one is in DLL-backups)" || echo "put in the game folder")."
  return 0
}
install_extras() { # index pkg -> 0 when something was (or would be) put in
  local i=$1 pkg=$2 did=1 f p
  case "${D_NAME[i]}" in
    WoWTranslate)
      if [ ! -f "$(ci_child "$GAME" cacert.pem)" ]; then
        if fetch "$CACERT_URL" "$TMP/cacert.pem" && grep -q "BEGIN CERTIFICATE" "$TMP/cacert.pem"; then
          if pinned "$TMP/cacert.pem" "$CACERT_SHA"; then put_extra WoWTranslate "$TMP/cacert.pem" cacert.pem 1 && did=0
          else refused WoWTranslate "$TMP/cacert.pem" "$CACERT_SHA"; fi
        else say warn "WoWTranslate: couldn't get cacert.pem - $(why)"; fi
      fi ;;
    WowPresence)
      for p in WowPresence.exe:0 WowPresence/discord_application_id:1 WowPresence/discord_broadcast_flags:1; do
        f=""; [ -n "$pkg" ] && f=$(find "$pkg" -type f -ipath "*/${p%:*}" -print -quit 2>/dev/null)
        if [ -z "$f" ]; then [ "${p#*:}" = 1 ] && [ -f "$(ci_path "$GAME" "${p%:*}")" ] || say warn "WowPresence: the download has no ${p%:*} - left as it is."; continue; fi
        # (the helper program: only the tested one)
        if [ "${p%:*}" = WowPresence.exe ] && ! pinned "$f" "$WPEXE_SHA"; then refused WowPresence "$f" "$WPEXE_SHA"; continue; fi
        put_extra WowPresence "$f" "${p%:*}" "${p#*:}" && did=0
      done
      if [ $CHECK = 0 ]; then
        local id; id=$(tr -d '[:space:]' <"$(ci_path "$GAME" WowPresence/discord_application_id)" 2>/dev/null)
        [[ "$id" =~ ^[0-9]{15,22}$ ]] || say warn "WowPresence: put your own Discord Application ID in WowPresence/discord_application_id in the game folder (how: ${D_PAGE[i]})."
      fi ;;
  esac
  return $did
}

# ---- install / update one DLL
install_one() { # index
  local i=$1 name=${D_NAME[i]} file=${D_FILE[i]} got pkg="" tag="" bydate=1 inside api url zip u b t same label result=same
  got="$TMP/$file"
  case "${D_KIND[i]}" in
    url)
      tag=${D_TAG[i]}
      fetch "${D_SRC[i]}" "$got" || { say warn "$name: skipped - $(why)"; return; } ;;
    archive)
      tag=${D_TAG[i]}
      pkg="$TMP/$name"
      get_zip "${D_SRC[i]}" "$pkg" || { say warn "$name: skipped - $(why)"; return; }
      inside=$(find_ci_r "$pkg" "$file"); [ -n "$inside" ] && cp "$inside" "$got" ;;
    release)
      api=${D_API[i]:-$GHAPI}
      # (1.5.0) the pinned release, by its tag - never "the newest"
      JSON=$(curl -fsSL --connect-timeout 20 --max-time 30 -A "$UA" "$api${D_SRC[i]}/releases/tags/${D_TAG[i]}" 2>"$ERRF") || {
        say warn "$name: couldn't reach its download page ($(why)). Check your internet and try again."; return; }
      tag=$(json_str tag_name | head -n 1)
      if [[ ! "$tag" =~ [0-9] ]]; then
        t=$(json_str name | head -n 1); [ -n "$t" ] && tag=$(printf '%s' "$t" | sed "s/^$name[[:space:]]*//")
      fi
      url=""; zip=""
      while IFS= read -r u; do
        [ -n "$u" ] || continue
        b=$(lower "${u##*/}")
        [ "$b" = "$(lower "$file")" ] && { url=$u; break; }
        [ -z "$zip" ] && [[ "$b" == *.zip ]] && [[ "$b" != *symbol* ]] && zip=$u
      done < <(json_str browser_download_url)
      if [ -z "$url" ] && [ -z "$zip" ]; then say warn "$name $tag: the release has no $file - left as it is."; return; fi
      if [ -n "$url" ]; then
        fetch "$url" "$got" || { say warn "$name $tag: skipped - $(why)"; return; }
      else
        pkg="$TMP/$name"
        get_zip "$zip" "$pkg" || { say warn "$name $tag: skipped - $(why)"; return; }
        inside=$(find_ci_r "$pkg" "$file"); [ -n "$inside" ] && cp "$inside" "$got"
      fi ;;
  esac
  label=$(printf '%s %s' "$name" "$tag" | sed 's/[[:space:]]*$//')
  [ -f "$got" ] || { say warn "$label: the download has no $file - left as it is."; return; }
  is_dll "$got" || { say warn "$label: the download is not a DLL - left as it is."; return; }
  # (1.5.0) the exact file that was tested, or nothing
  pinned "$got" "${D_SHA[i]}" || { refused "$label" "$got" "${D_SHA[i]:-(no pin)}"; return; }

  t=$(ci_child "$GAME" "$file")
  same=0; [ -f "$t" ] && cmp -s "$got" "$t" && same=1
  local mine="" hd nd
  if [ $same = 0 ] && [ -f "$t" ]; then
    # (Windows also compares the DLL's version number with the release's; the build date is what bash can read)
    hd=$(pe_date "$t"); nd=$(pe_date "$got")
    [ -n "$hd" ] && [ -n "$nd" ] && [ "$hd" -gt "$nd" ] && mine="yours is a newer build ($(day "$hd"))"
  fi
  if [ -n "$mine" ]; then say ok "$label: kept - $mine."; result=kept
  elif [ $same = 1 ]; then say ok "$label: already this version."
  elif [ $CHECK = 1 ]; then say info "$label: would be $([ -f "$t" ] && echo updated || echo installed)."; result=changed
  else
    local was=0; [ -f "$t" ] && { was=1; backup "$t"; }
    cp "$got" "$t" || die "couldn't copy $file into the game folder. Close the game completely and try again."
    say good "$label: $([ $was = 1 ] && echo "updated (the old one is in DLL-backups)" || echo installed)."
    result=changed
  fi
  if ! listed "$file"; then
    if [ $CHECK = 1 ]; then say info "$file: would be added to dlls.txt."; else LINES+=("$file"); say good "$file: added to dlls.txt."; fi
    LISTCHANGED=1
  fi
  if [ -n "${D_ADDON[i]}" ]; then
    local from=$pkg
    if [ -n "${D_ADDONZIP[i]}" ]; then
      from="$TMP/$name-addon"
      get_zip "${D_ADDONZIP[i]}" "$from" "${D_ADDONSHA[i]}"; local zr=$?
      if [ $zr = 2 ]; then REFUSED=$((REFUSED + 1)); say bad "${D_ADDON[i]} addon: $(why)"; from=""
      elif [ $zr != 0 ]; then say warn "${D_ADDON[i]} addon: skipped - $(why)"; from=""; fi
    fi
    [ -n "$from" ] && install_addon "$i" "$from" && result=changed
  fi
  install_extras "$i" "$pkg" && result=changed
  [ $result = changed ] && CHANGED=$((CHANGED + 1))
}

# ---- DmorphHelper: what DmorphOcto's tools/install_helper.ps1 does on Windows
# (copied in, added to dlls.txt right after VanillaHelpers.dll, the HD skin
# switch turned on when a ported pack is in)
install_helper() { # index
  local i=$1 name=${D_FILE[i]} adir src t same=0 isl=0 ver label hd nd l out placed=0
  adir=$(ci_child "$ADDONS" "${D_SRC[i]}")
  src=$(ci_path "$adir" helper/DmorphHelper.dll)
  [ -f "$src" ] || { say dim "${D_NAME[i]}: the ${D_SRC[i]} addon isn't in this game folder - skipped (it comes with ${D_SRC[i]})."; return; }
  t=$(ci_child "$GAME" "$name")
  ver=$(toc_version "$(ci_child "$adir" "${D_SRC[i]}.toc")")
  label="${D_NAME[i]}"; [ -n "$ver" ] && label="${D_NAME[i]} (from ${D_SRC[i]} $ver)"
  [ -f "$t" ] && cmp -s "$src" "$t" && same=1
  listed "$name" && isl=1
  if [ $same = 0 ] && [ -f "$t" ]; then
    hd=$(pe_date "$t"); nd=$(pe_date "$src")
    [ -n "$hd" ] && [ -n "$nd" ] && [ "$hd" -gt "$nd" ] && { say ok "$label: kept - yours is a newer build ($(day "$hd"))."; return; }
  fi
  local hdneed=0
  { [ -f "$(ci_path "$GAME" Data/patch-6.mpq)" ] || [ -f "$(ci_path "$ADDONS" DMorph_Ported/Ported.lua)" ]; } && [ ! -f "$(ci_child "$GAME" DmorphHelper_HD.txt)" ] && hdneed=1
  if [ $same = 1 ] && [ $isl = 1 ] && [ $hdneed = 0 ]; then say ok "$label: already this version."; return; fi
  if [ $CHECK = 1 ]; then say info "$label: would be $([ $same = 1 ] && echo "added to dlls.txt" || { [ -f "$t" ] && echo updated || echo installed; })."; CHANGED=$((CHANGED + 1)); return; fi
  if [ $hdneed = 1 ]; then
    printf '%s' "DMorph HD skin: delete this file to go back to the normal 256x256 skin." >"$GAME/DmorphHelper_HD.txt"
    say good "  Turned on the HD skin the ported pack needs."
  fi
  if [ $same = 0 ]; then
    [ -f "$t" ] && backup "$t"
    cp "$src" "$t" || die "couldn't copy $name into the game folder."
  fi
  out=()
  for l in "${LINES[@]+"${LINES[@]}"}"; do
    [ "$(lower "$(printf '%s' "$l" | tr -d '[:space:]')")" = "$(lower "$name")" ] && continue
    out+=("$l")
    if [ $placed = 0 ] && [ "$(lower "$(printf '%s' "$l" | tr -d '[:space:]')")" = "vanillahelpers.dll" ]; then out+=("$name"); placed=1; fi
  done
  if [ $placed = 0 ]; then out+=("$name"); say warn "  VanillaHelpers.dll isn't in dlls.txt. DmorphHelper needs it (OctoLauncher's vanillaHelpers mod)."; fi
  LINES=("${out[@]}"); LISTCHANGED=1
  say good "$label: $([ $same = 1 ] && echo "added to dlls.txt" || echo installed) (after VanillaHelpers.dll)."
  CHANGED=$((CHANGED + 1))
}

# ------------------------------------------------------------------ the run
if [ $FRESH = 1 ]; then
  # (a fresh install has no dlls.txt until the game was started once: made, with the launcher's DLLs that are there)
  LINES=("# DLLs VanillaFixes loads (made by the Octo DLL Installer; OctoLauncher adds its own mods here too)")
  for f in VanillaHelpers.dll nampower.dll UnitXP_SP3.dll VanillaMultiMonitorFix.dll transmogfix.dll ClassicAPI.dll; do
    [ -f "$(ci_child "$GAME" "$f")" ] && LINES+=("$f")
  done
  LISTCHANGED=1
  if [ $CHECK = 1 ]; then say info "dlls.txt: none yet - would be made."; else say good "dlls.txt: none yet - making it."; fi
fi
vanillafixes
for ((i = 0; i < N; i++)); do
  [ "${PICK[i]}" = 1 ] && [ "${D_KIND[i]}" != helper ] || continue
  say dim "Getting ${D_NAME[i]}..."
  install_one "$i"
done
# the full weirdutils.dll never loads beside the noperf build
if [ "${PICK[4]}" = 1 ]; then
  out=(); old=0
  for l in "${LINES[@]+"${LINES[@]}"}"; do
    case "$(lower "$(printf '%s' "$l" | tr -d '[:space:]')")" in weirdutils.dll|weirdutils_octo.dll) old=1 ;; *) out+=("$l") ;; esac
  done
  if [ $old = 1 ]; then
    if [ $CHECK = 1 ]; then say info "An old WeirdUtils DLL: would be taken out of dlls.txt (weirdutils_noperf.dll replaces it)."
    else LINES=("${out[@]}"); LISTCHANGED=1; say good "An old WeirdUtils DLL: taken out of dlls.txt (weirdutils_noperf.dll replaces it)."; fi
  fi
fi
for ((i = 0; i < N; i++)); do
  [ "${PICK[i]}" = 1 ] && [ "${D_KIND[i]}" = helper ] || continue
  say dim "Checking ${D_NAME[i]}..."
  install_helper "$i"
done

# Windows-style paths, the way the game sees the folder under Wine:
# .../drive_c/x -> C:\x, anything else -> Z:\... (Wine's Z: is /)
winpath() {
  local p=$1
  if [[ "$p" == */drive_c/* ]]; then p=${p#*/drive_c/}; printf 'C:\\%s' "${p//\//\\}"
  else printf 'Z:%s' "${p//\//\\}"; fi
}
if [ $CHECK = 0 ] && [ $LISTCHANGED = 1 ]; then
  [ $FRESH = 0 ] && [ ! -f "$LIST.pfui-backup" ] && cp -p "$LIST" "$LIST.pfui-backup"
  [ -f "$LIST" ] || LIST="$GAME/dlls.txt"
  # (CRLF, as OctoLauncher and the Windows installer write it)
  printf '%s\r\n' "${LINES[@]}" >"$LIST" || die "couldn't write dlls.txt."
fi
if [ $CHECK = 0 ] && [ -f "$LIST" ]; then
  # VanillaFixes asks you to confirm whenever the DLL list changes; OctoLauncher writes dlls.txt.cache (each
  # DLL's full path) after its changes so it doesn't. This does the same after ours.
  body=""; gw=$(winpath "$GAME")
  for l in "${LINES[@]+"${LINES[@]}"}"; do
    l=$(printf '%s' "$l" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$l" ] && [ "${l:0:1}" != "#" ] || continue
    [[ "$l" =~ ^[A-Za-z]:\\ ]] || l="$gw\\$l"
    if [ -n "$body" ]; then body="$body"$'\r\n'"$l"; else body=$l; fi
  done
  cache="$GAME/$(basename "$LIST").cache"
  if [ -n "$body" ]; then printf '%s' "$body" >"$cache"; else rm -f "$cache"; fi
fi

# pfUI Octo itself
if [ ! -f "$(ci_path "$ADDONS" pfUI/pfUI.toc)" ]; then
  say info "pfUI Octo is not installed yet: in OctoLauncher open Addons > Add custom git addon and paste https://github.com/bdot89/pfUI"
  say info "  (no launcher? unzip pfUI.zip from https://github.com/bdot89/pfUI-Octo/releases/latest into Interface/AddOns)"
fi

# ------------------------------------------------------------------ starting the game
# The DLLs only load when the game starts through VanillaFixes.exe (it finds WoW.exe in its own folder).
# Windows gets a desktop shortcut; here: "Play OctoWoW.sh" + a .desktop launcher for plain Wine, and the
# steps for Lutris / Steam, which run the game with their own Wine.
find_prefix() { # the Wine prefix the game folder is in, else $WINEPREFIX, else ~/.wine
  local d=$GAME
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ "$(basename "$d")" = drive_c ] && { dirname "$d"; return; }
    d=$(dirname "$d")
  done
  if [ -n "${WINEPREFIX:-}" ]; then printf '%s' "$WINEPREFIX"; elif [ -d "$HOME/.wine" ]; then printf '%s' "$HOME/.wine"; fi
}
how_lutris="Lutris: right-click the game > Configure > Game options > Executable: pick VanillaFixes.exe in the game folder (not WoW.exe)."
how_steam="Steam / Proton: the non-Steam game's Properties > Target: \"$GAME/VanillaFixes.exe\", Start in: \"$GAME\"."
play_shortcut() {
  [ -f "$(ci_child "$GAME" VanillaFixes.exe)" ] || return
  local kind=wine
  if [[ "$GAME" == */steamapps/* ]]; then kind=steam
  elif grep -rqsF "$GAME" "$HOME/.config/lutris/games" "$HOME/.local/share/lutris/games" 2>/dev/null; then kind=lutris; fi
  if [ $SHORTCUT = 0 ] || [ $kind != wine ] || ! command -v wine >/dev/null 2>&1; then
    say info "To load your DLLs, start the game through VanillaFixes.exe, never WoW.exe:"
    [ $kind = steam ] || say info "  $how_lutris"
    [ $kind = lutris ] || say info "  $how_steam"
    [ $kind = wine ] && say info "  Plain Wine: cd \"$GAME\" && wine VanillaFixes.exe"
    return
  fi
  local play="$GAME/Play OctoWoW.sh" prefix apps desk dfile e
  prefix=$(find_prefix)
  if [ -f "$play" ] && grep -q "VanillaFixes.exe" "$play"; then :; else
    if [ $CHECK = 1 ]; then say info "\"Play OctoWoW\" launcher (starts the game through VanillaFixes): would be made."; return; fi
    {
      echo '#!/usr/bin/env bash'
      echo '# Starts OctoWoW through VanillaFixes, so the DLLs in dlls.txt load (made by the Octo DLL Installer).'
      echo 'cd "$(dirname "$0")" || exit 1'
      [ -n "$prefix" ] && printf 'export WINEPREFIX=%q\n' "$prefix"
      echo 'exec wine VanillaFixes.exe "$@"'
    } >"$play"
    chmod +x "$play"
    MADE=1
    say good "Made \"Play OctoWoW.sh\" in the game folder: it starts the game through VanillaFixes, so your DLLs load."
  fi
  [ $CHECK = 1 ] && return
  # (the Exec line in a .desktop file: inside "..." escape " \` $ \ and double %)
  e=$(printf '%s' "$play" | sed 's/[\\"`$]/\\\\&/g; s/%/%%/g')
  apps=${OCTO_APPS:-${XDG_DATA_HOME:-$HOME/.local/share}/applications}
  desk=${OCTO_DESKTOP:-$( (command -v xdg-user-dir >/dev/null 2>&1 && xdg-user-dir DESKTOP) || echo "$HOME/Desktop")}
  dfile="[Desktop Entry]
Type=Application
Name=Play OctoWoW
Comment=Starts OctoWoW through VanillaFixes, so the DLLs in dlls.txt load
Exec=\"$e\"
Path=$GAME
Icon=wine
Terminal=false
Categories=Game;"
  mkdir -p "$apps" 2>/dev/null && printf '%s\n' "$dfile" >"$apps/play-octowow.desktop" && chmod +x "$apps/play-octowow.desktop"
  if [ -d "$desk" ]; then
    printf '%s\n' "$dfile" >"$desk/play-octowow.desktop" && chmod +x "$desk/play-octowow.desktop"
    command -v gio >/dev/null 2>&1 && gio set "$desk/play-octowow.desktop" metadata::trusted true 2>/dev/null
    say good "\"Play OctoWoW\" is on your desktop and in your app menu (first time, your desktop may ask you to allow launching it)."
  else
    say good "\"Play OctoWoW\" is in your app menu."
  fi
}
MADE=0
play_shortcut

# (1.5.0) a refused download: say what it is
if [ $REFUSED -gt 0 ]; then
  echo
  say bad "Not finished: $REFUSED download(s) REFUSED (in red above) - not the files that were tested, so they were not put in. The author's release has changed since this version of the tool: get the newest Octo DLL Installer, or tell us on the OctoWoW Discord."
  exit 1
fi
if [ $CHECK = 1 ]; then echo; say info "Check done - nothing was changed."; exit 0; fi
# anything that went in and is gone again
gone=()
for ((i = 0; i < N; i++)); do
  [ "${PICK[i]}" = 1 ] && listed "${D_FILE[i]}" && [ ! -f "$(ci_child "$GAME" "${D_FILE[i]}")" ] && gone+=("${D_FILE[i]}")
done
for f in VanillaFixes.exe VfPatcher.dll; do [ -f "$(ci_child "$GAME" "$f")" ] || gone+=("$f"); done
mkdir -p "$(dirname "$MEMO")" 2>/dev/null && printf '%s\n' "$GAME" >"$MEMO"
echo
if [ ${#gone[@]} -gt 0 ]; then
  say bad "Not finished: missing from the game folder: ${gone[*]}. See the lines above, then run this again."
  exit 1
fi
how="From now on start the game through VanillaFixes.exe (OctoLauncher's Play with vanillaFixes on, or Play OctoWoW) - never WoW.exe itself, which loads no DLLs."
if [ $CHANGED -gt 0 ] || [ $LISTCHANGED = 1 ] || [ $MADE = 1 ]; then
  say good "Done! $how The first start after new DLLs, VanillaFixes may ask you to confirm the DLL list: say yes."
  say dim "If it won't start, copy the old DLL back from DLL-backups, or put dlls.txt.pfui-backup back as dlls.txt."
else
  say good "Everything you ticked is already on its pinned version - nothing to do. $how"
fi
