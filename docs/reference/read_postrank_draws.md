# Read Posterior Draws or an Exact Finite Law from JSON

The reader imports a saved posterior input, including its target
definitions, ordered IDs and original sampling history. Files in this
format are produced by
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
Invalid JSON or unsupported input raises a structured error.

## Details

The reader supports joint equal-weight draws, criterion-wise blocks and
complete exact finite laws. It preserves the singleton criterion
dimension for `K = 1` and does not orient, reorder or round supplied
targets. Duplicate decoded JSON keys, invalid JSON numbers and malformed
supported array shapes are rejected. Exact-law integer tokens are
checked before conversion so that unsafe values cannot pass by
floating-point rounding.

Supported JSON shape checks and R semantic checks are performed; this is
not a general JSON Schema validation. Required declarations are
preserved without the high-level array route's additional
placeholder-text check. Reading a file does not verify its scientific
provenance, jointness or convergence. Use
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)
for equality-neutral inputs; this reader does not convert between the
two input domains.

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
