# Check Which Operations a Conditional-Law Input Supports

`postrank_coefficient_capabilities()` validates a normal or shared-state
mixture posterior input and returns logical flags telling which
`postrank` functions and settings accept it.

## Usage

``` r
postrank_coefficient_capabilities(x)
```

## Arguments

- x:

  A `postrank_coefficients` object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

## Value

A named list of 12 logical flags:

- `weighted_expected_risk`, `posterior_means` and
  `weighted_at_most_G_problem`: `TRUE`;

- `minimax_problem`, `protection_problem` (`q`) and `exact_G_problem`
  (in
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)):
  `FALSE`;

- `target_state_trace`, `target_quantiles` (empirical draw quantiles),
  `exact_rational` and `formal_numerical_certification`: `FALSE`;

- `rb_conditional_risk_trace`: `TRUE` for mixtures, `FALSE` for a single
  normal posterior;

- `hyperparameter_mcse_eligible`: `TRUE` only for mixtures with
  `source_regime == "hyperparameter_mcmc"`.

## Details

`exact_G_problem = FALSE` applies to unrestricted optimization in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md);
fixed-order cuts in
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
do allow `exact_G` on `postrank_coefficients`.
`hyperparameter_mcse_eligible = TRUE` indicates that
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
can compute MCMC metrics if valid `chain_history` records are supplied,
not that sampling converged.

## See also

[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md),
[`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md)

## Examples

``` r
caps <- postrank_coefficient_capabilities(pr_tutorial$one)
caps[c("weighted_expected_risk", "weighted_at_most_G_problem",
  "minimax_problem", "rb_conditional_risk_trace")]
#> $weighted_expected_risk
#> [1] TRUE
#> 
#> $weighted_at_most_G_problem
#> [1] TRUE
#> 
#> $minimax_problem
#> [1] FALSE
#> 
#> $rb_conditional_risk_trace
#> [1] FALSE
#> 
```
