# Read Posterior Draws or an Exact Finite Law from JSON

`read_postrank_draws()` reads a saved posterior input from a JSON file
in `postrank`'s `applied-0.1` JSON schema, restoring its values, entity
and criterion order, target descriptions and sampling history. Files in
this format are written by
[`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md).

## Usage

``` r
read_postrank_draws(path)
```

## Arguments

- path:

  Path to an existing `applied-0.1` JSON file.

## Value

A validated `postrank_draws` object from
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md).
Malformed JSON, schema mismatches or invalid input values stop the call
with a structured error.

## Details

Joint equal-weight draws (`joint_draws`), separate criterion-wise
matrices (`criterion_blocks`) and exact finite posterior laws
(`finite_law`) are supported. Singleton criterion dimensions (`K = 1`)
are kept, and target values are never negated, reordered or rounded on
import. Before decoding, the reader rejects duplicate JSON object keys,
nonfinite or underflowing numbers, and `finite_law` integer tokens
outside the exact 53-bit integer range (`<= 9007199254740991`), then
checks the JSON structure against the installed `draws-schema.json`
specification and runs
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md).

Required descriptions are checked for presence and non-empty text
without the placeholder-word list of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md).
Reading a file does not verify scientific identification, jointness or
MCMC convergence. For exact-tie inputs, use
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md).

## See also

[`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md),
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md)

## Examples

``` r
path <- system.file("examples", "synthetic-iid.json", package = "postrank")
draws <- read_postrank_draws(path)
draws$entity_ids
#> [1] "001"    "site-B" "site C"
draws$criterion_ids
#> [1] "need_A" "need_B"
validate_postrank_draws(draws)$valid
#> [1] TRUE
```
