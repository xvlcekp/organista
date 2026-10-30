#!/usr/bin/env python3
"""Compose App Store / Google Play screenshots from raw emulator captures.

    python3 tools/store-screenshots/compose.py            # all targets
    python3 tools/store-screenshots/compose.py --target google-play/phone

Reads docs/screenshots/raw/{android,ipad}/<shot>.png and tools/store-screenshots/captions.json,
writes docs/screenshots/store/<target>/NN-<shot>.png. Both stores get the same shots, captions
and styling; only the canvas size differs. Phone targets use the Android captures, tablet targets
the iPad captures. The OS status bar and the Android gesture bar are cropped away so the panels
are identical on both stores.
"""
import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "docs/screenshots/raw"
OUT = ROOT / "docs/screenshots/store"
CAPTIONS = Path(__file__).with_name("captions.json")

# (canvas width, canvas height, raw capture source). Sizes are the stores' exact requirements:
# App Store: "iPhone with Dynamic Island (medium display)" 1206x2622 (6.3") is the required iPhone
# slot since late 2026, iPad 13" 2064x2752 the required iPad slot; the 6.9" set 1320x2868 is
# optional (only needed if you add it in Media Manager).
# Google Play: 16:9..9:16 and no side longer than twice the other; 1080x1920 is required for
# featuring; 7"/10" tablets at 1200x1920 and 1600x2560.
TARGETS = {
    "app-store/iphone-6.3": (1206, 2622, "android"),
    "app-store/iphone-6.9": (1320, 2868, "android"),
    "app-store/ipad-13": (2064, 2752, "ipad"),
    "google-play/phone": (1080, 1920, "android"),
    "google-play/tablet-7": (1200, 1920, "ipad"),
    "google-play/tablet-10": (1600, 2560, "ipad"),
}

# Pixels to cut from the raw captures: Android status bar + gesture bar (24 dp at 420 dpi),
# iPad status bar (24 pt @2x). The simulator only lays the status bar out after the app has
# shown a full-screen viewer once, so capture.txt opens a sheet before any other screenshot.
CROP = {"android": (63, 63), "ipad": (48, 0)}

FONT = "/System/Library/Fonts/HelveticaNeue.ttc"  # macOS system font, ttc face indexes below
FONT_BOLD_INDEX, FONT_REGULAR_INDEX = 1, 0

BG_TOP, BG_BOTTOM = (23, 52, 92), (54, 97, 142)  # app primary blue (FAB colour) and a darker shade
TITLE_COLOR, SUBTITLE_COLOR = (255, 255, 255), (205, 220, 238)


def load_raw(source: str, shot: str, fullscreen: bool) -> Image.Image:
    path = RAW / source / f"{shot}.png"
    if not path.exists():
        sys.exit(f"missing raw capture {path}")
    im = Image.open(path).convert("RGB")
    if fullscreen:  # the viewer hides the OS bars itself
        return im
    top, bottom = CROP[source]
    return im.crop((0, top, im.width, im.height - bottom))


def gradient(w: int, h: int) -> Image.Image:
    im = Image.new("RGB", (w, h))
    px = im.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px_row = tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM))
        for x in range(w):
            px[x, y] = px_row
    return im


def wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for word in words:
        cand = f"{cur} {word}".strip()
        if draw.textlength(cand, font=font) <= max_w or not cur:
            cur = cand
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def rounded_panel(shot: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width - 1, shot.height - 1), radius=radius, fill=255)
    panel = shot.copy()
    panel.putalpha(mask)
    return panel


def compose(canvas_w: int, canvas_h: int, shot: Image.Image, title: str, subtitle: str) -> Image.Image:
    unit = canvas_w / 1080  # scale every metric with the canvas width
    margin = round(80 * unit)
    title_font = ImageFont.truetype(FONT, round(66 * unit), index=FONT_BOLD_INDEX)
    sub_font = ImageFont.truetype(FONT, round(38 * unit), index=FONT_REGULAR_INDEX)

    canvas = gradient(canvas_w, canvas_h)
    draw = ImageDraw.Draw(canvas)
    y = round(110 * unit)
    for line in wrap(draw, title, title_font, canvas_w - 2 * margin):
        draw.text((canvas_w / 2, y), line, font=title_font, fill=TITLE_COLOR, anchor="ma")
        y += round(80 * unit)
    y += round(10 * unit)
    for line in wrap(draw, subtitle, sub_font, canvas_w - 2 * margin):
        draw.text((canvas_w / 2, y), line, font=sub_font, fill=SUBTITLE_COLOR, anchor="ma")
        y += round(50 * unit)
    caption_bottom = y + round(50 * unit)

    # Fit the whole screenshot into the space below the caption, centred.
    avail_w, avail_h = canvas_w - 2 * margin, canvas_h - caption_bottom - margin
    scale = min(avail_w / shot.width, avail_h / shot.height)
    size = (round(shot.width * scale), round(shot.height * scale))
    panel = rounded_panel(shot.resize(size, Image.LANCZOS), radius=round(36 * unit))
    x = (canvas_w - size[0]) // 2
    py = caption_bottom + (avail_h - size[1]) // 2

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, py + round(18 * unit), x + size[0], py + size[1] + round(18 * unit)),
        radius=round(36 * unit), fill=(0, 0, 0, 110),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(28 * unit)))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)
    canvas.alpha_composite(panel, (x, py))
    return canvas.convert("RGB")  # stores reject alpha channels


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", choices=sorted(TARGETS), action="append", help="default: all")
    args = parser.parse_args()
    shots = json.loads(CAPTIONS.read_text())["shots"]
    for target in args.target or sorted(TARGETS):
        w, h, source = TARGETS[target]
        out_dir = OUT / target
        out_dir.mkdir(parents=True, exist_ok=True)
        for n, item in enumerate(shots, start=1):
            raw = load_raw(source, item["shot"], item.get("fullscreen", False))
            image = compose(w, h, raw, item["title"], item["subtitle"])
            path = out_dir / f"{n:02d}-{item['shot']}.png"
            image.save(path, optimize=True)
            print(f"{path.relative_to(ROOT)}  {image.width}x{image.height}")


if __name__ == "__main__":
    main()
