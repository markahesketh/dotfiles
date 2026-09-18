# Spreadsheets (ROI / TEI calculators, models, pricing sheets)

Read the **`xlsx` skill SKILL.md first**. Excel/Sheets can't use Inter/IBM Plex Mono unless
installed locally, and cell fonts are less portable than in decks/docs, so treat brand here as
**colour + structure + restraint**, with fonts as a nicety.

## Fonts

- Set cell fonts to **Inter** (body/labels) and **IBM Plex Mono** for figures/inputs where you
  can — they render in Google Sheets (both are available) and in Excel if installed. Provide a
  clean fallback by not relying on exact widths.
- If you want guaranteed portability in desktop Excel offline, Calibri/Arial is an acceptable
  fallback — but prefer Inter, since the target is usually Google Sheets.

## Type scale & row height (keep it proportionate)

A common complaint is a title that dwarfs the body. Keep the jump small and set row heights so
cells aren't cramped:

| Element | Size |
|---|---|
| Title (band) | 16 (not 20+) |
| Section header | 11 bold |
| Labels / input values / results | 11 |
| Answer/highlight cells | 11 bold (mono) |
| Notes / captions | 9 (muted) |

Set explicit **row heights** (~20pt for data rows, ~22pt for the title band) — openpyxl's default
(~15pt) looks squished under 11–16pt text. **Size the label column to fit the longest label** (or
shorten wordy labels) — Excel/Sheets clips text in a cell when the next cell is non-empty, so
clipped labels (e.g. "…DexoryVie", "(% of inventory") are the most common sheet complaint. Widen
value columns enough for the largest formatted number (e.g. `$8,000,000`).

## Colour system (hex with `#` in xlsx)

| Use | Colour |
|---|---|
| Header rows / section bands | Navy `#0B1A48` fill, white text |
| Sub-headers | Charcoal `#304256` fill, white text |
| Input cells (user-editable) | Light-blue `#E9F0F9` fill, navy text — make inputs obviously distinct |
| Output / result highlight | Lime `#CBFE34` fill, navy text — for the headline ROI/payback cell(s) only |
| Body cells | White, charcoal text `#304256` |
| Banding | Alternate rows light-blue `#E9F0F9` |
| Gridlines / borders | Light `#E9F0F9`; avoid heavy black grids |

**Lime discipline still applies:** reserve lime fills for the one or two "answer" cells (total
ROI, payback period, net benefit), not for whole columns.

## Structure for a calculator

1. **Title band** (row 1–2): navy fill, white Inter title + Plex Mono eyebrow ("ROI CALCULATOR").
2. **Inputs block:** clearly labelled, light-blue input cells, units noted, data-validation where
   sensible. Group assumptions together.
3. **Calculations:** hidden or a separate clearly-marked area; never mix inputs and formulas
   ambiguously.
4. **Results band:** the headline figures in a navy/charcoal band with the key output cell in a
   lime highlight; format currency/percentages properly.
5. **Notes:** Plex Mono, muted `#8A94A6` — assumptions, sources, "indicative vs confirmed".

## Charts

Palette `#0B1A48, #5631EA, #CBFE34, #304256`. Navy for the main series, lime for the series to
emphasise. Clean axes, no chartjunk, titled.

## Brand QA checklist

- [ ] Navy header bands, white body, light-blue input cells, **lime only on the answer cell(s)**.
- [ ] Inputs visually distinct from calculations and outputs.
- [ ] Numbers formatted (currency, %, thousands); figure cells legible.
- [ ] Title band present with correct product naming (Dexory / DexoryView).
- [ ] No heavy black gridlines; banding subtle.
