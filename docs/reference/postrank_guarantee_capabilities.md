# Check Which Uncertainty Bounds Are Implemented

This record describes the implemented conditional uncertainty
calculations. Evaluation of a reference formula in floating-point
arithmetic does not, by itself, provide a numerically certified
guarantee.

## Usage

``` r
postrank_guarantee_capabilities()
```

## Value

A named list of capability indicators and an interpretation string.
Implemented reference calculations include fixed-sample IID coefficient
bounds, weighted regret over a fixed action family, and protection
envelopes. Formal numerical certification, general MCMC finite-sample
certification, optional-stopping certification, and minimax regret
bounds are not implemented. ESS cannot be substituted for an IID sample
size.

## Details

The supported reference formulas require their stated sampling,
action-family, and numerical assumptions. Support does not establish
that those assumptions hold for an input. In particular, a solver's
numerical gap concerns optimization of the supplied coefficients; it
does not certify posterior probability accuracy, model adequacy, or
repeated-data calibration. See
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
and
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
for their distinct scopes.

## Examples

``` r
support <- postrank_guarantee_capabilities()
support[c("fixed_S_IID_reference_calculation", "formal_numerical_certifier",
  "general_MCMC_finite_sample_certificate", "ESS_as_IID_sample_size")]
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
