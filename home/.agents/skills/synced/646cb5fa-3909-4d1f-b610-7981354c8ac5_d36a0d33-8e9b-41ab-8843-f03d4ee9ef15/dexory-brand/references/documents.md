# Documents (case studies, business cases, reports, one-pagers)

Read the **`docx` skill SKILL.md first** for the mechanics. This file adds the Dexory styling.
Use `#`-prefixed hex in docx/CSS (e.g. `#0B1A48`). Fonts: Inter (body + headings), IBM Plex Mono
(labels/eyebrows/figures/footers). Both are Google Fonts, so the file renders correctly in Google
Docs; embed them in the .docx if it will be opened in desktop Word offline.

## Page system

- **Cover:** navy shard background (`assets/backgrounds/shard_cover.png`) as a full-bleed cover
  image, white wordmark, Inter Light title, Plex Mono eyebrow (doc type / date / client). For a
  one-pager the "cover" is a navy header band instead of a full page.
- **Body pages:** white. Generous margins (≥ 2.0 cm). Navy headings, charcoal body, blue accents.
- **Back/closing:** contact block (`marketing@dexory.com`, `Dexory.com` in lime on navy) or a
  simple navy footer band.

## Type styles

| Style | Font | Weight | Size (11pt base) | Colour |
|---|---|---|---|---|
| Title (cover) | Inter | Light | 30–36 | White (on navy) |
| H1 | Inter | Bold | 20–22 | Navy `#0B1A48` |
| H2 | Inter | SemiBold | 14–15 | Navy `#0B1A48` |
| Eyebrow / label / H3 | IBM Plex Mono | SemiBold | 9–10, UPPERCASE, tracked | Charcoal `#304256` or Blue `#5631EA` |
| Intro / lead paragraph | Inter | SemiBold | 12 | Charcoal `#304256` |
| Body | Inter | Regular | 11 | Charcoal `#304256` |
| Bullets | Inter | Regular | 11 | Charcoal, **blue disc marker** `#5631EA` |
| Stat / key figure | IBM Plex Mono | Bold | 28–40 | Navy on light / Lime on dark |
| Caption / footer / page no. | IBM Plex Mono | Regular | 8–9 | Muted `#8A94A6` |
| Quote | Inter | Regular italic-free | 14–16 | Navy, with a large blue/lime `"` glyph above |

Headings and body in **sentence case**. No underlined headings, no coloured rule lines under
headings (an AI/Word default to remove).

**Give it air (avoid congestion — the #1 complaint after Google Docs conversion).** Set body
**line spacing to 1.2–1.3** (docx-js `spacing:{ line: 288–312, lineRule: "auto" }`), **≥9pt after**
each paragraph, **≥16pt before** each heading, and generous cell margins in tables/callouts. Keep
page margins ≥ 2 cm. Single-spaced, tightly-stacked paragraphs read cramped once in Google Docs.

**Bullets need a hanging indent** or wrapped lines fall back to the far-left margin and look
ragged. In docx-js set `indent:{ left: 360, hanging: 250 }` on each bullet paragraph (bullet sits
left, text at ~0.25", wrapped lines align under the text), and keep the disc marker ~7pt
(`size: 14`) so it's proportionate to 11pt body — not oversized.

## Photography

Use the approved photos in `assets/photography/` (see its `MANIFEST.md`) for case studies,
brochures and reports — a hero robot shot as a full-width banner near the top, product/people
photos inline (two side-by-side in a borderless table reads well), each with a small Plex Mono
muted caption. docx can't crop, so preserve each image's aspect ratio: pick a width in px and set
height = width × srcH/srcW. See `graphics.md`.

## Layout devices

- **Callout / highlight box:** light-blue `#E9F0F9` fill, navy heading, charcoal text. Use for
  "Key result", "At a glance", assumptions. No single-side accent borders.
- **Stat band:** a navy or charcoal full-width band with 2–4 Plex Mono figures in lime and
  light-blue captions — ideal atop a case study or business case.
- **Tables:** navy header row (white Plex Mono SemiBold labels), white body, optional light-blue
  `#E9F0F9` banding on alternate rows. Thin `#E9F0F9` gridlines, not heavy black.
- **Icons:** navy stroke on a lime circle (see `graphics.md`), sized to the text.

## Business-case / ROI documents

When wrapping `business-case-advisor` output: lead with a navy stat band of the headline
numbers, then a light-blue "Assumptions" callout, then body sections. Keep TEI/ROI figures in
Plex Mono. Note where numbers are indicative vs. client-confirmed (the advisor skill flags this).

## Brand QA checklist

Install fonts, export to PDF (`docx` skill's converter) and check:
- [ ] Palette only; lime accent-only; navy headings, charcoal body.
- [ ] Inter body/headings sentence case; Plex Mono labels/figures/footer.
- [ ] Wordmark correct colour for its background + clear space; product names correct.
- [ ] Callouts use light-blue fill (no edge stripes); tables use navy header + light-blue banding.
- [ ] Margins generous; no orphaned headings; figures in Plex Mono.
