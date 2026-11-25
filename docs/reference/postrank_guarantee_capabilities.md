# List Which Uncertainty Bounds postrank Computes

`postrank_guarantee_capabilities()` lists which conditional uncertainty
bounds `postrank` computes and which it does not. Each implemented bound
holds only under its stated sampling and problem assumptions, and all
are evaluated in ordinary floating-point arithmetic rather than verified
with interval arithmetic.

## Usage

``` r
postrank_guarantee_capabilities()
```

## Value

A named list of logical capability flags, `schema_version`, and an
`interpretation` string:

- `TRUE`: `fixed_S_IID_reference_calculation`
  ([`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)),
  `fixed_space_weighted_regret_reference`
  ([`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md)),
  and `protection_envelope_diagnostic`
  ([`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md),
  [`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)).

- `FALSE`: `formal_numerical_certifier`,
  `conditional_IID_safe_certificate`,
  `general_MCMC_finite_sample_certificate`,
  `optional_stopping_certificate`, `minimax_regret_bound`, and
  `ESS_as_IID_sample_size`.

## Details

Implemented formulas require fixed-sample IID draw designs, fixed
grading families (or inner/outer protection envelopes), and usable
solver lower bounds; calling a bound function does not verify that those
external conditions hold for your posterior. Solver status labels and
gaps describe numerical optimization of the supplied comparison
probabilities and do not certify posterior probability accuracy, model
fit, or performance across new datasets.

## See also

[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md),
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)

## Examples

``` r
support <- postrank_guarantee_capabilities()
support[c(
  "fixed_S_IID_reference_calculation",
  "formal_numerical_certifier",
  "general_MCMC_finite_sample_certificate",
  "ESS_as_IID_sample_size"
)]
#> $fixed_S_IID_reference_calculation
#> [1] TRUE
#> 
#> $formal_numerical_certifier
#> [1] FALSE
#> 
#> $general_MCMC_finite_sample_certificate
#> [1] FALSE
#> 
#> $ESS_as_IID_sample_size
#> [1] FALSE
#> 
```
