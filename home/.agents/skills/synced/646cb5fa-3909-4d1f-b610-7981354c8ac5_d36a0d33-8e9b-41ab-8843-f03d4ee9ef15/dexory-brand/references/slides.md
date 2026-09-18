# Slides (on-brand decks)

Read the **`pptx` skill SKILL.md first** for the pptxgenjs mechanics and gotchas. This file adds
the Dexory layout system. Target canvas: **`pres.layout = "LAYOUT_WIDE"`** (13.33"×7.5"). Colours
are 6-digit hex **without `#`**. Pull exact values from `assets/brand_tokens.json`.

## Deck structure ("sandwich")

Dark cover → (dark section dividers) → light content slides → dark closing. Navy shard backgrounds
bookend a clean white body. Don't make every slide dark, and don't make every slide the same
layout — vary content slides (two-column, stat row, quote, grid).

## Shared setup

```js
const pptx = require("pptxgenjs");
const pres = new pptx();
pres.layout = "LAYOUT_WIDE";           // 13.33 x 7.5
const NAVY="0B1A48", LIME="CBFE34", WHITE="FFFFFF", BLUE="5631EA",
      LIGHTBLUE="E9F0F9", CHARCOAL="304256", MUTED="8A94A6";
const A = "assets"; // skill assets dir (copy assets next to your generator, or use abs paths)

// ── Logo helper ──────────────────────────────────────────────────────────────
// The Dexory logo MUST appear top-left on EVERY slide.
// Call addLogo(slide, "white") on dark backgrounds; addLogo(slide, "navy") on light backgrounds.
// Use isCover=true only on the cover slide (and closing hero if applicable) — it uses the
// full 2.0" width. All other slides (section dividers, content, stat, quote) use the smaller
// 1.4" width so the logo doesn't compete with slide content.
const LOGO_W_COVER = 2.0,  LOGO_H_COVER = LOGO_W_COVER * 575 / 2584;  // ≈ 0.445" — cover only
const LOGO_W_CONTENT = 1.4, LOGO_H_CONTENT = LOGO_W_CONTENT * 575 / 2584; // ≈ 0.311" — all other slides
function addLogo(slide, variant = "white", isCover = false) {
  const file = variant === "navy"
    ? `${A}/logos/Dexory_wordmark_Navy_RGB.png`
    : `${A}/logos/Dexory_wordmark_White_RGB.png`;
  const w = isCover ? LOGO_W_COVER : LOGO_W_CONTENT;
  const h = isCover ? LOGO_H_COVER : LOGO_H_CONTENT;
  slide.addImage({ path: file, x: 0.6, y: 0.5, w, h });
}

// ── Copyright helper ──────────────────────────────────────────────────────────
// "© 2026  Dexory. All rights reserved" must appear bottom-left on EVERY slide.
// Use the white variant on dark backgrounds (cover, dividers, stat-on-navy, closing);
// use the muted (8A94A6) variant on light/white backgrounds.
function addCopyright(slide, variant = "muted") {
  const color = variant === "white" ? "FFFFFF" : "8A94A6";
  slide.addText("© 2026  Dexory. All rights reserved", {
    x: 0.6, y: 7.1, w: 6, h: 0.25,
    fontFace: "Inter", fontSize: 7, color, margin: 0
  });
}
```

Assets you'll reference: `${A}/backgrounds/shard_cover.png`, `shard_divider.png`,
`shard_closing.png`; `${A}/logos/Dexory_wordmark_White_RGB.png` (and Navy/Lime);
`${A}/photography/*` (approved photos — see `graphics.md`).

## Locking the logo and copyright (required)

The logo and copyright line must be **non-editable and non-selectable** in the final deck — presenters and collaborators should never be able to accidentally move, resize, or delete them.

After `pres.writeFile(...)` resolves, run the lock script as a mandatory post-processing step:

```bash
python <skill-dir>/scripts/lock_brand_elements.py deck.pptx
# modifies in place; or supply a second arg for a separate output:
python <skill-dir>/scripts/lock_brand_elements.py deck.pptx deck_final.pptx
```

**How it works:** the script walks every slide's XML and injects OOXML shape-lock attributes (`<a:spLocks>` / `<a:picLocks>`) onto the copyright text shape (identified by the literal string "Dexory. All rights reserved") and the logo image (identified by the `wordmark` substring in its path/descr, or by its known x-offset of 0.6"). All other shapes on every slide are untouched.

Locks applied:
- **Copyright text** — `noSelect`, `noMove`, `noResize`, `noRot`, `noEditPoints`, `noAdjustHandles`, `noChangeArrowheads`, `noChangeShapeType`
- **Logo image** — `noSelect`, `noMove`, `noResize`, `noRot`, `noChangeAspect`

Run `python <pptx-skill>/scripts/office/validate.py deck.pptx` after locking to confirm the file is still valid.

Two pptxgenjs gotchas that bite here: the rectangle shape key is **`p.ShapeType.rect`** (not
`rectangle` — `rectangle` is `undefined` and throws). For a photo scrim, a `rect` with
`fill:{color:"0B1A48", transparency:35}` over a full-cover image gives legible white text.

### Fonts & fit on real content (do not skip — these are the two commonest real-run failures)

- **Every run needs a `fontFace`.** Set it on every `addText`, and on `addTable` (pass table-level
  `fontFace:"Inter"` **and** set it per styled cell). pptxgenjs does not default to Inter, so any
  run you forget renders Arial/Calibri — off-brand. Also set the deck theme/default font to Inter.
- **Leave slack and let text shrink.** Recipes here are drawn with short demo text; real titles,
  bullets and stats are longer. Size prose boxes with ~15–20% extra height, keep slide titles
  ≤ ~8 words, and set `autoFit:true` (or `shrinkText:true`) on paragraph boxes so long content
  shrinks instead of silently overflowing. pptxgenjs defaults to *no* autofit.

## 1. Cover slide

Navy shard background · white wordmark top-left · large Inter Light title in white · lime IBM
Plex Mono eyebrow (date / doc type).

```js
let s = pres.addSlide();
s.background = { path: `${A}/backgrounds/shard_cover.png` };
addLogo(s, "white", true); // isCover=true → full 2.0" width on the cover
addCopyright(s, "white");  // bottom-left, white on dark background
s.addText("OCTOBER 2024", { x:0.65, y:5.0, w:8, h:0.3, fontFace:"IBM Plex Mono",
  fontSize:12, color:LIME, charSpacing:2, margin:0 });
s.addText("Transform the logistics industry with real-time data intelligence",
  { x:0.6, y:2.4, w:8.6, h:2.4, fontFace:"Inter", fontSize:44, color:WHITE,
    lineSpacingMultiple:1.02, valign:"top", margin:0 });
```
Sentence case title. Keep the title clear of the bright glow (upper-right) — left/centre reads
best on this background. Use **Inter Regular or Bold** for the cover title: the master deck does
not embed Inter Light, so a `"Inter Light"` face may fall back to Regular in Google Slides. Only
reach for Light when you specifically want the airy display look and a Regular fallback is fine.

## 2. Section divider

Shard divider background · centred lime Plex Mono number with a short lime rule under it · large
white Inter title.

```js
let s = pres.addSlide();
s.background = { path:`${A}/backgrounds/shard_divider.png` };
addLogo(s, "white"); // smaller 1.4" logo on non-cover slides
addCopyright(s, "white");
s.addText("02", { x:0, y:2.5, w:13.33, h:0.6, align:"center", fontFace:"IBM Plex Mono",
  fontSize:20, color:LIME, margin:0 });
s.addShape(pres.ShapeType.line, { x:6.42, y:3.15, w:0.5, h:0, line:{ color:LIME, width:1.5 } });
s.addText("Colours", { x:0, y:3.3, w:13.33, h:1.0, align:"center", fontFace:"Inter",
  fontSize:40, bold:true, color:WHITE, margin:0 });
```

## 3. Content slide (standard)

White background · left rail = Plex Mono section number + Inter Bold title · right = content.
**No underline under the title, no edge stripes. No footer bar — no page numbers, no section
labels, no right-side text at the bottom of any slide.**

```js
let s = pres.addSlide();                         // white by default
addLogo(s, "navy"); // smaller 1.4" logo on non-cover slides
addCopyright(s);   // muted (default) on white background
// Section number starts at y:1.1 to clear the logo (logo occupies y:0.5–0.95 approx)
s.addText("2.1", { x:0.6, y:1.1, w:3.2, h:0.3, fontFace:"IBM Plex Mono", fontSize:14,
  color:MUTED, margin:0 });
s.addText("Real-time inventory visibility", { x:0.6, y:1.5, w:3.4, h:2.2, fontFace:"Inter",
  fontSize:30, bold:true, color:NAVY, valign:"top", margin:0 });
// right column content:
s.addText("DexoryView gives your team full control over inventory, improving warehouse space "
  +"and staff efficiency.", { x:4.4, y:1.0, w:8.3, h:1.2, fontFace:"Inter", fontSize:18,
  color:CHARCOAL, valign:"top", margin:0 });
```

Bullets (blue disc marker, charcoal text):
```js
const items = ["Cut inventory checks from days to hours","No infrastructure changes",
  "Live to value in under a week"];
items.forEach((t,i)=>{
  const y = 2.5 + i*0.5;
  s.addShape(pres.ShapeType.ellipse,{ x:4.4, y:y+0.07, w:0.09, h:0.09, fill:{color:BLUE} });
  s.addText(t,{ x:4.62, y:y, w:8.1, h:0.4, fontFace:"Inter", fontSize:14, color:CHARCOAL, margin:0 });
});
```

## 4. Stat / key-figure slide

Big IBM Plex Mono numbers. On white → navy numbers, charcoal captions. On navy → **lime**
numbers, light-blue captions. Great for results decks (event pipeline, ROI headlines).

```js
let s = pres.addSlide();
s.background = { color:NAVY };
addLogo(s, "white"); // smaller 1.4" logo on non-cover slides
addCopyright(s, "white");
const stats = [["$2.05M","Net-new pipeline, Modex"],["16","Deals sourced"],["99.9%","Scan accuracy"]];
stats.forEach(([n,c],i)=>{
  const x = 0.8 + i*4.1;
  s.addText(n,{ x, y:2.4, w:3.8, h:1.2, fontFace:"IBM Plex Mono", bold:true, fontSize:60,
    color:LIME, margin:0 });
  s.addText(c,{ x, y:3.7, w:3.8, h:0.8, fontFace:"Inter", fontSize:14, color:LIGHTBLUE, margin:0 });
});
```

## 5. Pull-quote slide

Quotation glyph above the quote (navy on light / lime on dark), Inter text, attribution in Plex
Mono.

```js
addLogo(s, "navy"); // smaller 1.4" logo on non-cover slides
addCopyright(s);    // muted on white
let s = pres.addSlide();
s.addText("“",{ x:0.9, y:1.4, w:2, h:1.6, fontFace:"Inter", fontSize:120, bold:true, color:BLUE, margin:0 });
s.addText("We had real-time visibility of the whole site in under a week.",
  { x:1.0, y:3.0, w:11.3, h:2.0, fontFace:"Inter", fontSize:32, color:NAVY, valign:"top", margin:0 });
s.addText("HEAD OF OPERATIONS · GLOBAL 3PL",{ x:1.0, y:5.2, w:11, h:0.4, fontFace:"IBM Plex Mono",
  fontSize:12, color:MUTED, charSpacing:2, margin:0 });
```

## 6. Closing slide

Shard-closing background · white wordmark top-left (required) + larger centred hero wordmark · contact in Plex Mono · `Dexory.com`
in lime.

```js
let s = pres.addSlide();
s.background = { path:`${A}/backgrounds/shard_closing.png` };
addLogo(s, "white"); // smaller 1.4" logo top-left; the hero centred wordmark below is separate
addCopyright(s, "white");
// Additional centred hero wordmark (closing slide only):
const LW=2.6, LH=LW*575/2584;
s.addImage({ path:`${A}/logos/Dexory_wordmark_White_RGB.png`, x:(13.33-LW)/2, y:0.7, w:LW, h:LH });
s.addText("Let's talk", { x:0, y:2.9, w:13.33, h:0.9, align:"center", fontFace:"Inter",
  fontSize:40, color:WHITE, margin:0 });
s.addText("marketing@dexory.com", { x:0, y:4.0, w:13.33, h:0.4, align:"center",
  fontFace:"IBM Plex Mono", fontSize:16, color:LIGHTBLUE, margin:0 });
s.addText("Dexory.com", { x:0, y:6.7, w:13.33, h:0.4, align:"center", fontFace:"IBM Plex Mono",
  fontSize:12, color:LIME, margin:0 });
```

## Photo layouts (use approved photography)

Real photos are in `assets/photography/` (see its `MANIFEST.md`). High-impact photo slides:
- **Split cover** — navy `rect` on the left ~42% (opaque), a hero robot photo cover-cropped on the
  right; white wordmark + Inter title on the navy block. Cleaner and more legible than text-on-photo.
- **Half-bleed** — photo cover-cropped down one side (~45%), content on the white side.
- **Stat / title over photo** — full-bleed photo + a navy scrim `rect`
  (`fill:{color:"0B1A48",transparency:35–50}`) + lime stats / white title on top.
- **Product trio** — three cover-cropped tower/camera close-ups above a 3-step "how it works".
- **2×2 grid** — four cover-cropped photos (mix people/product/craft) for a team/engineering slide.

Always **pre-crop** each photo to its box's exact aspect ratio (PIL `ImageOps.fit` or sharp
`fit:"cover"`) and place it with plain `w`/`h`. **Never pass both `w`/`h` and `sizing:{type:"cover"}`
to addImage — they conflict and stretch the image.** See `graphics.md` for the crop snippet, plus
scrim and resolution guidance.

## Charts

Use native `addChart()`. Chart palette from the brand: `chartColors: ["0B1A48","5631EA","CBFE34","304256","8A94A6"]`
(navy first, then blue, lime for the one series you want to pop). Quiet the frame: muted axis
labels (`8A94A6`), light `valGridLine`, `catGridLine:{style:"none"}`, `showLegend:false` for a
single series, `showTitle:true`. Follow the pptx skill's chart gotchas exactly.

## Icons

Per brand, icons are **navy stroke on a lime circle**. Render a line-style react-icon to
navy-stroke SVG, rasterize with sharp, and place it on a lime `ellipse`. See `graphics.md`.

## Brand QA checklist (in addition to the pptx skill's QA)

Run `bash scripts/install_fonts.sh` first, then render to images and check:

- [ ] Only palette colours used; **lime is accent-only** (no lime body text, no lime on white).
- [ ] Navy dominates; white body slides; dark cover/divider/closing (sandwich).
- [ ] Inter for headings/body/copyright, **sentence case**; IBM Plex Mono for eyebrows/numbers/stats.
- [ ] **No footer bar, no page numbers, no right-side bottom text on any slide.** The only bottom element is the copyright line (bottom-left). Do not add slide numbers, section labels, or any other text in the bottom-right corner.
- [ ] **Font audit — no off-brand fonts anywhere:**
      `unzip -p deck.pptx 'ppt/slides/slide*.xml' | grep -o 'typeface="[^"]*"' | sort | uniq -c`
      must list ONLY Inter / Inter SemiBold / IBM Plex Mono / IBM Plex Mono SemiBold. Any Arial,
      Calibri, or missing typeface means a run was left unstyled — fix it in the generator.
- [ ] **No overflow with real content** (test with the actual copy, not placeholders): titles,
      bullets and stats fit their boxes; long text shrinks or the box was sized with slack.
- [ ] Stat numbers in Plex Mono; navy on light / lime on dark.
- [ ] Bullets use the blue disc marker.
- [ ] **Wordmark present top-left on every slide** — cover, dividers, content, stat, quote, and
      closing slides all have `addLogo(s, ...)` called. White wordmark on dark backgrounds; navy
      wordmark on light backgrounds. No slide may be missing it.
- [ ] **Logo sizing:** cover slide uses `addLogo(s, variant, true)` → 2.0" wide. All other slides
      use the default `addLogo(s, variant)` → 1.4" wide. Never use the full 2.0" on content slides.
- [ ] **Copyright line present bottom-left on every slide** — `addCopyright(s)` called on every
      slide. White (`"white"`) on dark backgrounds; muted default (`"8A94A6"`) on light backgrounds.
      Text reads exactly: `© 2026  Dexory. All rights reserved`
- [ ] Wordmark: right colour for its background, correct aspect ratio, clear space respected, not
      on a busy/similar-toned area.
- [ ] **No underlines under titles, no edge stripes / colour bars** (AI-slide tells).
- [ ] Product names correct: Dexory / DexoryView.
- [ ] No text overflow/clipping; ≥0.5" margins; left-aligned body.
- [ ] **Logo and copyright are locked** — `lock_brand_elements.py` was run after `writeFile`.
      Verify: `unzip -p deck.pptx 'ppt/slides/slide1.xml' | grep -c 'noSelect'` should return ≥ 2.
- [ ] `python <pptx-skill>/scripts/office/validate.py deck.pptx` passes.
