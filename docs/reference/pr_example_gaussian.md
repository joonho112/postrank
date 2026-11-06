# The Three-Criterion Example's Gaussian Law

The frozen law behind
[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md)
as a `postrank_coefficients` object built by
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
with the explicit declaration `"entities_given_shared_h"` and the six
strict provenance fields (`input_payload_sha256` hashes the frozen law
file, `source_sha256` the law generator source and `config_sha256` the
generation configuration). Analytic directional errors and marginal
summaries describe this same law. The finite sample in
[pr_example_draws](https://joonho112.github.io/postrank/reference/pr_example_draws.md)
approximates it and need not give exactly the same coefficients or
grades. See
[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md)
for a smaller one-criterion example and
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
for native mode restrictions.

## Usage

``` r
pr_example_gaussian
```

## Format

A `postrank_coefficients` object
(`source$kind = "gaussian_conditional"`): `means` 30 x 3, `e` 30 x 30 x
3, `source$covariance` 3 x 3 x 30 (criterion_i, criterion_j, entity),
plus provenance, capabilities and identities.

## Source

`data-raw/make-pr-example-gaussian.R`.

## Examples

``` r
dim(pr_example_gaussian$e)
#> [1] 30 30  3
postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
#> [1] TRUE
```
