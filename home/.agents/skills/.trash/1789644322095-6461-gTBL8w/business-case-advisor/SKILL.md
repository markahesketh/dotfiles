---
name: business-case-advisor
description: >
  Build a grounded, credible DexoryView business case by combining a site questionnaire,
  live HubSpot deal data (including meeting notes and call context from meeting descriptions),
  the Forrester TEI study, and indicative Dexory pricing. Identifies the strongest benefit areas
  to focus on, flags where TEI assumptions need moderating, and surfaces knowledge gaps that
  must be filled before a robust ROI model can be presented. Use this skill whenever Abby or
  the sales team needs to scope a business case, review a questionnaire response, prioritise
  which benefits to lead with for a specific prospect, identify missing data, or pressure-test TEI
  numbers before sharing with a prospect. Trigger even for partial inputs — e.g. "we've only
  filled in sections 2 and 3", "build a business case for [deal name]", or "what's the most
  important question to ask next?" — the skill should work with whatever data exists.
---

# Business Case Advisor — DexoryView

**Reference files** (read both before starting): `references/tei-benefits.md` — benefit-by-benefit TEI assumptions, moderation flags, questionnaire inputs. `references/questionnaire-map.md` — full question list, Q→benefit mapping, known questionnaire gaps.

---

## Before starting — prompt the user

Before doing anything else, ask the user for the following if not already provided in the conversation:

1. **HubSpot deal link** — ask them to paste the URL of the deal record (e.g. `https://app.hubspot.com/contacts/.../deal/...`). This ensures you pull the right deal, especially if the name is ambiguous.
2. **Site value questionnaire** — ask them to upload the completed or partially completed questionnaire file. Make clear that partial responses are expected and fine.

If both are already present, skip this step and proceed directly. If the user confirms they don't have one or both, acknowledge it and proceed with what's available — never block the analysis on missing inputs.

---

## Input handling

Accept any of: HubSpot deal link + questionnaire (full or partial), deal name only, verbal prospect context, request to pressure-test a specific benefit, or "what questions to ask next?" Always work with what's given — never refuse for incomplete data.

---

## HubSpot data pull

Always run when a deal name or link is provided.

1. **Find deal** via `search_crm_objects` (objectType: deals). Retrieve: dealname, dealstage, amount, closedate, hubspot_owner_id, hs_deal_stage_probability.
2. **Associated company** via `get_crm_objects`. Retrieve: name, industry, annualrevenue, numberofemployees, city, country.
3. **Meetings** — most recent 5–10; retrieve hs_meeting_body, hs_meeting_title, hs_timestamp. Scan notes for: pain points, objections, prospect-stated data (override questionnaire blanks with these — label as "from call notes"), stakeholder dynamics, competitive context, urgency signals.
4. **Contacts** — firstname, lastname, jobtitle, email. Note persona spread.

If HubSpot is sparse, note it and proceed with questionnaire data.

---

## Step 1 — Classify the prospect

**Business model:**
- 3PL/4PL (multi-customer) → Benefit A (stockholding) potentially material
- Single-occupier (owns inventory) → Benefit A largely inapplicable; focus on C, D, G

**Automation maturity:**
- Manual/low → high baseline, most benefits apply
- Partial → lead with gaps current solution doesn't fill
- Well-automated → focus on daily visibility, racking damage, audit; cycle counting benefit weaker

Flag classification at top of output. Ask if unclear.

---

## Step 2 — Score each benefit (A–G)

For each benefit, assess three dimensions:

- **Strength**: HIGH / MEDIUM / LOW / N/A — based on questionnaire data + prospect type
- **Data sufficiency**: COMPLETE (can calculate) / PARTIAL (can estimate; state assumptions) / MISSING (needs follow-up)
- **TEI moderation needed**: YES / NO — with brief reason if YES

Output as a prioritised table, strongest to weakest.

---

## Step 3 — Top 2–3 focus areas

Pick benefits that are HIGH strength + COMPLETE or PARTIAL data + defensible to a finance audience. For each:
- Questionnaire-derived calculation (show working)
- TEI assumption it replaces or validates
- Moderated figure (after haircut)
- One-line prospect-conversation framing

---

## Step 4 — Knowledge gaps

Group as Critical (blocks the business case) / Important (would strengthen it) / Nice-to-have. For each critical gap: specific question to ask + questionnaire section it belongs to (or flag if missing from questionnaire entirely). Also flag any answers that look implausible or inconsistent.

---

## Step 5 — TEI moderation table

| Benefit | TEI Headline | Moderated Estimate | Reason |
|---|---|---|---|
| e.g. Stockholding | $1.1M/3yr | Not applicable | Single-occupier |

Apply to every benefit where TEI assumption doesn't fit this prospect's profile.

---

## Step 6 — Next actions

3–5 concrete next steps: follow-up questions to ask, data to request from prospect's WMS/finance team, benefits to hold until data improves, pricing discussion flag if needed.

---

## Output order

Deal Context (HubSpot) → Prospect Classification → Benefit Priority Table → Top Focus Areas → Knowledge Gaps → TEI Moderation Table → Next Actions

---

## Non-negotiable moderation rules

1. **219% ROI / $2.96M NPV = $2B global 3PL, 3 warehouses, 3 years.** Always rebase to prospect scale.
2. **Benefit A is the largest but most context-dependent.** Remove or reframe for single-occupiers.
3. **Benefit C (cycle counting) is most reliable** — calculate this first; scales directly from Q2.1 + Q2.2.
4. **Never cite the 99.4% employee retention figure** as a financial benefit — narrative only.
5. **TEI was commissioned by Dexory.** Finance audiences may discount it. Use prospect's own numbers wherever possible; TEI is corroboration, not the primary source.
6. **Uncertain baselines → additional 10–20% haircut** on top of TEI's own risk adjustment.
