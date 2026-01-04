# Organista
[![Codemagic build status](https://api.codemagic.io/apps/69246add8c4a7a82d015b54e/69246add8c4a7a82d015b54d/status_badge.svg)](https://codemagic.io/app/69246add8c4a7a82d015b54e/69246add8c4a7a82d015b54d/latest_build)

Info about project for organists: https://sites.google.com/view/organista-app/domov 

## Changelog
### Version 1.1.1 - 4.12.2026
- Pridané tlačidlo späť pri zobrazení nôt na celú obrazovku
- Jasnejšie inštrukcie pri prázdnom playliste / žiadnych playlistoch
- Opravené viaceré chyby

### Version 1.1.0 - 22.12.2025
<table>
<tr>
<th width="33.33%">Export playlistu do PDF</th>
<th width="33.33%">Prehľadnejšie nastavenia</th>
<th width="33.33%">Offline úložisko</th>
</tr>
<tr>
<td width="33.33%"><img src="docs/1.1.0/export_pdf.gif"></td>
<td width="33.33%"><img src="docs/1.1.0/updated_settings.jpg"></td>
<td width="33.33%"><img src="docs/1.1.0/storage_management.jpg"></td>
</tr>
<tr>
<td width="33.33%">Možnosť exportovať celý playlist do samostatného PDF súboru, ktoré sa uloží do zariadenia.</td>
<td width="33.33%">Jasne oddelené položky v nastaveniach.</td>
<td width="33.33%">Možnosť vyčistiť offline úložisko. Zároveň sa offline uložené noty automaticky nevymažúpo nejakom čase systémom, ako doteraz.</td>
</tr>
</table>

#### Ďalšie zmeny
- Nahradené Crashlytics za Sentry na monitorovanie chýb
- Interné zmeny organizácie projektu
- Používanie CodeMagic na deploy
- Opravené mazanie nôt, keď aplikácia nebola dlhšie pripojená k internetu
- Počas nahrávania vlastného súboru bolo možné zrušiť proces tlačidlom späť, opravené
- Aktualizované knižnice na Firebase Functions, balíky knižníc

### Version 1.0.7 - 26.11.2025
- pridaná podpora pre iOS od verzie 15
- optimalizácia kódu na pozadí, aktualizovaná verzia Flutteru na 3.38.1 a knižníc

### Version 1.0.6 - 4.10.2025
<table>
<tr>
<th width="33.33%">Vlastné repozitáre</th>
<th width="33.33%">Viaceré skladby do playlistu</th>
<th width="33.33%">Predohry JKS - advent</th>
</tr>
<tr>
<td width="33.33%"><img src="docs/1.0.6/custom_repositories.gif"></td>
<td width="33.33%"><img src="docs/1.0.6/multi_add_to_repository.gif"></td>
<td width="33.33%"><img src="docs/1.0.6/predohry_jks_advent.jpg"></td>
</tr>
<tr>
<td width="33.33%">Možnosť pridať vlastných repozitárov ako zložiek.</td>
<td width="33.33%">Pridávanie viacerých skladieb z repozitára naraz do playlistu.</td>
<td width="33.33%">Pridaný repozitár s predohrami JKS - advent</td>
</tr>
</table>

#### Ďalšie zmeny
- Zlepšenie chybových hlášok
- Opravená JKS 372 -> 371 
- Opravené náhľady piesní pri pridávaní nových
- Aktualizované knižnice na Firebase Functions

## Version 1.0.5 - 29.7.2025
### Pridané
- Pridané noty s Mariánskou kyticou a ďalšie svadobné
- Automatizácia procesu vydávania aplikácie
### Opravené
- Oprava chyby - po odstránení konta sa prejde na prihlasovaciu stránku
- Pri viacerých skladbách sa nedala otvoriť posledná položka v zozname kvôli blokujúcemu elementu
- Systémový panel vo farbe témy a nie stále biely
### Bezpečnosť
- Aktualizované knižnice
- Aktualizácia Flutteru na novšiu verziu
  
### Version 1.0.4 - 28.6.2025
<table>
<tr>
<th width="33.33%">Zrýchlené posúvanie strán</th>
<th width="33.33%">Prihlásenie cez Google</th>
<th width="33.33%">Ponechať obrazovku zapnutú</th>
</tr>
<tr>
<td width="33.33%"><img src="docs/1.0.4/fast_page_switching.gif" alt="Version 1.0.4 Col 1"></td>
<td width="33.33%"><img src="docs/1.0.4/sign_in_with_google.gif" alt="Version 1.0.4 Col 2"></td>
<td width="33.33%"><img src="docs/1.0.4/keep_screen_on.jpg" alt="Version 1.0.4 Col 3"></td>
</tr>
<tr>
<td width="33.33%">Rýchle a spoľahlivé pretáčanie strán je pre hudobníka nevyhnutné. Nová aktualizácia zrýchlila prepínanie z takmer jednej sekundy na pár milisekúnd.</td>
<td width="33.33%">Zabudnite na zložité heslá. Prihláste sa rýchlo, bezpečne a pohodlne – stačí jeden klik.</td>
<td width="33.33%">S novým nastavením sa nemusíte obávať, že počas hrania náhle zhasne displej.</td>
</tr>
</table>

### Version 1.0.3 - 11.5.2025
<table>
<tr>
<th width="33.33%">Posúvanie strán dotykom</th>
<th width="33.33%">Indikátor pre uložené noty</th>
<th width="33.33%">Nové noty v repozitáry</th>
</tr>
<tr>
<td width="33.33%"><img src="docs/1.0.3/feature_page_switching.gif" alt="Version 1.0.3 Col 1"></td>
<td width="33.33%"><img src="docs/1.0.3/feature_offline.gif" alt="Version 1.0.3 Col 2"></td>
<td width="33.33%"><img src="docs/1.0.3/new_music_sheets.jpg" alt="Version 1.0.3 Col 3"></td>
</tr>
<tr>
<td width="33.33%">Pre zobrazenie ďalšej strany treba kliknúť od šípky nižšie, resp. vyššie. Táto plocha je farebne mierne do zelena odlíšená od ostatnej časti. Prepínanie dotykom sa dá vypnúť / zapnúť v nastaveniach. Zachovaná možnosť potiahnutia.</td>
<td width="33.33%">Keď otvoríte náhľad nejakej noty, uloží sa vám do zariadenia a je k dispozícii pre offline použitie. Takto označené noty viete pridať do playlistu aj bez internetu.</td>
<td width="33.33%">Odpovede v rôznych tóninách, ďalších 60 transponovaných JKS, výber svadobných...</td>
</tr>
</table>




## Releasing a new version
1. **write changes** to `CHANGELOG.md` file
2. **increase app version** + bundle & commit
3. **create a release tag on github** - and set the release as primary
4. **upload to playstore** - on release tag a bundle is created automatically. Just download it and upload to Google Play

### Update JS libraries
In this project we use Firebase functions. As they use 3rd party JS libraries, they need to be regulary updated. To update them run:  
`cd functions/`  
`npm update`   

## Release from pipeline
For encoding, we will make use of the popular Base64 encoding scheme. Base64 doesn’t stand for specific but various encoding schemes that allow you to convert binary data into a text representation. We need to upload Keystore certificate to Github workflow in STRING format.
Encoding keystore cert:
`openssl base64 < your_signing_keystore.jks | tr -d '\n' | tee your_signing_keystore_base64_encoded.txt`

If you modify `assets/config/credentials.json`, you need to change it also in the pipeline.
1. Generate new encoded credentials.json file
  `cd assets/config/ && openssl base64 < credentials.json | tr -d '\n' | tee`
1. Upload the key to `CREDENTIALS_JSON_BASE64` repository secret to github.

If you modify `android/app/google_services.json`, you need to change it also in the pipeline.
1. Generate new encoded google_services.json file
  `cd android/app/ && openssl base64 < google-services.json | tr -d '\n' | tee`
2. Upload the key to `GOOGLE_SERVICES_JSON_BASE64` repository secret to github.

## Flutter upgrade 
- Go to folder where flutter is installed
### To latest stable version (prefered)
- `flutter upgrade`

### To specific version
- `git fetch`
- `git checkout 3.32.5` (before it was 3.29.3)

The latest flutter upgrade was from 3.32.5 to 3.38.1

### iOS
Reinstall dependencies:
```
cd ios
pod deintegrate (remove all iOS dependencies from workspace)
pod install
```
Release process:
```
flutter build ipa --obfuscate --split-debug-info=build/ios/outputs/symbols
open /Users/palo/Projects/organista/build/ios/archive/Runner.xcarchive
```
Click the **Validate App** button. If any issues are reported, address them and produce another build. You can reuse the same build ID until you upload an archive.
After the archive has been successfully validated, click **Distribute App**.

## Caching PDFs/images
The library [flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager) is not maintained for more then 1 year anymore. Since there is a bug that cache is not removed based on stalePerioad, or maxNrOfCachedFiles, it is overriden by a git commit which is not merged.
Another problem is that the library caches to cache directory which is not under full control of application and can be erased at any time. That is why a new `PersistentFileSystem` is added and necessary files are stored in /files folder. Be careful when updating the library, because there are these "hacks" (also mentioned in `pubspec.yaml`).

## Error Tracking

The app uses **Sentry** for error tracking and crash reporting. Sentry automatically captures:
- Unhandled exceptions and crashes
- BLoC/Cubit errors
- Unknown authentication errors
- Critical repository operations (user deletion, data streams)
- Storage operations (file uploads, deletions)

Errors are reported via `Sentry.captureException()` in catch blocks and automatically through `SentryWidget` wrapper for unhandled exceptions. Debug symbols, obfuscation maps, and source context are uploaded via `sentry_dart_plugin` during build for readable stack traces with source code visibility.

## Firebase

**deleteStorageFilesOnDocDelete** - automation on firebase using Firebase Functions. When musicSheet document is deleted, also musicSheet file is deleted in Firebase Storage.  
*After every deployment, artifacts needs to be removed in Google Artifact Repository!*

## How to crop music sheets from multi-sheets PDF
1. Download [PDF Gear](https://www.pdfgear.com/)
2. Split PDF to separate pages. (PDF Gear -> Page -> mark all -> Extract Pages -> All)
3. Manually crop pages and rename them.

### Cors issue
https://stackoverflow.com/questions/65849071/flutter-firebase-storage-cors-issue

### Other projects
https://github.com/stanislavbebej/ejks
