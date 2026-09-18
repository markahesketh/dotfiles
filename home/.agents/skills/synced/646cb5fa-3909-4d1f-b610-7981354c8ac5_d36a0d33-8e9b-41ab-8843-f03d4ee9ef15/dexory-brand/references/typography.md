# Typography

Two typefaces, both Google Fonts (so they render natively in Google Slides/Docs and in any
`.pptx`/`.docx` that names them):

- **Inter** — primary. Headlines and body. Weights allowed: **Light, Regular, SemiBold, Bold**
  (nothing else). Always **sentence case**.
- **IBM Plex Mono** — secondary. Eyebrows/labels, section numbers, stats & figures, footers,
  "page architecture". Sentence case **or** UPPERCASE. Weights: Regular, SemiBold, Bold.

Keep it simple: hierarchy comes from **size and weight**, not from colour tricks, italics, or
decoration. Never use ALL CAPS in Inter; never use an Inter weight outside the four allowed.

## Type hierarchy (from the brand guidelines)

| Role | Typeface / weight | Notes |
|---|---|---|
| Main / cover heading | Inter **Light** (large) or **Bold** | Light for big elegant display; Bold for punch. |
| Slide/section title | Inter **Bold** | On content slides. |
| Introductory copy (after a heading) | Inter **Regular** | The lead-in paragraph. |
| Subheading A | Inter **SemiBold** | Sentence case. |
| Subheading B / eyebrow / label | **IBM Plex Mono SemiBold** | Often UPPERCASE, small, letter-spaced. |
| Intro body (emphasised first line) | Inter **SemiBold** | |
| Body copy | Inter **Regular** | Left-aligned, never centered. |
| Bullets | Inter Regular with **blue filled-circle** marker (`5631EA`) | See below. |
| Stats / key figures | **IBM Plex Mono** (Bold), large | Navy on light, lime on dark. |
| Pull quote | Inter, with a quotation-mark glyph above | Navy on light, lime on dark. |
| Footer / page number / captions | **IBM Plex Mono Regular**, small, muted `8A94A6` | |

## Type scale (points, for pptx decks — 13.33"×7.5")

| Element | Font | Weight | Size |
|---|---|---|---|
| Cover title | Inter | Light | 48–56 |
| Section-divider title | Inter | Regular/Light | 40–44 |
| Slide title | Inter | Bold | 30–34 |
| Subheading A | Inter | SemiBold | 18–20 |
| Eyebrow / label / section no. | IBM Plex Mono | SemiBold | 11–12 (UPPERCASE, tracked) |
| Intro copy | Inter | Regular | 18 |
| Body | Inter | Regular | 14–16 |
| Stat number | IBM Plex Mono | Bold | 54–72 |
| Stat caption | Inter | Regular | 11–12 |
| Footer | IBM Plex Mono | Regular | 9 (muted) |

For **documents** (docx, ~11pt base): H1 Inter Bold ~22, H2 Inter SemiBold ~15, H3 / label IBM
Plex Mono SemiBold ~10 UPPERCASE, body Inter Regular ~11, caption Plex Mono ~9. See
`documents.md`.

## Bullets

The brand bullet is a **blue (`5631EA`) filled circle**. In pptxgenjs, set the bullet colour by
giving the paragraph a bullet and colouring the marker, or draw a small blue oval as the marker:

```js
// simplest portable approach: use a real bullet char, blue run colour applies to marker+text,
// so instead colour only the text and place a tiny blue disc, OR accept a blue bullet+text.
{ text: "Real-time inventory visibility", options: {
    bullet: { code: "2022", indent: 18 }, color: "304256",
    fontFace: "Inter", fontSize: 14, paraSpaceAfter: 6 } }
```
If you need the classic navy/charcoal text with a *blue* disc marker, draw a 0.06" blue oval at
the bullet x and left-pad the text — cleaner than fighting the bullet colour.

## Font-family strings & weights

- Name faces as `"Inter"` and `"IBM Plex Mono"` and control emphasis with the **bold** boolean —
  this round-trips reliably into Google Slides (Regular ↔ Bold).
- **Light** and **SemiBold** are intermediate weights .pptx can't express via the bold flag.
  Use the explicit family names `"Inter Light"` / `"Inter SemiBold"` for large display type
  (cover/section titles, big subheads). Desktop PowerPoint with the fonts installed and local QA
  (the installer aliases these) render them true; **Google Slides may fall back to Inter Regular**
  for these two — acceptable for display type. Don't rely on Light/SemiBold for anything where the
  exact weight is load-bearing at small sizes.
- Run `scripts/install_fonts.sh` before image QA so LibreOffice uses the real Inter/Plex Mono and
  your overflow checks are accurate. IBM Plex Mono is monospaced, so its width QA is exact.
