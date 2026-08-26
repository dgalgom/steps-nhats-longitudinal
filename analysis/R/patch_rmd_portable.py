#!/usr/bin/env python3
"""Make the analysis Rmd portable & repo-relative.
Applies:
 1. Portable data path (raw -> synthetic fallback) in place of read_csv("df.csv").
 2. figures/tables output subdirs + a ggsave wrapper that routes EVERY figure to
    outputs/figures by basename (fixes absolute paths, walk/ subdir, bare names).
 3. Rewrites print(<doc>, target = <expr>) to route all table .docx to outputs/tables.
 4. Routes readRDS model paths through out_dir.
Idempotent-ish: bails if the portability marker is already present.
"""
import re, sys

RMD = "/Users/danielgallardogomez/Downloads/steps-nhats-longitudinal/analysis/longitudinal_all3.Rmd"
src = open(RMD, encoding="utf-8").read()

if "PORTABILITY SHIM (repo)" in src:
    print("already patched; nothing to do"); sys.exit(0)

# --- 1 & 2: insert portability shim right after the out_dir block ------------
anchor = 'out_dir <- "outputs"\nif (!dir.exists(out_dir)) {\n  dir.create(out_dir, recursive = TRUE)\n}'
shim = anchor + '''

# ---------------------------------------------------------------------------
# PORTABILITY SHIM (repo) -- makes all paths repo-relative & machine-independent
# ---------------------------------------------------------------------------
# Output subdirectories
fig_dir <- file.path(out_dir, "figures")
tab_dir <- file.path(out_dir, "tables")
for (d in c(fig_dir, tab_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# Route EVERY ggsave() to outputs/figures by basename, regardless of the path
# written in the original call (absolute paths, "walk/..", bare names all work).
if (!isTRUE(getOption("repo_ggsave_wrapped"))) {
  .orig_ggsave <- ggplot2::ggsave
  ggsave <- function(filename, ...) .orig_ggsave(file.path(fig_dir, basename(filename)), ...)
  options(repo_ggsave_wrapped = TRUE)
}

# Portable data path: env DATA_PATH > data/raw/df.csv > data/synthetic/df_synthetic.csv
resolve_data_path <- function() {
  cand <- c(Sys.getenv("DATA_PATH", unset = NA),
            "../data/raw/df.csv", "data/raw/df.csv", "df.csv",
            "../data/synthetic/df_synthetic.csv", "data/synthetic/df_synthetic.csv")
  cand <- cand[!is.na(cand)]
  hit <- cand[file.exists(cand)]
  if (length(hit) == 0)
    stop("No data file found. Place the NHATS-derived df.csv in data/raw/ (see data/raw/README.md) or generate the synthetic sample.")
  if (grepl("synthetic", hit[1]))
    message("NOTE: using SYNTHETIC sample data (", hit[1], "). Results are illustrative only, not the published estimates.")
  hit[1]
}
'''
assert anchor in src, "out_dir anchor not found"
src = src.replace(anchor, shim, 1)

# --- data read line ---------------------------------------------------------
src = src.replace('df <- read_csv("df.csv", show_col_types = FALSE)',
                  'df <- read_csv(resolve_data_path(), show_col_types = FALSE)', 1)

# --- 3: route all table print(doc, target = EXPR) to tab_dir by basename -----
# matches: print(<var>, target = <expr up to the matching close paren of print>)
def route_print(m):
    var, expr = m.group(1), m.group(2).strip()
    return f'print({var}, target = file.path(tab_dir, basename({expr})))'
# expr must not itself contain an unbalanced ')'; targets here are simple file.path(...) or "..."/var
src = re.sub(r'print\((\w+),\s*target\s*=\s*((?:file\.path\([^()]*\)|"[^"]*"|[A-Za-z_][\w.]*))\)',
             route_print, src)

# --- 4: readRDS model paths through out_dir ---------------------------------
src = re.sub(r'readRDS\(paste0\(getwd\(\),\s*"/outputs/([^"]+)"\)\)',
             r'readRDS(file.path(out_dir, "\1"))', src)

open(RMD, "w", encoding="utf-8").write(src)

# report
import subprocess
n_abs = len(re.findall(r'"/Users/jesusdelpozocruz', src))
print("patched OK")
print("  remaining absolute-path literals to author machine:", n_abs, "(ggsave wrapper neutralizes figure ones by basename)")
print("  print->tab_dir rewrites:", len(re.findall(r'target = file\.path\(tab_dir', src)))
print("  readRDS->out_dir rewrites:", len(re.findall(r'readRDS\(file\.path\(out_dir', src)))
