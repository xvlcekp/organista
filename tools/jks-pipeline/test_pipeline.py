"""Tests for pipeline.py"""
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

from pipeline import (
    _musicxml_header,
    _strip_xml_preamble,
    extract_lyricist_from_credits,
    extract_svg_text_from_mscz,
    insert_lyricist_as_creator,
    jks_output_stem,
)


class TestJksOutputStem(unittest.TestCase):

    def test_plain_number_strips_leading_zeros(self):
        self.assertEqual(
            jks_output_stem("A včera z večera (JKS036) – Pavlín Bajan"),
            "36. A včera z večera – Pavlín Bajan",
        )

    def test_letter_suffix_preserved(self):
        self.assertEqual(
            jks_output_stem("Matka plače, ruky spína (JKS150a) – František Otto Matzenauer"),
            "150a. Matka plače, ruky spína – František Otto Matzenauer",
        )

    def test_letter_suffix_b(self):
        self.assertEqual(
            jks_output_stem("Matka plače, ruky spína (JKS150b) – Mikuláš Schneider Trnavský"),
            "150b. Matka plače, ruky spína – Mikuláš Schneider Trnavský",
        )

    def test_letter_suffix_later_in_alphabet(self):
        self.assertEqual(
            jks_output_stem("Tantum ergo (JKS536e) – Mikuláš Schneider Trnavský"),
            "536e. Tantum ergo – Mikuláš Schneider Trnavský",
        )

    def test_uppercase_letter_suffix_normalised_to_lowercase(self):
        self.assertEqual(
            jks_output_stem("Song title (JKS100A) – Author"),
            "100a. Song title – Author",
        )

    def test_no_jks_tag_returns_original(self):
        self.assertEqual(
            jks_output_stem("Some title without tag"),
            "Some title without tag",
        )


def _wrap(body: str) -> str:
    """Minimal valid score-partwise document wrapping body XML."""
    return (
        _musicxml_header()
        + '<score-partwise version="3.1">'
        + body
        + "</score-partwise>"
    )


def _parse(musicxml_str: str) -> ET.Element:
    return ET.fromstring(_strip_xml_preamble(musicxml_str).encode("utf-8"))


class TestExtractLyricistFromCredits(unittest.TestCase):

    def test_single_credit_single_words(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            '<credit-words justify="left">J. Potocký:</credit-words>'
            "</credit>"
        )
        self.assertEqual(extract_lyricist_from_credits(xml), "J. Potocký:")

    def test_single_credit_multiple_words(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            '<credit-words justify="left" valign="bottom">J. Potocký:</credit-words>'
            '<credit-words font-style="italic">Kancionál Katolícky</credit-words>'
            '<credit-words font-style="normal">Rukopisná sbierka,</credit-words>'
            "<credit-words>z r. 1790–1813, str. 368</credit-words>"
            "</credit>"
        )
        expected = "J. Potocký:\nKancionál Katolícky\nRukopisná sbierka,\nz r. 1790–1813, str. 368"
        self.assertEqual(extract_lyricist_from_credits(xml), expected)

    def test_no_lyricist_credit_returns_none(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>composer</credit-type>"
            "<credit-words>Someone</credit-words>"
            "</credit>"
        )
        self.assertIsNone(extract_lyricist_from_credits(xml))

    def test_no_credits_returns_none(self):
        self.assertIsNone(extract_lyricist_from_credits(_wrap("")))

    def test_multiple_lyricist_credits_concatenated(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            "<credit-words>First source</credit-words>"
            "</credit>"
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            "<credit-words>Second source</credit-words>"
            "</credit>"
        )
        self.assertEqual(
            extract_lyricist_from_credits(xml), "First source\nSecond source"
        )

    def test_ignores_non_lyricist_credit(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>composer</credit-type>"
            "<credit-words>Ignored</credit-words>"
            "</credit>"
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            "<credit-words>Kept</credit-words>"
            "</credit>"
        )
        self.assertEqual(extract_lyricist_from_credits(xml), "Kept")

    def test_empty_credit_words_skipped(self):
        xml = _wrap(
            '<credit page="1">'
            "<credit-type>lyricist</credit-type>"
            "<credit-words></credit-words>"
            "<credit-words>Real line</credit-words>"
            "</credit>"
        )
        self.assertEqual(extract_lyricist_from_credits(xml), "Real line")

    def test_malformed_xml_returns_none(self):
        self.assertIsNone(extract_lyricist_from_credits("not xml at all"))


class TestInsertLyricistAsCreator(unittest.TestCase):

    def _creator(self, result: str) -> ET.Element:
        root = _parse(result)
        identification = root.find("identification")
        self.assertIsNotNone(identification)
        creator = identification.find("creator")
        self.assertIsNotNone(creator)
        return creator

    def test_inserts_creator_into_existing_identification(self):
        xml = _wrap("<identification><encoding /></identification>")
        result = insert_lyricist_as_creator(xml, "J. Potocký:\nKancionál")
        creator = self._creator(result)
        self.assertEqual(creator.get("type"), "lyricist")
        self.assertEqual(creator.text, "J. Potocký:\nKancionál")

    def test_creates_identification_when_missing(self):
        xml = _wrap("")
        result = insert_lyricist_as_creator(xml, "Someone")
        creator = self._creator(result)
        self.assertEqual(creator.get("type"), "lyricist")
        self.assertEqual(creator.text, "Someone")

    def test_replaces_existing_lyricist_creator(self):
        xml = _wrap(
            '<identification>'
            '<creator type="lyricist">Old value</creator>'
            "</identification>"
        )
        result = insert_lyricist_as_creator(xml, "New value")
        root = _parse(result)
        creators = root.find("identification").findall("creator")
        lyricists = [c for c in creators if c.get("type") == "lyricist"]
        self.assertEqual(len(lyricists), 1)
        self.assertEqual(lyricists[0].text, "New value")

    def test_preserves_other_creator_types(self):
        xml = _wrap(
            '<identification>'
            '<creator type="composer">Bach</creator>'
            "</identification>"
        )
        result = insert_lyricist_as_creator(xml, "Someone")
        root = _parse(result)
        creators = root.find("identification").findall("creator")
        types = {c.get("type") for c in creators}
        self.assertIn("composer", types)
        self.assertIn("lyricist", types)

    def test_output_starts_with_xml_declaration(self):
        xml = _wrap("")
        result = insert_lyricist_as_creator(xml, "x")
        self.assertTrue(result.startswith('<?xml version="1.0"'))

    def test_multiline_text_preserved(self):
        text = "Line 1\nLine 2\nLine 3"
        xml = _wrap("")
        result = insert_lyricist_as_creator(xml, text)
        creator = self._creator(result)
        self.assertEqual(creator.text, text)

    def test_malformed_xml_returns_unchanged(self):
        bad = "not xml"
        result = insert_lyricist_as_creator(bad, "x")
        self.assertEqual(result, bad)


class TestExtractSvgTextFromMscz(unittest.TestCase):
    """
    MuseScore writes line breaks inside aria-label two different ways —
    a literal LF, or a &#10; character reference — sometimes in the same
    archive.  Both must yield one entry per line.
    """

    def _mscz(self, *svg_bodies: str) -> Path:
        """Build a .mscz archive containing one SVG per body and return its path."""
        tmp_dir = tempfile.mkdtemp()
        self.addCleanup(lambda: [p.unlink() for p in Path(tmp_dir).iterdir()])
        path = Path(tmp_dir) / "test.mscz"
        with zipfile.ZipFile(path, "w") as zf:
            for i, body in enumerate(svg_bodies):
                zf.writestr(f"Pictures/{i}.svg", body)
        return path

    @staticmethod
    def _svg(aria_label: str) -> str:
        return f'<svg xmlns="http://www.w3.org/2000/svg"><g aria-label="{aria_label}"/></svg>'

    def test_char_reference_separators_are_split(self):
        mscz = self._mscz(self._svg("Ako dcéra Stvoriteľa &#10;Matkou budeš Spasiteľa &#10;a nevestou Tešiteľa. "))
        self.assertEqual(
            extract_svg_text_from_mscz(mscz),
            ["Ako dcéra Stvoriteľa", "Matkou budeš Spasiteľa", "a nevestou Tešiteľa."],
        )

    def test_hex_char_reference_separators_are_split(self):
        mscz = self._mscz(self._svg("prvý riadok&#xA;druhý riadok"))
        self.assertEqual(extract_svg_text_from_mscz(mscz), ["prvý riadok", "druhý riadok"])

    def test_literal_newline_separators_still_split(self):
        mscz = self._mscz(self._svg("Kam sa mám obrátiť? \nmôj vlastný učeník \nTí ma nájdu "))
        self.assertEqual(
            extract_svg_text_from_mscz(mscz),
            ["Kam sa mám obrátiť?", "môj vlastný učeník", "Tí ma nájdu"],
        )

    def test_mixed_forms_in_one_archive(self):
        mscz = self._mscz(
            self._svg("Čo stanica prvá &#10;tu vyobrazuje?"),
            self._svg("Kam sa mám obrátiť? \nJudáš ma už zrádza,"),
        )
        self.assertEqual(
            extract_svg_text_from_mscz(mscz),
            ["Čo stanica prvá", "tu vyobrazuje?", "Kam sa mám obrátiť?", "Judáš ma už zrádza,"],
        )

    def test_escaped_ampersand_decoded_to_single_character(self):
        mscz = self._mscz(self._svg("Peter &amp; Pavol"))
        self.assertEqual(extract_svg_text_from_mscz(mscz), ["Peter & Pavol"])

    def test_archive_without_svg_returns_empty(self):
        mscz = self._mscz()
        self.assertEqual(extract_svg_text_from_mscz(mscz), [])

    def test_corrupt_archive_returns_empty(self):
        tmp_dir = tempfile.mkdtemp()
        path = Path(tmp_dir) / "broken.mscz"
        path.write_text("this is not a zip archive", encoding="utf-8")
        self.addCleanup(path.unlink)
        self.assertEqual(extract_svg_text_from_mscz(path), [])


class TestRoundTrip(unittest.TestCase):
    """extract → insert round-trip using the example from the task description."""

    EXAMPLE_CREDIT = (
        '<credit page="1">'
        "<credit-type>lyricist</credit-type>"
        '<credit-words justify="left" valign="bottom">J. Potocký:</credit-words>'
        '<credit-words font-style="italic">Kancionál Katolícky AFB aadwawadww</credit-words>'
        '<credit-words font-style="normal">Rukopisná sbierka z V. Bobrovca,</credit-words>'
        "<credit-words>z r. 1790–1813, str. 368</credit-words>"
        "</credit>"
    )

    def test_full_round_trip(self):
        xml = _wrap(self.EXAMPLE_CREDIT)
        lyricist = extract_lyricist_from_credits(xml)
        self.assertIsNotNone(lyricist)
        result = insert_lyricist_as_creator(xml, lyricist)
        root = _parse(result)
        creator = root.find("identification").find("creator")
        self.assertEqual(creator.get("type"), "lyricist")
        lines = creator.text.split("\n")
        self.assertEqual(lines[0], "J. Potocký:")
        self.assertEqual(lines[1], "Kancionál Katolícky AFB aadwawadww")
        self.assertEqual(lines[2], "Rukopisná sbierka z V. Bobrovca,")
        self.assertEqual(lines[3], "z r. 1790–1813, str. 368")


if __name__ == "__main__":
    unittest.main()
