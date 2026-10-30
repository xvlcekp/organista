# Zobrazenie nôt

Ťuknutím na notu v zozname skladieb sa noty otvoria na celú obrazovku — pripravené na hranie.

![Zobrazenie nôt na celú obrazovku](assets/screenshots/sheet-fullscreen.png){ width="300" }

## Listovanie medzi skladbami

Medzi skladbami zoznamu listujete **potiahnutím prsta** doľava/doprava — v poradí,
v akom ste si ich usporiadali:

<video autoplay loop muted playsinline controls width="300">
  <source src="../assets/videos/switching-songs.mp4" type="video/mp4">
</video>

## Viacstranové noty a navigačné šípky

Pri viacstranových notách vidíte vpravo dole **počítadlo strán** (napr. _1/2_).
Ak si v [Nastaveniach](settings.md) zapnete **Zobraziť navigačné šípky**, horný
a dolný okraj obrazovky sa zmení na **zelenkasté dotykové plochy so šípkou** — ťuknutím
na dolnú plochu otočíte na ďalšiu stranu, ťuknutím na hornú späť. Rýchlejšie
a spoľahlivejšie než posúvanie prstom; otočenie prebehne okamžite:

<video autoplay loop muted playsinline controls width="300">
  <source src="../assets/videos/page-navigation.mp4" type="video/mp4">
</video>

Celý postup — vytvorenie zoznamu, pridanie nôt, zapnutie šípok v nastaveniach
a hranie s otáčaním strán — ukazuje [video na úvodnej stránke](index.md).

Platí to pre PDF ako aj pre **digitálne noty JKS**: piesne s viac ako tromi slohami
majú ďalšie slohy na ďalších stranách pod rovnakými notami. Na obrazovke je vždy
jedna strana; počítadlo strán je pri digitálnych notách nad modrým tlačidlom ovládania.
Strany digitálnych nôt otočíte aj potiahnutím prstom nahor alebo nadol, rovnako ako pri PDF.

<div class="grid" markdown>
![Digitálne noty – 1. strana](assets/screenshots/sheet-fullscreen.png){ width="300" }
![Digitálne noty – 2. strana so slohami 4 a 5](assets/screenshots/sheet-musicxml-page2.png){ width="300" }
</div>

!!! tip
    Obrazovka počas hrania predvolene nezhasne. Ak to nechcete, v [Nastaveniach](settings.md)
    vypnite **Nechať obrazovku zapnutú**.

!!! note "Bluetooth pedál alebo klávesnica"
    Na listovanie môžete použiť aj **Bluetooth pedál či klávesnicu** — šikovné,
    keď máte obe ruky (aj nohy) zamestnané hraním.

## Transpozícia (MusicXML)

Noty vo formáte **MusicXML** (napr. repozitár _JKS - digitálne_) si viete digitálne
transponovať — celá skladba sa prepíše do novej tóniny, žiadne prelepovanie ani
hranie z hlavy.

1. Ťuknite na modré tlačidlo ovládania vpravo dole.
2. Tlačidlami **+** / **−** pri ikone noty transponujete o poltón vyššie/nižšie.
3. Aktuálna transpozícia sa zobrazuje v paneli (napr. **+3**); ťuknutím na hodnotu ju vynulujete.

<div class="grid" markdown>
![Panel transpozície](assets/screenshots/transpose-controls.png){ width="300" }
![Transpozícia +3](assets/screenshots/transpose-plus3.png){ width="300" }
</div>

<video autoplay loop muted playsinline controls width="300">
  <source src="../assets/videos/transposition.mp4" type="video/mp4">
</video>

Transpozícia sa pri note v zozname skladieb **zapamätá** — pri ďalšom otvorení aj pri
[exporte do PDF](export-pdf.md) sa použije naposledy nastavená hodnota.

V paneli nájdete aj:

- **Rozšíriť/zúžiť medzery v texte** (tlačidlá pri ikone **÷**) — širšie medzery pomôžu, ak sa text prekrýva (noty budú o niečo menšie);
  užšie noty zväčšia, ak je v texte dosť voľného miesta,
- **Skryť text / Zobraziť text** — schová alebo zobrazí text piesne pod notami.

## Práca bez internetu

Noty, ktoré ste už mali otvorené, sa ukladajú do pamäte telefónu a zobrazia sa aj bez
pripojenia — na chóre bez signálu sa teda na svoj zoznam skladieb môžete spoľahnúť.
V repozitári ich spoznáte podľa zelenej fajky. Podrobnosti o úložisku nájdete
v [Nastaveniach](settings.md#sprava-uloziska).

Nota, ktorá ešte nebola stiahnutá, sa bez internetu nezobrazí — aplikácia vypíše hlášku
**Bez internetu. Táto nota ešte nebola stiahnutá do zariadenia.** Bez internetu môžete do zoznamu skladieb
pridať len už stiahnuté noty. Vytvorenie, premenovanie či úpravy zoznamov sa bez internetu zobrazia hneď
a odošlú sa, keď sa telefón znova pripojí. Nahrať vlastné noty sa dá len s pripojením.
