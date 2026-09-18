# Logo

Files (transparent PNG) in `assets/logos/`:

Primary **wordmark** (2584×575, ~4.49:1) — use first, always:
- `Dexory_wordmark_Navy_RGB.png`
- `Dexory_wordmark_Lime_RGB.png`
- `Dexory_wordmark_White_RGB.png`

Secondary **badge/monogram** lockup (1080×1600, ~0.675:1 — the D-mark above "DEXORY") — only for
space-constrained contexts (e.g. a small square avatar, a back cover, a favicon-like corner):
- `Dexory_SecondaryLogo_Navy_RGB.png`
- `Dexory_SecondaryLogo_White_RGB.png`

No lime secondary is provided. The primary and secondary marks must **never appear side by side**,
but may both appear in one document with ample separation (e.g. primary on the cover, secondary on
the back). Never recreate either mark.

## Which colour where

| Background | Wordmark |
|---|---|
| White / light | **Navy** |
| Navy / charcoal / photography | **White** |
| Dark surface, as a deliberate accent (sparingly) | **Lime** |

Choose contrast first: the logo must be clearly legible. On busy or mid-toned photos, put the
white wordmark on a clear/darkened area, or don't place it over the image at all.

## Placement rules

- **Clear space** = the height of the "D" in the wordmark, squared, on every side. Keep all other
  elements (text, images, shards, page edges) out of that zone.
- **Minimum size:** 45px wide on screen (25mm print). Don't go smaller.
- **The Dexory logo must appear in the top-left corner of every slide — cover, section dividers,
  content slides, stat slides, quote slides, and closing slides alike.** This is non-negotiable.
  - On **dark/navy/photo backgrounds** (cover, dividers, closing): use the **white** wordmark.
  - On **light/white backgrounds** (content, stat-on-white): use the **navy** wordmark.
  - Recommended position: `x: 0.6, y: 0.5` (aspect-locked). Adjust `y` slightly if a shard
    background element would reduce contrast, but keep it visually top-left.
  - **Two sizes — use these consistently:**
    - **Cover slide only:** `w: 2.0"` — pass `isCover=true` to the `addLogo` helper.
    - **All other slides** (section dividers, content, stat, quote, closing top-left): `w: 1.4"` —
      the default `addLogo(s, variant)` call with no third argument.
- The closing slide may additionally centre the wordmark as a hero element — this is the one slide
  where a second, larger logo placement is acceptable alongside the top-left instance.

## Never (from "Incorrect usage")

1. Recolour beyond navy / lime / white.
2. Stretch, warp, skew, or rotate.
3. Add a drop shadow or any effect.
4. Place on busy or darkened imagery, or on a similar-toned background (e.g. navy wordmark on
   charcoal).
5. Let graphics or text overlap it or enter its clear space.
6. Remove or rearrange elements, or re-typeset "DEXORY" in a font.
7. Show the primary and secondary logos side by side. (They can appear in the same document —
   e.g. primary on the cover, secondary on the back — with ample separation.)

## Placing the logo in pptxgenjs

The PNGs are transparent, so they sit on any background. Preserve aspect ratio (w:h = 2584:575 ≈
4.49). Example — white wordmark top-left of a navy cover, ~2" wide:

```js
// Cover slide (isCover=true in addLogo helper):
const LOGO_W_COVER = 2.0, LOGO_H_COVER = LOGO_W_COVER * 575 / 2584; // ≈ 0.445"
slide.addImage({ path: "assets/logos/Dexory_wordmark_White_RGB.png",
                 x: 0.6, y: 0.5, w: LOGO_W_COVER, h: LOGO_H_COVER });

// All other slides (default addLogo call):
const LOGO_W_CONTENT = 1.4, LOGO_H_CONTENT = LOGO_W_CONTENT * 575 / 2584; // ≈ 0.311"
slide.addImage({ path: "assets/logos/Dexory_wordmark_Navy_RGB.png",
                 x: 0.6, y: 0.5, w: LOGO_W_CONTENT, h: LOGO_H_CONTENT });
```
Keep `x`/`y` ≥ ~0.5" so the clear space clears the slide edge. Never set only `w` or only `h`
with a mismatched counterpart (distorts the mark).

Secondary badge aspect ratio is **1080:1600 ≈ 0.675** (taller than wide):
`const H = 1.2, W = H * 1080/1600; // ≈ 0.81"`. Use white badge on dark, navy badge on light.
