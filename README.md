# Structured adversarial verification for secondary analysis of abandoned systematic reviews

A worked example: benzodiazepines versus pregabalin for generalised anxiety
disorder, resurrected from an abandoned RevMan 5 project file and analysed in R
under a multi-model adversarial verification pass.

**Preprint:** [medRxiv DOI — to be added on deposit]
**Archived release:** [Zenodo DOI — to be added on deposit]
**ORCID:** https://orcid.org/0000-0001-8032-765X

## Authors

- Christopher K Gale (Dr Christopher Gale Ltd, P.O. Box 325, Warkworth, New Zealand)
- Paul Glue (Department of Psychological Medicine, University of Otago, Dunedin)
- Giuseppe Guaiana (St Thomas Elgin General Hospital, University of Western Ontario)

## What this repository contains

| File | Description |
|------|-------------|
| `R/pregabalin_pipeline.R` | The full reproducible pipeline: native RM5 parse, documented corrections, meta-analysis, forest plots, adversarial pass, sensitivity analyses, summary. |
| `data/Benzodiazepines_versus_pregabalin_for_GAD.rm5` | The source RevMan 5 project file (see provenance in `data/README.md`). |
| `paper_reference_version.docx` | The manuscript this pipeline supports. |
| `sessionInfo.txt` | R environment snapshot from the analysis run (commit after running — see below). |

## Method in one paragraph

RevMan 5 stores review data as XML inside a `.rm5` file. The pipeline reads
that file natively — no manual re-transcription — parses the dichotomous and
continuous data nodes, applies a small set of documented, source-verified data
corrections, and runs the meta-analysis in metafor. Every correction is
justified against the primary source paper in-line. The analysis is then put
through a structured adversarial pass in which the load-bearing claims are
challenged, answered, and given an explicit verdict; challenges that survive
become sensitivity analyses. The point of the paper is not the clinical result
(k=3, a deliberately unpromising case) but the verification method.

## Reproducing the analysis

```r
# install.packages(c("metafor", "xml2", "dplyr", "ggplot2"))
source("R/pregabalin_pipeline.R")
```

The pipeline expects the .rm5 path near the top of the script — adjust it to
point at data/Benzodiazepines_versus_pregabalin_for_GAD.rm5 if running from the
repository root.

## Recording your environment

After a successful run, from the same R session:

```r
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
```

Committing this pins the R version and exact package versions (metafor, xml2,
etc.) used to produce the deposited results.

## Citation

```
Gale CK, Glue P, Guaiana G. Structured adversarial verification for secondary
analysis of abandoned systematic reviews: a worked example. medRxiv [preprint].
2026. doi: [to be added]
```

## License

MIT — see LICENSE.
