# Validate a Tie-Aware Posterior Input

`validate_postrank_tie_draws()` checks the numerical arrays or
finite-law states, declarations, criterion equality partitions, and
content hash of a `postrank_tie_draws` object used in tie-aware mode
(the workflow for posteriors with positive probability of exact equality
under equality-neutral loss).

## Usage

``` r
validate_postrank_tie_draws(x)
```

## Arguments

- x:

  A `postrank_tie_draws` object from
  [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
  or
  [`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md).

## Value

`TRUE` invisibly when `x` passes all checks. Unlike
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md),
invalid or modified objects stop with a structured error rather than
returning a report with `valid = FALSE`.

## Details

Checks cover `"tie-aware-input-0.1"` fields, UTF-8 text, axis dimensions
and order, sampling history or exact rational masses (`gmp` required for
`"exact_finite_posterior"`), exact equality across every retained draw
within declared structural classes, and `x$input_identity`. Ordinary
`postrank_draws` objects are rejected. Passing validation confirms
internal consistency, not scientific equality, MCMC convergence, or a
numerical certificate.

## See also

[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md),
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md),
[`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)

## Examples

``` r
input <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
validate_postrank_tie_draws(input)
input$equality$criterion_classes
#> $S
#>   A   B   C   D 
#> "A" "A" "C" "D" 
#> 
#> $C
#>   A   B   C   D 
#> "A" "A" "A" "D" 
#> 
```
