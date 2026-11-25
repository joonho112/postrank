# Save a Posterior Input as JSON

`write_postrank_draws()` validates a `postrank_draws` object (or
complete `applied-0.1` list) and writes its values, target descriptions
and sampling history to a JSON file that
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)
can restore.

## Usage

``` r
write_postrank_draws(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A `postrank_draws` object or a complete `applied-0.1` input list.

- path:

  Destination JSON file path. Its parent directory must exist.

- overwrite:

  Logical scalar (default `FALSE`); whether to replace an existing file
  at `path`.

## Value

`path`, invisibly.

## Details

Joint arrays, criterion-wise blocks and exact finite laws are supported.
Numbers are formatted with 17 significant digits, preserving entity,
criterion and draw order, singleton dimensions (`K = 1`), and MCMC chain
histories. The JSON text is checked against the installed
`draws-schema.json` specification, written to a temporary file in
`dirname(path)` and renamed into place.

The file stores the input fields (`schema_version = "applied-0.1"`), not
the in-memory `validation` record. Reading the file runs
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md)
afresh, so a prior
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)
`source_audit` is not carried through JSON. For exact-tie inputs, use
[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md).

## See also

[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md),
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)

## Examples

``` r
path <- tempfile(fileext = ".json")
write_postrank_draws(postrank_toy, path)
restored <- read_postrank_draws(path)
identical(restored$joint_draws$tensor$values,
  postrank_toy$joint_draws$tensor$values)
#> [1] TRUE
identical(restored$joint_draws$draw_index, postrank_toy$joint_draws$draw_index)
#> [1] TRUE
unlink(path)
```
