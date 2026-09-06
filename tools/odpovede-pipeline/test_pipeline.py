"""Tests for pipeline.py"""
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

from pipeline import (
    collect_frame_headers,
    collect_title,
    hide_rests_of_empty_staves,
    hide_tick_barlines,
    promote_frame_headers,
    read_hide_empty_staves,
    read_mscx_name,
    remove_empty_staves,
    set_work_title,
    staff_has_notes,
    write_cleaned_mscz,
)


def mscx(parts: str, staves: str) -> str:
    """Wrap part definitions and data staves in a minimal MuseScore 4 file."""
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<museScore version="4.10">\n'
        "  <programVersion>4.1.0</programVersion>\n"
        "  <Score>\n"
        "    <Division>480</Division>\n"
        f"{parts}"
        f"{staves}"
        "  </Score>\n"
        "</museScore>\n"
    )


def rest_measure() -> str:
    return "<Measure><voice><Rest><durationType>half</durationType></Rest></voice></Measure>"


def note_measure(pitch: int = 60) -> str:
    return (
        "<Measure><voice><Chord><durationType>half</durationType>"
        f"<Note><pitch>{pitch}</pitch><tpc>14</tpc></Note>"
        "</Chord></voice></Measure>"
    )


VOICE_PART = '    <Part id="1"><Staff id="1"/><trackName>Voice</trackName></Part>\n'
PIANO_PART = (
    '    <Part id="2">'
    '<Staff id="2"><bracket type="1" span="2"/><barLineSpan>1</barLineSpan></Staff>'
    '<Staff id="3"/>'
    "<trackName>Piano</trackName></Part>\n"
)


class TestStaffHasNotes(unittest.TestCase):

    def test_rest_only_staff_has_no_notes(self):
        staff = ET.fromstring(f'<Staff id="1">{rest_measure()}{rest_measure()}</Staff>')
        self.assertFalse(staff_has_notes(staff))

    def test_staff_with_a_chord_has_notes(self):
        staff = ET.fromstring(f'<Staff id="1">{rest_measure()}{note_measure()}</Staff>')
        self.assertTrue(staff_has_notes(staff))

    def test_empty_staff_has_no_notes(self):
        self.assertFalse(staff_has_notes(ET.fromstring('<Staff id="1"/>')))


class TestRemoveEmptyStaves(unittest.TestCase):

    def build(self):
        """A Voice part of rests above a two-staff Piano part with notes."""
        return mscx(
            VOICE_PART + PIANO_PART,
            f'    <Staff id="1">{rest_measure()}</Staff>\n'
            f'    <Staff id="2">{note_measure()}</Staff>\n'
            f'    <Staff id="3">{note_measure(48)}</Staff>\n',
        )

    def test_reports_the_removed_staff_id(self):
        _, removed = remove_empty_staves(self.build())
        self.assertEqual(removed, ["1"])

    def test_empty_data_staff_is_dropped(self):
        cleaned, _ = remove_empty_staves(self.build())
        score = ET.fromstring(cleaned).find("Score")
        data_staves = [s for s in score.findall("Staff") if s.find("Measure") is not None]
        self.assertEqual(len(data_staves), 2)
        self.assertTrue(all(staff_has_notes(s) for s in data_staves))

    def test_part_without_staves_is_dropped(self):
        cleaned, _ = remove_empty_staves(self.build())
        score = ET.fromstring(cleaned).find("Score")
        names = [p.findtext("trackName") for p in score.findall("Part")]
        self.assertEqual(names, ["Piano"])

    def test_surviving_staves_are_renumbered_from_one(self):
        cleaned, _ = remove_empty_staves(self.build())
        score = ET.fromstring(cleaned).find("Score")
        data_staves = [s for s in score.findall("Staff") if s.find("Measure") is not None]
        self.assertEqual([s.get("id") for s in data_staves], ["1", "2"])

    def test_staff_definitions_follow_the_new_numbering(self):
        cleaned, _ = remove_empty_staves(self.build())
        score = ET.fromstring(cleaned).find("Score")
        piano = score.findall("Part")[0]
        self.assertEqual([s.get("id") for s in piano.findall("Staff")], ["1", "2"])

    def test_parts_are_renumbered_from_one(self):
        cleaned, _ = remove_empty_staves(self.build())
        score = ET.fromstring(cleaned).find("Score")
        self.assertEqual([p.get("id") for p in score.findall("Part")], ["1"])

    def test_untouched_when_every_staff_has_notes(self):
        source = mscx(PIANO_PART, f'    <Staff id="2">{note_measure()}</Staff>\n')
        cleaned, removed = remove_empty_staves(source)
        self.assertEqual(removed, [])
        self.assertEqual(cleaned, source)

    def test_untouched_when_every_staff_is_empty(self):
        source = mscx(VOICE_PART, f'    <Staff id="1">{rest_measure()}</Staff>\n')
        cleaned, removed = remove_empty_staves(source)
        self.assertEqual(removed, [])
        self.assertEqual(cleaned, source)

    def test_xml_declaration_is_kept(self):
        cleaned, _ = remove_empty_staves(self.build())
        self.assertTrue(cleaned.startswith('<?xml version="1.0" encoding="UTF-8"?>'))


class TestFrameHandling(unittest.TestCase):
    """Title frames must survive the removal of the staff they live on."""

    def test_title_frame_moves_to_the_first_surviving_staff(self):
        title = "<VBox><Text><style>title</style><text>DIALÓG</text></Text></VBox>"
        source = mscx(
            VOICE_PART + PIANO_PART,
            f'    <Staff id="1">{title}{rest_measure()}</Staff>\n'
            f'    <Staff id="2">{note_measure()}</Staff>\n'
            f'    <Staff id="3">{note_measure(48)}</Staff>\n',
        )
        cleaned, _ = remove_empty_staves(source)
        score = ET.fromstring(cleaned).find("Score")
        first = [s for s in score.findall("Staff") if s.find("Measure") is not None][0]
        self.assertEqual([c.tag for c in first], ["VBox", "Measure"])
        self.assertEqual(first.find("VBox/Text/text").text, "DIALÓG")

    def test_mid_score_frame_keeps_its_place(self):
        frame = "<VBox><height>6</height></VBox>"
        source = mscx(
            VOICE_PART + PIANO_PART,
            f'    <Staff id="1">{rest_measure()}{frame}{rest_measure()}</Staff>\n'
            f'    <Staff id="2">{note_measure()}{note_measure()}</Staff>\n'
            f'    <Staff id="3">{note_measure(48)}{note_measure(48)}</Staff>\n',
        )
        cleaned, _ = remove_empty_staves(source)
        score = ET.fromstring(cleaned).find("Score")
        first = [s for s in score.findall("Staff") if s.find("Measure") is not None][0]
        self.assertEqual([c.tag for c in first], ["Measure", "VBox", "Measure"])


def line_break() -> str:
    return "<LayoutBreak><subtype>line</subtype></LayoutBreak>"


def page_break() -> str:
    return "<LayoutBreak><subtype>page</subtype></LayoutBreak>"


def broken_measure(break_xml: str) -> str:
    return f"<Measure>{break_xml}<voice><Rest><durationType>half</durationType></Rest></voice></Measure>"


class TestLayoutBreakHandling(unittest.TestCase):
    """The system breaks MuseScore keeps on the top staff must survive its removal."""

    def cleaned_first_staff(self, voice_staff: str, piano_staff: str) -> ET.Element:
        source = mscx(
            VOICE_PART + PIANO_PART,
            f'    <Staff id="1">{voice_staff}</Staff>\n'
            f'    <Staff id="2">{piano_staff}</Staff>\n'
            f'    <Staff id="3">{note_measure(48)}{note_measure(48)}</Staff>\n',
        )
        cleaned, _ = remove_empty_staves(source)
        score = ET.fromstring(cleaned).find("Score")
        return [s for s in score.findall("Staff") if s.find("Measure") is not None][0]

    def test_break_moves_to_the_same_measure_of_the_surviving_staff(self):
        first = self.cleaned_first_staff(
            rest_measure() + broken_measure(line_break()),
            note_measure() + note_measure(),
        )
        breaks = [m.find("LayoutBreak/subtype") for m in first.findall("Measure")]
        self.assertIsNone(breaks[0])
        self.assertEqual(breaks[1].text, "line")

    def test_break_is_written_before_the_voice(self):
        first = self.cleaned_first_staff(broken_measure(page_break()) + rest_measure(), note_measure() + note_measure())
        self.assertEqual([c.tag for c in first.find("Measure")], ["LayoutBreak", "voice"])

    def test_break_the_target_already_has_is_not_duplicated(self):
        first = self.cleaned_first_staff(
            broken_measure(line_break()) + rest_measure(),
            f"<Measure>{line_break()}<voice><Chord><durationType>half</durationType>"
            "<Note><pitch>60</pitch><tpc>14</tpc></Note></Chord></voice></Measure>" + note_measure(),
        )
        self.assertEqual(len(first.find("Measure").findall("LayoutBreak")), 1)

    def test_different_break_kinds_on_one_measure_are_both_kept(self):
        first = self.cleaned_first_staff(
            broken_measure(line_break()) + rest_measure(),
            f"<Measure>{page_break()}<voice><Chord><durationType>half</durationType>"
            "<Note><pitch>60</pitch><tpc>14</tpc></Note></Chord></voice></Measure>" + note_measure(),
        )
        kinds = sorted(b.findtext("subtype") for b in first.find("Measure").findall("LayoutBreak"))
        self.assertEqual(kinds, ["line", "page"])


class TestBracketAdjustment(unittest.TestCase):

    def test_brace_and_barline_span_are_dropped_for_a_single_staff(self):
        source = mscx(
            PIANO_PART,
            f'    <Staff id="2">{note_measure()}</Staff>\n'
            f'    <Staff id="3">{rest_measure()}</Staff>\n',
        )
        cleaned, removed = remove_empty_staves(source)
        self.assertEqual(removed, ["3"])
        score = ET.fromstring(cleaned).find("Score")
        definition = score.findall("Part")[0].findall("Staff")[0]
        self.assertEqual(definition.findall("bracket"), [])
        self.assertEqual(definition.findall("barLineSpan"), [])

    def test_brace_span_shrinks_to_the_remaining_staves(self):
        three_staff_part = (
            '    <Part id="1">'
            '<Staff id="1"><bracket type="1" span="3"/><barLineSpan>2</barLineSpan></Staff>'
            '<Staff id="2"/><Staff id="3"/>'
            "<trackName>Organ</trackName></Part>\n"
        )
        source = mscx(
            three_staff_part,
            f'    <Staff id="1">{note_measure()}</Staff>\n'
            f'    <Staff id="2">{note_measure(48)}</Staff>\n'
            f'    <Staff id="3">{rest_measure()}</Staff>\n',
        )
        cleaned, _ = remove_empty_staves(source)
        score = ET.fromstring(cleaned).find("Score")
        definition = score.findall("Part")[0].findall("Staff")[0]
        self.assertEqual(definition.find("bracket").get("span"), "2")


class TestArchiveRoundTrip(unittest.TestCase):

    def make_mscz(self, directory: Path) -> Path:
        path = directory / "score.mscz"
        with zipfile.ZipFile(path, "w") as zf:
            zf.writestr("META-INF/container.xml", "<container/>")
            zf.writestr("score.mscx", "<museScore/>")
            zf.writestr("score_style.mss", "<museScore><Style/></museScore>")
        return path

    def test_read_mscx_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(read_mscx_name(self.make_mscz(Path(tmp))), "score.mscx")

    def test_write_cleaned_mscz_replaces_only_the_mscx(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = self.make_mscz(Path(tmp))
            destination = Path(tmp) / "cleaned.mscz"
            write_cleaned_mscz(source, destination, "score.mscx", "<museScore>ok</museScore>")
            with zipfile.ZipFile(destination) as zf:
                self.assertEqual(
                    zf.namelist(),
                    ["META-INF/container.xml", "score.mscx", "score_style.mss"],
                )
                self.assertEqual(zf.read("score.mscx").decode(), "<museScore>ok</museScore>")
                self.assertEqual(zf.read("META-INF/container.xml").decode(), "<container/>")


# ---------------------------------------------------------------------------
# Step 3 — anchoring the section headers
# ---------------------------------------------------------------------------


def frame(text: str, tag: str = "VBox") -> str:
    return f"<{tag}><Text><style>frame</style><text>{text}</text></Text></{tag}>"


def title_frame(title: str, *extra_texts: str) -> str:
    """A title frame; every extra text is given as '<style>:<text>'."""
    texts = f"<Text><style>title</style><text>{title}</text></Text>"
    for extra in extra_texts:
        style, text = extra.split(":", 1)
        texts += f"<Text><style>{style}</style><text>{text}</text></Text>"
    return f"<VBox>{texts}</VBox>"


def headed_score(frames_and_measures: str) -> str:
    """A one-staff MuseScore file whose frames and measures are given verbatim."""
    return mscx('<Part id="1"><Staff id="1"/></Part>', f'<Staff id="1">{frames_and_measures}</Staff>')


def credit(text: str, credit_type: str = "") -> str:
    kind = f"<credit-type>{credit_type}</credit-type>" if credit_type else ""
    return (
        f'<credit page="1">{kind}'
        f'<credit-words default-x="96.8" default-y="1725.8" font-size="13" font-weight="bold">'
        f"{text}</credit-words></credit>"
    )


def export(credits: str, measures: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"'
        ' "http://www.musicxml.org/dtds/partwise.dtd">\n'
        f'<score-partwise version="4.0"><work><work-title>T</work-title></work>{credits}'
        f'<part-list><score-part id="P1"><part-name>P</part-name></score-part></part-list>'
        f'<part id="P1">{measures}</part></score-partwise>'
    )


def measure(number: int, preamble: str = "") -> str:
    return f'<measure number="{number}">{preamble}<note><rest/><duration>4</duration></note></measure>'


class TestCollectFrameHeaders(unittest.TestCase):

    def test_title_frame_is_not_a_header(self):
        source = headed_score(title_frame("TITLE") + note_measure())
        self.assertEqual(collect_frame_headers(source), [])

    def test_frame_after_the_title_anchors_to_the_first_measure(self):
        source = headed_score(title_frame("TITLE") + frame("1. formula") + note_measure())
        self.assertEqual(collect_frame_headers(source), [(1, "1. formula")])

    def test_mid_score_frame_anchors_to_the_following_measure(self):
        source = headed_score(
            title_frame("TITLE") + note_measure() + note_measure() + frame("2. formula") + note_measure()
        )
        self.assertEqual(collect_frame_headers(source), [(3, "2. formula")])

    def test_hbox_counts_too(self):
        source = headed_score(title_frame("TITLE") + frame("Recitanta A", "HBox") + note_measure())
        self.assertEqual(collect_frame_headers(source), [(1, "Recitanta A")])

    def test_several_texts_in_one_frame_are_all_reported(self):
        source = headed_score(
            title_frame("TITLE")
            + "<VBox><Text><style>frame</style><text>A</text></Text>"
            "<Text><style>frame</style><text>B</text></Text></VBox>"
            + note_measure()
        )
        self.assertEqual(collect_frame_headers(source), [(1, "A"), (1, "B")])

    def test_markup_inside_the_text_is_flattened(self):
        source = headed_score(
            title_frame("TITLE")
            + "<VBox><Text><style>frame</style><text><b>1.</b> formula</text></Text></VBox>"
            + note_measure()
        )
        self.assertEqual(collect_frame_headers(source), [(1, "1. formula")])

    def test_empty_frame_is_ignored(self):
        source = headed_score(title_frame("TITLE") + note_measure() + "<HBox/>" + note_measure())
        self.assertEqual(collect_frame_headers(source), [])

    def test_frame_after_the_last_measure_is_skipped(self):
        source = headed_score(title_frame("TITLE") + note_measure() + frame("trailing"))
        self.assertEqual(collect_frame_headers(source), [])


class TestTitleFrameTexts(unittest.TestCase):
    """Only the title/subtitle of the title frame are credits OSMD draws."""

    def test_frame_styled_text_of_the_title_frame_is_a_header_of_measure_one(self):
        score = headed_score(title_frame("KYRIE", "frame:641 (Missa Catholica)") + note_measure())
        self.assertEqual(collect_frame_headers(score), [(1, "641 (Missa Catholica)")])

    def test_subtitle_of_the_title_frame_is_not_a_header(self):
        score = headed_score(title_frame("OBRAD", "subtitle:Hyzopom ma pokrop") + note_measure())
        self.assertEqual(collect_frame_headers(score), [])

    def test_title_frame_text_comes_before_the_next_frame_header(self):
        score = headed_score(
            title_frame("AKLAMÁCIA", "frame:Recitanta") + frame("1. formula") + note_measure()
        )
        self.assertEqual(collect_frame_headers(score), [(1, "Recitanta"), (1, "1. formula")])


class TestCollectTitle(unittest.TestCase):

    def test_empty_spacer_frame_before_the_title_frame_is_skipped(self):
        score = headed_score("<HBox><width>5</width></HBox>" + title_frame("KYRIE", "frame:641") + note_measure())
        self.assertEqual(collect_title(score), "KYRIE")
        self.assertEqual(collect_frame_headers(score), [(1, "641")])

    def test_title_frame_must_precede_the_first_measure(self):
        score = headed_score(note_measure() + title_frame("LATE") + note_measure())
        self.assertIsNone(collect_title(score))
        self.assertEqual(collect_frame_headers(score), [(2, "LATE")])

    def test_title_is_the_title_styled_text_of_the_first_frame(self):
        score = headed_score(title_frame("KYRIE", "frame:641 (Missa Catholica)") + note_measure())
        self.assertEqual(collect_title(score), "KYRIE")

    def test_markup_inside_the_title_is_flattened(self):
        score = headed_score("<VBox><Text><style>title</style><text><b>KY</b>RIE</text></Text></VBox>" + note_measure())
        self.assertEqual(collect_title(score), "KYRIE")

    def test_no_title_frame_gives_no_title(self):
        self.assertIsNone(collect_title(headed_score(note_measure())))

    def test_first_frame_without_a_title_text_gives_no_title(self):
        self.assertIsNone(collect_title(headed_score(frame("1. formula") + note_measure())))


class TestSetWorkTitle(unittest.TestCase):

    def parse(self, xml):
        return ET.fromstring(xml[xml.index("<score-partwise"):])

    def test_work_title_is_replaced(self):
        root = self.parse(set_work_title(export("", measure(1)), "KYRIE"))
        self.assertEqual(root.findtext("work/work-title"), "KYRIE")

    def test_missing_work_element_is_created_first(self):
        source = export("", measure(1)).replace("<work><work-title>T</work-title></work>", "")
        root = self.parse(set_work_title(source, "KYRIE"))
        self.assertEqual(root[0].tag, "work")
        self.assertEqual(root.findtext("work/work-title"), "KYRIE")

    def test_no_title_leaves_the_export_untouched(self):
        source = export("", measure(1))
        self.assertEqual(set_work_title(source, None), source)

    def test_the_doctype_is_written_back(self):
        xml = set_work_title(export("", measure(1)), "KYRIE")
        self.assertIn("DOCTYPE score-partwise", xml)


def barline(style: str) -> str:
    return f'<barline location="right"><bar-style>{style}</bar-style></barline>'


class TestHideTickBarlines(unittest.TestCase):

    def styles(self, xml):
        root = ET.fromstring(xml[xml.index("<score-partwise"):])
        return [b.text for b in root.iter("bar-style")]

    def test_tick_becomes_none(self):
        xml, count = hide_tick_barlines(export("", measure(1, barline("tick"))))
        self.assertEqual((self.styles(xml), count), (["none"], 1))

    def test_short_becomes_none(self):
        xml, count = hide_tick_barlines(export("", measure(1, barline("short"))))
        self.assertEqual((self.styles(xml), count), (["none"], 1))

    def test_other_styles_are_kept(self):
        source = export("", measure(1, barline("light-light")) + measure(2, barline("light-heavy")))
        xml, count = hide_tick_barlines(source)
        self.assertEqual((xml, count), (source, 0))


def two_staff_measure(number: int, upper: str, lower: str, new_system: bool = False) -> str:
    """A piano measure; `upper`/`lower` are 'note' or 'rest'."""
    def note(kind, staff):
        body = "<pitch><step>C</step><octave>4</octave></pitch>" if kind == "note" else "<rest/>"
        return f"<note>{body}<duration>4</duration><voice>1</voice><staff>{staff}</staff></note>"
    print_element = '<print new-system="yes"/>' if new_system else ""
    return (
        f'<measure number="{number}">{print_element}<attributes><staves>2</staves></attributes>'
        f"{note(upper, 1)}<backup><duration>4</duration></backup>{note(lower, 2)}</measure>"
    )


class TestHideRestsOfEmptyStaves(unittest.TestCase):

    def run_on(self, measures, keep_first=False):
        xml, count = hide_rests_of_empty_staves(export("", measures), keep_first)
        root = ET.fromstring(xml[xml.index("<score-partwise"):])
        return root, count

    def hidden_by_measure(self, root):
        return [
            [n.get("print-object") for n in m.findall("note")]
            for m in root.findall("part/measure")
        ]

    def test_rests_of_a_staff_silent_through_a_system_are_hidden(self):
        root, count = self.run_on(two_staff_measure(1, "note", "rest") + two_staff_measure(2, "note", "rest"))
        self.assertEqual(count, 1)
        self.assertEqual(self.hidden_by_measure(root), [[None, "no"], [None, "no"]])

    def test_a_staff_that_sounds_somewhere_in_the_system_keeps_its_rests(self):
        root, count = self.run_on(two_staff_measure(1, "note", "rest") + two_staff_measure(2, "note", "note"))
        self.assertEqual(count, 0)
        self.assertEqual(self.hidden_by_measure(root), [[None, None], [None, None]])

    def test_systems_are_judged_separately(self):
        measures = (
            two_staff_measure(1, "note", "rest")
            + two_staff_measure(2, "note", "note", new_system=True)
            + two_staff_measure(3, "note", "rest")
        )
        root, count = self.run_on(measures)
        self.assertEqual(count, 1)
        self.assertEqual(self.hidden_by_measure(root), [[None, "no"], [None, None], [None, None]])

    def test_a_system_without_any_music_keeps_its_rests(self):
        root, count = self.run_on(two_staff_measure(1, "rest", "rest"))
        self.assertEqual(count, 0)
        self.assertEqual(self.hidden_by_measure(root), [[None, None]])

    def test_first_system_can_be_kept(self):
        measures = two_staff_measure(1, "note", "rest") + two_staff_measure(2, "note", "rest", new_system=True)
        root, count = self.run_on(measures, keep_first=True)
        self.assertEqual(count, 1)
        self.assertEqual(self.hidden_by_measure(root), [[None, None], [None, "no"]])

    def test_untouched_export_is_returned_verbatim(self):
        source = export("", two_staff_measure(1, "note", "note"))
        self.assertEqual(hide_rests_of_empty_staves(source), (source, 0))


class TestReadHideEmptyStaves(unittest.TestCase):

    def make_mscz(self, directory: Path, style: str) -> Path:
        path = directory / "score.mscz"
        with zipfile.ZipFile(path, "w") as zf:
            zf.writestr("score.mscx", "<museScore/>")
            if style is not None:
                zf.writestr("score_style.mss", f"<museScore><Style>{style}</Style></museScore>")
        return path

    def test_reads_both_settings(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = self.make_mscz(
                Path(tmp), "<hideEmptyStaves>1</hideEmptyStaves><dontHideStavesInFirstSystem>1</dontHideStavesInFirstSystem>"
            )
            self.assertEqual(read_hide_empty_staves(path), (True, True))

    def test_missing_settings_default_to_off(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(read_hide_empty_staves(self.make_mscz(Path(tmp), "<spatium>1.75</spatium>")), (False, False))

    def test_missing_style_file_defaults_to_off(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(read_hide_empty_staves(self.make_mscz(Path(tmp), None)), (False, False))


class TestPromoteFrameHeaders(unittest.TestCase):

    def promote(self, credits, measures, headers):
        xml, count = promote_frame_headers(export(credits, measures), headers)
        return ET.fromstring(xml[xml.index("<score-partwise"):]), count

    def test_no_headers_leaves_the_export_untouched(self):
        source = export(credit("1. formula"), measure(1))
        self.assertEqual(promote_frame_headers(source, []), (source, 0))

    def test_header_becomes_a_direction_on_its_measure(self):
        root, count = self.promote(credit("1. formula"), measure(1), [(1, "1. formula")])
        self.assertEqual(count, 1)
        words = root.find("part/measure/direction/direction-type/words")
        self.assertEqual(words.text, "1. formula")

    def test_direction_is_placed_above(self):
        root, _ = self.promote(credit("1. formula"), measure(1), [(1, "1. formula")])
        self.assertEqual(root.find("part/measure/direction").get("placement"), "above")

    def test_direction_is_pinned_to_the_top_staff(self):
        root, _ = self.promote(credit("1. formula"), measure(1), [(1, "1. formula")])
        self.assertEqual(root.find("part/measure/direction/staff").text, "1")

    def test_the_flattened_credit_is_removed(self):
        root, _ = self.promote(credit("1. formula"), measure(1), [(1, "1. formula")])
        self.assertEqual(root.findall("credit"), [])

    def test_the_title_credit_is_kept(self):
        root, _ = self.promote(
            credit("TITLE", "title") + credit("1. formula"), measure(1), [(1, "1. formula")]
        )
        kept = [c.findtext("credit-words") for c in root.findall("credit")]
        self.assertEqual(kept, ["TITLE"])

    def test_styling_is_carried_over_but_not_the_page_position(self):
        root, _ = self.promote(credit("1. formula"), measure(1), [(1, "1. formula")])
        words = root.find("part/measure/direction/direction-type/words")
        self.assertEqual(words.get("font-weight"), "bold")
        self.assertEqual(words.get("font-size"), "13")
        self.assertIsNone(words.get("default-y"))

    def test_header_without_a_credit_still_gets_a_direction(self):
        root, count = self.promote("", measure(1), [(1, "Recitanta A")])
        self.assertEqual(count, 1)
        words = root.find("part/measure/direction/direction-type/words")
        self.assertEqual((words.text, words.get("font-weight")), ("Recitanta A", "bold"))

    def test_direction_comes_after_print_and_attributes(self):
        preamble = '<print new-system="yes"/><attributes><divisions>1</divisions></attributes>'
        root, _ = self.promote("", measure(1, preamble), [(1, "H")])
        self.assertEqual(
            [child.tag for child in root.find("part/measure")],
            ["print", "attributes", "direction", "note"],
        )

    def test_header_comes_after_the_staff_text_already_on_the_beat(self):
        # OSMD stacks same-beat labels in document order, last on top — the
        # header must end up above the staff text ("C"), not glued to it.
        staff_text = '<direction placement="above"><direction-type><words>C</words></direction-type></direction>'
        root, _ = self.promote("", measure(1, staff_text), [(1, "Prežehnanie")])
        self.assertEqual([w.text for w in root.iter("words")], ["C", "Prežehnanie"])

    def test_staff_text_on_the_beat_is_nudged_by_one_fine_division(self):
        staff_text = (
            '<attributes><divisions>2</divisions></attributes>'
            '<direction placement="above"><direction-type><words>C</words></direction-type>'
            '<staff>1</staff></direction>'
        )
        root, _ = self.promote("", measure(1, staff_text), [(1, "Prežehnanie")])
        nudged, header = root.findall("part/measure/direction")
        self.assertEqual([c.tag for c in nudged], ["direction-type", "offset", "staff"])
        self.assertEqual(nudged.findtext("offset"), "1")
        self.assertIsNone(header.find("offset"))
        self.assertEqual(root.findtext("part/measure/attributes/divisions"), "128")
        self.assertEqual(root.findtext("part/measure/note/duration"), "256")

    def test_existing_offset_of_a_nudged_staff_text_is_scaled_then_bumped(self):
        staff_text = (
            '<direction placement="above"><direction-type><words>C</words></direction-type>'
            '<offset>1</offset><staff>1</staff></direction>'
        )
        root, _ = self.promote("", measure(1, staff_text), [(1, "H")])
        self.assertEqual(root.find("part/measure/direction").findtext("offset"), "65")

    def test_divisions_are_left_alone_when_no_staff_text_shares_the_beat(self):
        root, _ = self.promote("", measure(1, "<attributes><divisions>2</divisions></attributes>"), [(1, "H")])
        self.assertEqual(root.findtext("part/measure/attributes/divisions"), "2")
        self.assertEqual(root.findtext("part/measure/note/duration"), "4")

    def test_header_has_no_offset(self):
        root, _ = self.promote("", measure(1), [(1, "H")])
        direction = root.find("part/measure/direction")
        self.assertEqual([c.tag for c in direction], ["direction-type", "staff"])

    def test_headers_sharing_a_measure_become_one_label_with_a_line_each(self):
        # "1. formula" sits above "Recitanta A" in MuseScore.
        root, count = self.promote("", measure(1), [(1, "1. formula"), (1, "Recitanta A")])
        self.assertEqual(count, 2)
        self.assertEqual([w.text for w in root.iter("words")], ["1. formula\nRecitanta A"])

    def test_shared_label_takes_the_styling_of_the_first_header(self):
        root, _ = self.promote(credit("1. formula"), measure(1), [(1, "1. formula"), (1, "Recitanta A")])
        words = root.find("part/measure/direction/direction-type/words")
        self.assertEqual(words.get("font-size"), "13")

    def test_header_for_a_missing_measure_is_skipped(self):
        root, count = self.promote("", measure(1), [(9, "3. formula")])
        self.assertEqual(count, 0)
        self.assertEqual(root.findall("part/measure/direction"), [])

    def test_the_doctype_is_written_back(self):
        xml, _ = promote_frame_headers(export("", measure(1)), [(1, "H")])
        self.assertTrue(xml.startswith('<?xml version="1.0" encoding="UTF-8"?>'))
        self.assertIn("DOCTYPE score-partwise", xml)

    def test_notes_are_not_lost(self):
        root, _ = self.promote("", measure(1) + measure(2), [(1, "H")])
        self.assertEqual(len(root.findall("part/measure/note")), 2)


if __name__ == "__main__":
    unittest.main()
