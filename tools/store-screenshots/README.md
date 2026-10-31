# Store screenshots (App Store + Google Play)

One set of six screens, captured once per form factor and composed onto each store's canvas with
the same Slovak captions and styling, so the listings look identical on both stores.

| Target | Canvas | Source capture | Store rule it satisfies |
|---|---|---|---|
| `app-store/iphone-6.3` | 1206×2622 | Android phone emulator | App Store Connect "iPhone with Dynamic Island (medium display)" — the required iPhone slot; Apple scales it for other iPhones |
| `app-store/iphone-6.9` | 1320×2868 | Android phone emulator | Optional 6.9" slot (only via "View All Sizes in Media Manager") |
| `app-store/ipad-13` | 2064×2752 | iPad Pro 13" simulator | App Store Connect iPad 13" (required for iPad-capable apps) |
| `google-play/phone` | 1080×1920 | Android phone emulator | 9:16, ≥1080 px: eligible for Play featuring; sides within the 2:1 limit |
| `google-play/tablet-7` | 1200×1920 | iPad Pro 13" simulator | 7-inch tablet slot |
| `google-play/tablet-10` | 1600×2560 | iPad Pro 13" simulator | 10-inch tablet slot |

Both stores: PNG without alpha, 2–8 (Play) / up to 10 (App Store) images. Google Play also needs a
1024×500 feature graphic, which this tool does not produce.

Output: `docs/screenshots/store/<target>/NN-<shot>.png` (upload in that order).

Where to upload (App Store Connect → Product Page Information → Slovak):

- iPhone with Dynamic Island (medium display) → `app-store/iphone-6.3`
- iPad 13" display → `app-store/ipad-13`
- iPhone Duo, Apple Watch → nothing (the app does not target them)

Google Play Console → Store listing → Slovak: phone → `google-play/phone`, 7-inch tablet →
`google-play/tablet-7`, 10-inch tablet → `google-play/tablet-10`.
Raw captures: `docs/screenshots/raw/{android,ipad}/<shot>.png`.
Files in this folder:

- `captions.json` — ordered shot list with title/subtitle (Slovak, the store listings' language).
  `fullscreen: true` marks viewer screens, which hide the OS bars themselves and are not cropped.
- `compose.py` — builds the store images from the raw captures (needs Pillow; macOS Helvetica Neue).
- `android_capture.sh` — drives the Android emulator with `adb shell input` and captures the phone set.
- `ipad_capture.txt` + `vm_driver.dart` — drive the iPad simulator through the Dart VM service and
  capture the tablet set (there is no `adb input` for iOS and this Mac has no idb).

## Reproducing

Prerequisites: Android emulator `Medium_Phone_API_36.1` (1080×2400, 420 dpi), iPad Pro 13-inch (M5)
simulator, the demo account `demo@organista.app` (credentials in the private memory notes) with its
advent playlists, debug build of the app. All tap coordinates below assume exactly these devices.

### 1. Phone set (Android emulator)

```bash
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554        # debug build: no debug banner, Slovak UI
```

Sign in as the demo account if needed and stay on "Moje zoznamy skladieb", then:

```bash
tools/store-screenshots/android_capture.sh     # ~2 min, MusicXML sheets render slowly on the emulator
```

The script taps by fixed coordinates; if a screen changes, re-measure with
`adb shell uiautomator dump /sdcard/ui.xml && adb shell cat /sdcard/ui.xml` (Flutter labels and
bounds are in the dump). The status bar is cropped by `compose.py`, so its clock does not matter.

### 2. Tablet set (iPad simulator)

```bash
xcrun simctl boot "iPad Pro 13-inch (M5)"
open -a /Applications/Xcode.app/Contents/Applications/DeviceHub.app   # Xcode 27 has no Simulator.app
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
flutter run -d "iPad Pro 13-inch (M5)"
```

The app **must** be started by `flutter run`: `vm_driver.dart` evaluates Dart expressions, which
needs the expression compiler that only `flutter run` attaches (an app launched with
`simctl launch` answers "No compilation service available"). Copy the VM service URL that
`flutter run` prints (`http://127.0.0.1:PORT/TOKEN=/`), turn it into `ws://127.0.0.1:PORT/TOKEN=/ws`,
sign in if needed (`text 0 <email>`, `text 1 <password>`, `tap 512 786` on the login screen), make
sure "Moje zoznamy skladieb" is showing, then:

```bash
dart --packages=.dart_tool/package_config.json tools/store-screenshots/vm_driver.dart \
  ws://127.0.0.1:PORT/TOKEN=/ws < tools/store-screenshots/ipad_capture.txt
```

`vm_driver.dart` commands (logical pixels, iPad = 1032×1376): `tap`, `longpress`, `swipe`, `down/move/up`,
`text N STRING` (sets the N-th text field), `scroll N PX` (jumps the N-th Scrollable), `js CODE`
(runs JavaScript in the sheet WebView: synthetic Flutter pointer events never reach a platform view),
`eval EXPR`, `sleep MS`, `shot PATH`. Quirks learned the hard way:

- The simulator lays out the status bar only after the app has shown a full-screen sheet once, so
  `ipad_capture.txt` opens the viewer first; later y coordinates include the 24 pt status bar.
- `scroll` past the end of a non-scrollable list leaves the Material app bar tinted
  ("scrolled under"); restart the app rather than scrolling back.
- `simctl io screenshot` cannot write into `~/Documents`; the driver saves to a temp file and copies.

### 3. Compose

```bash
python3 tools/store-screenshots/compose.py                 # all five targets
python3 tools/store-screenshots/compose.py --target google-play/phone
```

Edit `captions.json` to change texts or the order; `compose.py` holds the canvas sizes, colours
(app primary blue), fonts and crop heights (Android 24 dp status/gesture bars at 420 dpi = 63 px,
iPad status bar 24 pt = 48 px).
