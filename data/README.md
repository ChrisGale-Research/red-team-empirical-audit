# Source data: RevMan 5 project file

## File

`Benzodiazepines_versus_pregabalin_for_GAD.rm5`

A RevMan 5 (`.rm5`) project file — XML under the hood — from an abandoned
Cochrane-style systematic review of benzodiazepines for generalised anxiety
disorder.

## Provenance

- **Last modified:** 2014-11-03 15:02:02 +1300 (recorded in the file's own
  `MODIFIED` attribute; timezone is NZDT, the lead author's machine).
- **Author's own note in the file** (`DESCRIPTION` attribute): *"Results gone
  through and correct p values inserted throughout."*
- **RevMan version:** 5.

The review methodology and the file itself predate the current analysis by
roughly a decade. This work is a *resurrection* of the author's own earlier
review, not a newly constructed dataset. The R pipeline and the adversarial
verification pass are recent; the underlying review is not.

## Scope: the full review vs the worked example

The `.rm5` contains the **complete benzodiazepine GAD review — 17 studies**:

    Feltner 2003, Pande 2003, Rickels 2005, Ansseau 1985, Ansseau 1990,
    Ballenger 1991, Barbee 2003, Bassi 1989a, Beaumont 1995, Bertolino 1989,
    Bohm 1990, Boral 1989, Cohn 1986a, Delle 1995, Dunner 1986, Lydiard 2010,
    Sonne 1975

with 20 dichotomous outcomes, 6 continuous outcomes, and 80 data rows in total.

**The worked example in the paper analyses only the pregabalin comparison —
k = 3 studies:** Feltner 2003, Pande 2003, Rickels 2005. These are the trials
that contribute a direct benzodiazepine-versus-pregabalin contrast. The other
14 studies belong to the wider review (benzodiazepines versus placebo and other
comparators) and are not part of this comparison.

This is deliberate. A reader inspecting the source file will see 17 studies and
an analysis of 3; the difference is the review scope, not missing data. The
pipeline narrows to the pregabalin arms explicitly.

## Corrections applied

The pipeline applies three documented, source-verified corrections to the
extracted data (see `R/pregabalin_pipeline.R`, Section 2), each justified
against the primary source:

- **Rickels et al., Arch Gen Psychiatry 2005;62(9):1022-1030** — the HAM-A
  standard deviations recorded in the RM5 (SD = 0.8) are the ANCOVA
  model-derived standard *errors*, not raw SDs. The correction recovers an
  approximate lower bound only; the outcome is treated as descriptive. The
  study duration (recorded as 8 weeks) is corrected to 4 weeks per the source
  paper, and the pregabalin dose labels are corrected to 300/450/600 mg/d.
- One benzodiazepine SD (Pande 2003, HAM-A) is carried as flagged/unverified;
  it does not affect the headline response outcomes.

## Reproducibility note

To confirm the file is intact before use:

```r
library(xml2)
doc <- read_xml("data/Benzodiazepines_versus_pregabalin_for_GAD.rm5")
length(xml_find_all(doc, ".//STUDY"))      # 17
length(xml_find_all(doc, ".//DICH_DATA"))  # 70
length(xml_find_all(doc, ".//CONT_DATA"))  # 10
```
