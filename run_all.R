## Orchestrator: reproduce the revision outputs (Table 2, Figure 2, Supp S1–S7).
## Run from the repository root:  Rscript run_all.R
## The full Bayesian pipeline + HTML report is produced by knitting
## analysis/longitudinal_all3.Rmd (needs the cached brms models or a refit).

# Resolve repo root = directory of this script (portable under Rscript)
.args <- commandArgs(trailingOnly = FALSE)
.sf <- sub("^--file=", "", .args[grep("^--file=", .args)])
if (length(.sf)) setwd(dirname(normalizePath(.sf)))

message("== Step 1: ensure data is available ==")
if (!file.exists("data/raw/df.csv") &&
    is.na(Sys.getenv("DATA_PATH", unset = NA)) &&
    !file.exists("data/synthetic/df_synthetic.csv")) {
  message("No raw data; generating synthetic sample so the pipeline can run.")
  source("data/synthetic/make_synthetic.R")
}

message("== Step 2: generate revision figures & tables ==")
out_dir <- "outputs"
fig_dir <- file.path(out_dir, "figures")
tab_dir <- file.path(out_dir, "tables")
source("analysis/R/generate_revision_outputs.R")

message("== Done. See outputs/figures and outputs/tables ==")
