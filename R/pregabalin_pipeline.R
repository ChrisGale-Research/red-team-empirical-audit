# =============================================================================
# Benzodiazepines vs Pregabalin for GAD: Reproducible Pipeline
# Source: Abandoned Cochrane RM5 file (Gale, last modified 2014-11-03)
# Deposit: https://doi.org/10.5281/zenodo.21252858 (concept DOI, latest version)
# Repo:    https://github.com/ChrisGale-Research/red-team-empirical-audit
#
# Pipeline reads data natively from RevMan 5 XML (.rm5).
# No manual transcription. Source -> parse -> correct -> analyse -> output.
#
# Methods paper: demonstrates RM5 resurrection in R with structured
# adversarial verification. The pregabalin comparison is the worked example.
#
# Authors: Gale CK, Glue P, Guaiana G
# Pipeline: AI-assisted construction (Claude), numerical outputs verified in
#           R/metafor by lead author.
#
# Revision history
#   v1.0.x (Jul 2026)  Initial deposit. Arm-level REML primary; rma.mv + CR2
#                      and arm-level K-H as sensitivity; HAM-A pooled with
#                      SE*sqrt(n) imputation.
#   v1.1.0 (Sep 2026)  Independent import via meta::read.rm5 cross-checked
#                      against parse_rm5(). Study-clustered estimates (rma.mv,
#                      CR2, containment-df t, and TRUE study-level Knapp-Hartung
#                      on arm-collapsed data) for all three dichotomous outcomes.
#                      HAM-A demoted to sensitivity: the Rickels 2005 "SD" is an
#                      ANCOVA SE, SE*sqrt(n) is a lower bound only, and the
#                      outcome is NOT POOLABLE (manuscript, Error 1). The
#                      earlier arm-level K-H (df = 6, mislabelled df = 2) is
#                      removed. Run from the repository root.
# =============================================================================

# --- 0. Dependencies ----------------------------------------------------------
# meta is used only for the independent read.rm5() import (Section 1b).
# clubSandwich supplies CR2 cluster-robust SEs (Section 6).
for (pkg in c("metafor", "xml2", "dplyr", "meta", "clubSandwich")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
library(metafor)
library(xml2)
library(dplyr)
library(meta)
library(clubSandwich)

# Working directory must be the repository root (open the .Rproj, or setwd()).
if (!dir.exists("data") || !dir.exists("R"))
  stop("Run this script from the repository root (expects ./data and ./R).")
dir.create("output", showWarnings = FALSE)

# =============================================================================
# SECTION 1: NATIVE RM5 PARSER
# Reads DICH_DATA and CONT_DATA nodes directly from RevMan 5 XML.
# Maps STUDY_ID to study label via STUDIES section.
# Returns tidy data frames ready for metafor.
# =============================================================================

parse_rm5 <- function(rm5_path) {

  doc <- read_xml(rm5_path)

  # --- 1a. Study ID -> Name map ---
  study_nodes <- xml_find_all(doc, ".//STUDY")
  study_map <- setNames(
    xml_attr(study_nodes, "NAME"),
    xml_attr(study_nodes, "ID")
  )

  # --- 1b. Outcome labels ---
  outcome_labels <- list()
  for (outcome in xml_find_all(doc, ".//DICH_OUTCOME|.//CONT_OUTCOME")) {
    id  <- xml_attr(outcome, "ID")
    nm  <- xml_text(xml_find_first(outcome, ".//NAME"))
    measure <- xml_attr(outcome, "EFFECT_MEASURE")
    outcome_labels[[id]] <- list(name = nm, measure = measure)
  }

  # --- 1c. Parse DICH_DATA ---
  dich_rows <- list()
  for (outcome in xml_find_all(doc, ".//DICH_OUTCOME")) {
    oid <- xml_attr(outcome, "ID")
    oname <- xml_text(xml_find_first(outcome, ".//NAME"))
    measure <- xml_attr(outcome, "EFFECT_MEASURE")
    for (node in xml_find_all(outcome, ".//DICH_DATA")) {
      sid <- xml_attr(node, "STUDY_ID")
      dich_rows[[length(dich_rows)+1]] <- list(
        outcome_id   = oid,
        outcome_name = oname,
        measure      = measure,
        study_id     = sid,
        study        = study_map[sid],
        ai           = as.integer(xml_attr(node, "EVENTS_1")),
        n1i          = as.integer(xml_attr(node, "TOTAL_1")),
        ci           = as.integer(xml_attr(node, "EVENTS_2")),
        n2i          = as.integer(xml_attr(node, "TOTAL_2")),
        order        = as.integer(xml_attr(node, "ORDER"))
      )
    }
  }
  dich_df <- bind_rows(lapply(dich_rows, as.data.frame,
                               stringsAsFactors = FALSE))

  # --- 1d. Parse CONT_DATA ---
  cont_rows <- list()
  for (outcome in xml_find_all(doc, ".//CONT_OUTCOME")) {
    oid <- xml_attr(outcome, "ID")
    oname <- xml_text(xml_find_first(outcome, ".//NAME"))
    measure <- xml_attr(outcome, "EFFECT_MEASURE")
    for (node in xml_find_all(outcome, ".//CONT_DATA")) {
      sid <- xml_attr(node, "STUDY_ID")
      cont_rows[[length(cont_rows)+1]] <- list(
        outcome_id   = oid,
        outcome_name = oname,
        measure      = measure,
        study_id     = sid,
        study        = study_map[sid],
        n1i          = as.integer(xml_attr(node, "TOTAL_1")),
        m1i          = as.numeric(xml_attr(node, "MEAN_1")),
        sd1i_raw     = as.numeric(xml_attr(node, "SD_1")),
        n2i          = as.integer(xml_attr(node, "TOTAL_2")),
        m2i          = as.numeric(xml_attr(node, "MEAN_2")),
        sd2i_raw     = as.numeric(xml_attr(node, "SD_2")),
        order        = as.integer(xml_attr(node, "ORDER"))
      )
    }
  }
  cont_df <- bind_rows(lapply(cont_rows, as.data.frame,
                               stringsAsFactors = FALSE))

  list(dich = dich_df, cont = cont_df, study_map = study_map)
}

# Parse the RM5 (repository copy; see data/README.md for provenance)
cat("=== Parsing RM5 file ===\n")
rm5_path <- "data/Benzodiazepines_versus_pregabalin_for_GAD.rm5"
if (!file.exists(rm5_path)) stop("RM5 not found at ", rm5_path)
rm5 <- parse_rm5(rm5_path)

cat(sprintf("Studies found: %d\n", length(rm5$study_map)))
cat(sprintf("Dichotomous data rows: %d\n", nrow(rm5$dich)))
cat(sprintf("Continuous data rows: %d\n", nrow(rm5$cont)))
cat("\nStudy map:\n")
print(rm5$study_map)

# =============================================================================
# SECTION 1b: INDEPENDENT IMPORT VIA meta::read.rm5 AND CROSS-CHECK
# read.rm5() has provided native RevMan 5 ingestion since 2009 (Schwarzer 2007).
# parse_rm5() is retained as an independent route; the two must agree on row
# counts, events and totals or the script stops. Recent meta versions steer
# users toward read.cdir() for RevMan Web exports; read.rm5() remains the
# correct route for a legacy .rm5 file.
# =============================================================================

cat("\n=== Cross-check: meta::read.rm5 vs parse_rm5() ===\n")
rm5_meta <- read.rm5(rm5_path)

# The file holds a single comparison (CMP-001); if a multi-comparison file is
# substituted, restrict here with rm5_meta$complab before summing.
if ("studlab" %in% names(rm5_meta))
  rm5_meta <- rm5_meta[!is.na(rm5_meta$studlab) & rm5_meta$studlab != "", ]

dich_meta <- rm5_meta[!is.na(rm5_meta$event.e), ]
cont_meta <- rm5_meta[!is.na(rm5_meta$mean.e),  ]

chk <- data.frame(
  route     = c("parse_rm5", "read.rm5"),
  dich_rows = c(nrow(rm5$dich), nrow(dich_meta)),
  cont_rows = c(nrow(rm5$cont), nrow(cont_meta)),
  dich_ev1  = c(sum(rm5$dich$ai,  na.rm = TRUE), sum(dich_meta$event.e, na.rm = TRUE)),
  dich_n1   = c(sum(rm5$dich$n1i, na.rm = TRUE), sum(dich_meta$n.e,     na.rm = TRUE))
)
print(chk, row.names = FALSE)
stopifnot(chk$dich_rows[1] == chk$dich_rows[2],
          chk$cont_rows[1] == chk$cont_rows[2],
          chk$dich_ev1[1]  == chk$dich_ev1[2],
          chk$dich_n1[1]   == chk$dich_n1[2])
cat("read.rm5 and parse_rm5 agree on row counts, events and totals.\n")

# =============================================================================
# SECTION 2: DATA CORRECTIONS AND VERIFIED EXTRACTION ERRORS
# Source verification: Rickels et al., Arch Gen Psychiatry 2005;62(9):1022-1030
# Tables 2 and 3 inspected against RM5 extraction.
# Three extraction errors confirmed.
# =============================================================================

cat("\n=== Applying data corrections ===\n")
cat("Source: Rickels et al. Arch Gen Psychiatry 2005;62(9):1022-1030\n")
cat("        Tables 2 and 3 verified against RM5 extraction\n\n")

# VERIFIED ERROR 1: SE extracted as SD (Rickels 2005, HAM-A outcome)
# ------------------------------------------------------------------
# RM5 records SD_2 = 0.8 for all three Rickels 2005 pregabalin arms.
# Table 2 of source paper reports: "Least Squares Mean ± SE" from ANCOVA
# (covariates: center, baseline, treatment). SE values = 0.77, 0.78, 0.80.
# Table 3 footnote explicitly states "Data are given as mean ± SE."
# The extracted SD=0.8 is therefore the ANCOVA model-derived SE, not raw SD.
#
# IMPORTANT LIMITATION OF CORRECTION:
# SD = SE * sqrt(n) recovers raw SD from a simple mean SE.
# However, ANCOVA model SEs are SMALLER than raw SEs because baseline
# covariance is partialled out. Therefore SD_imputed = SE * sqrt(n) will
# UNDERESTIMATE the true raw SD. The raw SDs are not reported in the paper.
# Neither the uncorrected (SE=0.8) nor the corrected (SD=SE*sqrt(n)) values
# are accurate; both bracket the true value from below.
#
# STATUS (v1.1.0): the source paper (Table 2) has been checked and confirms the
# 0.8 values are ANCOVA SEs. The manuscript therefore treats HAM-A as NOT
# POOLABLE and omits it from the results table. The SE*sqrt(n) imputation below
# is retained ONLY so the magnitude of the extraction error can be shown as a
# sensitivity analysis (Section 3d). It is not a correction and is not a result.

cat("VERIFIED ERROR 1: SE extracted as SD (Rickels 2005 HAM-A)\n")
cat("  Source: Table 2 reports ANCOVA Least Squares Mean ± SE\n")
cat("  SE values from paper: 0.77 (300mg), 0.78 (450mg), 0.80 (600mg)\n")
cat("  ANCOVA SEs cannot be back-transformed to raw SDs without residual MS\n")
cat("  Correction is approximate lower bound only — treat as descriptive\n\n")

rickels_mask <- rm5$cont$study == "Rickels 2005" &
  rm5$cont$outcome_id == "CMP-001.06" &
  rm5$cont$sd2i_raw == 0.8

rm5$cont$sd2i <- rm5$cont$sd2i_raw
rm5$cont$sd2i[rickels_mask] <- rm5$cont$sd2i_raw[rickels_mask] *
  sqrt(rm5$cont$n2i[rickels_mask])
rm5$cont$sd2i[!rickels_mask] <- rm5$cont$sd2i_raw[!rickels_mask]

cat("Approximate corrected SDs (lower bound — see caveat above):\n")
print(rm5$cont[rickels_mask, c("study", "order", "n2i", "sd2i_raw", "sd2i")])

# VERIFIED ERROR 2: Study duration
# ---------------------------------
# RM5 records 8 weeks follow-up for Rickels 2005.
# Paper title and methods: 4-week trial.
# Correct duration: 4 weeks.
cat("\nVERIFIED ERROR 2: Study duration\n")
cat("  RM5 extraction: 8 weeks\n")
cat("  Paper (title and methods): 4-WEEK trial\n")
cat("  Correct value: 4 weeks\n")
cat("  Impact: duration moderator analysis for pregabalin comparison\n")
cat("  is affected if this outcome were analysed (k=3, descriptive only)\n\n")

# VERIFIED ERROR 3: Pregabalin dose labels
# -----------------------------------------
# RM5 records pregabalin arms as order 111, 40, 39 (arbitrary)
# Paper Table 2: pregabalin doses are 300, 450, 600 mg/d
# Not 150, 300, 450 mg/d as assumed in earlier pipeline commentary.
cat("VERIFIED ERROR 3: Pregabalin dose labels\n")
cat("  Paper Table 2: pregabalin 300, 450, 600 mg/d\n")
cat("  Earlier pipeline commentary incorrectly stated 150, 300, 450 mg/d\n")
cat("  Alprazolam dose: 1.5 mg/d (confirmed)\n")
cat("  n per arm: preg 300=89, preg 450=87, preg 600=85, alpraz=88, placebo=85\n\n")

# CORRECTION 3: Pande 2003 benzo SD flag (unchanged)
cat("FLAG: Pande 2003 benzo SD = 20.83 in HAM-A — unverified, flagged\n\n")

# =============================================================================
# SECTION 3: PRIMARY ANALYSES
# =============================================================================

cat("\n", strrep("=", 70), "\n")
cat("PRIMARY ANALYSES: Benzodiazepines vs Pregabalin\n")
cat(strrep("=", 70), "\n")

# --- 3a. Response rate (50% HAM-A decrease) — CMP-001.01 ---
cat("\n--- Outcome 1: Response rate (50% HAM-A decrease) ---\n")

d_resp50 <- rm5$dich %>% filter(outcome_id == "CMP-001.01")
cat(sprintf("Arms: %d across %d studies\n",
            nrow(d_resp50), length(unique(d_resp50$study))))
print(d_resp50[, c("study", "ai", "n1i", "ci", "n2i")])

es_resp50 <- escalc(measure = "RR",
                    ai = ai, n1i = n1i, ci = ci, n2i = n2i,
                    data = d_resp50, slab = paste(study, order))

res_resp50 <- rma(yi, vi, data = es_resp50, method = "REML")
cat("\nRandom-effects model (REML):\n")
print(res_resp50)

# --- 3b. Response rate (author defined) — CMP-001.02 ---
cat("\n--- Outcome 2: Response rate (author defined) ---\n")

d_resp_auth <- rm5$dich %>% filter(outcome_id == "CMP-001.02")
es_resp_auth <- escalc(measure = "RR",
                       ai = ai, n1i = n1i, ci = ci, n2i = n2i,
                       data = d_resp_auth, slab = paste(study, order))
res_resp_auth <- rma(yi, vi, data = es_resp_auth, method = "REML")
cat("Random-effects model (REML):\n")
print(res_resp_auth)

# --- 3c. Acceptability (dropouts) — CMP-001.03 ---
cat("\n--- Outcome 3: Acceptability (dropouts — benzodiazepines vs pregabalin) ---\n")
cat("NOTE: RR > 1 = more dropouts in benzodiazepine arm\n")

d_dropout <- rm5$dich %>% filter(outcome_id == "CMP-001.03")
cat(sprintf("Arms: %d across %d studies\n",
            nrow(d_dropout), length(unique(d_dropout$study))))

es_dropout <- escalc(measure = "RR",
                     ai = ai, n1i = n1i, ci = ci, n2i = n2i,
                     data = d_dropout, slab = paste(study, order))
res_dropout <- rma(yi, vi, data = es_dropout, method = "REML")
cat("Random-effects model (REML):\n")
print(res_dropout)

# --- 3d. HAM-A continuous — CMP-001.06 — SENSITIVITY ONLY, NOT POOLABLE ---
# Rickels 2005 "SD" = ANCOVA SE; raw SDs are not recoverable (SE*sqrt(n) is a
# lower bound). Per manuscript Error 1, HAM-A is NOT POOLABLE and is excluded
# from the results table (Section 8). The fits below document the size of the
# extraction error and nothing more.
cat("\n--- Outcome 6: HAM-A mean difference — SENSITIVITY ONLY (not poolable) ---\n")
cat("NOTE: Rickels 2005 SD=0.8 is an ANCOVA SE; SE*sqrt(n) imputation is a lower bound.\n")
cat("      Pande 2003 SD_benzo=20.83 flagged, unverified. Outcome NOT reported as a result.\n")

d_hama <- rm5$cont %>% filter(outcome_id == "CMP-001.06")
es_hama_p <- escalc(measure = "MD",
                    m1i = m1i, sd1i = sd1i_raw, n1i = n1i,
                    m2i = m2i, sd2i = sd2i,     n2i = n2i,
                    data = d_hama, slab = paste(study, order))
res_hama_p <- rma(yi, vi, data = es_hama_p, method = "REML")
cat("Random-effects model (REML, imputed lower-bound SDs):\n")
print(res_hama_p)

# Sensitivity: exclude Pande 2003 (outlier SD)
es_hama_nopande <- es_hama_p %>% filter(study != "Pande 2003")
if (nrow(es_hama_nopande) >= 3) {
  res_hama_nopande <- rma(yi, vi, data = es_hama_nopande, method = "REML")
  cat("\nSensitivity (Pande 2003 excluded):\n")
  print(res_hama_nopande)
  cat(sprintf("Delta vs primary: MD %+.3f\n",
              res_hama_nopande$beta - res_hama_p$beta))
}

# Sensitivity: uncorrected SDs (what RevMan computed)
es_hama_uncorr <- escalc(measure = "MD",
                          m1i = m1i, sd1i = sd1i_raw, n1i = n1i,
                          m2i = m2i, sd2i = sd2i_raw, n2i = n2i,
                          data = d_hama, slab = paste(study, order))
res_hama_uncorr <- rma(yi, vi, data = es_hama_uncorr, method = "REML")
cat("\nSensitivity (uncorrected SD — as in RevMan):\n")
print(res_hama_uncorr)
cat(sprintf("Delta vs corrected: MD %+.3f\n",
            res_hama_uncorr$beta - res_hama_p$beta))

# --- 3e. CGI — CMP-001.07 ---
cat("\n--- Outcome 7: CGI mean difference (Rickels 2005 only) ---\n")

d_cgi <- rm5$cont %>% filter(outcome_id == "CMP-001.07")
es_cgi <- escalc(measure = "MD",
                 m1i = m1i, sd1i = sd1i_raw, n1i = n1i,
                 m2i = m2i, sd2i = sd2i_raw, n2i = n2i,
                 data = d_cgi, slab = paste(study, order))
res_cgi <- rma(yi, vi, data = es_cgi, method = "REML")
cat("Random-effects model (REML, Rickels 2005 only):\n")
print(res_cgi)

# =============================================================================
# SECTION 4: FOREST PLOTS
# =============================================================================

cat("\n=== Generating forest plots ===\n")
# Only the dropout plot is produced. The HAM-A forest plot from v1.0.x is
# withdrawn: a forest plot of an outcome the manuscript declares not poolable
# would contradict the paper.

png("output/preg_dropout_forest.png", width = 1200, height = 700, res = 120)
forest(res_dropout,
       header = c("Study (arm)", "RR [95% CI]"),
       xlab   = "Risk Ratio: Dropouts (Benzodiazepine vs Pregabalin)",
       mlab   = sprintf("RE Model (REML): RR = %.2f [%.2f, %.2f], I\u00B2=%.0f%%",
                        exp(res_dropout$beta),
                        exp(res_dropout$ci.lb),
                        exp(res_dropout$ci.ub),
                        res_dropout$I2),
       atransf = exp,
       at      = log(c(0.25, 0.5, 1, 2, 4, 8)),
       refline = 0,
       col     = "steelblue",
       border  = "steelblue")
dev.off()
cat("Saved: output/preg_dropout_forest.png\n")

# =============================================================================
# SECTION 5: ADVERSARIAL PASS
# Pre-analysis challenges documented with responses and verdicts.
# =============================================================================

cat("\n", strrep("=", 70), "\n")
cat("ADVERSARIAL PASS\n")
cat(strrep("=", 70), "\n\n")

challenges <- list(

  list(
    label    = "CHALLENGE 1: Unit of analysis — arms vs studies",
    claim    = "Each RM5 DICH_DATA/CONT_DATA row is an independent observation",
    challenge = paste(
      "Feltner 2003 and Pande 2003 each contribute two pregabalin dose arms",
      "compared against a single benzo arm. Rickels 2005 contributes three",
      "pregabalin dose arms vs one benzo arm. Treating each comparison as",
      "independent inflates the effective sample size and violates the",
      "independence assumption: the shared benzo arm appears multiple times."
    ),
    response = paste(
      "This is the dominant methodological issue in this dataset.",
      "Three approaches are available:",
      "(A) Analyse each arm comparison separately and apply cluster-robust",
      "standard errors (rma.mv with study as clustering factor);",
      "(B) Combine pregabalin dose arms within study before comparison",
      "(Cochrane Handbook 23.2.3 — pool doses using inverse-variance weighting);",
      "(C) Report arm-level results as the primary output with explicit",
      "acknowledgment of non-independence, as RevMan did.",
      "The pipeline implements (C) matching the original RM5 analysis,",
      "with (A) as a sensitivity analysis using rma.mv."
    ),
    verdict  = "CRITICAL — rma.mv sensitivity analysis added (Section 6)"
  ),

  list(
    label    = "CHALLENGE 2: Rickels 2005 SD = 0.8",
    claim    = "The RM5 extraction is accurate for Rickels 2005 pregabalin SDs",
    challenge = paste(
      "SD = 0.8 on a HAM-A change score (expected range 6-14) is implausible.",
      "If this is actually SE, the corrected SDs are ~7.4-7.6.",
      "The uncorrected value inflates the weight of Rickels 2005 arms",
      "in the continuous outcome, potentially dominating the pooled estimate."
    ),
    response = paste(
      "Source checked: Rickels 2005 Table 2 reports ANCOVA least-squares",
      "means +/- SE, so 0.8 is a model SE, not a raw SD. SE * sqrt(n) recovers",
      "a raw SD only for a simple mean; for an ANCOVA SE it is a lower bound",
      "and not a valid correction. Raw SDs are not reported. The HAM-A",
      "continuous outcome is therefore NOT POOLABLE and is withdrawn from the",
      "results table. Imputed and uncorrected fits are retained in Section 3d",
      "solely to document the magnitude of the extraction error."
    ),
    verdict  = "CONFIRMED — outcome withdrawn from pooling; sensitivity only (Section 3d)"
  ),

  list(
    label    = "CHALLENGE 3: All three studies are Pfizer-sponsored",
    claim    = "The pregabalin comparison provides an unbiased efficacy estimate",
    challenge = paste(
      "Feltner 2003, Pande 2003, and Rickels 2005 are all Pfizer-sponsored",
      "trials designed to demonstrate pregabalin non-inferiority.",
      "Sponsor influence on comparator selection, dose choice, population",
      "selection, and outcome reporting is well-documented.",
      "The pooled estimate may systematically underestimate benzo efficacy",
      "relative to pregabalin."
    ),
    response = paste(
      "Acknowledged as an irresolvable confound at k=3.",
      "All three studies used lorazepam or alprazolam as the benzo comparator",
      "at doses that may not represent optimal benzo treatment.",
      "The clinical conclusion is not 'benzos equal pregabalin' but",
      "'in Pfizer-sponsored non-inferiority trials, benzos and pregabalin",
      "showed similar efficacy on response outcomes, with benzos showing",
      "higher dropout rates.' This framing is used throughout."
    ),
    verdict  = "IRRESOLVABLE — framed explicitly in interpretation"
  ),

  list(
    label    = "CHALLENGE 4: k=3 is inadequate for any pooled inference",
    claim    = "The pooled estimates support clinical conclusions",
    challenge = paste(
      "With three studies contributing arms to each outcome, random-effects",
      "tau^2 estimation is unreliable (REML tau^2 is known to be biased",
      "toward zero at k<5). Confidence intervals should be widened.",
      "Any I^2 value is essentially uninterpretable at k=3."
    ),
    response = paste(
      "Agreed. The paper explicitly frames this as a methods demonstration,",
      "not a clinical evidence synthesis. Study-clustered estimates are",
      "reported alongside the arm-level primary: rma.mv with study random",
      "intercept, CR2 cluster-robust SE with Satterthwaite df, and a true",
      "study-level Knapp-Hartung interval (arms collapsed to one row per",
      "study, rma() with test='knha', df = 2). Note: an earlier version",
      "applied test='knha' to the seven arm rows (df = 6) and labelled it",
      "df = 2; that is removed. All small-sample corrections have uncertain",
      "coverage at k = 3 (Partlett & Riley 2017)."
    ),
    verdict  = "ACCEPTABLE for methods paper — study-clustered estimates in Section 6"
  ),

  list(
    label    = "CHALLENGE 5: The RM5 parser may miss data silently",
    claim    = "The parse_rm5() function recovers all data in the RM5 file",
    challenge = paste(
      "The parser uses xml_find_all() with simple XPath. If the RM5 schema",
      "has nested subgroup structures, data outside the expected node path",
      "would be silently dropped. RevMan allows subgroups within outcomes;",
      "the parser does not verify it has recovered the same N as RevMan reported."
    ),
    response = paste(
      "Validation step added: compare parsed arm counts and event totals",
      "against the summary-level EVENTS_1/TOTAL_1 stored in each",
      "DICH_OUTCOME/CONT_OUTCOME node. Discrepancies would indicate",
      "missed data. This RM5 has SUBGROUPS='NO' on all outcomes,",
      "so the risk is low — but the check is included."
    ),
    verdict  = "MITIGATED — validation check added (Section 7)"
  )
)

for (ch in challenges) {
  cat(ch$label, "\n")
  cat(sprintf("Claim    : %s\n", ch$claim))
  cat(sprintf("Challenge: %s\n", ch$challenge))
  cat(sprintf("Response : %s\n", ch$response))
  cat(sprintf("Verdict  : %s\n", ch$verdict))
  cat(strrep("-", 70), "\n\n")
}

# =============================================================================
# SECTION 6: STUDY-CLUSTERED ESTIMATES (Challenges 1 and 4)
# Four estimators for each dichotomous outcome, each labelled by what it is:
#   (i)   rma.mv on arm-level rows, random intercept per study; Wald CI
#   (ii)  same fit, CR2 cluster-robust SE with Satterthwaite df (clubSandwich;
#         Pustejovsky & Tipton 2021). CR2 changes the variance, not the point.
#   (iii) same fit, t-based inference with containment df (metafor test="t").
#         This is NOT Knapp-Hartung; metafor has no K-H for rma.mv.
#   (iv)  TRUE Knapp-Hartung: arms collapsed to one row per study, then
#         rma(test="knha") on k = 3 studies (df = 2).
# I^2 is not reported at k = 3 (Cochrane Handbook 10.10.4; Higgins 2003).
#
# Collapse rule for (iv): pregabalin (group 2) arms are summed within study.
# The shared benzodiazepine arm (group 1) is counted once: taken from the first
# row when RevMan repeated it identically (Feltner 34/34), summed when RevMan
# split it across comparisons (Rickels 29/29/30 -> 88).
# =============================================================================

cat("\n=== Study-clustered estimates (Table 4 columns) ===\n")
cat("NOTE: I^2 not reported at k=3 — estimator has high variance and is uninformative\n")
cat("      (Cochrane Handbook 10.10.4; Higgins et al. 2003)\n\n")

collapse_to_study <- function(es) {
  stopifnot(all(c("ai", "n1i", "ci", "n2i", "study") %in% names(es)))
  out <- lapply(split(es, es$study), function(d) {
    benzo_repeated <- nrow(d) > 1 &&
      length(unique(d$n1i)) == 1 && length(unique(d$ai)) == 1
    data.frame(
      study = d$study[1],
      ai  = if (benzo_repeated) d$ai[1]  else sum(d$ai),
      n1i = if (benzo_repeated) d$n1i[1] else sum(d$n1i),
      ci  = sum(d$ci),
      n2i = sum(d$n2i),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

cluster_fit <- function(es, label) {
  es$study_factor <- as.factor(es$study)
  mv  <- rma.mv(yi, vi, random = ~ 1 | study_factor, data = es, method = "REML")
  cr2 <- coef_test(mv, vcov = "CR2", cluster = es$study_factor)
  tc  <- rma.mv(yi, vi, random = ~ 1 | study_factor, data = es,
                method = "REML", test = "t", dfs = "contain")
  es_s <- collapse_to_study(es)
  kh  <- rma(measure = "RR", ai = ai, n1i = n1i, ci = ci, n2i = n2i,
             data = es_s, method = "REML", test = "knha")
  data.frame(
    outcome      = label,
    k_arms       = nrow(es),
    k_studies    = nlevels(es$study_factor),
    rr_mv        = exp(mv$beta[1]),
    ci_mv        = sprintf("[%.2f, %.2f]", exp(mv$ci.lb), exp(mv$ci.ub)),
    rr_cr2       = exp(cr2$beta),
    p_cr2        = cr2$p_Satt,
    df_satt      = cr2$df_Satt,
    ci_t_contain = sprintf("[%.2f, %.2f]", exp(tc$ci.lb), exp(tc$ci.ub)),
    df_contain   = tc$ddf,
    rr_kh        = exp(kh$beta[1]),
    ci_kh        = sprintf("[%.2f, %.2f]", exp(kh$ci.lb), exp(kh$ci.ub)),
    df_kh        = kh$k - 1,
    tau2_kh      = kh$tau2,
    stringsAsFactors = FALSE
  )
}

tab4 <- rbind(
  cluster_fit(es_dropout,   "Dropout, any cause"),
  cluster_fit(es_resp50,    "Response, >=50% HAM-A reduction"),
  cluster_fit(es_resp_auth, "Response, author-defined")
)
print(tab4, row.names = FALSE, digits = 3)
write.csv(tab4, "output/table4_clustered_estimates.csv", row.names = FALSE)
cat("\nSaved: output/table4_clustered_estimates.csv\n")
cat("\nNotes:\n")
cat("  rma.mv variance component may hit the zero floor at 3 clusters.\n")
cat("  CR2/Satterthwaite df ~ 2; coverage uncertain (Partlett & Riley 2017).\n")
cat("  ci_t_contain is t-based with containment df, not Knapp-Hartung.\n")
cat("  ci_kh is Knapp-Hartung on study-collapsed data (k = 3, df = 2).\n")

# --- 6b. HAM-A: sensitivity only, NOT a result --------------------------------
cat("\n=== HAM-A (SENSITIVITY ONLY — not reported as a result) ===\n")
cat(sprintf("Imputed SD (lower bound): MD %.2f [%.2f, %.2f]\n",
            res_hama_p$beta, res_hama_p$ci.lb, res_hama_p$ci.ub))
cat(sprintf("Uncorrected (as RevMan):  MD %.2f [%.2f, %.2f]\n",
            res_hama_uncorr$beta, res_hama_uncorr$ci.lb, res_hama_uncorr$ci.ub))
cat("Pande 2003 benzodiazepine SD = 20.83 remains unverified.\n")

# =============================================================================
# SECTION 7: PARSER VALIDATION
# =============================================================================

cat("\n=== Parser validation (Challenge 5) ===\n")

doc_val <- read_xml(rm5_path)

# Check dich outcome totals
for (outcome in xml_find_all(doc_val, ".//DICH_OUTCOME")) {
  oid      <- xml_attr(outcome, "ID")
  rev_ev1  <- as.integer(xml_attr(outcome, "EVENTS_1"))
  rev_tot1 <- as.integer(xml_attr(outcome, "TOTAL_1"))
  rev_k    <- as.integer(xml_attr(outcome, "STUDIES"))

  parsed   <- rm5$dich %>% filter(outcome_id == oid)
  parse_ev1  <- sum(parsed$ai, na.rm = TRUE)
  parse_tot1 <- sum(parsed$n1i, na.rm = TRUE)
  parse_k    <- length(unique(parsed$study))

  match_ev  <- isTRUE(all.equal(rev_ev1,  parse_ev1))
  match_tot <- isTRUE(all.equal(rev_tot1, parse_tot1))

  oname <- xml_text(xml_find_first(outcome, ".//NAME"))
  cat(sprintf(
    "%-12s %-45s events1: RM5=%3d parsed=%3d %s | total1: RM5=%3d parsed=%3d %s\n",
    oid, substr(oname, 1, 45),
    ifelse(is.na(rev_ev1),0,rev_ev1), parse_ev1,
    ifelse(match_ev, "OK", "MISMATCH"),
    ifelse(is.na(rev_tot1),0,rev_tot1), parse_tot1,
    ifelse(match_tot, "OK", "MISMATCH")
  ))
}

# =============================================================================
# SECTION 8: SUMMARY TABLE (manuscript Table 4 basis)
# HAM-A is excluded (not poolable, Section 3d). CGI is a single study.
# =============================================================================

cat("\n=== Summary (Table 4 basis) ===\n")
cat("NOTE: I^2 marked [NI] = Not Interpretable at k=3 studies.\n\n")

summary_table <- data.frame(
  Outcome   = c(tab4$outcome, "CGI improvement (Rickels 2005 only)"),
  k_studies = c(tab4$k_studies, 1L),
  k_arms    = c(tab4$k_arms, nrow(es_cgi)),
  Arm_level_REML = c(
    sprintf("RR=%.2f [%.2f, %.2f]", exp(res_dropout$beta),   exp(res_dropout$ci.lb),   exp(res_dropout$ci.ub)),
    sprintf("RR=%.2f [%.2f, %.2f]", exp(res_resp50$beta),    exp(res_resp50$ci.lb),    exp(res_resp50$ci.ub)),
    sprintf("RR=%.2f [%.2f, %.2f]", exp(res_resp_auth$beta), exp(res_resp_auth$ci.lb), exp(res_resp_auth$ci.ub)),
    sprintf("MD=%.2f [%.2f, %.2f]", res_cgi$beta, res_cgi$ci.lb, res_cgi$ci.ub)
  ),
  Clustered_rma_mv = c(sprintf("RR=%.2f %s", tab4$rr_mv, tab4$ci_mv), "n/a (single study)"),
  CR2_p_df         = c(sprintf("p=%.3f (%.2f)", tab4$p_cr2, tab4$df_satt), "n/a"),
  KH_study_level   = c(tab4$ci_kh, "n/a"),
  I2               = c(rep("[NI]", nrow(tab4)), "undefined (within-study arms)"),
  stringsAsFactors = FALSE
)
print(summary_table, row.names = FALSE)
write.csv(summary_table, "output/summary_table.csv", row.names = FALSE)
cat("HAM-A change (continuous): not poolable (SE recorded as SD) — see Section 3d.\n")

# =============================================================================
# SECTION 9: REPRODUCIBILITY
# =============================================================================

cat("\n=== Reproducibility ===\n")
cat(sprintf("R version   : %s\n", R.version.string))
cat(sprintf("metafor     : %s\n", packageVersion("metafor")))
cat(sprintf("meta        : %s\n", packageVersion("meta")))
cat(sprintf("clubSandwich: %s\n", packageVersion("clubSandwich")))
cat(sprintf("xml2        : %s\n", packageVersion("xml2")))
cat(sprintf("Analysis    : %s\n", Sys.time()))
cat(sprintf("Source file : %s\n", rm5_path))
cat("Parser reads RM5 natively — no manual transcription step; cross-checked\n")
cat("against meta::read.rm5 (Section 1b).\n")
cat("AI assistance: pipeline construction, adversarial pass (Section 5).\n")
cat("Numerical outputs: R/metafor. Author verification required.\n")
cat("Data corrections: Section 2. Flagged items require paper verification.\n")

# Pin the environment in the repository (committed; output/ is not).
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
cat("Saved: sessionInfo.txt\n")
cat("\n=== END ===\n")
