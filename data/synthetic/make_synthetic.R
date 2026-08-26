## Generate a SMALL synthetic dataset mimicking the structure of df.csv so the
## pipeline runs end-to-end WITHOUT the restricted NHATS data.
## The values are random and DO NOT reproduce the published estimates.
suppressPackageStartupMessages({library(dplyr); library(readr)})
set.seed(2026)

n_id <- 150
waves <- 11:14
base_age <- round(runif(n_id, 71, 96), 0)
sex <- sample(1:2, n_id, replace = TRUE, prob = c(.47, .53))

rows <- lapply(seq_len(n_id), function(i){
  # each person present in wave 11, then drops out with some probability
  keep <- c(TRUE, cumprod(runif(3) > 0.20) > 0)
  w <- waves[keep]
  t <- w - 11
  b_steps <- rnorm(1, 6200 - 120*(base_age[i]-78) - 500*(sex[i]==2), 1500)
  steps <- pmax(500, b_steps - 250*t + rnorm(length(w), 0, 700))
  walk  <- pmax(5,  (b_steps/70) - 3*t + rnorm(length(w), 0, 12))
  cad30 <- pmax(25, 70 - 1.1*(base_age[i]-78) - 3*(sex[i]==2) - 1.4*t + rnorm(length(w), 0, 8))
  data.frame(
    id = i, wave = w, age = base_age[i] + t, sex = sex[i],
    accelerometer = 1,
    weights_nhats = round(runif(1, 800, 40000)),
    Steps_ponderada = round(steps),
    Walk_mins_ponderada = round(walk, 1),
    CadencePeak30_steps_min_ponderada = round(cad30, 1),
    CadencePeak1_steps_min_ponderada  = round(cad30 + rnorm(length(w), 8, 4), 1),
    Cadence95th_steps_min_ponderada   = round(cad30 + rnorm(length(w), 4, 3), 1),
    sisindex = sample(0:6, length(w), replace = TRUE),
    res = sample(1:2, length(w), replace = TRUE, prob = c(.9,.1)),
    income = sample(1:5, length(w), replace = TRUE),
    frailty_category = sample(0:2, length(w), replace = TRUE, prob = c(.5,.35,.15)),
    bmi = round(rnorm(length(w), 27, 4), 1),
    mort_status = 0
  )
})
df <- bind_rows(rows)
# Always write to data/synthetic/ relative to the repo root (the working dir
# when run via `Rscript data/synthetic/make_synthetic.R` or sourced by run_all.R)
out <- "data/synthetic/df_synthetic.csv"
if (!dir.exists(dirname(out))) dir.create(dirname(out), recursive = TRUE)
write_csv(df, out)
cat("wrote", out, "with", nrow(df), "rows,", length(unique(df$id)), "ids\n")
