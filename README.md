# legal.p.values

Rmarkdown file and data sets needed to reproduce our analysis of how p-values have been interpreted in US court of appeal cases.

The data in `Comments.RData` (R format) and `Comments.txt` (tab-delimited) are the key results that give:
* the case number
* whether we judged the interpretation as correct
* if we judged it as incorrect, the type of mistake that was made
* additional comments

The Bayesian logistic model to estimate the probability of a correct interpretation of a p-value, is fitted using `bugs.model.R` and this produces the results file `Bugs.results.RData` which is used by the Rmarkdown file `legal.significance.Rmd`.

`meta.case.data.txt` is the meta data for the 298 cases found by our search for cases in _Westlaw_. `selected.txt` is the random selection of 98 cases.

The R packages used are:
* diagram
* doBy
* car
* ggplot2
* pander
* R2WinBUGS
* reshape2
* stringr
* tables
