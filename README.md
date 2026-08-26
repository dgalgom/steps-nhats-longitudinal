# Multidimensional Physical Activity Decline in the Oldest-Old (NHATS)

Reproducible analysis code for the manuscript:

> **Daily Steps and Multidimensional Physical Activity Decline in the Oldest-Old:
> A 4-Year Longitudinal Analysis** (JSHS-2026-1054).

Four waves of wrist accelerometry (NHATS Rounds 11–14, 2021–2024; 644 adults
aged 70+, 2,030 person-wave observations) are used to estimate within-person
decline in three complementary ambulatory dimensions — **daily steps** (volume),
**walking time** (duration), and **peak 30-minute cadence** (intensity) — using
Bayesian hierarchical models with frequentist and fixed-effects sensitivity
analyses.

---

## Repository structure

```
steps-nhats-longitudinal/
├── README.md
├── LICENSE                       # MIT (code only; data governed separately)
├── run_all.R                     # reproduce revision outputs end-to-end
├── analysis/
│   ├── longitudinal_all3.Rmd     # full analysis + HTML report (primary source)
│   └── R/
│       ├── generate_revision_outputs.R   # Table 2, Figure 2, Supp S1–S7
│       └── patch_rmd_portable.py         # one-off path-portability patch (record)
├── data/
│   ├── raw/                      # analysis dataset (no public access)
│   └── synthetic/                # tiny synthetic sample so code runs w/o real data
├── outputs/
│   ├── figures/                  # generated figures (.png/.pdf)
│   ├── tables/                   # generated tables (.docx/.csv)
│   └── models/                   # cached brms model objects (.rds; gitignored)
├── manuscript/                   # marked manuscript, response letter, supplement
└── docs/
    ├── figure_table_crosswalk.md # final figure/table numbering + generation status
    └── alignment_check.md        # cross-check: paper ↔ responses ↔ supp ↔ outputs
```

## Requirements

- R ≥ 4.4
- CRAN packages: `brms`, `lme4`, `fixest`, `marginaleffects`, `tidybayes`,
  `loo`, `survey`, `tidyverse`, `flextable`, `officer`, `ggplot2`, `scales`,
  `knitr`, `rmarkdown`. A Stan toolchain (`cmdstanr` or `rstan`) is required to
  *fit* the Bayesian models.

## Data

The NHATS data are **not** included (Data Use Agreement). See
[`data/raw/README.md`](data/raw/README.md) for how to obtain Rounds 11–14 and
build `data/raw/df.csv`. A small **synthetic** sample
(`data/synthetic/df_synthetic.csv`) lets the pipeline run without the real data;
its values are random and do **not** reproduce the published estimates.

Data path resolution order (both entry points): `DATA_PATH` env var →
`data/raw/df.csv` → `data/synthetic/df_synthetic.csv`.

## How to reproduce

**Revision outputs only** (Table 2, Figure 2, Supplementary Tables S1–S7) —
fast, no Bayesian fitting:

```bash
Rscript run_all.R                                   # uses synthetic if no raw data
DATA_PATH=/path/to/df.csv Rscript run_all.R         # uses the real data
```

**Full analysis + HTML report** (fits/loads all Bayesian models and writes every
figure and table to `outputs/`):

```r
rmarkdown::render("analysis/longitudinal_all3.Rmd", knit_root_dir = normalizePath("."))  # run from repo root
```

The Rmd loads cached model objects from `outputs/*.rds` if present; otherwise the
model-fitting chunks refit them (slow; needs a Stan toolchain).

## Outputs

All figures are written to `outputs/figures/` and all tables to
`outputs/tables/`. The final numbering and the map from manuscript callouts to
files is in [`docs/figure_table_crosswalk.md`](docs/figure_table_crosswalk.md).

## Notes on reproducibility fixes applied

The analysis Rmd was made machine-independent: hard-coded absolute paths were
removed, every `ggsave()` is routed to `outputs/figures/` and every table to
`outputs/tables/`, and the data path is configurable (see
`analysis/R/patch_rmd_portable.py` for the exact record of changes).

## Citation

See `CITATION.cff`. NHATS is funded by the National Institute on Aging
(U01AG032947).
