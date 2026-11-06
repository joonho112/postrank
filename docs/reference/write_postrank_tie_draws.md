# Save an Equality-Neutral Posterior Input as JSON

The writer stores a tie-aware input with its numerical values, target
definitions and equality classes. The file can be read by
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)
with all entities and their original order retained.

## Usage

``` r
write_postrank_tie_draws(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A complete canonical `tie-aware-input-0.1` payload or an unchanged
  `postrank_tie_draws` object.

- path:

  Destination JSON file; its parent directory must exist.

- overwrite:

  Logical; allow replacement of an existing file. Defaults to `FALSE`.

## Value

The destination path, invisibly.

## Details

Validation is repeated before writing. Values use 17 significant digits;
all entities, singleton dimensions, sampling histories and named
criterion equality partitions are retained. A temporary file in the
destination directory is renamed into place after the supported JSON
checks pass.

The file stores the canonical input, not a claim of scientific
verification. Reading it repeats validation and recreates its content
identity. Changed objects fail validation rather than being silently
accepted. Use
[`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md)
for the ordinary zero-equality input domain.

## See also

[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md),
[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
    package = "postrank"))
  path <- tempfile(fileext = ".json")
  write_postrank_tie_draws(input, path)
  restored <- read_postrank_tie_draws(path)
  identical(restored$input_identity, input$input_identity)
  identical(restored$equality, input$equality)
  unlink(path)
}
```
