# Select and Evaluate Gradings on Two Draw Folds

`postrank_crossfit()` splits posterior draws into two folds (`A` and
`B`), solves the grading problem on each fold, and evaluates each fold's
grading on the held-out fold. It measures sensitivity of the chosen
grading and its risk to finite posterior simulation without refitting
your statistical model to held-out observations. Running
`postrank_crossfit()` executes two solver runs.

## Usage

``` r
postrank_crossfit(
  draws,
  fit = NULL,
  settings = NULL,
  backend = NULL,
  control = list(),
  strategy = NULL
)
```

## Arguments

- draws:

  Joint equal-weight posterior draws from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  (`dependence_mode = "joint_model"`), so each draw contains a joint
  state across all entities and criteria. Criterion-wise blocks, exact
  finite laws, Gaussian or mixture coefficients, pre-computed
  probabilities, and tie-mode inputs are not accepted.

- fit:

  Optional `postrank_fit` or `postrank_analysis` solved on `draws` (for
  an original public problem, without protection envelopes or
  second-stage risk caps). Supplies the problem settings and, when a
  checked grading is present, also evaluates that full-draw grading on
  each fold. Supply `fit` or `settings`, not both.

- settings:

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object or named list with `weights`, `tau`, `G_max`, and optional
  `objective`, `q`, `exact_G`, `minimax_criteria`, and `minimax_refine`.
  Supply `fit` or `settings`, not both.

- backend, control, strategy:

  Solver choice,
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  options, and search strategy passed to
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  on each fold. `backend = NULL` (the default) uses
  `getOption("postrank.backend")` or Gurobi (which requires a license);
  install `highs` and pass `backend = "highs"` to use HiGHS. `postrank`
  never switches solvers automatically.

## Value

A `postrank_crossfit` list containing `split` metadata, per-fold records
in `folds` (`draws`, `status`, `incumbent_validated`,
`risk_absolute_gap`, and when a checked grading exists, `grade`, `G`,
`in_fold_risk`, `out_of_fold_risk`,
`optimism = out_of_fold_risk - in_fold_risk`, plus
`out_of_fold_protection` when `q` is set and `full_grade_risk_on_fold`
when `fit` has grades), `agreement` (`between_folds`, plus `full_vs_A`
and `full_vs_B` when `fit` has grades), `folds_with_incumbent`,
`mean_optimism`, `mean_abs_optimism`, and `warnings`.

## Details

For IID draws (`S >= 4`), fold `A` is the first `floor(S / 2)` draws and
fold `B` is the remainder. For MCMC draws with at least two chains, fold
`A` holds the first `ceiling(C / 2)` whole chains and fold `B` holds the
remaining chains; single-chain MCMC (`S >= 4`) splits iterations into
first and second halves with an autocorrelation warning.

When `A` and `B` are independent IID folds from the same posterior and
`objective = "weighted"` with loss settings fixed beforehand,
out-of-fold weighted risk is conditionally unbiased for that fold
grading's true posterior risk (computed from roughly `S / 2` draws
rather than all `S` draws). When both folds select the exact same
grading, their two signed `optimism` values have opposite signs and
cancel in `mean_optimism`; check `mean_abs_optimism` for the noise
scale. Under `objective = "minimax"` (a maximum of empirical criterion
risks) or MCMC folds, out-of-fold risk is not unbiased. When `q` budgets
are present, `out_of_fold_protection` reports held-out `E_k / N`
descriptively.

Cross-fitting is a descriptive summary of Monte Carlo sensitivity and
does not adjust the full-sample risk or provide a finite-sample
guarantee.

## See also

[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
[`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)

## Examples

``` r
cf <- postrank_example("toy_crossfit")
cf[c("folds_with_incumbent", "mean_optimism", "mean_abs_optimism")]
#> $folds_with_incumbent
#> [1] 2
#> 
#> $mean_optimism
#> [1] 0
#> 
#> $mean_abs_optimism
#> [1] 0.008333333
#> 
cf$agreement
#> $between_folds
#> [1] 1
#> 
#> $full_vs_A
#> [1] 1
#> 
#> $full_vs_B
#> [1] 1
#> 
```
