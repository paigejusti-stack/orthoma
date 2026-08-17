# Report Spec

## Report identity
- Report name: Orthoma — Page 4 MVA Aging & Follow-Up
- Semantic model: `power-bi/Orthoma.SemanticModel`
- Audience: Clinic revenue-cycle and operations leaders
- Primary purpose: Identify unresolved motor vehicle accident receivable exposure and prioritize follow-up by aging bucket, location, and claim status.
- Delivery target: Local PBIP/PBIR repository and Power BI Desktop validation

## User decisions and constraints
- Scope: Add one Page 4 only; preserve Pages 1–3.
- Page count: One new 1280 × 720 page.
- Interactivity: Page-specific Date of Service, Location, Service Line, and Claim Status slicers; default Claim Status is Open plus Denied; chart selections cross-filter the page.
- Design direction: Match the existing Orthoma pale-green analytical canvas, left filter rail, white bordered surfaces, Segoe UI typography, and compact executive density.
- Publishing: Not authorized.
- Tooling: Power BI Modeling MCP for semantic-model writes; PBIR authoring CLI and Desktop bridge for report validation.
- Model edit permissions: Maintain the approved aging bucket columns and nine MVA measures only; no relationships.
- Accessibility: Descriptive titles, concise labels, logical keyboard order, and alt text on charts and matrix.
- Data caveats: Outstanding A/R is an operational proxy equal to Allowed Amount less Paid Amount. Unresolved means Open plus Denied. Claims with negative age are excluded. Aging originates from Submit Date as of Data Through Date.

## Narrative
- Core story: Show how much unresolved MVA exposure exists, how old it is, and which location needs action.
- Audience promise: A single operational page that moves from headline risk to aging profile, location concentration, and follow-up status.
- Key questions answered: How much is unresolved? What share is beyond 90/120 days? Which aging buckets and locations dominate? How do Open and Denied claims compare?

## Design identity
- Tone: Clinical Operations Brief
- Signature: One six-metric KPI strip above a four-band green-to-amber-to-red aging-risk progression.
- Brownfield delta: Existing Orthoma analytical canvas → same visual language with explicit aging-risk semantics.

## Page plan
1. MVA Aging & Follow-Up
   - Archetype: Analytical Canvas
   - Layout variant: Left filter rail with KPI strip, three-chart diagnostic row, and full-width action matrix.
   - Purpose: Prioritize unresolved MVA claim follow-up.
   - Visuals: Multi-value cardVisual, waterfall, donut, stacked column chart, pivotTable, four slicers, reset and back buttons, title/subtitle, and data-definition note.
   - Fields/measures: Aging Bucket, Location, Claim Status, Service Date, Service Line, nine approved MVA measures.
   - Slicers/interactions: All slicers are Page 4 specific; all analytical visuals use default cross-filtering; page filter is exact Payer Class Name = Motor Vehicle Accident.

## Design system summary
- Theme name + base palette: Existing Orthoma theme; canvas #F9FCF7, surfaces #FFFFFF, text #303030/#63655F, border #DDE5D8.
- Aging hierarchy: 0–60 = Current / Early Aging; 61–90 = Developing Risk; 91–120 = High Risk; 121+ = Critical Aging.
- Color semantics: 0–60 #98C177, 61–90 #64A846, 91–120 #E8A33D, 121+ #C4432B.
- Typography pairing: Segoe UI Semibold for headings and Segoe UI for supporting text.
- Layout pattern: 8 px grid, 16 px gutters, 228 px left rail, dense executive canvas.
- Accessibility commitments: Minimum readable text, high contrast, descriptive titles and alt text, predictable tab order.

## Model requirements
- Existing measures: Claims; Data Through Date.
- New measures: MVA Open Claims; MVA Outstanding A/R; MVA Avg Outstanding per Open Claim; MVA 90+ A/R; MVA 90+ A/R %; MVA 120+ A/R; MVA 120+ A/R %; MVA Median Days Outstanding; MVA % of Total A/R.
- New calculated columns: Aging Bucket; Aging Bucket Sort.
- Relationship/sort requirements: No relationship changes. Sort Aging Bucket by Aging Bucket Sort using 0–60 = 1, 61–90 = 2, 91–120 = 3, and 121+ = 4.
- KPI threshold requirements: MVA 90+ A/R continues to use ClaimAgeDays > 90; MVA 120+ A/R continues to use ClaimAgeDays > 120; Median Days Outstanding remains based on raw nonnegative ClaimAgeDays.
- Page 4 typography delta: Increase visual titles, subtitles, axes, legends, chart labels, and matrix text while preserving the existing multi-value KPI card sizing.

## Canonical design contract

```yaml
Design Brief:
  generated_by: powerbi-report-design
  contract_version: "1.0"
  report_name: "Orthoma"
  design_identity:
    tone: "Clinical Operations Brief"
    signature: "Six-metric strip with explicit aging-risk progression"
    theme: "Existing Orthoma"
    typography:
      display: "Segoe UI Semibold"
      body: "Segoe UI"
    color_map:
      canvas: "#F9FCF7"
      surface: "#FFFFFF"
      text_primary: "#303030"
      text_secondary: "#63655F"
      border: "#DDE5D8"
      age_0_60: "#98C177"
      age_61_90: "#64A846"
      age_91_120: "#E8A33D"
      age_121_plus: "#C4432B"
  pages:
    - name: "MVA Aging & Follow-Up"
      page_id: "9d6c4b2a1f8e7350c4d2"
      archetype: "Analytical Canvas"
      page_title: "MVA AGING & FOLLOW-UP"
      subtitle: "Where is MVA receivable exposure aging, and which location needs action first?"
      page_filter: "PayerClass[PayerClassName] = Motor Vehicle Accident"
      layout_contract:
        canvas:
          width: 1280
          height: 720
          display_option: "FitToPage"
        grid:
          unit: 8
          gutter: 16
          regions:
            - {name: "header", x: 40, y: 8, width: 960, height: 56}
            - {name: "filters", x: 40, y: 96, width: 176, height: 584}
            - {name: "kpis", x: 244, y: 80, width: 1024, height: 112}
            - {name: "diagnostics", x: 244, y: 208, width: 1024, height: 248}
            - {name: "follow_up", x: 244, y: 472, width: 1024, height: 232}
        placements:
          - {id: "page_title", visual_type: "textbox", x: 46, y: 8, width: 760, height: 32, title: "MVA AGING & FOLLOW-UP"}
          - {id: "page_subtitle", visual_type: "textbox", x: 46, y: 43, width: 900, height: 18, title: "Where is MVA receivable exposure aging, and which location needs action first?"}
          - {id: "filter_label", visual_type: "textbox", x: 40, y: 96, width: 176, height: 24, title: "FILTERS"}
          - {id: "service_date_slicer", visual_type: "slicer", x: 40, y: 128, width: 176, height: 72, title: "Date of Service"}
          - {id: "location_slicer", visual_type: "slicer", x: 40, y: 216, width: 176, height: 56, title: "Location"}
          - {id: "service_line_slicer", visual_type: "slicer", x: 40, y: 288, width: 176, height: 56, title: "Service Line"}
          - {id: "claim_status_slicer", visual_type: "slicer", x: 40, y: 360, width: 176, height: 56, title: "Claim Status"}
          - {id: "reset_button", visual_type: "actionButton", x: 56, y: 440, width: 144, height: 40, title: "RESET FILTERS"}
          - {id: "definition_note", visual_type: "textbox", x: 40, y: 504, width: 176, height: 72, title: "A/R proxy = Allowed less Paid. Unresolved = Open + Denied. Negative-age claims excluded."}
          - {id: "back_button", visual_type: "actionButton", x: 40, y: 640, width: 176, height: 40, title: "BACK"}
          - {id: "kpi_strip", visual_type: "cardVisual", x: 244, y: 80, width: 1024, height: 112, title: "MVA aging headline metrics"}
          - {id: "aging_waterfall", visual_type: "waterfallChart", x: 244, y: 208, width: 384, height: 248, title: "Outstanding A/R by Aging Bucket"}
          - {id: "aging_donut", visual_type: "donutChart", x: 644, y: 208, width: 280, height: 248, title: "A/R Mix by Aging Bucket"}
          - {id: "location_stack", visual_type: "columnChart", x: 940, y: 208, width: 328, height: 248, title: "Outstanding A/R by Location and Age"}
          - {id: "claim_status_matrix", visual_type: "pivotTable", x: 244, y: 472, width: 1024, height: 232, title: "Follow-Up by Claim Status"}
        space_audit:
          unplaced_regions: []
          overlap_count: 0
          out_of_bounds_count: 0
          balance_rationale: "The filter rail anchors the page, while the equal-height diagnostic row and full-width matrix use the remaining canvas without dead zones."
      accessibility:
        tab_order: "Title, slicers, reset, back, KPI strip, charts left-to-right, matrix"
        alt_text_required: true
      interactions:
        default_cross_filter: true
        slicer_sync: false
        reset_bookmark: "Reset MVA Aging and Follow-Up filters"
```

## Implementation notes
- Model changes: Maintain the approved two calculated columns and nine measures under `orthoplus_claims`; consolidate the existing five-band display logic to four bands without changing the raw-day KPI thresholds; validate DAX against the MVA cohort; export to PBIP.
- PBIR/report authoring: Add Page 4, its visuals, page filter, page order entry, and reset bookmark; do not edit existing page folders.
- Validation: Parse JSON, run PBIR validator, verify bindings/roles/sort/filter defaults, and compare protected-file hashes.
- Desktop screenshot verification: Reload the PBIP-backed Desktop instance only if it has no pre-existing unsaved changes; capture Page 4 and review for clipping, errors, color consistency, and usable slicers.
- Publishing boundary: Local only; no Fabric publish.
- Risks: A/R is a proxy rather than a transaction ledger; future-dated claims are deliberately excluded; structural validation is not a substitute for rendered Desktop verification.
