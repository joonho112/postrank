# Inspect Monte Carlo Precision for Reports or Pairs

The diagnostics summarize target draws, requested pair-error traces and
the loss of a supplied grading. Posterior target intervals describe
uncertainty under the model, whereas Monte Carlo standard errors
describe the numerical precision with which features of that law are
estimated.

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

  Ordinary input from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
  including a specified finite law, or Gaussian/mixture coefficients.
  The latter delegate to
  [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
  and have no latent target-draw traces. Supplied probability arrays and
  equality-neutral inputs do not provide this diagnostic route.

- fit:

  Optional `postrank_fit` from exactly the same input. Its settings and
  validated grade are used; results are marked descriptive after
  selection on those draws. A fit without a validated incumbent supplies
  no fixed grade.

- grade:

  Optional named fixed grade vector, with smaller grades indicating
  higher priority. It must agree with `fit` when both are supplied. The
  software cannot verify that a manually supplied grade was chosen
  independently of these draws.

- settings:

  Explicit `weights` and `tau` for a grade without a fit, plus optional
  problem settings. `G_max` is required for stability solves.

- pairs:

  Explicit list of records or a data.frame with `entity_i`, `entity_j`,
  and `criterion_id`, naming up to 500 distinct directed comparisons.
  Each trace is the indicator that the row entity's target is less than
  or equal to the column entity's. `NULL` requests no pair traces.

- stability:

  Optional request for additional optimization runs, with explicit
  `backend` and `control` (`threads = 1`). `prefixes`, `include_full`,
  `chain_subsets`, and `settings_grid` select at most `max_solves`
  attempts (default and hard maximum 12); the settings grid has at most
  six overrides. Joint equal-weight draws are required. IID inputs allow
  full-input settings grids only; chain subsets and per-chain prefixes
  require original MCMC history.

## Value

For draw input, a `postrank_diagnostics` list containing `traces`, their
`summaries`, `posterior_profiles`, `total_loss` availability, and any
`stability` results, along with grade, settings, sampling regimes,
selection context, and warnings. Metric records retain `value`,
`available`, `unavailable_reason`, and `method`; unavailable is not
zero. Gaussian/mixture input instead returns
`postrank_coefficient_diagnostics`; see
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).

## Details

IID trace MCSE is sample SD divided by the square root of the actual
retained count. Eligible MCMC traces use the optional `posterior`
package for MCSE, R-hat, and ESS. Original chain/iteration history is
retained; unequal chains are not truncated or padded to obtain
cross-chain metrics. Missing, nonfinite, or inapplicable metrics keep
their reasons. A complete finite law uses its stated masses and has no
Monte Carlo error to diagnose.

Joint inputs combine criterion losses within the same state, preserving
covariance in the total-loss trace. Criterion-wise blocks can provide
individual traces without a joint total-loss MCSE. Under minimax, a
weighted total-loss trace is auxiliary; it is not MCSE for the maximum
of expected criterion risks. Without a fixed grade, no total-loss trace
is produced.

Pointwise MCSE for a grading selected on the same draws is a descriptive
measure and does not automatically provide post-selection coverage or
regret bounds. An all-withheld report has constant ordinary loss `tau`,
which provides no information about exploration of the targets.
Similarly, a constant observed pair trace does not establish a posterior
probability of zero or one. Stability across overlapping subsets is
insufficient to establish convergence. Changes in grades after changes
in policy settings may reflect the decision problem rather than
simulation error.

Gaussian/mixture inputs reject pair traces and stability solves. This
wrapper supplies no original hyperparameter chain history; use
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
with explicit `chain_history` for eligible conditional expected-risk
metrics. No route here verifies convergence, numerical accuracy, or
external repeated-data calibration.

## See also

[`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md),
[`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)

## Examples

``` r
# Begin with one explicitly named directional comparison.
pair <- data.frame(entity_i = "001", entity_j = "site-B",
  criterion_id = "need_A")
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

# A declared report, evaluated without optimizing its grades.
grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
d <- postrank_diagnose(postrank_toy, grade = grade,
  settings = list(weights = c(need_A = .6, need_B = .4), tau = .25))
d$summaries$weighted_total_loss$mean
#> [1] 0.2125
d$post_selection_descriptive
#> [1] FALSE
```
