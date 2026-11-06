# Check Conditional Coefficients and Source Calculations

Gaussian or mixture coefficients are checked for consistency with their
stored input and source records. With `recompute = TRUE`, the means and
directional probabilities are recalculated from the supplied law.

## Usage

``` r
validate_postrank_coefficients(x, recompute = FALSE)
```

## Arguments

- x:

  An object from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  or
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md).

- recompute:

  Logical scalar, default `FALSE`. If `TRUE`, recompute the projection
  from the stored conditional law as well as checking the object.

## Value

Invisible `TRUE` on success; invalid structure, altered content, or an
inconsistent recomputed projection raises an error. The object is not
repaired.

## Details

The default checks named axes, finite values, covariance geometry,
provenance fields, supported-operation indicators, and content identity.
It does not repeatedly integrate every mixture component.

The optional recomputation requires identical axes and `NA` masks. It
compares probabilities to absolute tolerance `1e-12` and means to
`1e-12 * max(1, abs(recomputed mean))` element by element. These
tolerances apply to floating-point recalculation; they do not permit
changes to the recorded object.

Passing validation establishes neither a connection to actual
observations nor the scientific truth of conditional independence,
source provenance, or MCMC convergence. It is not a probability-accuracy
certificate. To change a law or its source records, call its constructor
again.

## See also

[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)

## Examples

``` r
validate_postrank_coefficients(pr_tutorial$one)
validate_postrank_coefficients(pr_tutorial$one, recompute = TRUE)
```
