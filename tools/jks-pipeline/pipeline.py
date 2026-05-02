#!/usr/bin/env python3
"""
JKS Music Pipeline
==================
Converts .mscz files to enhanced MusicXML through three steps:

  Step 1: Convert .mscz → .musicxml using MuseScore 3 CLI
  Step 2: Read MSCX from the .mscz zip, extract verse labels, and prepend them
          to the first lyric of each verse — mirroring the logic in
          musescore-display/src/MscxToMusicXml.ts
  Step 3: Extract text from SVG aria-label attributes embedded in the .mscz zip
          and insert them as the <rights> element inside <identification> —
          mirroring the logic in musescore-display/tools/mscz-to-musicxml.ts

Usage:
  python3 pipeline.py                 # Process first 10 files in JKS_DIR
  python3 pipeline.py file1.mscz ...  # Process specific files
"""

import os
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

JKS_DIR = Path("/Users/pavol.vlcek/Documents/Personal/JKS digitalne")
OUTPUT_DIR = Path(__file__).parent / "output"

# MuseScore 3 binary path — tried in order until one works
MUSESCORE_CANDIDATES = [
    "/Applications/MuseScore 3.app/Contents/MacOS/mscore",
    "mscore3",
    "musescore3",
    "/usr/bin/mscore3",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_JKS_TAG_RE = re.compile(r'\s*\(JKS(\d+)([a-z]?)\)', re.IGNORECASE)


def jks_output_stem(mscz_stem: str) -> str:
    """
    Convert a .mscz stem like "A včera z večera (JKS036) – Pavlín Bajan"
    to an output stem like "36. A včera z večera – Pavlín Bajan".

    When the JKS tag contains a letter suffix (e.g. JKS150a), it is preserved:
    "Matka plače (JKS150a) – Author" → "150a. Matka plače – Author".

    Falls back to the original stem when no JKS tag is found.
    """
    m = _JKS_TAG_RE.search(mscz_stem)
    if not m:
        return mscz_stem
    number = int(m.group(1))           # strip leading zeros: 036 → 36
    letter = m.group(2).lower()        # optional variant letter: a, b, c …
    clean = _JKS_TAG_RE.sub("", mscz_stem).strip()
    return f"{number}{letter}. {clean}"


def find_musescore() -> Optional[str]:
    """Return the first working MuseScore 3 binary path, or None."""
    for cmd in MUSESCORE_CANDIDATES:
        try:
            r = subprocess.run([cmd, "--version"], capture_output=True, timeout=10)
            if r.returncode == 0:
                return cmd
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return None


def _strip_xml_preamble(xml_str: str) -> str:
    """Remove <?xml …?> declaration and <!DOCTYPE …> so ET can parse cleanly."""
    xml_str = re.sub(r"<\?xml[^?]*\?>\s*", "", xml_str, flags=re.IGNORECASE)
    xml_str = re.sub(r"<!DOCTYPE\s+\S+[^>]*>\s*", "", xml_str, flags=re.DOTALL)
    return xml_str


def _musicxml_header() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"'
        ' "http://www.musicxml.org/dtds/partwise.dtd">\n'
    )


def read_mscx_from_mscz(mscz_path: Path) -> Optional[str]:
    """Extract the MSCX XML string from inside a .mscz zip archive."""
    try:
        with zipfile.ZipFile(mscz_path, "r") as zf:
            for name in zf.namelist():
                if name.lower().endswith(".mscx"):
                    return zf.read(name).decode("utf-8", errors="replace")
    except zipfile.BadZipFile:
        pass
    return None


# ===========================================================================
# Step 1 — Convert .mscz to .musicxml using MuseScore 3 CLI
# ===========================================================================

def convert_mscz_to_musicxml(
    mscz_path: Path, output_path: Path, musescore_cmd: str
) -> bool:
    """
    Run MuseScore 3 CLI to export a .mscz file to MusicXML.
    Returns True on success.
    """
    print(f"  [1/3] MuseScore export → {output_path.name}")
    try:
        result = subprocess.run(
            [musescore_cmd, "-o", str(output_path), str(mscz_path)],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            print(f"        ERROR (exit {result.returncode}): {result.stderr.strip()[:300]}")
            return False
        if not output_path.exists():
            print("        ERROR: output file not created")
            return False
        return True
    except subprocess.TimeoutExpired:
        print("        ERROR: MuseScore timed out after 120 s")
        return False
    except Exception as exc:
        print(f"        ERROR: {exc}")
        return False


# ===========================================================================
# Step 2 — Extract verse labels from MSCX and prepend to MusicXML lyrics
#
# Verse labels in MSCX are <Lyrics> elements that:
#   • Have NO <syllabic> child  (regular lyrics always have <syllabic>)
#   • Have <offset> or <align> child  (manual positioning used for labels)
#
# This mirrors the parseLyric() logic in musescore-display/src/MscxParser.ts
# and the pendingLabels mechanism in MscxToMusicXml.ts.
# ===========================================================================

def extract_verse_labels_from_mscx(mscx_xml: str) -> list:
    """
    Parse the MSCX XML and return a list of (measure_idx, verse_num_0based, label_text) tuples.

    Mirrors parseLyric() in MscxParser.ts and the pendingLabels collection in
    MscxToMusicXml.ts (lines 241-254):

      • Verse label = <Lyrics> with no <syllabic> child AND a direct <offset> or <align> child.
      • Labels are collected per measure from ALL data staves (staves that are direct children
        of <Score> and contain <Measure> elements — as opposed to <Part>-nested instrument-
        definition staves which have no <Measure> children).
      • Within a measure, duplicate verse numbers use last-write-wins (mirrors Map.set()).
      • measure_idx is 0-based and aligns with the MusicXML measure sequence.
    """
    labels: list = []
    try:
        root = ET.fromstring(mscx_xml)
    except ET.ParseError as exc:
        print(f"        WARNING: could not parse MSCX — {exc}")
        return labels

    # Find <Score> (direct child of root, or root itself).
    score_el = root.find("Score") or root

    # Collect the music-data staves: direct children of <Score> tagged <Staff> that
    # actually contain <Measure> elements.  This mirrors:
    #   directChildren(scoreEl, "Staff").filter(s => directChildren(s,"Measure").length > 0)
    # in MscxParser.ts:parseStaffData.  Part-definition <Staff> elements (nested inside
    # <Part>) have no <Measure> children and are intentionally excluded.
    data_staves = [
        child for child in score_el
        if child.tag == "Staff" and child.find("Measure") is not None
    ]

    if not data_staves:
        return labels

    # Build measure_idx -> {verse_num_0based -> label_text}.
    # Iterating all data staves mirrors the TS loop over numStaves that fills pendingLabels.
    by_measure: dict = {}

    for staff_el in data_staves:
        for measure_idx, measure_el in enumerate(staff_el.findall("Measure")):
            for lyrics_el in measure_el.iter("Lyrics"):
                has_syllabic = lyrics_el.find("syllabic") is not None
                has_offset   = lyrics_el.find("offset")   is not None
                has_align    = lyrics_el.find("align")     is not None

                if has_syllabic or not (has_offset or has_align):
                    continue  # regular lyric, not a verse label

                text_el = lyrics_el.find("text")
                no_el   = lyrics_el.find("no")
                if text_el is None or not text_el.text:
                    continue

                verse_num = int(no_el.text) if (no_el is not None and no_el.text) else 0
                by_measure.setdefault(measure_idx, {})[verse_num] = text_el.text.strip()

    # Flatten to a sorted list of (measure_idx, verse_num, label).
    for measure_idx in sorted(by_measure):
        for verse_num, label in by_measure[measure_idx].items():
            labels.append((measure_idx, verse_num, label))

    return labels


def prepend_verse_labels_to_musicxml(musicxml_str: str, verse_labels: list) -> str:
    """
    Post-process exported MusicXML to inject verse labels before the first
    lyric syllable of each verse section, wherever it appears in the score.

    verse_labels is a list of (measure_idx, verse_0based, label) tuples as
    returned by extract_verse_labels_from_mscx.

    The injection pattern (matching MscxToMusicXml.ts lines 719-726):
        <lyric number="N">
          <text>Label </text>          ← injected
          <elision/>                   ← injected
          <syllabic>begin|single</syllabic>
          <text>original lyric</text>
        </lyric>
    """
    if not verse_labels:
        return musicxml_str

    print(f"  [2/3] Prepending {len(verse_labels)} verse label(s): "
          + ", ".join(f'v{v+1}@m{m}="{lbl}"' for m, v, lbl in verse_labels))

    # MusicXML uses 1-based verse numbers; MSCX uses 0-based.
    # Key: (measure_idx, verse_1based) → label text.
    # If multiple labels share the same key, keep the first occurrence.
    pending: dict = {}
    for measure_idx, verse_0based, label in verse_labels:
        key = (measure_idx, verse_0based + 1)
        pending.setdefault(key, label)

    try:
        root = ET.fromstring(_strip_xml_preamble(musicxml_str).encode("utf-8"))
    except ET.ParseError as exc:
        print(f"        WARNING: could not parse MusicXML — {exc}")
        return musicxml_str

    # Iterate measures per part; inject at the first lyric of each verse
    # within the measure where the label was placed in the MSCX.
    for part_el in root.iter("part"):
        for measure_idx, measure_el in enumerate(part_el.findall("measure")):
            injected_this_measure: set = set()
            for lyric_el in measure_el.iter("lyric"):
                num_attr = lyric_el.get("number")
                if num_attr is None:
                    continue
                try:
                    verse_1based = int(num_attr)
                except ValueError:
                    continue

                key = (measure_idx, verse_1based)
                if key not in pending or key in injected_this_measure:
                    continue

                injected_this_measure.add(key)
                label = pending.pop(key)

                # Build the two elements to inject at position 0
                label_el = ET.Element("text")
                label_el.text = label + " "
                elision_el = ET.Element("elision")

                # Insert in reverse order so both end up at the front
                lyric_el.insert(0, elision_el)
                lyric_el.insert(0, label_el)

    if pending:
        print(f"        WARNING: no matching lyric found for {len(pending)} label(s): "
              + str(list(pending.keys())))

    result = ET.tostring(root, encoding="unicode", xml_declaration=False)
    return _musicxml_header() + result


# ===========================================================================
# Step 3 — Extract SVG aria-label text from .mscz and append as lyrics block
#
# Mirrors collectSvgText() + appendLyricsToMusicXml() from
# musescore-display/tools/mscz-to-musicxml.ts
# ===========================================================================

_ARIA_LABEL_RE = re.compile(r'aria-label="([^"]*)"')
_VERSE_NUM_RE  = re.compile(r'^\d+\.\s*$')


def extract_svg_text_from_mscz(mscz_path: Path) -> list:
    """
    Read all *.svg files embedded in the .mscz zip archive and extract every
    aria-label attribute value, split by newline, trimmed.
    Returns a flat list of non-empty lines in archive order.
    """
    lines: list = []
    try:
        with zipfile.ZipFile(mscz_path, "r") as zf:
            svg_names = sorted(n for n in zf.namelist() if n.lower().endswith(".svg"))
            for name in svg_names:
                try:
                    content = zf.read(name).decode("utf-8", errors="replace")
                except Exception:
                    continue
                for m in _ARIA_LABEL_RE.finditer(content):
                    for line in m.group(1).split("\n"):
                        trimmed = line.strip()
                        if trimmed:
                            lines.append(trimmed)
    except zipfile.BadZipFile:
        pass
    return lines


def insert_svg_lyrics_as_rights(musicxml_str: str, extra_lines: list) -> str:
    """
    Insert `extra_lines` as the content of a <rights> element inside
    <identification> in the MusicXML header.

    If <identification> does not exist it is created; if <rights> already
    exists its text is replaced.
    """
    if not extra_lines:
        return musicxml_str

    print(f"  [3/3] Inserting {len(extra_lines)} SVG text line(s) into <rights>")

    # Group lines into (verse_num, [lines]) segments and sort by verse number
    verses: list = []
    current_num = None
    current_lines: list = []

    for raw in extra_lines:
        trimmed = raw.strip()
        if not trimmed:
            continue
        if _VERSE_NUM_RE.match(trimmed):
            if current_lines or current_num is not None:
                verses.append((current_num, current_lines))
            try:
                current_num = int(trimmed.rstrip(".").strip())
            except ValueError:
                current_num = None
            current_lines = [trimmed]
        else:
            current_lines.append(trimmed)

    if current_lines or current_num is not None:
        verses.append((current_num, current_lines))

    # Sort: unnumbered segments first, then ascending by verse number
    verses.sort(key=lambda v: (v[0] is None, v[0] if v[0] is not None else 0))

    output_lines = []
    for i, (_, lines) in enumerate(verses):
        if i > 0:
            output_lines.append("")
        output_lines.extend(lines)

    full_text = "\n".join(output_lines)

    try:
        root = ET.fromstring(_strip_xml_preamble(musicxml_str).encode("utf-8"))
    except ET.ParseError as exc:
        print(f"        WARNING: could not parse MusicXML for rights insert — {exc}")
        return musicxml_str

    # Find or create <identification>
    identification = root.find("identification")
    if identification is None:
        identification = ET.Element("identification")
        root.insert(0, identification)

    # Find or create <rights> and set its text
    rights = identification.find("rights")
    if rights is None:
        rights = ET.SubElement(identification, "rights")
    rights.text = full_text

    result = ET.tostring(root, encoding="unicode", xml_declaration=False)
    result = result.replace('ns0:space="preserve"', 'xml:space="preserve"')
    return _musicxml_header() + result


# ===========================================================================
# Step 4 — Promote lyricist credit to <creator type="lyricist"> in <identification>
#
# MuseScore exports source attribution as <credit><credit-type>lyricist</credit-type>
# <credit-words>…</credit-words></credit> blocks.  This step folds all credit-words
# for lyricist credits into a single <creator type="lyricist"> element, with each
# credit-words value on its own line, which is the canonical identification slot.
# ===========================================================================

def extract_lyricist_from_credits(musicxml_str: str) -> Optional[str]:
    """
    Find all <credit> elements whose <credit-type> is 'lyricist' and return
    the <credit-words> text joined by newlines.  If multiple lyricist <credit>
    blocks are present their lines are concatenated in document order.
    Returns None when no lyricist credit exists.
    """
    try:
        root = ET.fromstring(_strip_xml_preamble(musicxml_str).encode("utf-8"))
    except ET.ParseError as exc:
        print(f"        WARNING: could not parse MusicXML for lyricist credits — {exc}")
        return None

    all_lines: list = []
    for credit_el in root.findall("credit"):
        credit_type = credit_el.find("credit-type")
        if credit_type is None or (credit_type.text or "").strip() != "lyricist":
            continue
        for words_el in credit_el.findall("credit-words"):
            if words_el.text:
                all_lines.append(words_el.text)

    return "\n".join(all_lines) if all_lines else None


def insert_lyricist_as_creator(musicxml_str: str, lyricist_text: str) -> str:
    """
    Insert (or replace) <creator type="lyricist">lyricist_text</creator>
    inside <identification>.
    """
    print("  [4/4] Inserting lyricist credit as <creator type=\"lyricist\">")

    try:
        root = ET.fromstring(_strip_xml_preamble(musicxml_str).encode("utf-8"))
    except ET.ParseError as exc:
        print(f"        WARNING: could not parse MusicXML for creator insert — {exc}")
        return musicxml_str

    identification = root.find("identification")
    if identification is None:
        identification = ET.Element("identification")
        root.insert(0, identification)

    # Replace any existing lyricist creator
    for existing in identification.findall("creator"):
        if existing.get("type") == "lyricist":
            identification.remove(existing)

    creator = ET.SubElement(identification, "creator")
    creator.set("type", "lyricist")
    creator.text = lyricist_text

    result = ET.tostring(root, encoding="unicode", xml_declaration=False)
    result = result.replace('ns0:space="preserve"', 'xml:space="preserve"')
    return _musicxml_header() + result


# ===========================================================================
# Full pipeline for one file
# ===========================================================================

def process_file(mscz_path: Path, output_dir: Path, musescore_cmd: str) -> bool:
    """Run all three steps for a single .mscz file."""
    print(f"\n{'─' * 60}")
    print(f"  {mscz_path.name}")
    print(f"{'─' * 60}")

    output_path = output_dir / (jks_output_stem(mscz_path.stem) + ".musicxml")

    # Step 1
    if not convert_mscz_to_musicxml(mscz_path, output_path, musescore_cmd):
        return False

    try:
        musicxml_str = output_path.read_text(encoding="utf-8")
    except Exception as exc:
        print(f"  FAILED reading exported MusicXML: {exc}")
        return False

    # Step 2
    mscx_xml = read_mscx_from_mscz(mscz_path)
    if mscx_xml:
        verse_labels = extract_verse_labels_from_mscx(mscx_xml)
        if verse_labels:
            musicxml_str = prepend_verse_labels_to_musicxml(musicxml_str, verse_labels)
        else:
            print("  [2/3] No verse labels found in MSCX")
    else:
        print("  [2/3] MSCX not found in archive (skipping verse labels)")

    # Step 3
    extra_lines = extract_svg_text_from_mscz(mscz_path)
    if extra_lines:
        musicxml_str = insert_svg_lyrics_as_rights(musicxml_str, extra_lines)
    else:
        print("  [3/3] No SVG text found in .mscz archive")

    # Step 4
    lyricist_text = extract_lyricist_from_credits(musicxml_str)
    if lyricist_text:
        musicxml_str = insert_lyricist_as_creator(musicxml_str, lyricist_text)
    else:
        print("  [4/4] No lyricist credit found")

    output_path.write_text(musicxml_str, encoding="utf-8")
    print(f"  ✓ Written → {output_path}")
    return True


# ===========================================================================
# Entry point
# ===========================================================================

def main():
    # Resolve MuseScore binary
    musescore_cmd = find_musescore()
    if musescore_cmd is None:
        print("ERROR: MuseScore 3 not found. Tried:")
        for c in MUSESCORE_CANDIDATES:
            print(f"  {c}")
        sys.exit(1)
    print(f"MuseScore binary: {musescore_cmd}")

    # Resolve input files
    if len(sys.argv) > 1:
        # Files passed as CLI arguments
        files = [Path(a) for a in sys.argv[1:]]
    else:
        # Default: first 10 .mscz files in JKS_DIR (sorted alphabetically)
        files = sorted(JKS_DIR.glob("*.mscz"))[:10]

    if not files:
        print(f"No .mscz files found in {JKS_DIR}")
        sys.exit(1)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Files to process: {len(files)}")

    ok, fail = 0, 0
    for mscz_path in files:
        if process_file(Path(mscz_path), OUTPUT_DIR, musescore_cmd):
            ok += 1
        else:
            fail += 1

    print(f"\n{'=' * 60}")
    print(f"Done — {ok} succeeded, {fail} failed")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
