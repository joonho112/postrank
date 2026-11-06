# Find Pairwise Decisions Close to the Monte Carlo Noise Scale

The diagnostic identifies pairs for which the estimated loss from
disclosure in the better direction is close to the withholding cost.
Since grades are selected jointly, a flagged pair need not imply a
change in the selected grading. Indicator traces are calculated without
optimization.

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

  Joint equal-weight ordinary posterior draws. Whole states must retain
  the dependence among entities and criteria. Exact finite laws,
  criterion-wise blocks, Gaussian/mixture coefficients, supplied
  probabilities, and equality-neutral inputs are not supported by this
  Monte Carlo diagnostic.

- fit, settings:

  Supply exactly one, as in
  [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md).
  Only `weights` and `tau` are needed in a settings list. A supplied
  fit's grade is used to label its relation for each traced pair; its
  optimization status is not improved by this diagnostic.

- z:

  Positive MCSE multiplier, default 2. This sets a descriptive scale,
  not a simultaneous confidence level.

- screen_margin:

  Positive threshold: only pairs with margin strictly below it are
  traced. For IID samples with `S > 1`, the default is
  `z * 0.5 / sqrt(S - 1)`, using the maximum sample SD of a bounded
  indicator to avoid screening out a pair that this rule could flag. The
  MCMC default `0.1` is a heuristic screening threshold, not a bound on
  omitted pairs.

## Value

A `postrank_mc_fragility` list with a `pairs` table of better
directions, weighted error, margin, MCSE, margin/MCSE ratio, and
`fragile` flag; a supplied grade adds its reported relation. `summary`
counts all pairs, traced pairs, flagged pairs, and unavailable MCSEs.
Screening choices, sampling regime, and diagnostic warnings are
retained.

## Details

Let \\\bar e\_{ij}=\sum_k w_k e\_{ij,k}\\ and \\d=\min(\bar e\_{ij},\bar
e\_{ji})\\. Considering this pair alone, disclosure in the better
direction has lower estimated loss than withholding when \\d\<\tau\\.
The function flags \\\|d-\tau\|\<z\\\widehat{\mathrm{MCSE}}\\ using the
weighted indicator trace for the empirically better direction. It does
not diagnose global action stability, enforce grade counts or
protections, or provide post-selection coverage for that chosen
direction.

IID MCSE is sample SD divided by the square root of the actual draw
count. MCMC MCSE uses
[`posterior::mcse_mean`](https://rdrr.io/pkg/posterior/man/mcse_mean.html)
with the original equal-length chains. Unequal chains are not truncated
or padded; missing optional software or unavailable MCSE leaves the
corresponding flags unavailable. In particular, a constant empirical
trace is not proof of certainty or adequate chain exploration. MCMC ESS
cannot replace an IID sample count in a concentration bound. These
pairwise flags are descriptive, not finite-sample guarantees.

## See also

[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
[`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)

## Examples

``` r
fragility <- postrank_mc_fragility(postrank_toy,
  settings = list(weights = c(need_A = .6, need_B = .4), tau = .25))
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
