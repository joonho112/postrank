# Inspect Monte Carlo Precision for Reports or Pairs

`postrank_diagnose()` summarizes posterior target distributions,
requested directed-pair error traces, and per-draw loss traces for a
supplied grading, with optional subset or settings-grid stability
re-solves. Posterior target intervals describe uncertainty under your
statistical model, whereas Monte Carlo standard errors (MCSEs) describe
simulation precision when estimating summaries of that posterior from
finite draws.

## Usage

``` r
postrank_diagnose(
  draws,
  fit = NULL,
  grade = NULL,
  settings = NULL,
  pairs = NULL,
  stability = NULL
)
```

## Arguments

- draws:

  Posterior draws from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  (equal-weight IID or MCMC draws, or an exact finite law), or a
  `postrank_coefficients` object (Gaussian or mixture, which delegates
  to
  [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)).
  Pre-computed
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  and tie-mode inputs (`postrank_tie_*`) are not accepted.

- fit:

  Optional `postrank_fit` (for example `analysis$fit`) solved on
  `draws`. Supplies problem settings and, when a checked grading is
  present, its grade vector; results are marked
  `post_selection_descriptive = TRUE`.

- grade:

  Optional named integer vector of fixed grades (`1` = highest
  priority). Must match `fit$grade` when both are supplied; requires
  `settings` when `fit` is `NULL`. `postrank` cannot verify whether a
  manually supplied `grade` was chosen independently of `draws`.

- settings:

  Named list (or `postrank_settings` fields) with `weights` and `tau`
  when `grade` is supplied without `fit`, plus optional `G_max`,
  `objective`, `q`, `exact_G`, `minimax_criteria`, and `minimax_refine`.
  `G_max` is required when `stability` is requested.

- pairs:

  Optional list of records or data frame with columns `entity_i`,
  `entity_j`, and `criterion_id` naming up to 500 distinct directed
  pairs. Each pair trace records the per-draw indicator
  `I(theta_i <= theta_j)`. `NULL` (the default) requests no pair traces.

- stability:

  Optional named list requesting up to `max_solves` (default and maximum
  `12L`) re-solves on joint equal-weight draws. Requires explicit
  `backend` (`"gurobi"` or `"highs"`) and `control` with `threads = 1L`,
  plus optional `prefixes`, `include_full`, `chain_subsets`, and
  `settings_grid` (at most 6 overrides). Chain subsets and per-chain
  prefixes require MCMC chain history; IID inputs support full-draw
  `settings_grid` runs only.

## Value

For draw inputs, a `postrank_diagnostics` list containing `traces`,
`summaries`, `posterior_profiles`, `total_loss`, `stability`, `grade`,
`settings`, `regimes`, `post_selection_descriptive`, and `warnings`.
Each diagnostic metric record stores `value`, `available`,
`unavailable_reason`, and `method` (unavailable metrics remain `NA`,
never zero). For `postrank_coefficients` inputs, returns
`postrank_coefficient_diagnostics`; see
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).

## Details

For IID draws, trace MCSE is `sd(z) / sqrt(S)` using the retained draw
count `S`. For MCMC draws with equal-length chains and the optional
`posterior` package installed, `postrank_diagnose()` computes
`mcse_mean`, `rhat`, `ess_bulk`, and `ess_tail` from the original
chain-by-iteration layout; unequal chains are never truncated or padded
to force cross-chain metrics. An exact finite law uses its rational
state masses (`gmp` quantiles at `1/40`, `1/2`, and `39/40`) and has
zero Monte Carlo error.

Joint draws (`dependence_mode = "joint_model"`) combine criterion losses
within each draw to form `weighted_total_loss`, preserving
cross-criterion covariance; criterion-wise draw blocks provide
per-criterion traces without a joint total-loss MCSE. Under
`objective = "minimax"`, `weighted_total_loss` is marked
`"weighted_auxiliary"` because minimax optimizes the maximum of expected
criterion risks rather than an expectation of per-draw maxima. Without a
fixed grade, no loss trace is computed.

An all-withheld single-grade report has constant per-draw loss `tau`
(zero variance), and an all-zero or all-one pair indicator trace does
not establish an exact posterior probability of `0` or `1`. Gaussian and
mixture coefficient inputs reject `pairs` and `stability`; call
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
directly when supplying hyperparameter `chain_history`. These
diagnostics are descriptive summaries and do not provide post-selection
coverage, convergence proof, or a finite-sample guarantee.

## See also

[`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md),
[`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md),
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)

## Examples

``` r
pair <- data.frame(
  entity_i = "001",
  entity_j = "site-B",
  criterion_id = "need_A"
)
d <- postrank_diagnose(postrank_toy, pairs = pair)
d$summaries$pair_1$diagnostics$mcse_mean
#> $value
#> [1] 0.07777138
#> 
#> $raw_value
#> [1] 0.07777138
#> 
#> $result_kind
#> [1] "finite"
#> 
#> $available
#> [1] TRUE
#> 
#> $unavailable_reason
#> NULL
#> 
#> $warnings
#> character(0)
#> 
#> $error
#> NULL
#> 
#> $error_class
#> NULL
#> 
#> $method
#> [1] "iid_sample_sd_over_sqrt_S"
#> 

grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
d_grade <- postrank_diagnose(
  postrank_toy,
  grade = grade,
  settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
)
d_grade$summaries$weighted_total_loss$mean
#> [1] 0.2125
d_grade$post_selection_descriptive
#> [1] FALSE
```
