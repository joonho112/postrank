# Check an Equality-Neutral Posterior Input

The validator checks numerical values, declared equality classes and
sampling history for a tie-aware analysis. It also detects changes
introduced after the object was constructed by
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

## Usage

``` r
validate_postrank_tie_draws(x)
```

## Arguments

- x:

  A `postrank_tie_draws` from
  [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

## Value

Invisible `TRUE` on success. Invalid or changed input raises a
structured error; unlike
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md),
this function does not return a record with `valid = FALSE`.

## Details

Checks cover ordered axes, required source descriptions, sampling
history, exact within-class equality and the object's content identity.
Scientific equality classes for Monte Carlo draws remain declarations
about the model; their agreement with finitely many draws is not proof
of almost-sure equality. Complete finite laws determine equality from
all positive-mass states. Validation does not establish scientific
provenance, jointness, stationarity or convergence. Ordinary
`postrank_draws` inputs are not accepted, and reusing the constructor
does not silently accept mutations.

## See also

[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md),
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
    package = "postrank"))
  valid <- validate_postrank_tie_draws(input)
  valid
  input$equality$criterion_classes
}
#> $S
#>   A   B   C   D 
#> "A" "A" "C" "D" 
#> 
#> $C
#>   A   B   C   D 
#> "A" "A" "A" "D" 
#> 
```
