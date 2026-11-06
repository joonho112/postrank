# Read an Equality-Neutral Posterior Input from JSON

The reader imports posterior values, declarations of genuine equality
and original source histories for a tie-aware analysis. Files produced
by
[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)
preserve the numerical targets and IDs.

## Usage

``` r
read_postrank_tie_draws(path)
```

## Arguments

- path:

  Path to an existing `tie-aware-input-0.1` JSON file.

## Value

A validated `postrank_tie_draws` from
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

## Details

The reader supports joint equal-weight IID/MCMC draws and complete exact
finite laws. It preserves the `K = 1` criterion axis and performs no
target transformation. It does not convert ordinary inputs or
reinterpret rounded continuous values as a scientific equality model.

Duplicate decoded keys, malformed supported array shapes and unsafe
finite-law integer tokens are rejected before floating conversion. Shape
checks cover the supported JSON binding; the R validator checks the
corresponding metadata, values and equality partition. These checks do
not verify scientific equality, jointness or convergence. Complete
finite laws require the optional `gmp` package.

## See also

[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md),
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  input <- read_postrank_tie_draws(path)
  input$criterion_ids
  input$equality$criterion_classes
  validate_postrank_tie_draws(input)
}
```
