# Read a Tie-Aware Posterior Input from JSON

`read_postrank_tie_draws()` reads a `"tie-aware-input-0.1"` JSON file
into a validated `postrank_tie_draws` object for tie-aware mode (the
workflow for posteriors in which distinct entities can be equal with
positive probability under equality-neutral loss, where true equality
has zero loss). Files written by
[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)
round-trip with identical numerical values, IDs, equality partitions,
and `input_identity`.

## Usage

``` r
read_postrank_tie_draws(path)
```

## Arguments

- path:

  Path to an existing `"tie-aware-input-0.1"` JSON file.

## Value

A validated `postrank_tie_draws` object from
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

## Details

Supports both `input_kind = "equal_weight_draws"` (joint IID or MCMC
draws, preserving singleton criterion axes when `K = 1`) and
`"exact_finite_posterior"` (which requires optional package `gmp`).
Before floating-point conversion, `read_postrank_tie_draws()` scans the
raw JSON structure against `inst/schema/tie-draws-schema.json`,
rejecting duplicate object keys, malformed array shapes, and integer
tokens outside safe-integer range (`2^53 - 1`), and then runs
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

Use
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)
for ordinary zero-equality inputs; this reader does not convert ordinary
inputs or treat rounded continuous draws as a valid equality model.
Schema and R validation do not verify scientific equality or MCMC
convergence.

## See also

[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md),
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
input <- read_postrank_tie_draws(path)
input$criterion_ids
#> [1] "S" "C"
input$equality$criterion_classes
#> $S
#>   A   B   C   D 
#> "A" "A" "C" "D" 
#> 
#> $C
#>   A   B   C   D 
#> "A" "A" "A" "D" 
#> 
validate_postrank_tie_draws(input)
```
