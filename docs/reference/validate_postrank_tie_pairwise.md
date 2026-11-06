# Check Equality-Neutral Comparison Coefficients

The strict-error, equality and distinctness arrays from
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
are checked against their retained input and equality records. Invalid
or altered content is detected without modifying the object.

## Usage

``` r
validate_postrank_tie_pairwise(x)
```

## Arguments

- x:

  An object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

## Value

Invisible `TRUE` on success. Invalid probabilities, axes, source
records, or changed content raise an error. The function does not repair
or replace an object.

## Details

Checks include matching entity and criterion axes, unused `NA`
diagonals, probability ranges, symmetric equality and distinctness, and
the identities `b[i,j,k] + b[j,i,k] = d[i,j,k]` and
`d[i,j,k] + t[i,j,k] = 1` off the diagonal, to tolerance `1e-12`. It
also checks consistency with the stored input, sample-size meaning,
equality declarations, and content identity.

Validation does not independently recalculate every probability from the
source states, verify a scientific structural-equality claim, or provide
a numerical accuracy certificate. To change the source, construct a new
tie-aware input and run
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
again.

## See also

[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md),
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  validate_postrank_tie_pairwise(pw)
}
```
