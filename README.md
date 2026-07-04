# Red-team Methodology for Auditing Empirical Specifications

Companion code and data for the medRxiv preprint applying a multi-model
adversarial review pipeline to empirical research specifications.

**Preprint:** [medRxiv DOI to be added]
**Archived release:** [Zenodo DOI to be added]
**ORCID:** https://orcid.org/0000-0001-8032-765X

## Authors

- Christopher Gale (FRANZCP, Dr Christopher Gale Ltd, Northland NZ)
- Giuseppe Guaiana
- Paul Glue

## What this is

A structured red-team pass that runs a claim through several reasonable
specification variants (anchor, steelman, technical, analogy, cold read,
adjudicator) and treats *divergence across those variants* as the signal —
a fragile claim is one that only survives under a narrow specification.

## Quick start

```r
source('R/01_data_import.R')
source('R/02_red_team_pass.R')
source('R/03_divergence_analysis.R')
```

Outputs are written to `output/`.

## Structure

```
red-team-empirical-audit/
├── README.md
├── LICENSE                 (MIT)
├── sessionInfo.R           (R environment snapshot)
├── R/
│   ├── 01_data_import.R
│   ├── 02_red_team_pass.R
│   ├── 03_divergence_analysis.R
│   └── utilities.R
├── data/
│   └── README.md           (data source documentation)
└── output/                 (generated tables/figures)
```

## Reproducibility

Run `source('sessionInfo.R')` once and commit the output so the R version
and package set are on record.

## Citation

```
Gale C, Guaiana G, Glue P. Red-team methodology for auditing empirical
specifications. medRxiv [preprint]. 2026. doi: [to be added]
```

## License

MIT — see LICENSE.
