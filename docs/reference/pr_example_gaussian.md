# The Three-Criterion Example's Gaussian Law

`pr_example_gaussian` is the synthetic analytic normal posterior
underlying
[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md),
stored as a `postrank_coefficients` object built by
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
with `conditional_independence = "entities_given_shared_h"`. Its
pairwise directional-error probabilities and marginal intervals follow
analytically from the normal posterior (`provenance` records SHA-256
hashes of the parameter file, generator script and configuration). The
4,000 IID draws in
[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md)
approximate this distribution and need not give identical probabilities
or grades.

## Usage

``` r
pr_example_gaussian
```

## Format

A `postrank_coefficients` object
(`source$kind = "gaussian_conditional"`): `means` 30 x 3, `e` 30 x 30 x
3, `source$covariance` 3 x 3 x 30 (criterion_i x criterion_j x entity),
plus `provenance`, `capabilities` and identity hashes.

## Source

Built by `data-raw/make-pr-example-gaussian.R` from the same synthetic
normal posterior as
[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md).

## See also

[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md),
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)

## Examples

``` r
dim(pr_example_gaussian$e)
#> [1] 30 30  3
postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
#> [1] TRUE
```
