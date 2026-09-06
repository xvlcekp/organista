#!/usr/bin/env python3
"""
Odpovede Music Pipeline
=======================
Converts the .mscz files of the Slovak Mass responses ("Odpovede") to MusicXML
for the Organista viewer. Independent of tools/jks-pipeline — the Odpovede
scores are saved in the MuseScore 4 file format, which MuseScore 3 cannot open,
and they need a clean-up step the JKS hymns do not.

  Step 1: Drop every staff that contains no notes from the MSCX inside the
          .mscz, then rebuild the archive. MuseScore hides such staves through
          the <hideEmptyStaves> style, but that style has no MusicXML
          equivalent, so OSMD would draw them as empty staves above the music.
          Title/text frames and system/page breaks living on a dropped staff
          move to the first surviving staff: MuseScore keeps both on the top
          staff only, and without the breaks it would re-flow the systems on
          export and the line breaks the scores were engraved with would be lost.

  Step 2: Export the cleaned score to MusicXML with the MuseScore 4 CLI.

  Step 3: Make the export read in OSMD the way the score reads in MuseScore.

          Title — MuseScore fills <work-title> from the "workTitle" meta tag,
          which in these scores holds an internal label ("641 (Missa
          Catholica)") rather than the title printed on the page ("KYRIE").
          OSMD draws <work-title>, so it is replaced with the title text of the
          title frame.

          Section headers — MuseScore writes a section header ("1. formula",
          "Recitanta A") as a text frame between two systems, and MusicXML has
          no element for such a frame, so the export flattens it into a
          page-level <credit> positioned by absolute page coordinates. OSMD only
          draws the title credit and never those, so the headers vanish. Their
          position is still known from the MSCX — the frame sits between two
          measures — so each one is re-emitted as a <direction> on the measure
          that follows it, the same encoding MuseScore uses for staff text,
          which OSMD does render. OSMD merges every text that starts on the
          same beat of the same staff into one label ("Prežehnanie C"), and it
          stacks the labels of one beat in document order, the last on top. So
          the headers of a measure become one multi-line <direction> written
          after the staff text of the beat, and that staff text is nudged by a
          tiny positive <offset> onto a timestamp of its own; OSMD then draws
          the header as a separate label above the staff text, at the start of
          the system where MuseScore prints it. The nudge is 1/64 of a quarter,
          which needs the score's <divisions> scaled up first.

          Barlines — a MuseScore "tick" barline (a short stroke above the
          staff, used between phrases of a chant) is exported as
          <bar-style>tick</bar-style>, which OSMD draws as an ordinary full
          barline. It is rewritten to "none", the closest OSMD gets to the
          near-invisible stroke MuseScore prints.

          Empty staves — with the <hideEmptyStaves> style MuseScore drops a
          staff from any system in which it has no notes (the accompaniment
          often rests through a recited intonation). OSMD always draws every
          staff, so the rests of such a staff are made invisible within that
          system and it appears as empty staff lines, the nearest OSMD gets to
          a hidden staff. The systems are the ones MuseScore exported
          (<print new-system>), which include its automatic line wraps.

  Known OSMD limitations that cannot be worked around in the MusicXML: lyrics
  placed above the staff are always drawn below it, and notes in parentheses
  lose their parentheses.

Usage:
  python3 pipeline.py file1.mscz …   # process specific files
  python3 pipeline.py                # process every .mscz under ODPOVEDE_DIR

The input is one .mscz per response. See README.md for the run that produced
the current output and for the OSMD render harness used to check it.
"""

import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import List, Optional, Tuple

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ODPOVEDE_DIR = Path("/Users/pavol.vlcek/Documents/Personal/Odpovede/Odpovede na konverziu")
OUTPUT_DIR = Path(__file__).parent / "output"

# MuseScore 4 binary paths — tried in order until one reports major version 4.
# MuseScore 3 is deliberately not a candidate: it refuses to open these scores.
MUSESCORE4_CANDIDATES = [
    "/Applications/MuseScore 4.app/Contents/MacOS/mscore",
    "mscore4",
    "musescore4",
    "/usr/bin/mscore4",
    "mscore",
    "musescore",
]

# Staff-level children that carry text rather than music (title, subtitle, …).
FRAME_TAGS = ("VBox", "HBox", "TBox", "FBox")

# Text styles of the title frame that MuseScore exports as typed credits, which
# OSMD draws by itself. Any other text in the title frame ("641 (Missa
# Catholica)" in the "frame" style) is exported as an anonymous credit that
# OSMD ignores, so it is treated as a header of the first measure instead.
TITLE_FRAME_STYLES = ("title", "subtitle", "composer", "lyricist", "poet")

# The text style of the score title within the title frame.
TITLE_STYLE = "title"

# Measure children that decide the layout: system and page breaks. MuseScore
# stores them on the top staff only.
LAYOUT_BREAK_TAG = "LayoutBreak"

# Barline styles OSMD cannot draw as MuseScore does; both are drawn as a full
# barline, so they are replaced with an invisible one.
HIDDEN_BARLINE_STYLES = ("tick", "short")
INVISIBLE_BARLINE_STYLE = "none"

# The style file inside the .mscz and the two settings that decide whether
# MuseScore hides a staff in a system where it has no notes.
STYLE_ENTRY = "score_style.mss"
HIDE_EMPTY_STAVES_TAG = "hideEmptyStaves"
KEEP_FIRST_SYSTEM_TAG = "dontHideStavesInFirstSystem"

# <print> attributes that start a new system in the export.
NEW_SYSTEM_ATTRIBUTES = ("new-system", "new-page")

# Note children that make a <note> sound (everything else is a rest).
PITCHED_NOTE_TAGS = ("pitch", "unpitched")

# Font attributes worth carrying from a <credit> onto the <direction> that
# replaces it. Anything positional is dropped — the direction is placed by the
# measure it hangs on, not by page coordinates.
CREDIT_FONT_ATTRIBUTES = ("font-family", "font-size", "font-style", "font-weight")

# Styling for a header that never reached the export as a credit, so no styling
# of its own survived. MuseScore sets these frame texts bold.
DEFAULT_HEADER_FONT = {"font-weight": "bold"}

# Children that a header <direction> is inserted after: the measure preamble
# and the staff text MuseScore already exported for the same beat. Coming later
# in the XML puts the header above that text in OSMD's stacking order.
MEASURE_PREAMBLE = ("print", "attributes", "direction", "sound")

# Several headers on one measure are stacked into one label, one per line.
HEADER_LINE_SEPARATOR = "\n"

# Staff text sharing its beat with a header is nudged by one division so OSMD
# gives it a label of its own; the score's divisions are scaled up by this
# factor first so the nudge is a negligible 1/64 of a quarter note.
STAFF_TEXT_NUDGE_SCALE = 64
STAFF_TEXT_NUDGE = 1

# Elements whose value is measured in divisions and must follow a rescaling.
DIVISION_VALUED_TAGS = ("divisions", "duration", "offset")

# Direction children that must precede <offset> in a <direction>.
DIRECTION_HEAD_TAGS = ("direction-type",)

# The MuseScore 4 CLI aborts at start-up every few runs, so retry before failing.
CONVERT_ATTEMPTS = 5
CONVERT_RETRY_DELAY_S = 2

# Some scores have measures whose content does not match the time signature
# ("Incomplete measure … Found: 8/4. Expected: 4/4."). MuseScore opens them with
# a corruption warning in the GUI but refuses them in converter mode unless the
# warning is waived with --force.
MUSESCORE_FORCE_FLAG = "-f"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def find_musescore4() -> Optional[str]:
    """Return the first binary that reports itself as MuseScore 4, or None."""
    for cmd in MUSESCORE4_CANDIDATES:
        try:
            r = subprocess.run([cmd, "--version"], capture_output=True, text=True, timeout=20)
        except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
            continue
        if r.returncode != 0:
            continue
        # MuseScore prints e.g. "MuseScore4 4.7.4" (3.x prints "MuseScore3 3.6.2")
        if "MuseScore4" in (r.stdout or "") + (r.stderr or ""):
            return cmd
    return None


def read_mscx_name(mscz_path: Path) -> Optional[str]:
    """Return the name of the .mscx entry inside a .mscz archive."""
    with zipfile.ZipFile(mscz_path, "r") as zf:
        for name in zf.namelist():
            if name.lower().endswith(".mscx"):
                return name
    return None


# ===========================================================================
# Step 1 — Drop empty staves from the MSCX
# ===========================================================================


def staff_has_notes(staff: ET.Element) -> bool:
    """True when a data staff contains at least one sounding note."""
    return next(staff.iter("Chord"), None) is not None or next(staff.iter("Note"), None) is not None


def _data_staves(score: ET.Element) -> List[ET.Element]:
    """
    The <Staff> elements that hold the music.

    A MuseScore file has two kinds of <Staff>: the staff *definitions* nested in
    <Part>, and the *data* staves that are direct children of <Score> and carry
    the <Measure> elements. Only the latter can be judged empty.
    """
    return [s for s in score.findall("Staff") if s.find("Measure") is not None]


def _move_frames(source: ET.Element, target: ET.Element) -> int:
    """
    Move title/text frames off a staff that is about to be dropped.

    A frame is re-inserted before the same measure it preceded on the source
    staff, so a title frame stays at the top and a mid-score frame stays where
    it was. Returns the number of frames moved.
    """
    target_measures = [i for i, child in enumerate(target) if child.tag == "Measure"]

    moved = 0
    measures_seen = 0
    for child in list(source):
        if child.tag == "Measure":
            measures_seen += 1
            continue
        if child.tag not in FRAME_TAGS:
            continue
        if measures_seen < len(target_measures):
            insert_at = target_measures[measures_seen]
        else:
            insert_at = len(target)
        target.insert(insert_at, child)
        # Every later measure of the target shifted one position to the right.
        target_measures = [i for i, c in enumerate(target) if c.tag == "Measure"]
        moved += 1
    return moved


def _move_layout_breaks(source: ET.Element, target: ET.Element) -> int:
    """
    Copy the system/page breaks of a staff that is about to be dropped onto the
    same measures of the target staff. A break the target already has is not
    duplicated. Returns the number of breaks moved.
    """
    target_measures = target.findall("Measure")

    moved = 0
    for index, measure in enumerate(source.findall("Measure")):
        if index >= len(target_measures):
            break
        existing = {b.findtext("subtype") for b in target_measures[index].findall(LAYOUT_BREAK_TAG)}
        for position, layout_break in enumerate(measure.findall(LAYOUT_BREAK_TAG)):
            if layout_break.findtext("subtype") in existing:
                continue
            # MuseScore writes the breaks before the <voice> children.
            target_measures[index].insert(position, layout_break)
            moved += 1
    return moved


def _fix_part_bracket(part: ET.Element) -> None:
    """
    Keep a part's brace consistent after some of its staves were dropped.

    The brace and the shared barline live on the part's first staff definition
    and span the whole part, so they have to shrink with it — and disappear
    when a single staff is left.
    """
    staves = part.findall("Staff")
    if not staves:
        return
    first = staves[0]
    for bracket in first.findall("bracket"):
        if len(staves) <= 1:
            first.remove(bracket)
        elif int(bracket.get("span", "1")) > len(staves):
            bracket.set("span", str(len(staves)))
    if len(staves) <= 1:
        for span in first.findall("barLineSpan"):
            first.remove(span)


def remove_empty_staves(mscx_xml: str) -> Tuple[str, List[str]]:
    """
    Return (cleaned MSCX, ids of the dropped staves).

    Staves without a single note are removed together with their staff
    definition, parts left without any staff are removed as well, and the
    remaining staff and part ids are renumbered from 1 so MuseScore still finds
    them. The input is returned unchanged when every staff carries music.
    """
    root = ET.fromstring(mscx_xml)
    score = root.find("Score")
    if score is None:
        return mscx_xml, []

    staves = _data_staves(score)
    empty = [s for s in staves if not staff_has_notes(s)]
    surviving = [s for s in staves if staff_has_notes(s)]
    if not empty or not surviving:
        # Nothing to do — or every staff is empty, in which case removing them
        # all would leave no score at all.
        return mscx_xml, []

    removed_ids = [s.get("id") for s in empty]

    for staff in empty:
        _move_frames(staff, surviving[0])
        _move_layout_breaks(staff, surviving[0])
        score.remove(staff)

    # Drop the matching staff definitions, then the parts left without staves.
    for part in score.findall("Part"):
        for definition in part.findall("Staff"):
            if definition.get("id") in removed_ids:
                part.remove(definition)
        if not part.findall("Staff"):
            score.remove(part)
        else:
            _fix_part_bracket(part)

    # Renumber: staff ids follow document order, part ids follow part order.
    new_id = {staff.get("id"): str(i) for i, staff in enumerate(_data_staves(score), start=1)}
    for staff in _data_staves(score):
        staff.set("id", new_id[staff.get("id")])
    for part_index, part in enumerate(score.findall("Part"), start=1):
        part.set("id", str(part_index))
        for definition in part.findall("Staff"):
            definition.set("id", new_id[definition.get("id")])

    cleaned = ET.tostring(root, encoding="unicode", xml_declaration=False)
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + cleaned, removed_ids


def write_cleaned_mscz(source: Path, destination: Path, mscx_name: str, mscx_xml: str) -> None:
    """Copy a .mscz archive, replacing its .mscx entry with mscx_xml."""
    with zipfile.ZipFile(source, "r") as src, zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as dst:
        for item in src.infolist():
            if item.filename == mscx_name:
                dst.writestr(item, mscx_xml.encode("utf-8"))
            else:
                dst.writestr(item, src.read(item.filename))


# ===========================================================================
# Step 2 — Export to MusicXML with MuseScore 4
# ===========================================================================


def convert_mscz_to_musicxml(mscz_path: Path, output_path: Path, musescore_cmd: str) -> bool:
    """
    Run the MuseScore 4 CLI to export a .mscz to MusicXML. True on success.

    The MuseScore 4 CLI aborts every few runs ("mutex lock failed"), usually at
    start-up but occasionally while shutting down after the export was already
    written. A written export therefore counts as success whatever the exit
    code, and any stale output is removed before each attempt so that only an
    export of this attempt can count. Scores MuseScore considers corrupted are
    exported anyway (--force).
    """
    for attempt in range(1, CONVERT_ATTEMPTS + 1):
        output_path.unlink(missing_ok=True)
        try:
            result = subprocess.run(
                [musescore_cmd, MUSESCORE_FORCE_FLAG, "-o", str(output_path), str(mscz_path)],
                capture_output=True,
                text=True,
                timeout=180,
            )
        except subprocess.TimeoutExpired:
            print("        MuseScore timed out after 180 s")
            result = None
        except Exception as exc:
            print(f"        MuseScore could not be started: {exc}")
            return False

        if output_path.exists() and output_path.stat().st_size > 0:
            if result is None or result.returncode != 0:
                print("        MuseScore aborted after writing the export; export kept")
            return True

        if result is not None and result.returncode != 0:
            print(f"        attempt {attempt} failed (exit {result.returncode}): "
                  f"{result.stderr.strip()[:200]}")
        elif result is not None:
            print(f"        attempt {attempt} produced no output file")

        if attempt < CONVERT_ATTEMPTS:
            time.sleep(CONVERT_RETRY_DELAY_S)

    print(f"        ERROR: MuseScore failed {CONVERT_ATTEMPTS} times")
    return False


# ===========================================================================
# Step 3 — Make the export read in OSMD as it does in MuseScore
# ===========================================================================


def _text_value(element: ET.Element) -> str:
    """The visible string of a MuseScore <Text>, markup flattened."""
    node = element.find("text")
    if node is None:
        return ""
    return re.sub(r"\s+", " ", "".join(node.itertext())).strip()


def _frame_texts(frame: ET.Element, styles: Optional[Tuple[str, ...]] = None) -> List[str]:
    """
    The visible strings of a MuseScore text frame.

    With `styles`, only the texts in one of those styles are returned; without
    it, every text is.
    """
    texts = []
    for element in frame.findall("Text"):
        if styles is not None and (element.findtext("style") or "") not in styles:
            continue
        value = _text_value(element)
        if value:
            texts.append(value)
    return texts


def _is_title_frame(frame: ET.Element) -> bool:
    return bool(_frame_texts(frame, (TITLE_STYLE,)))


def _title_frame(mscx_xml: str) -> Optional[ET.Element]:
    """
    The title block: the first frame ahead of the first measure that carries a
    title-styled text. An empty spacer frame before it does not count.
    """
    root = ET.fromstring(mscx_xml)
    score = root.find("Score")
    if score is None:
        return None
    staves = _data_staves(score)
    if not staves:
        return None
    for child in staves[0]:
        if child.tag == "Measure":
            return None
        if child.tag in FRAME_TAGS and _is_title_frame(child):
            return child
    return None


def collect_title(mscx_xml: str) -> Optional[str]:
    """The title printed on the page: the title-styled text of the title frame."""
    frame = _title_frame(mscx_xml)
    if frame is None:
        return None
    titles = _frame_texts(frame, (TITLE_STYLE,))
    return titles[0] if titles else None


def collect_frame_headers(mscx_xml: str) -> List[Tuple[int, str]]:
    """
    Return (measure number, text) for every section header in the score, in
    the order MuseScore prints them from top to bottom.

    MuseScore keeps the frames on the first data staff, in document order, so a
    frame's position is simply the number of measures that precede it. The very
    first frame is the title block: its title/subtitle texts become typed
    credits that OSMD draws, so only its other texts are headers, anchored to
    the first measure. A frame after the last measure has nothing to hang on
    and is skipped.
    """
    root = ET.fromstring(mscx_xml)
    score = root.find("Score")
    if score is None:
        return []

    staves = _data_staves(score)
    if not staves:
        return []
    staff = staves[0]
    total = len(staff.findall("Measure"))

    headers: List[Tuple[int, str]] = []
    measures_seen = 0
    title_frame_seen = False
    for child in staff:
        if child.tag == "Measure":
            measures_seen += 1
            continue
        if child.tag not in FRAME_TAGS:
            continue
        if measures_seen >= total:
            continue
        if measures_seen == 0 and not title_frame_seen and _is_title_frame(child):
            # The title block, as _title_frame() finds it.
            title_frame_seen = True
            texts = [
                _text_value(t)
                for t in child.findall("Text")
                if (t.findtext("style") or "") not in TITLE_FRAME_STYLES and _text_value(t)
            ]
        else:
            texts = _frame_texts(child)
        headers.extend((measures_seen + 1, text) for text in texts)
    return headers


def _make_direction(text: str, font: dict) -> ET.Element:
    """A staff-text direction carrying the section header(s) of one measure."""
    direction = ET.Element("direction", {"placement": "above"})
    group = ET.SubElement(direction, "direction-type")
    words = ET.SubElement(group, "words", dict(font))
    words.text = text
    ET.SubElement(direction, "staff").text = "1"
    return direction


def _direction_index(measure: ET.Element) -> int:
    """Where a header may be inserted: after the preamble and existing text."""
    index = 0
    for child in measure:
        if child.tag not in MEASURE_PREAMBLE:
            break
        index += 1
    return index


def _nudge_direction(direction: ET.Element) -> None:
    """Move a direction one division later so it no longer shares the header's beat."""
    offset = direction.find("offset")
    if offset is None:
        position = 0
        for child in direction:
            if child.tag not in DIRECTION_HEAD_TAGS:
                break
            position += 1
        offset = ET.Element("offset")
        direction.insert(position, offset)
        offset.text = "0"
    offset.text = str(int(offset.text or "0") + STAFF_TEXT_NUDGE)


def _scale_divisions(root: ET.Element, factor: int) -> None:
    """Express every division-valued element in `factor` times finer divisions."""
    for element in root.iter():
        if element.tag in DIVISION_VALUED_TAGS and element.text and element.text.strip():
            element.text = str(int(element.text) * factor)


def set_work_title(musicxml_str: str, title: Optional[str]) -> str:
    """
    Replace the <work-title> with the title printed on the page.

    The export is returned unchanged when no title is known.
    """
    if not title:
        return musicxml_str

    root = ET.fromstring(_strip_xml_preamble(musicxml_str))
    work = root.find("work")
    if work is None:
        work = ET.Element("work")
        root.insert(0, work)
    work_title = work.find("work-title")
    if work_title is None:
        work_title = ET.SubElement(work, "work-title")
    work_title.text = title
    return _serialize(root)


def read_hide_empty_staves(mscz_path: Path) -> Tuple[bool, bool]:
    """
    (hide empty staves, keep them in the first system) from the score's style.

    Both default to MuseScore's own defaults (off) when the style file or the
    setting is missing.
    """
    with zipfile.ZipFile(mscz_path, "r") as zf:
        if STYLE_ENTRY not in zf.namelist():
            return False, False
        style = ET.fromstring(zf.read(STYLE_ENTRY))
    hide = (style.findtext(f".//{HIDE_EMPTY_STAVES_TAG}") or "0").strip() == "1"
    keep_first = (style.findtext(f".//{KEEP_FIRST_SYSTEM_TAG}") or "0").strip() == "1"
    return hide, keep_first


def _starts_system(measure: ET.Element) -> bool:
    for print_element in measure.findall("print"):
        if any(print_element.get(attribute) == "yes" for attribute in NEW_SYSTEM_ATTRIBUTES):
            return True
    return False


def _systems(part: ET.Element) -> List[List[ET.Element]]:
    """The measures of a part grouped into the systems MuseScore exported."""
    systems: List[List[ET.Element]] = []
    for measure in part.findall("measure"):
        if not systems or _starts_system(measure):
            systems.append([])
        systems[-1].append(measure)
    return systems


def _note_staff(note: ET.Element) -> str:
    return (note.findtext("staff") or "1").strip()


def hide_rests_of_empty_staves(musicxml_str: str, keep_first_system: bool = False) -> Tuple[str, int]:
    """
    Make the rests of a staff invisible in every system where the staff has no
    sounding note, so OSMD shows the staff empty where MuseScore hides it.
    Returns (xml, number of staff-systems emptied).
    """
    root = ET.fromstring(_strip_xml_preamble(musicxml_str))
    part = root.find("part")
    if part is None:
        return musicxml_str, 0

    emptied = 0
    for index, system in enumerate(_systems(part)):
        if index == 0 and keep_first_system:
            continue
        notes = [note for measure in system for note in measure.findall("note")]
        staves = {_note_staff(note) for note in notes}
        sounding = {_note_staff(n) for n in notes if any(n.find(tag) is not None for tag in PITCHED_NOTE_TAGS)}
        silent = staves - sounding
        if not sounding or not silent:
            # A system without any music keeps its rests; a system where every
            # staff sounds has nothing to hide.
            continue
        for note in notes:
            if _note_staff(note) in silent:
                note.set("print-object", "no")
        emptied += len(silent)

    if not emptied:
        return musicxml_str, 0
    return _serialize(root), emptied


def hide_tick_barlines(musicxml_str: str) -> Tuple[str, int]:
    """
    Replace the barline styles OSMD would draw as a full barline with an
    invisible one. Returns (xml, count).
    """
    root = ET.fromstring(_strip_xml_preamble(musicxml_str))
    hidden = 0
    for style in root.iter("bar-style"):
        if style.text in HIDDEN_BARLINE_STYLES:
            style.text = INVISIBLE_BARLINE_STYLE
            hidden += 1
    if not hidden:
        return musicxml_str, 0
    return _serialize(root), hidden


def _take_credit_styling(root: ET.Element, wanted: set) -> dict:
    """
    Drop the credits that only exist because a frame had nowhere else to go, and
    report the styling each of them carried.

    A credit that names its role (title, subtitle, composer) is left in place —
    OSMD draws those. Only the anonymous ones, which are the flattened frames,
    are removed, and only when their text is one we are about to re-anchor.
    """
    styling: dict = {}
    for credit in list(root.findall("credit")):
        if credit.find("credit-type") is not None:
            continue
        words = credit.find("credit-words")
        text = (words.text or "").strip() if words is not None else ""
        if text not in wanted:
            continue
        styling.setdefault(
            text,
            {k: v for k, v in words.attrib.items() if k in CREDIT_FONT_ATTRIBUTES},
        )
        root.remove(credit)
    return styling


def promote_frame_headers(musicxml_str: str, headers: List[Tuple[int, str]]) -> Tuple[str, int]:
    """
    Re-attach the section headers to their measures. Returns (xml, count).

    The export is returned unchanged when the score has no headers, so scores
    that label their sections with staff text — which MuseScore already exports
    as a <direction> — pass through untouched.
    """
    if not headers:
        return musicxml_str, 0

    root = ET.fromstring(_strip_xml_preamble(musicxml_str))
    part = root.find("part")
    if part is None:
        return musicxml_str, 0

    styling = _take_credit_styling(root, {text for _, text in headers})
    measures = {m.get("number"): m for m in part.findall("measure")}

    grouped: dict = {}
    for number, text in headers:
        grouped.setdefault(number, []).append(text)

    promoted = 0
    sharing_the_beat: List[ET.Element] = []
    for number, texts in grouped.items():
        measure = measures.get(str(number))
        if measure is None:
            continue
        index = _direction_index(measure)
        sharing_the_beat.extend(child for child in list(measure)[:index] if child.tag == "direction")
        measure.insert(
            index,
            _make_direction(HEADER_LINE_SEPARATOR.join(texts), styling.get(texts[0], DEFAULT_HEADER_FONT)),
        )
        promoted += len(texts)

    if sharing_the_beat:
        # Scale first so the nudge itself stays a single, now tiny, division.
        _scale_divisions(root, STAFF_TEXT_NUDGE_SCALE)
        for direction in sharing_the_beat:
            _nudge_direction(direction)

    return _serialize(root), promoted


def _serialize(root: ET.Element) -> str:
    """A MusicXML document with its declaration and DOCTYPE restored."""
    version = root.get("version", "4.0")
    body = ET.tostring(root, encoding="unicode", xml_declaration=False)
    return _musicxml_header(version) + body


def _strip_xml_preamble(xml_str: str) -> str:
    """Remove <?xml …?> and <!DOCTYPE …> so ElementTree can parse cleanly."""
    xml_str = re.sub(r"<\?xml[^?]*\?>\s*", "", xml_str, flags=re.IGNORECASE)
    xml_str = re.sub(r"<!DOCTYPE\s+\S+[^>]*>\s*", "", xml_str, flags=re.DOTALL)
    return xml_str


def _musicxml_header(version: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML {version} Partwise//EN"'
        ' "http://www.musicxml.org/dtds/partwise.dtd">\n'
    )


# ===========================================================================
# Full pipeline for one file
# ===========================================================================


def process_file(mscz_path: Path, output_dir: Path, output_stem: str, musescore_cmd: str) -> bool:
    """Run all three steps for a single .mscz file."""
    print(f"\n{'─' * 60}")
    print(f"  {mscz_path.name}")
    print(f"{'─' * 60}")

    mscx_name = read_mscx_name(mscz_path)
    if mscx_name is None:
        print("  [1/3] ERROR: no .mscx entry inside the archive")
        return False

    with zipfile.ZipFile(mscz_path, "r") as zf:
        mscx_xml = zf.read(mscx_name).decode("utf-8", errors="replace")

    try:
        cleaned_xml, removed = remove_empty_staves(mscx_xml)
        headers = collect_frame_headers(mscx_xml)
        title = collect_title(mscx_xml)
    except ET.ParseError as exc:
        print(f"  [1/3] ERROR: could not parse MSCX — {exc}")
        return False

    output_dir.mkdir(parents=True, exist_ok=True)
    exported = output_dir / (output_stem + ".musicxml")

    with tempfile.TemporaryDirectory() as tmp:
        if removed:
            print(f"  [1/3] Removed {len(removed)} empty staff/staves (ids {', '.join(removed)})")
            source = Path(tmp) / mscz_path.name
            write_cleaned_mscz(mscz_path, source, mscx_name, cleaned_xml)
        else:
            print("  [1/3] No empty staves to remove")
            source = mscz_path

        print("  [2/3] MuseScore 4 export")
        if not convert_mscz_to_musicxml(source, exported, musescore_cmd):
            return False

        musicxml_str = exported.read_text(encoding="utf-8")

    hide_empty, keep_first_system = read_hide_empty_staves(mscz_path)
    try:
        finished = set_work_title(musicxml_str, title)
        finished, promoted = promote_frame_headers(finished, headers)
        finished, hidden = hide_tick_barlines(finished)
        emptied = 0
        if hide_empty:
            finished, emptied = hide_rests_of_empty_staves(finished, keep_first_system)
    except ET.ParseError as exc:
        print(f"  [3/3] ERROR: could not parse the MusicXML export — {exc}")
        return False

    print(f"  [3/3] Title {title!r}" if title else "  [3/3] No title frame, <work-title> kept")
    if promoted:
        print(f"        Anchored {promoted} section header(s): "
              f"{', '.join(f'm{n} {t!r}' for n, t in headers)}")
    else:
        print("        No section headers to anchor")
    if hidden:
        print(f"        Hid {hidden} tick barline(s)")
    if emptied:
        print(f"        Emptied {emptied} staff-system(s) MuseScore hides")
    if finished != musicxml_str:
        exported.write_text(finished, encoding="utf-8")

    print(f"  ✓ Written → {exported}")
    return True


# ===========================================================================
# Entry point
# ===========================================================================


def main():
    musescore_cmd = find_musescore4()
    if musescore_cmd is None:
        print("ERROR: MuseScore 4 not found. Tried:")
        for c in MUSESCORE4_CANDIDATES:
            print(f"  {c}")
        sys.exit(1)
    print(f"MuseScore binary: {musescore_cmd}")

    if len(sys.argv) > 1:
        files = [Path(a).resolve() for a in sys.argv[1:]]
        base = None
    else:
        files = sorted(ODPOVEDE_DIR.rglob("*.mscz"))
        base = ODPOVEDE_DIR

    if not files:
        print(f"No .mscz files found in {ODPOVEDE_DIR}")
        sys.exit(1)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Files to process: {len(files)}")

    ok, fail = 0, 0
    for mscz_path in files:
        # Keep the source folder structure so same-named files cannot collide.
        relative = mscz_path.relative_to(base).parent if base else Path(".")
        if process_file(mscz_path, OUTPUT_DIR / relative, mscz_path.stem, musescore_cmd):
            ok += 1
        else:
            fail += 1

    print(f"\n{'=' * 60}")
    print(f"Done — {ok} succeeded, {fail} failed")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
