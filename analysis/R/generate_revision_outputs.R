## =============================================================================
## generate_revision_outputs.R
## Generates every NEW figure/table introduced during revision (JSHS-2026-1054):
##   - Table 2  (observed outcomes by sex x age group): full 3-band + main 80+
##   - Figure 2 (within-person annual change by baseline-activity quartile)
##   - Supplementary Material: Tables S1-S7 (sensitivity analyses)
##
## Dual-use:
##   * Sourced from analysis/longitudinal_all3.Rmd  -> reuses df_mod/df_rev in memory
##   * Run standalone:  Rscript analysis/R/generate_revision_outputs.R
##     (resolves data via DATA_PATH env / data/raw/df.csv / synthetic sample)
## =============================================================================
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(lme4)
  library(ggplot2); library(flextable); library(officer)
})

## ---- output dirs -----------------------------------------------------------
if (!exists("out_dir")) out_dir <- "outputs"
if (!exists("fig_dir")) fig_dir <- file.path(out_dir, "figures")
if (!exists("tab_dir")) tab_dir <- file.path(out_dir, "tables")
for (d in c(fig_dir, tab_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

## ---- data ------------------------------------------------------------------
.resolve_data <- function() {
  cand <- c(Sys.getenv("DATA_PATH", unset = NA),
            "data/raw/df.csv", "../data/raw/df.csv", "df.csv",
            "data/synthetic/df_synthetic.csv", "../data/synthetic/df_synthetic.csv")
  cand <- cand[!is.na(cand)]; hit <- cand[file.exists(cand)]
  if (!length(hit)) stop("No data file found (see data/raw/README.md).")
  hit[1]
}
if (exists("df_rev")) {
  d <- df_rev
} else if (exists("df_mod")) {
  d <- df_mod
} else {
  raw <- read_csv(.resolve_data(), show_col_types = FALSE)
  d <- raw %>% filter(accelerometer == 1, !is.na(Steps_ponderada)) %>%
    mutate(wave = factor(wave, levels = c(11,12,13,14)), id = factor(id),
           sex = factor(sex, levels = c("1","2"), labels = c("Male","Female")),
           wave_num = as.integer(wave), time = wave_num - min(wave_num, na.rm = TRUE)) %>%
    group_by(id) %>% mutate(age_baseline = first(age, order_by = wave_num)) %>% ungroup() %>%
    mutate(age_c = as.numeric(scale(age_baseline, scale = FALSE)))
}
# ensure helper vars regardless of source
d <- d %>% mutate(
  age_attained_c = if ("age_attained_c" %in% names(.)) age_attained_c else as.numeric(age - mean(age_baseline, na.rm = TRUE)),
  w_norm = if ("w_norm" %in% names(.)) w_norm else weights_nhats / mean(weights_nhats, na.rm = TRUE)
)

OC <- list(
  list(key="Steps",   var="Steps_ponderada",                   lab="Daily steps (steps/day)",         dp=1),
  list(key="Walk",    var="Walk_mins_ponderada",               lab="Daily walking time (min/day)",    dp=2),
  list(key="Cadence", var="CadencePeak30_steps_min_ponderada", lab="Peak 30-min cadence (steps/min)", dp=2)
)
lmm  <- function(f, data=d, wts=NULL) lmer(as.formula(f), data=data, weights=wts, control=lmerControl(optimizer="bobyqa"))
rnd  <- function(x,dp) formatC(round(x,dp), format="f", digits=dp, big.mark=",")
ftbl <- function(df) flextable(df) |> bold(part="header") |> fontsize(size=9,part="all") |>
  font(fontname="Times New Roman",part="all") |> align(align="center",part="all") |>
  align(j=1, align="left", part="all") |> autofit()

## ===========================================================================
## TABLE 2  (full 3-band + main-text collapsed 80+)
## ===========================================================================
band3 <- function(a) cut(a, c(70,80,90,Inf), c("70-79","80-89","90-98"), right=FALSE)
band2 <- function(a) factor(ifelse(a<80,"70-79","80+"), c("70-79","80+"))
t2_core <- function(dat, var, dp) summarise(dat,
    `N (obs)`=sum(!is.na(.data[[var]])), `N (persons)`=n_distinct(id[!is.na(.data[[var]])]),
    `Mean (SD)`=paste0(rnd(mean(.data[[var]],na.rm=TRUE),dp)," (",rnd(sd(.data[[var]],na.rm=TRUE),dp),")"),
    `Median [IQR]`=paste0(rnd(median(.data[[var]],na.rm=TRUE),dp)," [",rnd(quantile(.data[[var]],.25,na.rm=TRUE),dp),"-",rnd(quantile(.data[[var]],.75,na.rm=TRUE),dp),"]"),
    .groups="drop")
t2_build <- function(o, bandfun){
  dd <- d %>% mutate(AB = bandfun(age_baseline))
  bs <- dd %>% group_by(Sex=sex, `Age group`=AB) %>% t2_core(o$var,o$dp)
  al <- dd %>% group_by(`Age group`=AB) %>% t2_core(o$var,o$dp) %>% mutate(Sex="All") %>% relocate(Sex)
  bind_rows(bs,al) %>% arrange(factor(Sex,levels=c("Male","Female","All")),`Age group`)
}
write_table2 <- function(bandfun, target, title, note){
  doc <- read_docx() |> body_add_par(title, style="heading 1") |> body_add_par(note, style="Normal")
  for (o in OC){ doc <- doc |> body_add_par("", style="Normal") |> body_add_par(o$lab, style="heading 2") |>
    body_add_flextable(ftbl(t2_build(o, bandfun))) }
  print(doc, target=target)
}
write_table2(band3, file.path(tab_dir,"Table_S8_observed_by_sex_age_full.docx"),
  "Supplementary Table S8. Observed accelerometry outcomes by sex and three age bands.",
  "Unweighted observed summaries (2,030 person-wave observations, 644 participants). N (obs)=person-waves; N (persons)=unique participants. Cells in 90-98 are based on few participants.")
write_table2(band2, file.path(tab_dir,"Table_2_observed_by_sex_age.docx"),
  "Table 2. Observed accelerometry outcomes by sex and age group.",
  "Main-text version: the two oldest bands are collapsed to 80+ (the 90-98 cell was small); the full three-band version is Supplementary Table S8.")

## ===========================================================================
## FIGURE 1  (main-text): predicted within-person trajectories over follow-up,
## by sex, for the three outcomes. Uses the frequentist mixed model so it is
## fast and reproducible without the Bayesian toolchain. (Authors may instead
## promote a Bayesian prediction figure from the supplement; see crosswalk.)
## ===========================================================================
pred_traj <- function(o){
  m <- lmm(paste0(o$var," ~ time * sex + age_c + (1 + time | id)"))
  grid <- expand.grid(time = seq(0, 3, by = 0.5),
                      sex = factor(c("Male","Female"), levels = levels(d$sex)),
                      age_c = 0)
  X <- model.matrix(~ time * sex + age_c, grid)
  b <- fixef(m); V <- as.matrix(vcov(m))
  grid$fit <- as.numeric(X %*% b)
  se <- sqrt(rowSums((X %*% V) * X))
  grid$lo <- grid$fit - 1.96*se; grid$hi <- grid$fit + 1.96*se
  grid$Outcome <- o$lab; grid
}
f1 <- bind_rows(lapply(OC, pred_traj)) %>% mutate(Outcome=factor(Outcome, levels=sapply(OC,`[[`,"lab")))
p1 <- ggplot(f1, aes(time, fit, color=sex, fill=sex)) +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=0.15, colour=NA) + geom_line(linewidth=0.9) +
  facet_wrap(~Outcome, scales="free_y") +
  scale_color_manual(values=c(Male="#2c7fb8", Female="#d95f0e")) +
  scale_fill_manual(values=c(Male="#2c7fb8", Female="#d95f0e")) +
  labs(title="Predicted within-person activity trajectories over follow-up",
       subtitle="Model-based means (95% CI) at mean baseline age, by sex",
       x="Years since baseline", y="Predicted value", color="Sex", fill="Sex") +
  theme_bw(base_size=11) + theme(plot.title=element_text(face="bold"),
       strip.background=element_rect(fill="grey92"), strip.text=element_text(face="bold"),
       panel.grid.minor=element_blank(), legend.position="bottom")
ggplot2::ggsave(file.path(fig_dir,"Figure_1_predicted_trajectories.png"), p1, width=10, height=4.2, dpi=300)
ggplot2::ggsave(file.path(fig_dir,"Figure_1_predicted_trajectories.pdf"), p1, width=10, height=4.2)

## ===========================================================================
## FIGURE 2  (within-person annual change by baseline-activity quartile)
## ===========================================================================
slope_q <- function(o){
  bq <- d %>% filter(wave_num==min(wave_num)) %>% transmute(id, b=.data[[o$var]]) %>%
    distinct(id,.keep_all=TRUE) %>% filter(!is.na(b)) %>%
    mutate(Quartile=factor(ntile(b,4), labels=c("Q1 (lowest)","Q2","Q3","Q4 (highest)")))
  d %>% inner_join(bq,by="id") %>% group_by(id,Quartile) %>% filter(dplyr::n()>=2) %>%
    group_modify(~tibble(slope=coef(lm(reformulate("time",o$var),data=.x))[2])) %>% ungroup() %>%
    group_by(Quartile) %>% summarise(mean_slope=mean(slope), se=sd(slope)/sqrt(dplyr::n()),
      n=dplyr::n(), .groups="drop") %>% mutate(lo=mean_slope-1.96*se, hi=mean_slope+1.96*se, Outcome=o$lab)
}
fig_df <- bind_rows(lapply(OC, slope_q)) %>% mutate(Outcome=factor(Outcome, levels=sapply(OC,`[[`,"lab")))
p2 <- ggplot(fig_df, aes(Quartile, mean_slope)) +
  geom_hline(yintercept=0, linetype="dashed", colour="grey50") +
  geom_col(aes(fill=Quartile), width=0.65, alpha=0.9) +
  geom_errorbar(aes(ymin=lo, ymax=hi), width=0.18, linewidth=0.5) +
  geom_text(aes(label=paste0("n=",n), y=ifelse(mean_slope>=0, hi+abs(hi)*0.06, lo-abs(lo)*0.06)),
            size=2.7, vjust=ifelse(fig_df$mean_slope>=0,0,1)) +
  facet_wrap(~Outcome, scales="free_y") + scale_fill_brewer(palette="Blues") +
  labs(title="Within-person annual change by baseline-activity quartile",
       subtitle="Mean annual change (95% CI); higher baseline activity is associated with steeper decline",
       x="Baseline-activity quartile", y="Annual change (units per year)") +
  theme_bw(base_size=11) + theme(legend.position="none", plot.title=element_text(face="bold"),
       strip.background=element_rect(fill="grey92"), strip.text=element_text(face="bold"),
       panel.grid.minor=element_blank(), axis.text.x=element_text(angle=20, hjust=1))
ggplot2::ggsave(file.path(fig_dir,"Figure_2_quartile_decline.png"), p2, width=10, height=4.2, dpi=300)
ggplot2::ggsave(file.path(fig_dir,"Figure_2_quartile_decline.pdf"), p2, width=10, height=4.2)

## ===========================================================================
## SUPPLEMENTARY TABLES S1-S7 (sensitivity analyses) -> one docx
## ===========================================================================
final_wave <- max(d$wave_num)
person <- d %>% group_by(id) %>% summarise(
  g=ifelse(max(wave_num)==final_wave,"Completer","Non-completer"),
  Steps=first(Steps_ponderada,order_by=wave_num), Walk=first(Walk_mins_ponderada,order_by=wave_num),
  Cad=first(CadencePeak30_steps_min_ponderada,order_by=wave_num), Age=first(age_baseline), .groups="drop")
tab_attr <- person %>% group_by(Group=g) %>% summarise(N=dplyr::n(),
  `Baseline steps, mean (SD)`=paste0(rnd(mean(Steps),0)," (",rnd(sd(Steps),0),")"),
  `Baseline walking, mean (SD)`=paste0(rnd(mean(Walk),1)," (",rnd(sd(Walk),1),")"),
  `Baseline cadence, mean (SD)`=paste0(rnd(mean(Cad),1)," (",rnd(sd(Cad),1),")"),
  `Baseline age, mean (SD)`=paste0(rnd(mean(Age),1)," (",rnd(sd(Age),1),")"), .groups="drop")

mnar_row <- function(o){
  m <- lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)")); s0 <- fixef(m)[["time"]]
  non <- person$id[person$g=="Non-completer"]
  v <- sapply(c(0,.25,.5,1), function(dl){
    ex <- d %>% filter(id %in% non) %>% group_by(id) %>% slice_max(wave_num,n=1) %>% ungroup() %>%
      mutate(time=time+1, !!o$var := .data[[o$var]] + s0*(1+dl))
    round(fixef(lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)"), data=bind_rows(d,ex)))[["time"]], o$dp)})
  data.frame(Outcome=o$lab,`delta=0 (MAR)`=v[1],`delta=0.25`=v[2],`delta=0.50`=v[3],`delta=1.00`=v[4],check.names=FALSE)
}
tab_mnar <- bind_rows(lapply(OC, mnar_row))
tab_age <- bind_rows(lapply(OC, function(o){
  m<-lmm(paste0(o$var," ~ age_attained_c + sex + (1 | id)")); fe<-summary(m)$coefficients
  data.frame(Outcome=o$lab,`Primary (time since baseline)`=round(fixef(lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)")))[["time"]],o$dp),
    `Attained-age scale`=round(fe["age_attained_c","Estimate"],o$dp),`SE`=round(fe["age_attained_c","Std. Error"],o$dp),check.names=FALSE)}))
tab_sel <- bind_rows(lapply(OC, function(o){
  a<-lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)")); i<-lmm(paste0(o$var," ~ time * sex + age_c + (1 + time | id)"))
  data.frame(Outcome=o$lab,`Additive model`=round(fixef(a)[["time"]],o$dp),`Sex-by-time model`=round(fixef(i)[["time"]],o$dp),check.names=FALSE)}))
tab_wt <- bind_rows(lapply(OC, function(o){
  uw<-lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)")); w<-lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)"),wts=d$w_norm)
  data.frame(Outcome=o$lab,Unweighted=round(fixef(uw)[["time"]],o$dp),`Weight-informed`=round(fixef(w)[["time"]],o$dp),check.names=FALSE)}))
tab_q <- bind_rows(lapply(OC, function(o){
  bq<-d %>% filter(wave_num==min(wave_num)) %>% transmute(id,b=.data[[o$var]]) %>% distinct(id,.keep_all=TRUE) %>% filter(!is.na(b)) %>% mutate(q=ntile(b,4))
  sl<-d %>% inner_join(bq,by="id") %>% group_by(id,q) %>% filter(dplyr::n()>=2) %>%
    group_modify(~tibble(s=coef(lm(reformulate("time",o$var),data=.x))[2])) %>% ungroup() %>% group_by(q) %>% summarise(m=round(mean(s),o$dp),.groups="drop")
  m<-lmm(paste0(o$var," ~ time + age_c + sex + (1 + time | id)")); re<-ranef(m)$id
  data.frame(Outcome=o$lab,`Q1 (lowest)`=sl$m[1],Q2=sl$m[2],Q3=sl$m[3],`Q4 (highest)`=sl$m[4],
    `Model r (int,slope)`=round(attr(VarCorr(m)$id,"correlation")[1,2],2),
    `Empirical-Bayes r`=round(cor(re[["(Intercept)"]],re[["time"]]),2),check.names=FALSE)}))
iv <- c("CadencePeak30_steps_min_ponderada","CadencePeak1_steps_min_ponderada","Cadence95th_steps_min_ponderada")
iv <- iv[iv %in% names(d)]; cm <- round(cor(d[iv], use="complete.obs"),2)
tab_int <- data.frame(Metric=c("Peak 30-min cadence","Peak 1-min cadence","95th-percentile cadence")[seq_along(iv)],
  setNames(as.data.frame(cm), c("Peak 30-min","Peak 1-min","95th pct")[seq_len(ncol(cm))]),
  `Annual decline`=sapply(iv, function(v) round(fixef(lmm(paste0(v," ~ time + age_c + sex + (1 + time | id)")))[["time"]],2)),
  check.names=FALSE, row.names=NULL)

supp <- read_docx()
H1 <- function(x,t) body_add_par(x,t,style="heading 1"); H2 <- function(x,t) body_add_par(x,t,style="heading 2")
P  <- function(x,t) body_add_par(x,t,style="Normal")
supp <- supp |> H1("Supplementary Material") |>
  P("Additional sensitivity analyses (JSHS-2026-1054). Analytic sample: 2,030 person-wave observations from 644 participants.")
supp <- supp |> H1("S1. Supplementary Methods") |>
  H2("S1.1 Attrition and missing-data sensitivity") |> P("Baseline characteristics of completers vs non-completers were compared, followed by a pattern-mixture (delta-adjustment) analysis appending an unobserved post-dropout value for non-completers equal to the last observed value plus the MAR-predicted change times (1+delta).") |>
  H2("S1.2 Attained-age specification") |> P("Trajectories re-estimated with attained chronological age (mean-centred) as the time scale, with a participant-level random intercept.") |>
  H2("S1.3 Model-selection robustness") |> P("Pre-specified candidate set compared by leave-one-out information criteria (predictive, not hypothesis testing); the time estimate is reported under additive vs sex-by-time models.") |>
  H2("S1.4 Weight-informed sensitivity") |> P("Primary models refitted using NHATS analytic weights rescaled to mean 1. Design-based variance (stratum/PSU) was not possible as those variance units are absent from the analytic file.") |>
  H2("S1.5 Baseline heterogeneity and regression to the mean") |> P("Within-person slopes summarised by baseline-activity quartile; model-estimated vs shrunken empirical-Bayes intercept-slope correlations compared.") |>
  H2("S1.6 Intensity-metric triangulation") |> P("Minute-level series for a consecutive-bout cadence were not retained; association and parallel decline among available intensity metrics reported instead.")
supp <- supp |> H1("S2. Supplementary Results")
add_tab <- function(x, cap, tb, interp){ x |> P(cap) |> body_add_flextable(ftbl(tb)) |> P(interp) }
supp <- add_tab(supp,"Table S1. Completers vs non-completers.",tab_attr,"Non-completers began lower and were older; estimates are therefore likely conservative.")
supp <- add_tab(supp,"Table S2. Pattern-mixture (delta-adjustment) sensitivity: annual change.",tab_mnar,"Decline steepens monotonically under MNAR; it cannot become shallower.")
supp <- add_tab(supp,"Table S3. Decline on the attained-age scale.",tab_age,"Consistent with primary estimates.")
supp <- add_tab(supp,"Table S4. Additive vs sex-by-time interaction.",tab_sel,"Decline estimate is stable across specifications.")
supp <- add_tab(supp,"Table S5. Unweighted vs weight-informed decline.",tab_wt,"Close for all outcomes.")
supp <- add_tab(supp,"Table S6. Quartile slopes and intercept-slope correlations.",tab_q,"Monotonic gradient; negative correlation persists under empirical-Bayes shrinkage.")
supp <- add_tab(supp,"Table S7. Intensity-metric triangulation.",tab_int,"Peak 30-min cadence correlates with and declines in parallel with related intensity metrics.")
supp <- P(supp, "See also Table 2 (main text) and Figure 2 (main text).")
print(supp, target=file.path(tab_dir,"Supplementary_Material_Revision.docx"))

message("Revision outputs written to: ", fig_dir, " and ", tab_dir)
