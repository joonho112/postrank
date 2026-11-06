# Check a Posterior Input and Inspect Its Validation Results

The validator checks the target definitions, numerical values, axes and
sampling history required by the ordinary input routes. Its `valid` and
`issues` fields report whether the input meets those requirements.

## Usage

``` r
validate_postrank_draws(x, source = NULL)
```

## Arguments

- x:

  A canonical `applied-0.1` named-list payload or a `postrank_draws`.

- source:

  Reserved; leave `NULL`. To compare mapped values with a `posterior`
  source object, use
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

## Value

A `postrank_validation` list with logical `valid`, an `issues` list of
error codes, paths and messages, and separate check flags. Invalid
payloads are reported in this record rather than constructed as inputs.

## Details

The checks cover the supported structures, ordered IDs, target and
source declarations, numeric values, zero-tie policy and sampling
history. They do not change the values or perform a fit. The function
does not run a general JSON Schema validator, so `schema_checked` is
`FALSE` even for a valid R input. The additional placeholder-text checks
of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
are not applied here.

`source_values_checked`, `jointness_verified` and `convergence_verified`
are separate from `valid`. Source-value comparison is retained only when
an existing object's successful
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)
audit matches its current input identity. Structural validity does not
establish the scientific truth of the declarations, model adequacy or
convergence. The tie-aware validator has a different return convention;
see
[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md).

## See also

[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)

## Examples

``` r
check <- validate_postrank_draws(postrank_toy)
check$valid
#> [1] TRUE
check[c("source_values_checked", "jointness_verified", "convergence_verified")]
#> $source_values_checked
#> [1] FALSE
#> 
#> $jointness_verified
#> [1] FALSE
#> 
#> $convergence_verified
#> [1] FALSE
#> 

# Deliberately omit required context to inspect the reported problem.
bad <- postrank_toy
bad$context <- NULL
validate_postrank_draws(bad)$issues
#> [[1]]
#> [[1]]$code
#> [1] "invalid_input"
#> 
#> [[1]]$path
#> [1] "$"
#> 
#> [[1]]$message
#> [1] "$: missing fields: context"
#> 
#> [[1]]$severity
#> [1] "error"
#> 
#> 
```
