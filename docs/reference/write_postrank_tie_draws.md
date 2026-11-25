# Write a Tie-Aware Posterior Input to JSON

`write_postrank_tie_draws()` validates and writes a tie-aware posterior
input (for posteriors with positive probability of exact equality under
equality-neutral loss) to a `"tie-aware-input-0.1"` JSON file readable
by
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md).

## Usage

``` r
write_postrank_tie_draws(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A plain `"tie-aware-input-0.1"` named list or an unmodified
  `postrank_tie_draws` object.

- path:

  Destination JSON file path; `dirname(path)` must already exist.

- overwrite:

  Logical scalar (`FALSE` by default). When `FALSE`, stops with an error
  if `path` already exists.

## Value

`path`, invisibly.

## Details

Re-runs
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
before writing, formats numbers to 17 significant digits while retaining
all entities, singleton dimensions, sampling histories, and criterion
equality partitions, validates the JSON output against
`inst/schema/tie-draws-schema.json`, and writes to a temporary file in
`dirname(path)` before renaming into place. Modified
`postrank_tie_draws` objects fail validation rather than being written.
Use
[`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md)
for ordinary zero-equality inputs.

## See also

[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md),
[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md),
[`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md)

## Examples

``` r
input <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
path <- tempfile(fileext = ".json")
write_postrank_tie_draws(input, path)
restored <- read_postrank_tie_draws(path)
identical(restored$input_identity, input$input_identity)
#> [1] TRUE
identical(restored$equality, input$equality)
#> [1] TRUE
unlink(path)
```
