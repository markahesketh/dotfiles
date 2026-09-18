# Jobs To Be Done & Needs Models

Insight-driven opportunities per operational persona, in the **"I want… / because… / but…" → opportunity** format. Use these to build hooks, value props, and demo narratives. Each persona's needs model (product benefits → required tool characteristics → today's gaps) follows.

---

## Operations Manager

**JTBD 01 — Future-proofing**
- I want… to future-proof my warehouse, to ensure we consistently meet all KPIs and SLAs.
- because… as consumer demand grows, the supply chain must keep up within the same infrastructure.
- but… I'm so overwhelmed firefighting day-to-day that I can't step back to find process improvements.
- → **Opportunity:** AI-generated insights using trend data to identify root causes, reduce day-to-day issues, and free time for future-proofing.

**JTBD 02 — Proactive inventory lifecycle**
- I want… to identify slow-moving and ageing inventory before it creates a capacity crisis.
- because… current lifecycle decisions are reactive — we only flush product when already in a capacity crisis.
- but… there's no proactive lifecycle process; it only becomes a priority at ~95% capacity.
- → **Opportunity:** automated ageing/slow-mover SKU flagging with forecasted utilisation impact and proactive solution suggestions.

**JTBD 03 — Fast pre-shift decisions**
- I want… the ability to make quick, data-driven decisions when planning the shift ahead.
- because… rounded information lets me adapt labour allocation and prioritise tasks to hit SLAs and KPIs.
- but… it takes 30–45 min checking multiple reports and emails to see what's left from the prior shift.
- → **Opportunity:** complete operational visibility via a single real-time dashboard consolidating all reports.

**JTBD 04 — Performance diagnosis**
- I want… to understand why a team member is underperforming or erroring without physically observing every task.
- because… performance problems diagnosed early save SLAs, prevent shortfalls, and protect morale.
- but… errors surface late and require laborious investigation to pin down the behaviour.
- → **Opportunity:** near-real-time individual performance and quality-error surfacing with coaching triggers and behaviour context.

**Needs model** — Overarching need: *confident, proactive decisions to run the warehouse today and for the future.*
| Product benefit | Required tool characteristics | Today's gap |
|---|---|---|
| Unified pre-shift picture in <5 min | Single consolidated dashboard (overnight KPIs, volumes, staffing, inventory health), mobile pre-shift | Power BI close but needs cross-referencing 6+ tabs |
| Labour decisions backed by live data | Live volume-to-resource view by zone/function; recommended staffing adjustments | LMS exists but rarely real-time integrated with WMS |
| AI root-cause for recurring issues | Trend analysis + anomaly detection with prioritised hypotheses and corrective actions | Absent; Power BI Copilot/Tableau detect anomalies but don't contextualise for warehouse ops |
| Forward-looking capacity/utilisation forecasting | Day-level forecasting updated live; alert at 80% capacity breach with suggested actions | Done manually via spreadsheets |
| Individual performance & quality-error visibility | Near-real-time breakdown by task type; error attribution with recency weighting; coaching triggers | Blue Yonder LMS gives aggregate % only; quality errors surface next-day |

---

## Inventory Manager

**JTBD 01 — Real-time discrepancy detection**
- I want… to identify and resolve inventory discrepancies in real time, before they impact fulfilment.
- because… by the time ops reports a missing pallet, the order may already be at risk — early detection means proactive resolution.
- but… I only find out when ops goes to pick and the item isn't there; by then it's too late.
- → **Opportunity:** real-time discrepancy detection with automated alerts when system vs. physical diverges, *before* pick tasks are generated.

**JTBD 02 — Root-cause without manual digging**
- I want… to understand the root cause of blocked inventory and shortages without hours of manual investigation.
- because… spotting patterns (wrong locations, process errors, system issues) lets me fix the underlying problem.
- but… WMS shows only 30 days and needs clicking through screens; analysis is manual and slow.
- → **Opportunity:** AI-powered root-cause analysis that finds patterns in discrepancies and suggests corrective actions from historical data.

**JTBD 03 — Proactive aging management**
- I want… to proactively manage aging/slow-moving inventory before it creates capacity and efficiency problems.
- because… slow movers in pick areas increase travel time, cut pick efficiency, and force rushed clearance.
- but… there's no systematic flagging — we only act when capacity is already a crisis.
- → **Opportunity:** automated aging alerts with forecasted capacity/efficiency impact plus recommended actions (relocate, promote, clear).

**Needs model** — Overarching need: *perfect inventory accuracy with minimal manual effort, so operations never has a shortage from inventory issues.*
| Product benefit | Required tool characteristics | Today's gap |
|---|---|---|
| Real-time discrepancy detection | Live WMS↔physical feed; alerts within minutes of divergence, before pick tasks | No real-time detection |
| Root-cause automation | Pattern recognition across discrepancies; suggested actions; ≥90 days fast-query history | WMS 30 days only, no pattern recognition |
| Proactive aging management | Daily slow-mover alerts with forecasted impact | Reactive, manual |
| Unified inventory-health dashboard | Single view: blocked, shortages, aging, cycle-count, discrepancies; mobile | Power BI needs manual export; no alerting/workflows |
| Cycle-count optimisation | AI prioritisation of locations by risk/historical accuracy; visual heat maps; drill-down | Counting robots reduce manual work but don't prioritise or predict |

---

## Inbound/Outbound Manager

**JTBD 01 — Fast labour & wave decisions**
- I want… to make quick, data-driven labour-allocation and wave-prioritisation decisions at the start of each shift.
- because… the first hour sets the tone — wrong labour or wave priorities put us behind all day.
- but… it takes 30–45 min across reports/emails to see what's left from the previous shift.
- → **Opportunity:** unified pre-shift dashboard consolidating overnight performance, incoming volumes, staffing, wave priorities, capacity constraints — mobile.

**JTBD 02 — Real-time conveyance visibility**
- I want… real-time visibility into conveyance flow and bottlenecks so I can adjust before delays cascade.
- because… by the time I see staging congestion, it's too late — I need to see problems forming.
- but… I only know of a bottleneck when supervisors report it or I walk the floor.
- → **Opportunity:** real-time conveyance flow monitoring with predictive bottleneck alerts plus recommended labour reallocation.

**JTBD 03 — Accurate capacity forecasting**
- I want… to forecast capacity and utilisation accurately so I can plan proactively instead of reacting.
- because… at 95% capacity / full staging we're forced into rushed clear-or-overflow decisions.
- but… forecasting is manual (spreadsheets) and often inaccurate; no forward-looking alerts.
- → **Opportunity:** day-level capacity/utilisation forecasting updated in real time, alert at 80% breach with suggested actions.

**Needs model** — Overarching need: *orchestrate seamless dock-to-dock flow with optimal labour/capacity, so every order ships on time and in full.*
| Product benefit | Required tool characteristics | Today's gap |
|---|---|---|
| Unified pre-shift picture | Consolidated dashboard incl. conveyance flow + capacity utilisation | Power BI needs 6+ reports cross-referenced |
| Real-time conveyance/flow monitoring | Live feed from WMS, conveyance, LMS; threshold alerts | WMS gives no flow visibility/forecasting |
| Forward-looking capacity forecasting | Day-level projections, proactive 80% alerts | LMS rarely real-time integrated |
| Wave orchestration optimisation | AI wave prioritisation/release on real-time constraints & deadlines | Wave planning rule-based, not adaptive |
| Labour allocation recommendations | Data-driven staffing suggestions; cross-functional shared view | No dynamic allocation recommendations |

---

## Warehouse Supervisor

**JTBD 01 — Dynamic reallocation on call-outs**
- I want… to quickly adjust my labour plan when people call out, without disrupting the whole shift.
- because… I spend 30–60 min building a plan, then 5–10 call-outs force me to start over.
- but… I manually recalculate, coordinate labour-sharing, and communicate changes while the shift is starting.
- → **Opportunity:** dynamic labour-allocation tool that suggests reallocation options on call-outs, considering cross-training, workload, and priorities.

**JTBD 02 — Structured shift handover**
- I want… a structured handover capturing key decisions, unresolved issues, and staffing notes.
- because… verbal handovers are inconsistent and the next supervisor wastes time re-discovering known problems.
- but… handover is manual notes / quick chats — no systematic capture/surfacing.
- → **Opportunity:** structured digital shift handover capturing decisions, issues, staffing, and performance trends, auto-surfaced for the incoming supervisor.

**JTBD 03 — More coaching, less firefighting**
- I want… to spend more time coaching and developing my team and less firefighting and checking reports.
- because… coaching improves performance, retention, and morale.
- but… daily firefighting (absenteeism, equipment, systems) consumes most of my time.
- → **Opportunity:** automated issue detection and escalation that handles routine problem identification/routing, freeing supervisor time for coaching.

**Needs model** — Overarching need: *lead a high-performing, engaged team that meets targets with safety and quality, without burning out.*
| Product benefit | Required tool characteristics | Today's gap |
|---|---|---|
| Dynamic labour-allocation support | Auto reallocation suggestions on call-outs (cross-training, workload) | Manual recalculation |
| Structured digital shift handover | Template capturing decisions/issues/trends, surfaced with priority flags | Teams chat unstructured; info lost |
| Automated issue detection & escalation | Detects equipment/inventory/system errors, routes to support without supervisor | None |
| Mobile-accessible performance dashboard | Mobile-first (supervisors on the floor); live WMS/LM/quality feed; minute-level alerts | WMS/LM require manual checking; not on floor |
