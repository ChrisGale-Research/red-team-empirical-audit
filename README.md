# Structured adversarial verification for secondary analysis of abandoned systematic reviews

A worked example: benzodiazepines versus pregabalin for generalised anxiety
disorder, resurrected from an abandoned RevMan 5 project file and analysed in R
under a multi-model adversarial verification pass.

**Archived release (concept DOI, resolves to latest version):** https://doi.org/10.5281/zenodo.21252858
**Preprint:** [medRxiv DOI — to be added]
**ORCID (corresponding author):** https://orcid.org/0000-0001-8032-765X

## Authors

- Christopher K Gale (Dr Christopher Gale Ltd, P.O. Box 325, Warkworth, New Zealand)
- Paul Glue (Department of Psychological Medicine, University of Otago, Dunedin)
- Giuseppe Guaiana (Department of Psychiatry, Schulich School of Medicine and Dentistry, Western University, London, Ontario)

## What this repository contains

| Path | Description |
|------|-------------|
| `R/pregabalin_pipeline.R` | The full reproducible pipeline: native RM5 parse, independent `meta::read.rm5` cross-check, documented corrections, arm-level and study-clustered meta-analysis, forest plot, adversarial pass, parser validation, summary table. |
| `data/Benzodiazepines_versus_pregabalin_for_GAD.rm5` | The source RevMan 5 project file (provenance in `data/README.md`). |
| `reviewer_outputs/` | The multi-model review outputs the manuscript reports (panel results and cold reads). See `reviewer_outputs/README.md` for which run is which. |
| `triveritas_pregabalin.py` | The orchestration script that produced the reviewer outputs (OpenRouter panel). |
| `paper_reference_version.docx` | The full-length reference version of the manuscript. |
| `sessionInfo.txt` | R environment snapshot, written automatically at the end of each run. |
| `output/` | Regenerated on every run (forest plot, Table 4 CSV, summary CSV). Not committed. |

## Method in one paragraph

RevMan 5 stores review data as XML inside a `.rm5` file. The pipeline reads
that file natively with a bespoke parser and, independently, with
`meta::read.rm5`; the two must agree on row counts, events and totals or the
script stops. A small set of documented, source-verified data corrections is
applied and the meta-analysis run in metafor. Because dose arms share a
comparator within study, arm-level estimates are reported alongside
study-clustered ones: `rma.mv` with a study random intercept, CR2
cluster-robust standard errors (clubSandwich), and a study-level Knapp–Hartung
interval on arm-collapsed data. The analysis is then put through a structured
adversarial pass in which the load-bearing claims are challenged, answered, and
given an explicit verdict. The point of the paper is not the clinical result
(k = 3, a deliberately unpromising case) but the verification method.

## Reproducing the analysis

From the repository root (open the `.Rproj` or `setwd()` there):

```r
source("R/pregabalin_pipeline.R")
```

Missing packages (`metafor`, `xml2`, `dplyr`, `meta`, `clubSandwich`) are
installed on first run. `meta` pulls in `lme4` and `nloptr`; on Linux the
latter compiles from source and needs CMake (`sudo pacman -S cmake`,
`sudo apt install cmake`, etc.).

The script stops with an error if run from anywhere other than the repository
root, or if the `read.rm5` cross-check disagrees with the bespoke parser.

## Version history

- **v1.1.0 (September 2026)** — `read.rm5` cross-check added; study-clustered
  estimates (rma.mv, CR2, true study-level Knapp–Hartung) for all three
  dichotomous outcomes; HAM-A demoted to sensitivity-only (not poolable: the
  Rickels 2005 "SD" is an ANCOVA SE); the earlier arm-level Knapp–Hartung fit
  (df = 6, mislabelled df = 2) removed; reviewer outputs and orchestration
  script deposited.
- **v1.0.x (July 2026)** — Initial deposit.

## Citation

Cite the concept DOI; it always resolves to the current version.

```
Gale CK, Glue P, Guaiana G. Structured adversarial verification for secondary
analysis of abandoned systematic reviews: a worked example [software and data].
Zenodo. 2026. doi:10.5281/zenodo.21252858
```

## License

MIT — see LICENSE.
