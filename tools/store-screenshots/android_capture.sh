#!/bin/bash
# Captures the raw phone screenshots on the Android emulator (Medium_Phone_API_36.1, 1080x2400).
# Precondition: the debug app is running, signed in as demo@organista.app, on "Moje zoznamy skladieb".
#   tools/store-screenshots/android_capture.sh
set -euo pipefail
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
OUT="$(cd "$(dirname "$0")/../.." && pwd)/docs/screenshots/raw/android"
mkdir -p "$OUT"

tap() { adb shell input tap "$1" "$2"; }
shot() { sleep "${2:-0}"; adb exec-out screencap -p > "$OUT/$1.png"; echo "captured $1"; }
RENDER=32   # MusicXML sheets take ~25 s to render on the emulator

shot playlists 1
tap 540 500;    shot playlist 6               # 1. adventná nedeľa (thumbnails need a few seconds)
tap 540 1549;   sleep $RENDER                 # 25. V spôsobe chleba (saved transposition -2)
tap 960 2280;   shot transpose 1.5            # open the transpose/zoom panel
tap 960 2280;   sleep 1; tap 84 84; sleep 2   # close panel, back to the playlist
tap 540 1864;   sleep $RENDER                 # 28. Príde Kristus
tap 540 1200;   shot viewer-clean 1.5         # tap the sheet to hide the overlays
tap 84 84;      sleep 2; tap 74 137; sleep 2  # back to the playlists tab
tap 810 2250;   sleep 4; tap 176 294          # Repozitáre tab, make sure "Globálne" is selected
adb shell input swipe 540 600 540 1800 400; sleep 2.5   # the grid remembers its scroll offset: back to top
shot repositories 1
adb shell input swipe 540 1800 540 500 400; sleep 2.5
tap 805 1618;   shot repo-jks 7               # JKS - digitálne (position after the swipe above)
tap 74 137;     sleep 2; tap 270 2250         # back to the playlists tab for the next run
