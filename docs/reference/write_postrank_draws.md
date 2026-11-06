# Save a Posterior Input as JSON

The writer saves posterior values and their scientific descriptions in
the format read by
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md).
The input is validated before writing, and its declared entity,
criterion and draw order is preserved.

## Usage

``` r
write_postrank_draws(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A `postrank_draws` or complete canonical `applied-0.1` payload.

- path:

  Destination JSON file. Its parent directory must exist.

- overwrite:

  Logical; allow replacement of an existing file. Defaults to `FALSE`.

## Value

The destination path, invisibly.

## Details

Joint arrays, criterion-wise blocks and complete exact finite laws are
supported. Values are written with 17 significant digits, retaining
singleton dimensions and source sampling histories. The writer creates a
temporary file in the destination directory and renames it into place.

The file contains the canonical input, not a saved validation receipt or
external source-value audit. Reading it performs validation again; a
prior adapter's source-value comparison is not claimed merely because
the file round-trips. Required declaration checks apply without the
high-level array route's extra placeholder check. Use
[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)
for an equality-neutral input.

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
