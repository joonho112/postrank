# Validate Tie-Aware Pairwise Probabilities

`validate_postrank_tie_pairwise()` checks the strict directional-error
(`b`), equality (`t`), and distinctness (`d`) probability arrays of a
`postrank_tie_pairwise` object against its stored `postrank_tie_draws`
source and content hash.

## Usage

``` r
validate_postrank_tie_pairwise(x)
```

## Arguments

- x:

  A `postrank_tie_pairwise` object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

## Value

`TRUE` invisibly when `x` passes all checks; invalid or modified objects
stop with a structured error.

## Details

Verifies `x$source` via
[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md),
matching entity and criterion axes, `NA` diagonals (rejecting `NaN`),
`[0, 1]` off-diagonal bounds, symmetry of `t` and `d`, and the
identities `b[i, j, k] + b[j, i, k] = d[i, j, k]` and
`d[i, j, k] + t[i, j, k] = 1` off the diagonal within tolerance `1e-12`,
along with `sample_sizes`, `sampling_regimes`, `method`, `exact`, and
`pairwise_identity`. Validation does not recompute probabilities from
raw states, verify scientific equality, or issue a numerical
certificate.

## See also

[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md),
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
validate_postrank_tie_pairwise(pw)
```
