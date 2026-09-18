---
name: gtm-intelligence
description: Dexory's warehouse GTM intelligence — buyer and user personas, jobs-to-be-done, vertical positioning, buyer insights, objections, lifecycle plays, proof points and customer references. Use this skill WHENEVER producing any go-to-market or sales/marketing content for Dexory, even if the personas are not explicitly mentioned. That includes writing or reviewing outbound email and LinkedIn sequences, cold outreach, nurture and lifecycle campaigns, battlecards, discovery-call questions, call and meeting prep, demo narratives, one-pagers, landing-page or ad copy, value propositions, vertical or persona-specific messaging, objection handling, ROI and business-case framing, and competitive positioning versus manual counting and drones. Also use it for any persona research question (what an Inventory Manager cares about, who signs off, which KPIs matter) and whenever tailoring a message to a warehouse role, buying centre, vertical, or funnel stage.
---

# Dexory GTM Intelligence

This skill is the canonical reference for Dexory's go-to-market intelligence: who buys and uses the product, what they care about, how to message to them by role / vertical / funnel stage, and what proof to bring. Use it to ground all derivative GTM work so messaging stays consistent, specific, and credible rather than generic.

Source: *Warehouse Persona Template* (April 2026) + HubSpot data-driven buyer personas and won/lost journey analysis. All written content is human-validated. Note on confidence: `persona/`, `jtbd/`, `icp/`, `insight/` and `proof/`/`client/` are lifted from the source material; `objection/`, `alternative/`, `signal/` and `global/` are *synthesised* across the source's journey and messaging layers rather than taken from a single section — treat their framing as interpretation, not verbatim source.

## Core framing (read this first — it governs everything below)

- **What Dexory is:** autonomous mobile robots that perform daily wall-to-wall warehouse scans, plus a software platform (a real-time "digital twin" of locations, exceptions and actions). Two module families: **Integrity** (inventory accuracy, exception-based cycle counting, ~99.9% accuracy) and **Optimise** (space/flow — slotting, weight restrictions, congestion, outbound optimiser, consolidation).
- **ICP = operators, not vendors.** The buyer *operates* large physical warehouse space (20,000m²+): 3PLs, retailers, manufacturers. It is NOT companies that sell equipment/software to warehouses. Keep this distinction when targeting or writing.
- **Two persona lenses — don't confuse them:**
  - **Operational / user personas** (`persona/operations-manager`, `inventory-manager`, `inbound-outbound-manager`, `warehouse-supervisor`) = how the product is lived day-to-day. Best for value props, discovery questions, demo narratives, and pain-led hooks.
  - **Buyer / marketing personas** (`persona/buyer-personas`) = the buying centres that appear in deals (Supply Chain/Inventory, Innovation/IT, Finance/Procurement, Executive/Director, Quality/Safety). Best for targeting, sequencing, and tailoring the *business* case.
- **Headline proof to reach for:** Forrester TEI — **219% ROI, <6-month payback**; ~99.9% accuracy; deployment in 1–2 weeks. Use role/vertical-specific numbers from `proof/` and `client/` rather than these defaults wherever possible.

## How this is organised (mirrors the Cargo context taxonomy)

Read only the file(s) relevant to the task. Each folder corresponds 1:1 to a Cargo context folder.

| Folder | What's in it | Reach for it when… |
|---|---|---|
| `persona/` | 4 operational personas (one file each) + `buyer-personas.md` (5 buying centres) | Anchoring any message, value prop, discovery, or call prep to a role |
| `jtbd/` | Jobs-to-be-done + needs models per operational persona | Building "I want… because… but…" hooks; product/feature value framing |
| `icp/` | 6 vertical playbooks (challenge → solution → features → proof) | Tailoring to 3PL, Retail/eFulfilment, F&B, Pharma/Beauty, Automotive/Mfg, Air cargo |
| `insight/` | Data-driven buyer insights (titles, pains, feature interest) | Targeting, list-building criteria, knowing what each buyer reacts to |
| `objection/` | Common objections + responses (from won/lost analysis) | Handling pushback; pre-empting risk in proposals |
| `play/` | Lifecycle plays & hooks across the funnel (awareness→expansion) | Writing nurture/sequence content matched to funnel stage |
| `proof/` | Aggregate proof: ROI ranges, Forrester TEI, awards, stage-mapped proof | Choosing the right stat/credibility marker for the moment |
| `client/` | Named customer references and their results | Citing a concrete logo + outcome relevant to the prospect |
| `alternative/` | Positioning vs manual counting and drones | Competitive displacement, "why not just X" objections |
| `medium/` | Collateral inventory by funnel stage | Recommending which asset to send/attach next |
| `signal/` | Buying signals — who initiates, when each buyer joins, won/lost correlates | Multithreading guidance, deal-stage diagnostics |
| `global/` | One-page company positioning synthesis | Quick top-of-message framing, boilerplate |

## Working rules for derivative content

1. **Lead with the persona's own pain and KPI, not the product.** Every operational persona file lists primary KPIs and pain points with impact — open there.
2. **Match message to funnel stage.** Operational pain + quick wins early (Manager initiates ~80% of SQLs); integration/scale for IT at proposal; ROI for Finance; resilience/sponsorship for Execs before contracting. See `signal/` and `play/`.
3. **Be specific with proof.** Prefer a named customer outcome (`client/`) or a vertical stat (`icp/`) over a generic figure. Don't invent numbers — if a fact isn't in these files, say so.
4. **Multithread.** Won deals correlate with Director-level sponsorship (~65%) and C-suite involvement (~70%); lost deals lacked exec buy-in or unproven ROI. Flag single-threaded deals.
5. **Stay in the operator frame.** If a draft reads like it's selling to a tech vendor rather than a warehouse operator, fix it.

When a task spans several lenses (e.g. "write a sequence to an Inventory Manager at a 3PL"), read the relevant `persona/`, `icp/`, and `play/` files together and synthesise.

## Output conventions (apply to every derivative output)

Format follows the artifact, but these hold across all of them:

- **Cold email:** ~50–90 words, one idea, one CTA. Subject line lowercase and specific to their pain, not salesy ("your morning blocked-inventory check", not "Revolutionise your warehouse with AI"). Open on the recipient's pain/KPI; mention Dexory only after the problem lands.
- **Sequence:** 4–6 touches that each take a *different* angle (operational pain → named proof → a second persona/teammate → short break-up). Don't reuse the same stat twice in one sequence.
- **LinkedIn / DM:** shorter and lighter than email, no subject, conversational; a connection note is ~1–2 sentences.
- **Battlecard / one-pager / exec summary:** structured and proof-dense; this is where board-level stats (219% ROI, ~99.9%) belong.
- **Match proof to stage, not just persona.** Discovery → lead with an operational quick-win from a *named, vertical-matched* customer (e.g. Yusen for a 3PL). ROI stage → lead with financial proof (Nidec, Forrester TEI). Don't open a first-touch to an operational persona with 219% ROI — that's a board-level number aimed at the wrong reader at the wrong stage.
- **When no customer matches both vertical and stage, stage wins — don't stretch.** Some verticals have no named customer tagged at the stage you need (e.g. automotive/manufacturing has GE Appliances and Stellantis, but both are tagged Contracting/ROI, not Discovery). In that case prefer the vertical's *operational stats* from `icp/` (e.g. automotive's "zero stock outages after 3 months · 30% fewer lost-stock incidents") over forcing a contracting-stage logo into a discovery email. A vertical-matched operational stat reads as discovery-appropriate; an enterprise contracting logo at first touch is exactly the stage-mismatch this skill exists to prevent.
- **Bind every stat to its named source. Never blend two customers' numbers** (e.g. don't attach Nidec's 450% ROI to GXO). If the right proof isn't in `proof/` or `client/`, say so rather than estimating.

### Worked example — first-touch email to an Inventory Manager at a 3PL

**Generic draft (what to avoid):**
> Subject: Revolutionise your warehouse with AI robots
> Hi [Name], I wanted to introduce Dexory, the leading autonomous warehouse robotics platform. Our cutting-edge robots and AI digital twin deliver 99.9% accuracy and 219% ROI, and we work with industry leaders like Maersk. I'd love to book a demo — are you free Thursday?

Why it's weak: opens on the product and the company, not the reader's problem; fires a board-level ROI stat at an operational persona during discovery; cites Maersk's enterprise scale, irrelevant to this person's daily pain; asks for a demo (too heavy for a first touch); leans on buzzwords instead of a KPI hook.

**Grounded draft (what the skill should produce):**
> Subject: your morning blocked-inventory check
> Hi [Name] — most inventory teams I talk to at 3PLs lose 30–45 minutes each morning stitching together Power BI, WMS screens and Excel just to see what blocked overnight, and still only catch a missing pallet when a picker hits an empty location.
> Dexory scans the whole site daily and flags system-vs-physical gaps *before* pick tasks are generated. Yusen freed up 205+ hours a year working this way.
> Worth a 15-minute look at what your exceptions would surface tomorrow?

Why it works: opens on this persona's actual pain and KPI (blocked inventory, the 30–45 min data-gathering ritual) straight from `persona/inventory-manager`; ties to their real-time-discrepancy JTBD; uses a named, 3PL, discovery-appropriate proof point (Yusen) instead of a generic figure; stays in the operator frame; and lands a light, stage-appropriate CTA rather than a demo ask.
