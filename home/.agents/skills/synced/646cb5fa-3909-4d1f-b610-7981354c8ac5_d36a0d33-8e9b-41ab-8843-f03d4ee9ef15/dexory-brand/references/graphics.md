# Brand graphics (shard pattern + iconography)

## Shard pattern

Dexory's signature graphic: a navy base with translucent blue/navy leaning parallelogram
"shards" and a soft blue glow. It gives covers, section dividers and closings their identity.

- **Pre-made backgrounds** (1920×1080, 16:9 → 13.33"×7.5") in `assets/backgrounds/`:
  `shard_cover.png`, `shard_divider.png`, `shard_closing.png`. Use these directly as slide/page
  backgrounds.
- **Regenerate** at any size/variant:
  ```bash
  python3 scripts/make_shard_background.py out.png --variant cover|divider|closing --size 2560x1440
  ```
- **Usage:** bold and sophisticated, not busy. Keep it to covers/dividers/closings and the
  occasional accent panel — content pages stay clean white. Ensure the wordmark/title sits on a
  clear part (avoid the bright glow area for text).
- **Fidelity note:** these are a faithful *approximation* generated for internal work and drafts.
  The brand guidelines ask that flagship customer-facing shard artwork be produced/approved by
  marketing (marketing@dexory.com) — prefer official art for high-stakes external covers if
  available.

## Iconography

- Style: **navy stroke on a lime-fill circle** — simple line icons, consistent stroke weight.
- Prefer official Dexory icons when available (Efficiency, Logistics, Warehouses, Scan, Increase,
  Revenue, Team, Future-proof, etc. — see the guidelines). When not available, approximate with
  line-style icons kept to the navy-on-lime treatment.

### Building an icon-in-circle for a deck (pptxgenjs)

```js
// 1) render a line-style react-icon to an SVG with a navy stroke, no fill
const ReactDOMServer = require("react-dom/server");
const React = require("react");
const { FiEye } = require("react-icons/fi");
const svg = ReactDOMServer.renderToStaticMarkup(
  React.createElement(FiEye, { color: "#0B1A48", strokeWidth: 2, size: 256 })
);
// 2) rasterize with sharp at >=256px -> PNG buffer (see pptx skill)
// 3) place a LIME circle, then the icon centred on it
slide.addShape(pres.ShapeType.ellipse, { x:1, y:1, w:0.9, h:0.9, fill:{ color:"CBFE34" } });
slide.addImage({ data:"image/png;base64,"+buf.toString("base64"),
                 x:1.18, y:1.18, w:0.54, h:0.54 }); // icon ~60% of circle, centred
```
Keep the icon comfortably inside the circle (~55–65% of diameter). Navy stroke on lime gives the
right contrast; don't invert (no lime icon on navy circle for the standard icon set).

## Photography (approved, bundled)

Real, brand-approved Dexory photos are bundled in `assets/photography/` — **use these, not stock
or generated imagery.** See `assets/photography/MANIFEST.md` for the full categorised list (hero
robot-in-warehouse, product/tower detail, people/build, craft/engineering, event) with exact
filenames and dimensions.

Placement rules:
- Show the robot and DexoryView **together** with authentic human interaction where possible;
  keep it sophisticated and focused.
- **Always crop-fill to the box's aspect ratio — never stretch.** The reliable, renderer-proof
  method (works the same in PowerPoint, Google Slides and LibreOffice) is to **pre-crop** each
  photo to the exact aspect ratio of its box, then place it with plain `w`/`h`:
  ```python
  # Python (PIL) — cover-crop centered to the box's pixel size (inches × ~150 ppi)
  from PIL import Image, ImageOps
  im = ImageOps.fit(Image.open(src).convert("RGB"), (px_w, px_h), Image.LANCZOS, centering=(0.5,0.5))
  im.save(out, "JPEG", quality=86)
  ```
  ```js
  slide.addImage({ path: croppedOut, x, y, w: box_w_in, h: box_h_in }); // plain w/h, no sizing
  ```
  **Do NOT pass both top-level `w`/`h` and `sizing:{type:"cover",...}` to addImage** — they
  conflict and pptxgenjs stretches the image to the box. Pre-cropping avoids the whole problem.
  (sharp's `resize(w,h,{fit:"cover"})` works too if you're already in Node.)
  A ready helper is bundled: `python scripts/crop_to_box.py SRC OUT WIDTH_IN HEIGHT_IN`.
  In docx, size the `ImageRun` to preserve the source aspect ratio (docx can't crop, so pick a
  width and set height = width × srcH/srcW — or pre-crop with PIL as above and place at the box size).
- White text over a photo needs a **navy scrim** for legibility — a full-cover `rect` with
  `fill:{color:"0B1A48", transparency:30–55}` over the image, then text on top. Never put text
  over a busy/bright region without a scrim.
- Prefer the higher-res `GN*` (2400px) and `Photography-0X` (4966px) for full-bleed fills; the
  `L27A*` robot heroes (~900–1500px) are fine on-screen, a little soft for full-bleed print.
