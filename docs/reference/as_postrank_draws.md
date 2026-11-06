# Prepare a Fully Described Posterior Input

A complete posterior description is validated and prepared for
directional comparisons. This constructor accepts the full
producer-supplied metadata, including an exact finite law or separate
criterion-wise blocks. For a numeric joint array,
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
constructs the metadata from explicit scientific declarations.

## Usage

``` r
as_postrank_draws(x)
```

## Arguments

- x:

  A canonical `applied-0.1` named-list payload, or an existing
  `postrank_draws` to revalidate.

## Value

A `postrank_draws` object containing the supplied values in their
declared order and a `validation` record. Invalid input raises a
structured error containing its code, path and message.

## Details

The supported forms are joint equal-weight IID or MCMC draws
(`joint_draws`), separate equal-weight criterion blocks
(`criterion_blocks`), and a complete exact finite posterior
(`finite_law`). Every form records entity/criterion IDs, target
definitions, context, identification, the zero-equality policy and
provenance. Joint arrays retain all three axes, including `S x n x 1`
for a single criterion. Values must already be oriented so that larger
means higher priority.

MCMC inputs retain original chain IDs, iteration numbers, warmup and
selection history. Criterion-wise blocks preserve joint entity states
within each criterion without specifying dependence across criteria. An
exact finite law specifies every positive-mass state, safe-integer
target values and positive integer mass numerators summing to a common
denominator. Such a law describes the complete posterior rather than a
Monte Carlo sample; its evaluation requires the optional `gmp` package.

The ordinary input domain assumes zero probability of within-criterion
equality between distinct entities and rejects observed ties. Recover
unrounded continuous values or use
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
for genuine equality mass. Validation checks the structure and presence
of declarations; it cannot verify their scientific truth or convergence.
The extra placeholder checks of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
are not applied here. See
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md)
for the separate check flags.

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md),
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md),
[`vignette("m3-posterior-inputs", package = "postrank")`](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md)

## Examples

``` r
# The bundled generator supplies a complete two-criterion canonical input.
# source() only defines this synthetic generator; it does not fit a model.
generator <- new.env()
sys.source(system.file("examples", "make-synthetic-input.R",
  package = "postrank"), envir = generator)
payload <- generator$make_postrank_synthetic_input()
draws <- as_postrank_draws(payload)
draws$criterion_ids
#> [1] "need_A" "need_B"
dim(draws$joint_draws$tensor$values)
#> [1] 32  3  2
```
