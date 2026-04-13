"""Tests for pipeline.py — step 4: lyricist credit → <creator type="lyricist">"""
import unittest
import xml.etree.ElementTree as ET

from pipeline import (
    _musicxml_header,
    _strip_xml_preamble,
    extract_lyricist_from_credits,
    insert_lyricist_as_creator,
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
