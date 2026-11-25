# Historical Economic Opportunity in 67 Alabama Counties

`pr_case_alabama` is a two-criterion case-study dataset for all 67
Alabama counties adapted from the Opportunity Atlas replication data,
combining adult household income rank (measured in 2014–2015) and
incarceration rate (measured on April 1, 2010) for children born in
1978–1983 to parents at the 25th national income percentile (race and
gender pooled). Larger target values mean higher adult income and lower
incarceration. These values describe historical cohort outcomes, not
current county conditions or causal policy effects.

## Usage

``` r
pr_case_alabama
```

## Format

A named list with five elements:

- input:

  A `postrank_probabilities` object for the 67 counties on `income` and
  `incarceration` from MCMC pool A, with marginal posterior means and
  95% equal-tail intervals.

- units:

  Data frame of 67 rows in input order: county IDs and names, published
  Opportunity Atlas point estimates and standard errors, and oriented
  point-scale columns. Published cohort counts are descriptive, not
  binomial denominators in the model.

- alternatives:

  Alternative `postrank_probabilities` inputs: `pool_B` (from a second
  MCMC run on the same data and model) and single-criterion `income` and
  `incarceration` from pool A, each with matching 95% marginal
  summaries.

- reference:

  Archived settings, seven reference gradings, pool A and B loss
  evaluations, single-criterion and commonality summaries, and
  chain-based precision records (originally computed with postrank 0.9.0
  and HiGHS 1.12.0.3).

- provenance:

  Source filenames and SHA-256 hashes, cohort and outcome dates, target
  orientations, model conditioning, attribution and the CC BY 4.0
  license notice.

## Source

Chetty, Raj, John Friedman, Nathaniel Hendren, Maggie R. Jones and Sonya
R. Porter (2022), *Replication Data for: The Opportunity Atlas: Mapping
the Childhood Roots of Social Mobility*, Harvard Dataverse V1.0,
[doi:10.7910/DVN/NKCQM1](https://doi.org/10.7910/DVN/NKCQM1) ;
Opportunity Insights and U.S. Census Bureau
(`county_outcomes_simple.csv`, licensed under [CC BY
4.0](https://creativecommons.org/licenses/by/4.0/)). Alabama filtering,
county labels, incarceration sign orientation, separate hierarchical
fits and compact probability extraction by the package author; no
endorsement is implied.

## Details

**Model and numerical pools.** Each criterion was fitted separately to
the published county point estimates and standard errors using a
Gaussian observation model with logistic-normal partial pooling. The
resulting pairwise probabilities support weighted additive expected loss
without specifying a cross-criterion joint posterior, and observed Monte
Carlo `0` or `1` frequencies are finite-sample estimates rather than
exact posterior certainties.

Pool A (16,000 retained MCMC draws per criterion in the source study)
and pool B (8,000 draws) are two MCMC runs on the exact same
observations and model, not independent data replications. Original MCMC
draws are not bundled, so archived chain-based MCSEs cannot be
recomputed from `input` (and MCSE on constant zero/one pair traces is
unavailable, not zero). In pool B, 486 directional criterion entries
exceeded the source study's `0.005` pair-MCSE screen (maximum
`0.00586708`).

**Intervals and archived settings.** Pass `level = 0.95` when requesting
a report card in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)
(other levels cannot be computed from stored summaries). Incarceration
is negated so lower incarceration means higher priority toward grade 1.
At `weights = c(0.5, 0.5)`, `tau = 0.20` and `G_max = 5` (see
`postrank_example("case_alabama67")`), the common grading matches the
expected-rank cut baseline `B3`, whose fixed-order optimality has a
narrower scope than the unrestricted solver lower bound.

**Source license.** Source observations and documented derivatives
(including dependent stored results) are distributed under CC BY 4.0,
with attribution and modification notices retained in
`provenance$rights` (alongside historical preparation records) and the
installed `DATA-NOTICE.md`.

## See also

[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`vignette("a4-alabama-opportunity", package = "postrank")`](https://joonho112.github.io/postrank/articles/a4-alabama-opportunity.md)

## Examples

``` r
x <- pr_case_alabama
head(x$units[, c("entity_id", "county_name", "income_estimate_points",
  "incarceration_estimate_points")])
#>   entity_id    county_name income_estimate_points incarceration_estimate_points
#> 1     01001 Autauga County               36.16662                      3.056820
#> 2     01003 Baldwin County               38.88471                      2.259338
#> 3     01005 Barbour County               34.93856                      3.351606
#> 4     01007    Bibb County               36.33907                      3.166666
#> 5     01009  Blount County               39.18788                      2.052751
#> 6     01011 Bullock County               34.56590                      1.916004
postrank_posterior_means(x$input, level = 0.95)[1:3, ]
#>        criterion
#> entity    income incarceration
#>   01001 36.20615     -2.881527
#>   01003 38.84718     -2.233233
#>   01005 35.06699     -3.013570

ala_res <- postrank_example("case_alabama67")
get_risk(ala_res)
#> $risk
#> [1] 0.1503937
#> 
#> $lower_bound
#> [1] 0.1503937
#> 
#> $gap
#> [1] 1.110223e-16
#> 
#> $status
#> [1] "optimal"
#> 
```
