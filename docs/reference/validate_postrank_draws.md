# Check a Posterior Input and Inspect Its Validation Results

`validate_postrank_draws()` checks whether a `postrank_draws` object or
an `applied-0.1` input list satisfies `postrank`'s structural, numeric
and description requirements, returning a report rather than stopping on
an invalid input.

## Usage

``` r
validate_postrank_draws(x, source = NULL)
```

## Arguments

- x:

  A `postrank_draws` object or an `applied-0.1` named list.

- source:

  Reserved; leave `NULL` (any non-`NULL` value stops with
  `unsupported_source_audit`). To check values against a `posterior`
  package object, use
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

## Value

A `postrank_validation` list with components:

- `valid`: `TRUE` if all R structural and semantic checks passed,
  `FALSE` otherwise;

- `issues`: empty list when `valid` is `TRUE`, otherwise a list
  containing the error `code`, `path`, `message` and `severity`;

- `semantic_checks_completed`: check IDs `"DC01"` through `"DC15"` when
  `valid` is `TRUE`, otherwise
  [`character()`](https://rdrr.io/r/base/character.html);

- `eligible_functional`, `input_identity`, `validator_version`,
  `check_results` and `limitations`;

- `schema_checked` (`FALSE`), `source_values_checked`,
  `jointness_verified` (`FALSE`) and `convergence_verified` (`FALSE`).

## Details

The checks verify axis order, entity and criterion IDs, target and
source descriptions, finite numeric values, absence of within-criterion
ties, and MCMC chain-history consistency. They do not run an external
Draft 2020-12 JSON Schema validator (`schema_checked` is always
`FALSE`), and they do not apply the placeholder-word list of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md).

`source_values_checked` is `TRUE` only when `x` is an unchanged
`postrank_draws` object created by
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md),
in which case `source_audit` is also retained. `valid = TRUE` means the
input's structure and required descriptions are complete; it does not
verify scientific identification, joint sampling or MCMC convergence.
For exact-tie inputs, see
[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md),
which uses a different return format.

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

# Omit required context to inspect the reported issue without throwing an error:
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
