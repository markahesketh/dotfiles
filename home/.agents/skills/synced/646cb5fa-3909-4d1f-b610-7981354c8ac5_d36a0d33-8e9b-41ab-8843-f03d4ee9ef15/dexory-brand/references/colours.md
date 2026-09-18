# Colours

Hex is 6-digit. For **pptxgenjs** use it **without `#`** (e.g. `"0B1A48"`); a `#` or 8-digit
alpha corrupts the file. For docx/xlsx/CSS add the `#`.

## Palette

| Name | Hex | Tier | Use for |
|---|---|---|---|
| Navy | `0B1A48` | primary | The dominant brand colour. Dark backgrounds, headings on light, primary text. |
| Lime | `CBFE34` | primary | **Accent only.** Key figures on dark, eyebrow numerals, CTAs, small highlights. |
| White | `FFFFFF` | primary | Content backgrounds; text/logo on dark. |
| Blue | `5631EA` | secondary | Shard graphics & gradients, bullet fills, occasional heading accent on light. |
| Light blue | `E9F0F9` | secondary | Subtle section tints, table row banding, avatar/photo placeholders, body text on dark. |
| Charcoal | `304256` | secondary | Alternate dark surface; muted body text on light; footer text. |

`8A94A6` is a derived muted grey for footers/captions/section numbers on light (matches the
guidelines' footer grey). It's a utility tint, not a brand colour — use only for that purpose.

## How to use colour

- **Dominance, not equality.** Navy carries ~60–70% of the visual weight. White is the canvas.
  Lime is a spark — a little goes a long way. Blue and charcoal are supporting players.
- **Lime discipline.** Never set body copy in lime, never fill large areas with it, never put
  lime type on white (fails contrast). Lime shines as a stat/number on navy, a CTA button, a
  divider numeral, a single highlighted word.
- **Backgrounds.** Content slides/pages are white. Covers, section dividers and closings are navy
  (shard pattern). Charcoal is an occasional alternate dark surface (e.g. a callout band).
- **Colour to modulate personality:** brighter (more blue/lime) for marketing and top-of-funnel;
  calmer (navy/white/charcoal) for exec, finance and business-case contexts.

## Contrast pairings (safe, accessible)

| Surface | Heading | Body | Accent |
|---|---|---|---|
| White `FFFFFF` | Navy `0B1A48` | Charcoal `304256` | Blue `5631EA` |
| Navy `0B1A48` | White `FFFFFF` | Light blue `E9F0F9` | Lime `CBFE34` |
| Charcoal `304256` | White `FFFFFF` | Light blue `E9F0F9` | Lime `CBFE34` |
| Light blue `E9F0F9` (tint block) | Navy `0B1A48` | Charcoal `304256` | Blue `5631EA` |

**Stats/key figures:** navy number on light, **lime** number on dark. Captions in charcoal
(light) or light-blue (dark).

## Don'ts

- No colours outside this palette (no stock "corporate blue", no greens other than lime).
- No lime text on white; no navy text on charcoal (too low contrast).
- No gradients as flat fills in decks — pptxgenjs can't gradient-fill shapes; use the shard
  background image instead (see `graphics.md`).
