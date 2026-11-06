# Diagnose Integration of a Conditional Expected Risk

The conditional expected risk of a fixed grading is evaluated from
Gaussian or shared-state mixture coefficients. For a mixture,
conditional expected risks are also obtained for the individual shared
states. Where the hyperparameter states were obtained using MCMC and the
required original chain histories are available, these values support
diagnostics of the integration.

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

  An object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

- fit:

  Optional fit computed from the same input. Its problem, settings, and
  released grade are checked; an incumbent is independently revalidated.

- grade:

  Optional named fixed grade vector, with smaller grades indicating
  higher priority. It must agree with `fit` when both are supplied.

- settings:

  Weighted-loss settings for a fixed `grade` without `fit`, including
  criterion-named `weights`, `tau`, and `G_max`.

- chain_history:

  Original retained-history records, each with `chain_id` and ordered
  `retained_iterations`. Required for eligible hyperparameter-MCMC
  metrics; not used for a single Gaussian or fixed finite mixture.

- max_trace_bytes:

  Nonnegative integer bound on the numeric conditional-risk output
  buffers, in bytes. This is not a bound on total process memory.

## Value

A `postrank_coefficient_diagnostics` object with the fixed-action
`evaluation` when available, a mixture `conditional_risk_trace` where
defined, and `diagnostics` records that distinguish available metrics
from explicit unavailable reasons. It does not certify convergence or a
selected report's frequentist or posterior accuracy.

## Details

The diagnostic traces concern conditional expected risk. They do not
represent realized target losses or their quantiles. A single Gaussian
law has no Monte Carlo trace, and its MCSE is unavailable rather than
zero. A fixed finite mixture is evaluated using its specified weights
and has no Monte Carlo sampling history.

MCMC metrics require history matching all original retained source
coordinates, at least two chains with four iterations each, equal chain
lengths, and regular common spacing. Chains are not truncated, padded,
or interpolated. Matching the records checks history structure, not its
truth or sampler convergence. Missing history, unavailable optional
libraries, inadequate chain layouts, and nonfinite raw metrics retain
their reasons.

[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
dispatches these coefficient inputs here with the default
missing-history behavior. Use this function to supply history. Target
pair-indicator traces, stability solves, cross-fit diagnostics, target
Monte Carlo fragility, and IID target-coefficient bounds are not
supplied by this route. An all-withheld report has structurally constant
risk and cannot diagnose exploration of the target posterior.

## See also

[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md),
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
for displaying already prepared diagnostics.

## Examples

``` r
x <- pr_tutorial$one
# A specified report, evaluated without optimization.
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
d <- postrank_coefficient_diagnose(x, grade = grade,
  settings = list(weights = c(score_A = 1), tau = .25, G_max = 3L))
d$evaluation$weighted_risk
#> [1] 0.05165164
d$diagnostics$mcse_mean$unavailable_reason
#> [1] "analytic_Gaussian_no_hyperstate_MC_trace"
```
