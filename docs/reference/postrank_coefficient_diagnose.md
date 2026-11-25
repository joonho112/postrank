# Diagnose Integration of a Conditional Expected Risk

`postrank_coefficient_diagnose()` evaluates the expected loss of a fixed
grading under normal or shared-state mixture posterior coefficients,
records state-by-state conditional expected losses for mixtures, and
computes MCMC integration diagnostics (`rhat`, `ess_bulk`, `ess_tail`,
`ess_mean`, `mcse_mean`) when the mixture states came from
hyperparameter MCMC and `chain_history` is supplied.

## Usage

``` r
postrank_coefficient_diagnose(
  x,
  fit = NULL,
  grade = NULL,
  settings = NULL,
  chain_history = NULL,
  max_trace_bytes = 8 * 1024^2
)
```

## Arguments

- x:

  A `postrank_coefficients` object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

- fit:

  Optional `postrank_fit` computed from `x`. Its problem, settings and
  checked grading are verified against `x`.

- grade:

  Optional positive integer grade vector named by `x$entity_ids` (grade
  1 = highest priority). Must match `fit$grade` when `fit` is also
  given.

- settings:

  Weighted-loss settings
  ([`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  or a named list with `weights`, `tau` and `G_max`), required when
  `grade` is given without `fit`.

- chain_history:

  Optional plain list of original MCMC chain records, each with scalar
  positive integer `chain_id` and strictly increasing integer vector
  `retained_iterations`. Used only when `x` has
  `source_regime == "hyperparameter_mcmc"`.

- max_trace_bytes:

  Nonnegative integer memory cap in bytes for the `S x (K + 1)`
  conditional-loss trace arrays (default `8 * 1024^2`).

## Value

A `postrank_coefficient_diagnostics` list containing `evaluation`
(`NULL` when no grade is supplied or validated),
`conditional_risk_trace` (for mixtures with a grade), the five metric
records in `diagnostics`, `layout`, `unavailable_reason`,
`conditional_risk_mcse_available`, and `interpretation`.

## Details

For a mixture posterior, `conditional_risk_trace$values` holds the
analytic conditional expected loss given each shared state `h_s`, rather
than realized entity-level loss draws or target-loss quantiles. A single
normal posterior has no state trace
(`unavailable_reason = "analytic_Gaussian_no_hyperstate_MC_trace"`), and
a `"fixed_finite_mixture"` uses fixed weights without MCMC sampling
(`"fixed_finite_mixture_MC_not_used"`).

Hyperparameter-MCMC metrics require `chain_history` covering every chain
in `x$source$state_index`, at least 2 chains of equal length (`>= 4`
retained iterations each) and common regular spacing; otherwise
`diagnostics` records `available = FALSE` with a specific
`unavailable_reason`.
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
calls this function with `chain_history = NULL`, so call
`postrank_coefficient_diagnose()` directly when supplying
`chain_history`. Diagnostics are descriptive summaries, not guarantees
of MCMC convergence or post-selection accuracy.

## See also

[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md),
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)

## Examples

``` r
x <- pr_tutorial$one
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
d <- postrank_coefficient_diagnose(x, grade = grade,
  settings = list(weights = c(score_A = 1), tau = 0.25, G_max = 3L))
d$evaluation$weighted_risk
#> [1] 0.05165164
d$diagnostics$mcse_mean$unavailable_reason
#> [1] "analytic_Gaussian_no_hyperstate_MC_trace"
```
