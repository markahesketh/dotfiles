---
name: deal-review
description: >
  Pull a live deal from HubSpot and produce a structured Dexory deal review covering an exec summary,
  next steps, hidden risks, and deal acceleration ideas. Use this skill whenever Abby mentions reviewing
  a deal, checking on a pipeline opportunity, preparing for a deal call or QBR, or asks anything like
  "what should I do with this deal", "review this opportunity", "what are the risks on X", or
  "how can I accelerate Y". Trigger even if the request is brief — e.g. "review Maersk" or
  "what's the status on the IKEA deal". Always fetch live data from HubSpot rather than relying
  on memory.
---

# Deal Review Skill

## Before starting — prompt the user

If a HubSpot deal URL has not been provided, ask for it before proceeding (e.g. `https://app.hubspot.com/contacts/.../deal/...`). This avoids ambiguous name matches. If the user doesn't have it, proceed with the deal or company name they've given.

---

## Step 1 — Fetch from HubSpot

Search by deal URL, deal name, or company name. If ambiguous, show matches and ask. Note if deal is closed.

Retrieve: deal properties (stage, amount, close date, deal type, owner, create date, last modified), ALL contacts on **this deal** (not company-level), company properties (industry, employees/sites, country), last 10 engagements (notes, emails, activity).

---

## Step 2 — Build the review

**Exec Summary** — 3–5 sentences: what the deal is, pipeline position, headline risk/opportunity, single most important action.

**Next Steps** — 3–5 items: specific (what, with whom, why), grounded in stage/activity/close date. Flag if no activity in >14 days.

**Risks** — surface issues the user may not have flagged:

*Structural:*
- **Single-threading**: one contact = dominant loss pattern; flag strongly
- **Missing Warehouse Ops + Innovation/Automation**: strongest winning combo; flag absence
- **C-level only**: 0% win rate; needs operational champion beneath
- **Finance/Procurement absent late-stage**: 50% win rate when engaged; absence = commercial process gap
- **No champion**: flag if no contact appears to be actively sponsoring

*Commercial:*
- **OPEX/CAPEX friction**: HaaS model vs CAPEX-oriented procurement — often surfaces as "pricing" objection
- **Small site ROI**: single small site = weak ROI case
- **Competitive exposure**: flag any mention of Corvus Robotics or other AMR/drone vendors
- **Deal age**: flag if stage duration is unusually long

*Data quality:*
- Missing amount, close date, or deal type → affects forecast
- No activity + no contacts + no amount → likely ghost/non-opportunity

**Acceleration Ideas** — 3–5 actions:
- **Multi-thread**: suggest Warehouse Ops Manager, Head of Innovation/Automation, Finance/Procurement; offer to draft outreach
- **Champion activation**: business case material, ROI model, vertical reference customers
- **Proof of value**: site visit, live demo, or reference call if pre-pilot/pre-proposal
- **Commercial clarity**: reframe HaaS for finance if OPEX/CAPEX friction likely
- **Urgency**: implementation queue, contract timing, competitive pressure
- **Expansion**: multi-site angle if applicable — increases ACV and stickiness

**Contacts & Coverage** — table: Name | Title | Persona (Warehouse Ops / Innovation & Automation / Finance & Procurement / C-Suite / IT / Other) | Engagement (active/passive/unknown). Follow with coverage assessment: present vs missing personas, single vs multi-threaded, recommended persona types to add.

---

## Dexory context

**Model**: HaaS — autonomous inventory robots on subscription. Value: accuracy, labour reduction, real-time visibility.

**ICP (stronger)**: multi-site operators, high SKU/complex inventory, 3PLs, e-commerce fulfilment, empowered Innovation/Automation function.
**ICP (weaker)**: single small site, rigid CAPEX procurement, C-level-only, SDR-sourced new business (~3x lower close rate than expansion).

**Win/loss**: 17% overall. Finance & Procurement 50%. C-level only 0%. Single-threaded = strong loss signal. Best combo: Innovation/Automation + Warehouse Ops. ~30% of closed-lost mislabelled (ghosts, OPEX/CAPEX friction as pricing, Corvus losses as fit).

**Deployment**: 90-day target post-signature; meaningful proportion delayed. Revenue recognised at go-live, not signature.

---

## Output

**Output order:** Deal Review header (name, stage, amount) → Summary → Next Steps → Risks → Acceleration Ideas → Contacts & Coverage table + assessment.

---

## Edge cases

- **No contacts**: flag loudly (data + risk issue); produce review from company data
- **Deal not found**: say so, offer company name search or open deals list
- **Closed-won**: pivot to deployment risk, expansion opportunity, relationship health
- **Closed-lost**: brief post-mortem — likely loss drivers from data, re-open potential
