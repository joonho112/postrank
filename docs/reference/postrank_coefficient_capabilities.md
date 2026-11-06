# Check Which Operations a Conditional-Law Input Supports

These indicators describe the calculations supported for Gaussian or
shared-state mixture coefficients. They concern the implemented
operations and provide no assessment of the model assumptions or
probability accuracy.

## Usage

``` r
postrank_coefficient_capabilities(x)
```

## Arguments

- x:

  An object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

## Value

A named list of logical indicators, after validating `x`. These cover
weighted expected risk, means, native problem types, target-draw
quantities, conditional-risk traces, and eligibility for
hyperparameter-MCMC metrics.

## Details

The native
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
route supports weighted loss with an upper grade-count limit for these
inputs. Its `minimax_problem`, `protection_problem`, and
`exact_G_problem` indicators are `FALSE`. These are problem-construction
limits; a fixed-action evaluator or fixed-order baseline has its own
documented scope.

A mixture can supply a trace of conditional expected risk across shared
states. Eligibility for hyperparameter-MCMC diagnostics does not mean
that sufficient original chain history was supplied or that sampling
converged. Neither Gaussian nor mixture coefficients supply realized
target-loss draws, target quantiles, exact rational coefficients, or a
statistical or numerical certificate.

## See also

[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md),
[`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md)

## Examples

``` r
capabilities <- postrank_coefficient_capabilities(pr_tutorial$one)
capabilities[c("weighted_expected_risk", "weighted_at_most_G_problem",
  "target_state_trace", "formal_numerical_certification")]
#> $weighted_expected_risk
#> [1] TRUE
#> 
#> $weighted_at_most_G_problem
#> [1] TRUE
#> 
#> $target_state_trace
#> [1] FALSE
#> 
#> $formal_numerical_certification
#> [1] FALSE
#> 
```
