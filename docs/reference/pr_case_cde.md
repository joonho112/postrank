# Chronic Absence in a Small California School Example

`pr_case_cde` is a one-criterion case-study dataset for 12 California
elementary schools adapted from 2026 California School Dashboard
chronic-absenteeism counts (academic year 2025–26) and an
empirical-Bayes model. Larger target values mean lower chronic-absence
probability: \\\theta = -p\\, measured in proportion units. Source
attribution and documented adaptations are recorded in `provenance` and
the installed `DATA-NOTICE.md` file.

## Usage

``` r
pr_case_cde
```

## Format

A named list with five elements:

- input:

  A `postrank_probabilities` object for the 12 schools on one criterion,
  with marginal posterior means and 90% equal-tail intervals for
  \\\theta = -p\\.

- units:

  Data frame of 12 rows in input order with columns `entity_id`
  (14-digit County-District-School CDS codes stored as character strings
  to preserve leading zeros), `chronic_absent_count`, `eligible_count`,
  `observed_rate`, `observed_rate_group` and `denominator_group`. Counts
  are observed school data, not posterior estimates.

- alternatives:

  Alternative `postrank_probabilities` inputs `order_32` and `order_64`,
  computed with 32 and 64 Gauss-Legendre nodes per prior bin under the
  same posterior and marginal summaries.

- reference:

  Settings, three fixed comparison gradings (all-unordered,
  observed-rate tertiles and posterior-mean tertiles) with their losses,
  piecewise-Beta posterior parameters, quadrature diagnostics, and
  archived statewide baseline summaries.

- provenance:

  Source filenames and SHA-256 hashes, dates, school selection rule,
  model conditioning, target orientation, attribution and historical
  preparation-stage review records. Raw CDE download files, logos, full
  source tables and statewide pairwise matrices are not bundled.

## Source

California Department of Education, 2026 California School Dashboard
chronic absenteeism data, academic year 2025–26,
<https://www.cde.ca.gov/ta/ac/cm/chronicdatafiles.asp>; source
conditions at <https://www.cde.ca.gov/re/di/cr/index.asp> (accessed
2026-10-30). Empirical-Bayes model, numerical integration and 12-school
selection by the package author; no CDE endorsement is implied.

## Details

**School selection.** The statewide frame comprises 5,834
elementary-type schools outside Dashboard Alternative School Status
(non-DASS, including eligible charter schools) with usable ALL-student
chronic-absence counts and denominators of at least 30. One school was
chosen from each cell of 4 observed-rate rank groups crossed with 3
denominator rank groups (the lower-median row `ceiling(m / 2)` within
each cell when ordered by observed rate, denominator and CDS code). This
12-school subset spans rate and size strata for teaching and is not a
representative sample of California schools.

**Posterior and numerical integration.** A piecewise-uniform
empirical-Bayes prior `G` over 161 continuous bins was estimated on the
5,834-school frame and held fixed; uncertainty in estimating `G` is not
propagated. Within each bin, a school's posterior is a truncated
`Beta(y + 1, n - y + 1)` density weighted by its posterior bin
probability, so independent school posteriors given `G` have zero
probability of exact equality. Primary pairwise probabilities use 16
Gauss-Legendre nodes per bin, clipping raw values that overshot `[0, 1]`
by at most 64 machine epsilons back into `[0, 1]` before applying
symmetric complement correction with `tolerance = 1e-6` in
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md).
Small corrections and agreement across 16, 32 and 64 nodes are
diagnostic checks, not certified bounds on integration error, and no
posterior draws are stored.

**Intervals and scope.** Each school's mean is \\-E\[p\]\\ and its 90%
marginal (not simultaneous) interval is \\\[-q\_{0.95}(p),
-q\_{0.05}(p)\]\\; pass `level = 0.90` in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)
(other levels cannot be computed from stored summaries). Archived
statewide rows in `reference$statewide$metrics` summarize fixed-order
contiguous cuts, an all-unordered row and matched grade-size baselines
rather than an unrestricted 5,834-school optimization, and their
independent-pair relaxation lower bound has a separate scope.
Posterior-conditioned losses do not provide external validation, and the
results do not reproduce California Dashboard Status-plus-Change colors
or estimate causal effects.

**Source conditions.** Only the 12 selected school IDs/counts and
author-derived summaries are included. `provenance$rights` retains
historical preparation-stage records, while the installed
`DATA-NOTICE.md` describes the current public distribution scope. CDE
source conditions apply to `pr_case_cde` and dependent stored results
(such as `postrank_example("case_cde_12")`) rather than a Creative
Commons or MIT code license.

## See also

[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`vignette("a2-cde-accountability", package = "postrank")`](https://joonho112.github.io/postrank/articles/a2-cde-accountability.md)

## Examples

``` r
x <- pr_case_cde
x$units[, c("entity_id", "chronic_absent_count", "eligible_count", "observed_rate")]
#>         entity_id chronic_absent_count eligible_count observed_rate
#> 1  30665976068399                   20            363    0.05509642
#> 2  38684786113997                   26            409    0.06356968
#> 3  30736506094718                   55            873    0.06300115
#> 4  58727516056840                   49            390    0.12564103
#> 5  30736436030639                   56            448    0.12500000
#> 6  01750936118038                  112            909    0.12321232
#> 7  19647330106427                   67            348    0.19252874
#> 8  37684520105882                  105            552    0.19021739
#> 9  36676866035711                  124            642    0.19314642
#> 10 34674216033732                   99            340    0.29117647
#> 11 19648816021687                  128            448    0.28571429
#> 12 36677106035901                  164            569    0.28822496
postrank_posterior_means(x$input, level = 0.90)
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.05959043
#>   38684786113997              -0.06741062
#>   30736506094718              -0.06484309
#>   58727516056840              -0.12739063
#>   30736436030639              -0.12655681
#>   01750936118038              -0.12403027
#>   19647330106427              -0.19124897
#>   37684520105882              -0.18945586
#>   36676866035711              -0.19241127
#>   34674216033732              -0.28618836
#>   19648816021687              -0.28201593
#>   36677106035901              -0.28525081
#> attr(,"lower")
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.08106193
#>   38684786113997              -0.08862801
#>   30736506094718              -0.07901464
#>   58727516056840              -0.15546707
#>   30736436030639              -0.15276486
#>   01750936118038              -0.14226231
#>   19647330106427              -0.22621309
#>   37684520105882              -0.21700330
#>   36676866035711              -0.21816439
#>   34674216033732              -0.32690719
#>   19648816021687              -0.31715130
#>   36677106035901              -0.31650101
#> attr(,"upper")
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.04074866
#>   38684786113997              -0.04848198
#>   30736506094718              -0.05176929
#>   58727516056840              -0.10134991
#>   30736436030639              -0.10218227
#>   01750936118038              -0.10668051
#>   19647330106427              -0.15842066
#>   37684520105882              -0.16315798
#>   36676866035711              -0.16773115
#>   34674216033732              -0.24741189
#>   19648816021687              -0.24818431
#>   36677106035901              -0.25464526
#> attr(,"level")
#> [1] 0.9
#> attr(,"interval_source")
#> [1] "supplied_marginal_summaries"

cde_res <- postrank_example("case_cde_12")
get_grades(cde_res)
#> 30665976068399 38684786113997 30736506094718 58727516056840 30736436030639 
#>              1              1              1              2              2 
#> 01750936118038 19647330106427 37684520105882 36676866035711 34674216033732 
#>              2              2              2              2              3 
#> 19648816021687 36677106035901 
#>              3              3 
```
