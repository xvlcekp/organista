# Odpovede pipeline

Converts the Slovak Mass responses ("Odpovede", MuseScore 4 files) to MusicXML
that renders in the app's OSMD viewer the way the scores look in MuseScore.

## Files

| File | Role |
|------|------|
| `pipeline.py` | The conversion. Three steps per `.mscz`: drop the silent staff, export with the MuseScore 4 CLI, post-process the MusicXML for OSMD. Run without arguments it converts every `.mscz` in `ODPOVEDE_DIR`. |
| `preview/render_osmd.js` | Verification harness. Renders a MusicXML file with the app's own viewer (`assets/html/musicXml_display.html`, OSMD 2.1.2) in headless Chrome and saves a PNG, so the output can be compared with MuseScore's PNG export. |
| `test_pipeline.py` | Unit tests (`python3 -m unittest test_pipeline`). |
| `output/` | Generated MusicXML, gitignored. |

## What was run (2026-09-06)

The sources live outside the repo in `~/Documents/Personal/Odpovede/Odpovede na
konverziu/`: one `.mscz` per response, 85 files. The pipeline converts them all:

```bash
rm -rf output
python3 pipeline.py                      # every .mscz in ODPOVEDE_DIR
python3 pipeline.py "…/Some file.mscz"   # or just the given files
```

The MuseScore 4 CLI (4.7.4) is flaky: it aborts at start-up every few runs and
sometimes after it has already written the export; the pipeline retries and
keeps a written export. Six scores have measures MuseScore flags as corrupted
and are exported with `--force`.

## Checking the result against MuseScore

Reference rendering straight from MuseScore:

```bash
"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -f -r 100 -o ref.png "…/Some file.mscz"
```

The app's rendering of the converted file (needs Google Chrome and `npm install`
in `preview/` once, which fetches `puppeteer-core`):

```bash
cd preview && npm install
node render_osmd.js 900 out.png "../output/Some file.musicxml"
```

The OSMD behaviours the post-processing works around were established this way
and are listed at the top of `pipeline.py`. Re-check them with this harness
before changing the pipeline or upgrading OSMD.
