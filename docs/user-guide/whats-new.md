# Novinky

Prehľad noviniek a hlavných funkcií aplikácie v jednotlivých verziách.

## Verzia 1.3.1 - 9.8.2026

- Možnosť zobraziť pieseň bez nutnosti pridávať do repozitára - spodný navigačný panel (playlisty / repozitáre)
- Opravené texty v digitálnych JKS, kde sa zobrazovali znaky ako "&#10;" (46 súborov)
- Digitálna verzia JKS59 nešla načítať - opravené
- Pridané digitálne verzie JKS 436a a 436b
- Zjednotená obrazovka repozitárov – prehliadanie aj správa vlastných nôt na jednom mieste
- Výrazné zrýchlenie načítavania digitálnych nôt MusicXML a presnejšie prispôsobenie veľkosti obrazovke
- Opravené uvoľňovanie pamäte po zatvorení PDF nôt a ďalšie chyby
- Aktualizované knižnice

## Verzia 1.3.0 - 2.5.2026

<video loop muted playsinline controls width="300">
  <source src="../assets/whats-new/1.3.0/transpose_digital.mp4" type="video/mp4">
</video>

Podpora digitálnych nôt vo formáte MusicXML. Noty sa zobrazujú priamo v aplikácii
s možnosťou zoomovania a posúvania. Noty je možné transponovať priamo v aplikácii
tlačidlami nahor/nadol/reset.

## Verzia 1.2.1 - 22.2.2026

- Opravené prihlasovanie cez Google na Androidoch

## Verzia 1.2.0 - 5.2.2026

<table>
<tr>
<th width="33.33%">Zobrazenie nôt na celú obrazovku</th>
<th width="33.33%">Pridaná podpora pre pedál / klávesnicu</th>
<th width="33.33%">Pridané pôstne a veľkonočné predohry</th>
</tr>
<tr>
<td width="33.33%"><img src="../assets/whats-new/1.2.0/fullscreen_music_sheets.jpg"></td>
<td width="33.33%"><img src="../assets/whats-new/1.2.0/bt_arrows.gif"></td>
<td width="33.33%"><img src="../assets/whats-new/1.2.0/lent_easter_songs.png"></td>
</tr>
<tr>
<td width="33.33%">Využitie celého displeja v režime na výšku/šírku na zobrazenie nôt.</td>
<td width="33.33%">V prípade, že si pripojíte Bluetooth, alebo externú klávesnicu, prípadne pedál, ktorý simuluje stláčanie šípok, tak si viete prepínať skladby po poradí.</td>
<td width="33.33%">Pridané diela Slzy pokánia (pôstne) a CHRISTUS RESURREXIT (veľkonočné) predohry zo stránky <a href="https://organspaniadolina.sk/na-stiahnutie/">https://organspaniadolina.sk/na-stiahnutie/</a></td>
</tr>
</table>

### Ďalšie zmeny

- Opravené mazanie offline nôt po týždni -> 365 dní (doteraz sa uložené noty naozaj po týždni nenačítali)
- Zobrazovanie názvvu piesne aj pri obrázkoch (v režime celej obrazovky)
- Opravené premenovanie piesne v offline režime
- Opravené chyby na pozadí

## Verzia 1.1.1 - 4.1.2026

- Pridané tlačidlo späť pri zobrazení nôt na celú obrazovku
- Jasnejšie inštrukcie pri prázdnom playliste / žiadnych playlistoch
- Opravené viaceré chyby

## Verzia 1.1.0 - 22.12.2025

<table>
<tr>
<th width="33.33%">Export playlistu do PDF</th>
<th width="33.33%">Prehľadnejšie nastavenia</th>
<th width="33.33%">Offline úložisko</th>
</tr>
<tr>
<td width="33.33%"><img src="../assets/whats-new/1.1.0/export_pdf.gif"></td>
<td width="33.33%"><img src="../assets/whats-new/1.1.0/updated_settings.jpg"></td>
<td width="33.33%"><img src="../assets/whats-new/1.1.0/storage_management.jpg"></td>
</tr>
<tr>
<td width="33.33%">Možnosť exportovať celý playlist do samostatného PDF súboru, ktoré sa uloží do zariadenia.</td>
<td width="33.33%">Jasne oddelené položky v nastaveniach.</td>
<td width="33.33%">Možnosť vyčistiť offline úložisko. Zároveň sa offline uložené noty automaticky nevymažúpo nejakom čase systémom, ako doteraz.</td>
</tr>
</table>

### Ďalšie zmeny

- Nahradené Crashlytics za Sentry na monitorovanie chýb
- Interné zmeny organizácie projektu
- Používanie CodeMagic na deploy
- Opravené mazanie nôt, keď aplikácia nebola dlhšie pripojená k internetu
- Počas nahrávania vlastného súboru bolo možné zrušiť proces tlačidlom späť, opravené
- Aktualizované knižnice na Firebase Functions, balíky knižníc

## Verzia 1.0.7 - 26.11.2025

- pridaná podpora pre iOS od verzie 15
- optimalizácia kódu na pozadí, aktualizovaná verzia Flutteru na 3.38.1 a knižníc

## Verzia 1.0.6 - 4.10.2025

<table>
<tr>
<th width="33.33%">Vlastné repozitáre</th>
<th width="33.33%">Viaceré skladby do playlistu</th>
<th width="33.33%">Predohry JKS - advent</th>
</tr>
<tr>
<td width="33.33%"><img src="../assets/whats-new/1.0.6/custom_repositories.gif"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.6/multi_add_to_repository.gif"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.6/predohry_jks_advent.jpg"></td>
</tr>
<tr>
<td width="33.33%">Možnosť pridať vlastných repozitárov ako zložiek.</td>
<td width="33.33%">Pridávanie viacerých skladieb z repozitára naraz do playlistu.</td>
<td width="33.33%">Pridaný repozitár s predohrami JKS - advent</td>
</tr>
</table>

### Ďalšie zmeny

- Zlepšenie chybových hlášok
- Opravená JKS 372 -> 371
- Opravené náhľady piesní pri pridávaní nových
- Aktualizované knižnice na Firebase Functions

## Verzia 1.0.5 - 29.7.2025

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

## Verzia 1.0.4 - 28.6.2025

<table>
<tr>
<th width="33.33%">Zrýchlené posúvanie strán</th>
<th width="33.33%">Prihlásenie cez Google</th>
<th width="33.33%">Ponechať obrazovku zapnutú</th>
</tr>
<tr>
<td width="33.33%"><img src="../assets/whats-new/1.0.4/fast_page_switching.gif" alt="Version 1.0.4 Col 1"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.4/sign_in_with_google.gif" alt="Version 1.0.4 Col 2"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.4/keep_screen_on.jpg" alt="Version 1.0.4 Col 3"></td>
</tr>
<tr>
<td width="33.33%">Rýchle a spoľahlivé pretáčanie strán je pre hudobníka nevyhnutné. Nová aktualizácia zrýchlila prepínanie z takmer jednej sekundy na pár milisekúnd.</td>
<td width="33.33%">Zabudnite na zložité heslá. Prihláste sa rýchlo, bezpečne a pohodlne – stačí jeden klik.</td>
<td width="33.33%">S novým nastavením sa nemusíte obávať, že počas hrania náhle zhasne displej.</td>
</tr>
</table>

## Verzia 1.0.3 - 11.5.2025

<table>
<tr>
<th width="33.33%">Posúvanie strán dotykom</th>
<th width="33.33%">Indikátor pre uložené noty</th>
<th width="33.33%">Nové noty v repozitáry</th>
</tr>
<tr>
<td width="33.33%"><img src="../assets/whats-new/1.0.3/feature_page_switching.gif" alt="Version 1.0.3 Col 1"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.3/feature_offline.gif" alt="Version 1.0.3 Col 2"></td>
<td width="33.33%"><img src="../assets/whats-new/1.0.3/new_music_sheets.jpg" alt="Version 1.0.3 Col 3"></td>
</tr>
<tr>
<td width="33.33%">Pre zobrazenie ďalšej strany treba kliknúť od šípky nižšie, resp. vyššie. Táto plocha je farebne mierne do zelena odlíšená od ostatnej časti. Prepínanie dotykom sa dá vypnúť / zapnúť v nastaveniach. Zachovaná možnosť potiahnutia.</td>
<td width="33.33%">Keď otvoríte náhľad nejakej noty, uloží sa vám do zariadenia a je k dispozícii pre offline použitie. Takto označené noty viete pridať do playlistu aj bez internetu.</td>
<td width="33.33%">Odpovede v rôznych tóninách, ďalších 60 transponovaných JKS, výber svadobných...</td>
</tr>
</table>
