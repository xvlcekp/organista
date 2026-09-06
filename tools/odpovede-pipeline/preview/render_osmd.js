// Renders MusicXML files with the app's own OSMD viewer in headless Chrome.
//
// Usage: node render_osmd.js <width-px> <out.png> <file.musicxml> [<out2.png> <file2.musicxml> …]
//
// Loads assets/html/musicXml_display.html (the page the Flutter WebView shows),
// hands it the MusicXML the way the app does and screenshots the sheet. The
// zoom fit and engraving rules are therefore exactly the app's. Requires
// Google Chrome and `npm install` in this directory (puppeteer-core).
const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const VIEWER = path.resolve(__dirname, '..', '..', '..', 'assets', 'html', 'musicXml_display.html');

(async () => {
  const [width, ...pairs] = process.argv.slice(2);
  if (!width || pairs.length < 2 || pairs.length % 2) {
    console.error('Usage: node render_osmd.js <width-px> <out.png> <file.musicxml> [<out.png> <file.musicxml> …]');
    process.exit(2);
  }
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    args: ['--allow-file-access-from-files', '--no-sandbox'],
  });
  for (let i = 0; i < pairs.length; i += 2) {
    const out = pairs[i], xmlPath = pairs[i + 1];
    const page = await browser.newPage();
    const logs = [];
    page.on('console', m => logs.push(m.text()));
    page.on('pageerror', e => logs.push('PAGEERROR ' + e.message));
    await page.setViewport({ width: Number(width), height: 1400, deviceScaleFactor: 1 });
    await page.goto('file://' + VIEWER, { waitUntil: 'load' });
    const xml = fs.readFileSync(xmlPath, 'utf8');
    const info = await page.evaluate(async (xml, w) => {
      document.getElementById('osmdContainer').style.width = w + 'px';
      await loadMusicXmlFile(xml, 'Endless');
      return { zoom: osmd.zoom, systems: countSystems(osmd), title: osmd.Sheet.Title && osmd.Sheet.Title.text };
    }, xml, Number(width));
    await (await page.$('#osmdContainer')).screenshot({ path: out });
    console.log(`${path.basename(xmlPath)} -> ${path.basename(out)} ${JSON.stringify(info)}`);
    const bad = logs.filter(l => /error|warn|PAGEERROR/i.test(l) && !/\[perf\]/.test(l));
    if (bad.length) console.log('   console: ' + bad.slice(0, 8).join(' | ').slice(0, 900));
    await page.close();
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
