# Find Pairwise Decisions Near the Monte Carlo Noise Scale

`postrank_mc_fragility()` identifies unordered entity pairs whose
estimated wrong-direction error in the better ordering direction lies
close to the withholding cost `tau` relative to its Monte Carlo standard
error (MCSE), without running a solver. Because grades are chosen
jointly across all pairs, a flagged pair need not change the selected
grading.

## Usage

``` r
postrank_mc_fragility(
  draws,
  fit = NULL,
  settings = NULL,
  z = 2,
  screen_margin = NULL
)
```

## Arguments

- draws:

  Joint equal-weight posterior draws from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  (`dependence_mode = "joint_model"`). Criterion-wise blocks, exact
  finite laws, Gaussian or mixture coefficients, pre-computed
  probabilities, and tie-mode inputs are not accepted.

- fit, settings:

  Supply `fit` (`postrank_fit` or `postrank_analysis` on `draws`) or
  `settings`
  ([`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  or named list with `weights` and `tau`), not both. When `fit` has a
  checked grading, each traced pair is also labeled by its relation in
  `fit$grade`.

- z:

  Positive numeric MCSE multiplier (`2` by default) setting the
  descriptive flagging threshold `|d - tau| < z * mcse`.

- screen_margin:

  Positive numeric pre-screen threshold: only pairs with
  `|d - tau| < screen_margin` have per-draw indicator traces built. When
  `NULL` (the default), IID inputs with `S > 1` use
  `z * 0.5 / sqrt(S - 1)` (the maximum sample SD of a `[0, 1]`
  indicator, so no pair that could be flagged is skipped), and MCMC
  inputs use `0.1` (a working screen accompanied by a warning, not an
  upper bound).

## Value

A `postrank_mc_fragility` list with `pairs` (data frame of traced pairs
containing `entity_i`, `entity_j`, `better_direction`, `weighted_error`,
`margin`, `disclose_preferred`, `mcse`, `ratio`, and `fragile`, plus
`relation_in_grade` when `fit` has grades), `summary` (`pairs`,
`traced`, `fragile`, `fragile_share`, `mcse_unavailable`, plus
`fragile_disclosed` and `fragile_tied` when `fit` has grades), `regime`,
`draws`, `z`, `screen_margin`, `mcse_method`, and `warnings`.

## Details

For each unordered pair `(i, j)`, let \\\bar e\_{ij} = \sum_k w_k
e\_{ij,k}\\ be the criterion-weighted directional-error probability and
\\d = \min(\bar e\_{ij}, \bar e\_{ji})\\. Taken in isolation, ordering
the pair in its better direction beats withholding when \\d \< \tau\\.
For pairs passing `screen_margin`, `postrank_mc_fragility()` builds the
per-draw weighted indicator trace for that empirically better direction
and flags `|d - tau| < z * mcse`.

IID MCSE is `sd(trace) / sqrt(S)`. MCMC MCSE uses
[`posterior::mcse_mean()`](https://rdrr.io/pkg/posterior/man/mcse_mean.html)
on equal-length chains; unequal chain lengths or an uninstalled
`posterior` package leave `mcse` and `fragile` as `NA` with a warning
rather than truncating chains or substituting zero. Pairwise fragility
flags are descriptive summaries and do not assess global grade
stability, account for `G_max` or error budgets `q`, or provide
simultaneous confidence levels or a finite-sample guarantee.

## See also

[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
[`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)

## Examples

``` r
fragility <- postrank_mc_fragility(
  postrank_toy,
  settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
)
fragility$summary
#> $pairs
#> [1] 3
#> 
#> $traced
#> [1] 2
#> 
#> $fragile
#> [1] 0
#> 
#> $fragile_share
#> [1] 0
#> 
#> $mcse_unavailable
#> [1] 0
#> 
fragility$pairs
#>   entity_i entity_j better_direction weighted_error margin disclose_preferred
#> 1      001   site C          i_ahead         0.3125 0.0625              FALSE
#> 2   site-B   site C          i_ahead         0.0750 0.1750               TRUE
#>         mcse    ratio fragile
#> 1 0.02969944 2.104417   FALSE
#> 2 0.03206596 5.457501   FALSE
```
