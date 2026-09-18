---
name: dexory-brand
description: >-
  Dexory's company-wide brand system — colours, type, logo, layouts and graphics. Use WHENEVER
  creating, designing, formatting, or restyling any Dexory deliverable: decks / presentations /
  pitch decks, case studies, business cases, ROI or TEI calculators and models, one-pagers,
  reports, proposals, battlecards, brochures and event collateral — customer-facing OR internal.
  Apply it even when the person never says 'brand', 'Dexory', colours or fonts, and even if they
  only describe the content ('make a deck on our Modex results', 'write up this business case',
  'build an ROI calculator'). If the output is something someone will open, present, send or
  download (.pptx, .docx, .xlsx, PDF, or a designed HTML/interactive artifact), apply this skill
  so it carries Dexory's identity. It composes on top of the pptx, docx, xlsx and frontend-design
  skills and content skills (business-case-advisor, deal-review, gtm-intelligence). Default to
  using it; skip only for plain conversational answers, throwaway notes, or raw exports.
---

# Dexory brand system

This skill makes anything you produce look unmistakably like Dexory. It carries the real brand
assets (Inter + IBM Plex Mono fonts, the DEXORY wordmarks, the shard-pattern graphics) and the
rules for using them, and it plugs into the file-creation skills rather than replacing them.

**Mental model:** the *content* skill (or the person's request) decides **what to say**; the
*file* skill (pptx / docx / xlsx / frontend-design) handles **the file format**; this skill
decides **how it looks and reads as Dexory**. Read all three that apply.

## When this applies

Apply it to any produced artifact — a deck, case study, business case, ROI/TEI model,
one-pager, report, proposal, brochure, data sheet, or designed interactive — whether it's for a
customer or purely internal. Internal work still gets the brand: it keeps everyone fluent in the
system and makes internal decks reusable externally.

It's light-touch or skip-worthy only for: plain conversational answers, throwaway internal notes
(a quick Slack message doesn't need a branded treatment unless it's a designed graphic), and
raw/unstyled data exports where formatting would get in the way. When unsure, apply it.

## Brand at a glance (the non-negotiables)

Even before reading the references, never violate these:

- **Colours** (6-digit hex, no `#` for pptxgenjs): Navy `0B1A48`, Lime `CBFE34`, White `FFFFFF`
  are primary. Blue `5631EA`, Light blue `E9F0F9`, Charcoal `304256` are secondary. **Lime is an
  accent only** — highlights, key figures on dark, CTAs, eyebrow numerals — never body text and
  never large fills of it. Navy is the dominant brand colour.
- **Fonts:** **Inter** is primary (headlines + body). **IBM Plex Mono** is secondary — for
  eyebrows/labels, section numbers, stats/figures, footers, "page architecture". Use only Inter
  Light / Regular / SemiBold / Bold. **Sentence case** for Inter always (never Title Case, never
  ALL CAPS). Plex Mono may be sentence case or UPPERCASE. **Set the typeface on EVERY text run —
  every `addText`, every table cell, every bullet and caption — and set the file's theme font to
  Inter.** Text left unstyled falls back to Arial/Calibri (off-brand); leaving stray default-font
  runs is the single most common failure, so audit for it in QA (see `slides.md`).
- **Copyright:** `© 2026  Dexory. All rights reserved` must appear **bottom-left on every slide**
  in Inter 7pt. White on dark backgrounds; muted (`8A94A6`) on light. Use the
  `addCopyright(slide, variant)` helper defined in `references/slides.md`.
- **Locked elements:** The logo and copyright line must be **non-editable** in the final deck.
  After `pres.writeFile()`, run `scripts/lock_brand_elements.py deck.pptx` — see
  `references/slides.md` for details and the QA check.
- **Logo:** The **Dexory logo must appear in the top-left corner of every slide** — no exceptions.
  Use the **primary wordmark** (`addLogo(s, variant)` helper in `references/slides.md`): navy
  wordmark on light backgrounds; white wordmark on navy/charcoal/photos. Keep clear space (height
  of the "D", squared) around it. Never recolour, stretch, rotate, shadow, or place it on
  busy/similar-toned backgrounds. Files are in `assets/logos/`. The logo is locked
  (non-selectable/non-editable) via `scripts/lock_brand_elements.py` — see Locked elements above.
- **Voice for names:** the company is **Dexory**; the platform is **DexoryView** (one word,
  capital V).
- **Tone of layout:** clean, confident, lots of whitespace, strong size contrast. No AI-slide
  clichés (no accent underlines beneath titles, no edge stripes/colour bars).
- **No footer bar or page numbers:** the only bottom element on any slide is the copyright line
  (bottom-left). Never add page numbers, slide numbers, section labels, or any other text or
  element in the bottom-right corner.

Machine-readable values live in `assets/brand_tokens.json` — read it when generating code so you
copy exact hex/sizes rather than eyeballing.

## Workflow

1. **Identify the deliverable** and pick the output skill + reference:

   | Deliverable | File skill to read | Brand reference to read |
   |---|---|---|
   | Deck / presentation / pitch / cover | `pptx` | `references/slides.md` |
   | Case study, business case, report, one-pager, proposal, brochure | `docx` | `references/documents.md` |
   | ROI / TEI calculator, model, pricing sheet | `xlsx` | `references/spreadsheets.md` |
   | Interactive calculator / web artifact / landing snippet | `frontend-design` | `references/documents.md` + tokens |

   Also read `references/colours.md`, `references/typography.md` and `references/logo.md` — they
   apply to every format. Read `references/graphics.md` when you need the shard pattern or icons.

2. **Read the matching output skill's SKILL.md first** (its file mechanics and gotchas are
   authoritative), then this skill's reference for how to make it Dexory.

3. **Install the brand fonts** before any PDF/image QA of a pptx or docx, so QA renders the real
   fonts instead of substitutes:
   ```bash
   bash <skill-dir>/scripts/install_fonts.sh
   ```
   Inter + IBM Plex Mono are Google Fonts, so a `.pptx`/`.docx` that names them opens correctly in
   Google Slides / Docs; this step only makes local QA accurate.

4. **Build** using the exact tokens and the layout recipes in the reference. Pull backgrounds,
   logos and fonts from `assets/` — don't recreate them.

4a. **Lock brand elements** — after `pres.writeFile()` resolves, run:
    ```bash
    python <skill-dir>/scripts/lock_brand_elements.py deck.pptx
    ```
    This makes the logo and copyright non-selectable and non-editable. Required step.

5. **QA against the brand checklist** at the end of the relevant reference (plus the output
   skill's own QA). Fix, then stop.

## Output & delivery (Google-native)

Always **build** the artifact as `.pptx` / `.docx` / `.xlsx` — that's where precise brand layout
control lives (there is no Google Slides/Docs/Sheets *editing* API available; only Drive
create/copy/read). Then **deliver** it in the form the person wants:

- **Native Google file (Slides/Docs/Sheets):** upload the built file to the person's Drive via the
  Google Drive connector's `create_file` with the Office `contentMimeType` and **conversion left
  on** (the default). It lands as a fully editable Google file — no manual "import" step:
  - `.pptx` → `application/vnd.google-apps.presentation` (Google Slides)
  - `.docx` → `application/vnd.google-apps.document` (Google Docs)
  - `.xlsx` → `application/vnd.google-apps.spreadsheet` (Google Sheets)
  ```
  Google Drive:create_file(
    title="Dexory – <name>",
    base64Content=<base64 of the .pptx/.docx/.xlsx>,
    contentMimeType="application/vnd.openxmlformats-officedocument.presentationml.presentation",
    parentId=<optional folder id>)      # do NOT set disableConversionToGoogleType
  ```
  Then return the resulting Google file link. **Only push to the person's Drive when they've asked
  for a Google file / a link** (it writes to their Drive) — otherwise deliver the file locally.
- **Local file** (`present_files`): when they just want a download, or a `.pptx`/`.docx`/`.xlsx` to
  keep. Fonts are Google Fonts, so a local file still opens on-brand and, if they later drop it in
  Drive, "Open with Google Slides/Docs/Sheets" converts it too.

**Conversion fidelity:** `.docx`→Docs and `.xlsx`→Sheets convert near-losslessly. `.pptx`→Slides
is good but the one to eyeball — keep layouts to text boxes, images and simple shapes (which this
skill's recipes do), avoid exotic grouped/gradient shapes, and the conversion stays clean. If a
person needs guaranteed pixel-perfection they can also just open the `.pptx` in Slides directly.

### Mirroring the master deck

For maximum fidelity on a deck, you can template off the org's real deck (it embeds Inter + IBM
Plex Mono and the true shard art). Thumbnail it, map sections onto its slides, duplicate and fill
via the `pptx` skill's template workflow (unzip → `add_slide.py` → edit slide XML → repack) rather
than building from scratch. Ask the person for the current master `.pptx` if they want this — the
one seen so far is an internal EVP deck, useful as a style reference but not a clean empty template.

## Composing with content skills

- **business-case-advisor / deal-review** → these produce the substance of a business case or
  deal review; wrap their output in this brand system (usually a `.docx` or a deck).
- **gtm-intelligence** → supplies persona-correct messaging and proof points for sales/marketing
  collateral; this skill makes that collateral look right.
- **notion-project-docs** → Notion-flavoured markdown for internal write-ups; brand styling is
  lighter there (Notion controls layout), but keep colour/name conventions and correct product
  naming.

## Assets

```
assets/
  brand_tokens.json          # exact hex, type scale, pairings, logo rules (read when coding)
  fonts/                     # Inter (Light/Regular/SemiBold/Bold) + IBM Plex Mono (Reg/SemiBold/Bold)
  logos/                     # wordmark_{Navy,Lime,White} (2584x575) + SecondaryLogo_{Navy,White} (1080x1600)
  backgrounds/               # shard_cover.png, shard_divider.png, shard_closing.png (1920x1080)
scripts/
  install_fonts.sh           # install fonts + aliases for accurate QA (run once per session)
  make_shard_background.py   # regenerate shard backgrounds at any size/variant
  lock_brand_elements.py     # post-process a .pptx to lock logo + copyright on every slide
references/
  colours.md  typography.md  logo.md  slides.md  documents.md  spreadsheets.md  graphics.md
```

Both the primary wordmark and the secondary badge/monogram lockup are bundled (navy + white for
the badge; navy/lime/white for the wordmark). Never recreate either mark or place them side by
side. See `references/logo.md`.
