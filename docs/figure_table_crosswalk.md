# Figure & Table Crosswalk (final numbering + generation status)

Manuscript **JSHS-2026-1054**. This file defines the **final** figure/table
numbering for the revised paper and maps each item to the code that produces it
and to its output file. It also records the fix for the pre-existing problem
that the manuscript's in-text callouts used **placeholder labels**
(`S_F14`, `W_T01`, `C_F14`, …) that did **not** match the generated filenames.

Status legend: **✓ generated** (file present in `outputs/`, from real data) ·
**⟳ on knit** (produced when `analysis/longitudinal_all3.Rmd` is knitted;
paths now portable) · **✎ author decision** (editorial choice noted).

---

## 1. Main text

| Final | Description | Produced by | Output file | Status |
|------|-------------|-------------|-------------|--------|
| **Table 1** | Baseline sample characteristics (weighted), by wave, with SMD | `longitudinal_all3.Rmd` (CreateTableOne chunk) | `outputs/tables/Table1.docx` | ⟳ on knit (abs-path fixed) |
| **Table 2** | Observed outcomes by **sex × age group** (80+ collapsed) — *new (R1-Q1)* | `analysis/R/generate_revision_outputs.R` | `outputs/tables/Table_2_observed_by_sex_age.docx` | ✓ generated |
| **Figure 1** | Predicted within-person trajectories, 3 outcomes, by sex (0–3 yr) | `generate_revision_outputs.R` | `outputs/figures/Figure_1_predicted_trajectories.png` | ✓ generated ✎ |
| **Figure 2** | Within-person annual change by **baseline-activity quartile** — *new (R1-Q4/R2-Q8)* | `generate_revision_outputs.R` | `outputs/figures/Figure_2_quartile_decline.png` | ✓ generated |

> **Figure 1 note (✎):** a fast, reproducible frequentist version is provided so
> the main-text set is complete without the Bayesian toolchain. If preferred,
> promote a Bayesian marginal-prediction figure from the supplement instead and
> keep this as a supplementary figure.

## 2. Supplement — sensitivity analyses (new in revision)

All in one file: `outputs/tables/Supplementary_Material_Revision.docx`
(also mirrored as the standalone `manuscript/Supplementary_Material_Revision_JSHS-2026-1054.docx`).

| Final | Description | Reviewer point | Status |
|------|-------------|----------------|--------|
| **Table S1** | Completers vs non-completers (baseline) | R2-Q1 | ✓ generated |
| **Table S2** | Pattern-mixture (delta-adjustment) MNAR sensitivity | R2-Q1 | ✓ generated |
| **Table S3** | Decline on the attained-age scale | R2-Q4 | ✓ generated |
| **Table S4** | Additive vs sex-by-time model estimates | R2-Q5 | ✓ generated |
| **Table S5** | Unweighted vs weight-informed decline | R2-Q9 | ✓ generated |
| **Table S6** | Quartile slopes + intercept–slope correlations (RTM) | R1-Q4/R2-Q8 | ✓ generated |
| **Table S7** | Intensity-metric triangulation | R2-Q6 | ✓ generated |
| **Table S8** | Observed outcomes by sex × **three** age bands (full) | R1-Q1 | ✓ generated (`outputs/tables/Table_S8_observed_by_sex_age_full.docx`) |

## 3. Supplement — model outputs per outcome (existing, from the Rmd)

The Rmd produces a **parallel set** of figures and tables for each of the three
outcomes. Naming convention going forward (outcome tag **S**=steps, **W**=walking,
**C**=cadence):

**Supplementary figures** (`outputs/figures/`, ⟳ on knit):

| Content | steps file | walking file | cadence file |
|---|---|---|---|
| Observed distribution | `Figure_1_observed_steps.png` | `Figure_1_observed_walking_mins.png` | `Figure_5_observed_peak30.png` |
| Prediction distribution | `Figure_2_prediction_distribution_steps.png` | `Figure_2_prediction_distribution_walk_minutes.png` | `Figure_2_prediction_distribution_peak30.png` |
| Extended predictions | `Figure_3_extended_predictions_steps.png` | `Figure_3_extended_predictions_walk_minutes.png` | `Figure_3_extended_predictions_peak30.png` |
| Marginal by sex | *(in steps set)* | `W_F04_…marginal_bysex_walk_minutes.png` | `Figure_4_marginal_bysex_peak30.png` |
| Counterfactual | `Figure_5_counterfactual_steps.png` | `Figure_5_counterfactual_walk_minutes.png` | `Figure_5_counterfactual_peak30.png` |
| Trajectories age×sex | `Figure_6_trajectories_age_sex_steps.png` | `Figure_6_trajectories_age_sex_walk_minutes.png` | `Figure_6_trajectories_age_sex_peak30.png` |
| Wave predictions | `Figure_7_wave_predictions_steps.png` | `Figure_7_wave_predictions_walk_minutes.png` | `Figure_7_wave_predictions_peak30.png` |
| FE spline bootstrap | `Figure_8_FE_spline_bootstrap_steps.png` | `Figure_W1_FE_spline_bootstrap_walk_minutes.png` | `Figure_8_FE_spline_bootstrap_peak30.png` |
| Posterior predictive check | `Figure_9_posterior_predictive_steps.png` | `Figure_9_posterior_predictive_walk.png` | `Figure_9_posterior_predictive_peak30.png` |
| Conditional/marginal/full posteriors | `Figure_10/11/12_*` | `Figure_10/11/12_*_walk.png` | `Figure_14/15/16_*_peak30.png` |
| 10-yr projection (illustrative only) | `Figure_13_10yr_projections.png` | `Figure_13_10yr_projections_walk.png` | `Figure_17_10yr_projections_walk.png` |
| Age×time heatmap | `Figure_steps_age_time_heatmap.png` | `Figure_walk_age_time_heatmap.png` | `Figure_peak30_age_time_heatmap.png` |
| Diagnostics / random effects | `Figure_A1_diagnostics*`, `A2/A3` | `…_walk` | `…_peak30` |

**Supplementary tables** (`outputs/tables/`, ⟳ on knit):

| Content | steps | walking | cadence |
|---|---|---|---|
| Fixed effects | `Table_S2_fixed_effects_steps.docx` | `Table_W3_fixed_effects_walking.docx` | `Table_C1_fixed_effects_peak30.docx` |
| Random effects | `Table_S3_random_effects_steps.docx` | `Table_W4_random_effects_walking.docx` | `Table_C2_random_effects_peak30.docx` |
| Avg predictions by sex | *(steps set)* | `Table_W5_avg_pred_sex_walking.docx` | `Table_C3_avg_pred_sex_peak30.docx` |
| FE linear / within | `Table_S5_FE_spline_daily_steps.docx` | `Table_W6_FE_within_walking.docx`, `Table_W7_FE_spline_walking.docx` | `Table_C4_FE_linear_peak30.docx`, `C_T05_FE_spline_peak30.docx` |
| LOO model comparison | `Table_S6_LOO_model_comparison_daily_steps.docx` | `Table_W8_LOO_walk.docx` | `Table_C6_LOO_peak30.docx` |
| Predicted model comparison | `Table_S7_predicted_steps_model_comparison.docx` | — | `Table_C7_predicted_peak30_model_comparison.docx` |
| Baseline by sex (SMD) | `Table_S1_sex_SMD.docx` | — | — |

## 4. Callout reconciliation (ACTION for authors ✎)

The manuscript body still uses placeholder callouts (`S_F01–S_F14`, `W_F01–W_F14`,
`C_F01–C_F15`, `S_T01–S_T07`, `W_T*`, `C_T*`). Before submission, replace each
in-text callout with the **final** label above and confirm it points to the
correct file in §3. The code side is now consistent: knitting the (portable) Rmd
writes every figure to `outputs/figures/` and every table to `outputs/tables/`
using the filenames listed here.

## 5. What the revision changed vs. did not

- The revision analyses are **additive**: the primary models and their estimates
  (steps −250.6, walking −3.0, cadence −1.43 per year) are **unchanged**, so the
  existing §3 figures/tables remain valid in content and do **not** need
  recomputation for correctness.
- **New** items requiring generation were Table 2, Figure 1, Figure 2, and
  Supplementary Tables S1–S8 — all now produced by
  `analysis/R/generate_revision_outputs.R` (✓) and wired into the Rmd
  (`revision-save-outputs` chunk).
- To obtain a **complete, current** output set (new items + full per-outcome
  supplement) in one pass, knit `analysis/longitudinal_all3.Rmd`.
