# Alignment check: responses ↔ revised paper ↔ supplement ↔ outputs

Manuscript **JSHS-2026-1054**. Each reviewer point is traced across the four
deliverables to confirm they are mutually consistent.

Columns: **Response letter** (`manuscript/Response_to_Reviewers_JSHS-v1.docx`) ·
**Marked paper** (`manuscript/BPC_Manuscript_MARKED_JSHS-2026-1054.docx`) ·
**Supplement / output** (`Supplementary_Material_Revision.docx`, Table 2, Figure 2) ·
**Aligned?**

| # | Point | Response letter | Marked paper (tracked change) | Supplement / output | Aligned |
|---|-------|-----------------|-------------------------------|---------------------|---------|
| R1-Q1 | Present raw data by sex × age group | A1: promote to Table 2, stratified; collapse 80+ | Results: "…presented in Table 2." | **Table 2** (main, 80+) + **Table S8** (full 3-band) | ✓ |
| R1-Q2 | 10-yr projection plausibility | A2: within- vs between-person distinct; de-emphasize | Results: within/between clarifier after 70/85-yr example | (conceptual; see Fig 1 restricted to 0–3 yr) | ✓ |
| R1-Q3 | Cadence declines proportionally less | A3: add discussion (preserved capacity, range) | Discussion: new inserted paragraph | %/yr: steps −4.0, walk −3.3, cadence −2.1 (Rmd R1-Q3 chunk) | ✓ |
| R1-Q4 | Show steeper decline in high-baseline | A4: quartile figure + RTM caveat | Results: "…shown in Figure 2 (new)." | **Figure 2** + **Table S6** | ✓ |
| R1-Q5 | "Sex differences were outcome specific" wording | A5: reword (levels, not slopes) | Abstract + Discussion: both reworded | — | ✓ |
| R1-Q6 | Cautious clinical interpretation | A6: between-person/age-adjusted + reverse causation | Discussion (public-health paragraph): caveat inserted | — | ✓ |
| R1-Q7 | Harmonize supp variable names | A7: relabel supplementary table | (supplementary table formatting) | Variable labels harmonized in Table 1 / supp | ✓ (formatting) |
| R2-Q1 | MAR unlikely; attrition | A1: attrition + MNAR; estimates conservative | Sample + Limitations: conservative-bias + pattern-mixture | **Table S1** (attrition), **Table S2** (MNAR δ) | ✓ |
| R2-Q2 | Projections beyond follow-up | A2: de-emphasize; extrapolation caveat | Methods (0–3 primary) + Limitations | Figure 1 shown 0–3 yr only | ✓ |
| R2-Q3 | Causal language | A3: association audit | Discussion: "represent early manifestations"→"be an early marker" | — | ✓ |
| R2-Q4 | Time as years-since-baseline | A4: baseline age modeled; attained-age sensitivity | Methods: attained-age sentence | **Table S3** | ✓ |
| R2-Q5 | LOO selection inflates FP | A5: pre-specified; additive vs interaction stable | (Methods; estimates stable) | **Table S4** | ✓ |
| R2-Q6 | Peak cadence definition | A6: reframe "best 30 min"; minute-level not retained | Measures: reframe + limitation | **Table S7** (triangulation) | ✓ |
| R2-Q7 | Frailty on causal pathway | A7: frailty NOT a covariate (only Table 1 descriptive) | Methods: "adjusted for age & sex only…" | Rmd R2-Q7 chunk asserts no frailty term | ✓ |
| R2-Q8 | Regression to the mean | A8: quartile gradient + empirical-Bayes | (Discussion via R1-Q4 wording) | **Table S6** (model r vs EB r) | ✓ |
| R2-Q9 | Complex survey design | A9: weight-informed; no PSU/strata available | Methods: weighting sentence + PSU note | **Table S5** | ✓ |
| R2-Q10 | "Multidimensional" overclaim | A10: reframe to ambulatory; add limitation | Limitations: non-ambulatory sentence | — | ✓ |

## Numeric consistency (spot-checks, real data)

These values appear identically in the response letter, the supplement, and are
reproduced by `run_all.R` on the real data:

| Quantity | Value |
|---|---|
| Primary decline — steps / walking / cadence (per year) | −250.6 / −3.0 / −1.43 |
| Attrition: completer vs non-completer baseline steps | 6,554 vs 4,764 |
| MNAR δ (steps): δ=0 → δ=1.0 | −268 → −293 (monotone steeper) |
| Attained-age steps (vs primary) | −215 (vs −251) |
| Additive vs sex-by-time (steps) | −250.6 vs −247.7 |
| Weighted vs unweighted (steps) | −227 vs −251 |
| Quartile slopes steps Q1→Q4 | +114 → −621 |
| Intensity correlations (peak30 vs peak1 / 95th) | 0.88 / 0.90 |

## Known open items (author action)

1. **Callout reconciliation** — replace placeholder callouts (`S_F14`, `W_T01`, …)
   in the manuscript body with the final labels in `figure_table_crosswalk.md`.
2. **Figure 1 choice** — keep the reproducible frequentist Figure 1 or promote a
   Bayesian prediction figure (see crosswalk §1 note).
3. **Full knit** — run `analysis/longitudinal_all3.Rmd` to regenerate the complete
   per-outcome supplement into `outputs/` (needs cached brms `.rds` or a refit).
4. **R1-Q7** applies to a supplementary table's variable labels (formatting), not
   a model change.

_Last verified: outputs regenerated from the real `df.csv` via `run_all.R`._
