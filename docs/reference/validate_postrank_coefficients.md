# Check Conditional Coefficients and Source Calculations

`validate_postrank_coefficients()` checks that a `postrank_coefficients`
object has intact axes, positive-definite covariances, valid
`provenance` SHA-256 digests and unchanged identity hashes, and
optionally recalculates `means` and `e` from the stored normal or
mixture parameters.

## Usage

``` r
validate_postrank_coefficients(x, recompute = FALSE)
```

## Arguments

- x:

  A `postrank_coefficients` object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

- recompute:

  Plain logical scalar (default `FALSE`). When `TRUE`, also recomputes
  `means` and `e` from `x$source` and checks agreement.

## Value

`TRUE`, invisibly, when all checks pass; otherwise stops with an error
(`invalid_coefficients`, `stale_coefficient_identity` or
`coefficient_projection_mismatch`).

## Details

With `recompute = FALSE`, structure, positive definiteness and SHA-256
object identities are verified without re-evaluating every mixture
state. With `recompute = TRUE`, recomputed probabilities must match
stored `e` within `1e-12` and recomputed means must match within
`1e-12 * max(1, abs(recomputed_mean))`.

Passing validation confirms internal consistency of `x`; it does not
verify conditional independence in the underlying data, MCMC convergence
or external files. To modify parameters or provenance, call the
constructor again.

## See also

[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)

## Examples

``` r
validate_postrank_coefficients(pr_tutorial$one)
validate_postrank_coefficients(pr_tutorial$one, recompute = TRUE)
```
