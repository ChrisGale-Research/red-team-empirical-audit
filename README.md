# Automated post-hoc testing of archived systematic review data

A worked example: benzodiazepines versus pregabalin for generalised anxiety disorder, resurrected from an abandoned RevMan 5 project file, analysed in R, and put through a multi-model review that treats each flag as a claim about the stored data to be verified against the source publication.

**Archived release (concept DOI, resolves to latest version):** https://doi.org/10.5281/zenodo.21252858
**ORCID (corresponding author):** https://orcid.org/0000-0001-8032-765X

## Authors

- Christopher K Gale (Dr Christopher Gale Ltd, P.O. Box 325, Warkworth, New Zealand)
- Paul Glue (Department of Psychological Medicine, University of Otago, Dunedin, New Zealand)
- Giuseppe Guaiana (Saint Thomas Elgin General Hospital, University of Western Ontario, Ontario, Canada)

## What this repository contains

| Path | Description |
|------|-------------|
| `R/pregabalin_pipeline.R` | The full reproducible pipeline: native RM5 parse, independent `meta::read.rm5` cross-check, documented corrections, arm-level and study-clustered meta-analysis, forest plot, structured pre-analysis challenge pass, parser validation, summary table. |
| `data/Benzodiazepines_versus_pregabalin_for_GAD.rm5` | The source RevMan 5 project file (provenance in `data/README.md`). |
| `reviewer_outputs/` | The multi-model review outputs (panel runs and Gemini cold reads). See `reviewer_outputs/README.md` for which run is which, and for the Grok gap. |
| `triveritas_pregabalin.py` | The orchestration script that produced the panel outputs. The review prompt is defined in this script. |
| `MODEL_VERSIONS.md` | Model identifiers, access routes and dates. |
| `manuscripts/Gale_RSM_ResearchInBrief.docx` | Research in Brief prepared for *Research Synthesis Methods*, condensed and revised from the reference version. |
| `paper_reference_version.docx` | The original, full-length reference version of the manuscript (as deposited in v1.1.1). |
| `sessionInfo.txt` | R environment snapshot, written automatically at the end of each run. |
| `output/` | Regenerated on every run (forest plot, Table 4 CSV, summary CSV). Not committed. |

## Method in one paragraph

RevMan 5 stores review data as XML inside a `.rm5` file. The pipeline reads that file natively with a bespoke parser and, independently, with `meta::read.rm5` (available since 2009); the two must agree on row counts, events and totals or the script stops. Agreement certifies transfer, not truth: faithful import reproduces stored errors exactly. Values that looked implausible during extraction were recorded as challenges in a scripted pre-analysis pass, with provisional corrections marked as unverified. The analysis and manuscript were then given to a panel of open-weight models, plus interactive cold reads, instructed to find errors. Each flag was treated as a claim about the stored or derived data and checked by a human against the source publication. In this file, that check confirmed a standard error stored as a standard deviation, showed the provisional correction to be invalid, and found two further extraction errors (trial duration, dose labels) that no model named. The point is not the clinical result (k = 3, a deliberately unpromising case) but the verification method.

## Reproducing the analysis

From the repository root (open the `.Rproj` or `setwd()` there):

```r
source("R/pregabalin_pipeline.R")
```

Missing packages (`metafor`, `xml2`, `dplyr`, `meta`, `clubSandwich`) are installed on first run. `meta` pulls in `lme4` and `nloptr`; on Linux the latter compiles from source and needs CMake (`sudo pacman -S cmake`, `sudo apt install cmake`, etc.).

The script stops with an error if run from anywhere other than the repository root, or if the `read.rm5` cross-check disagrees with the bespoke parser.

## Version history

- **v1.2.3 (October 2026)**: Research in Brief added under `manuscripts/`, alongside the reference version. `MODEL_VERSIONS.md` and `.zenodo.json` added; licence split made explicit. The Research in Brief was checked line by line against the archived outputs. Some attributions in the reference version's Table 3 are not supported by the archive and are corrected there. The implausible SD was first raised at extraction, not by the panel; the panel flagged the provisional correction as unverified. The parser-novelty catch cannot be traced to an archived output. The Grok cold read was not retained. The reference version is left unchanged as the historical record.
- **v1.2.0–v1.2.2 (October 2026)**: Released in error or withdrawn. Superseded by v1.2.3; do not cite.
- **v1.1.1 (September 2026)**: All eleven reviewer runs deposited (keys redacted) with run notes; Gemini cold reads recovered and deposited.
- **v1.1.0 (September 2026)**: `read.rm5` cross-check added; study-clustered estimates (rma.mv, CR2, true study-level Knapp–Hartung) for all three dichotomous outcomes; HAM-A demoted to sensitivity-only (not poolable: the Rickels 2005 "SD" is an ANCOVA SE); the earlier arm-level Knapp–Hartung fit (df = 6, mislabelled df = 2) removed; reviewer outputs and orchestration script deposited.
- **v1.0.x (July 2026)**: Initial deposit.

## Citation

Cite the concept DOI; it always resolves to the current version.

```
Gale CK, Glue P, Guaiana G. Automated post-hoc testing of archived systematic
review data: code, data, model outputs and manuscripts [software and data].
Zenodo. 2026. doi:10.5281/zenodo.21252858
```

## Licence

Code (`R/`, `*.py`) is released under the MIT licence; see `LICENSE`. Data (`data/`), model outputs (`reviewer_outputs/`) and manuscripts are released under CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
