# Prepare a Fully Described Posterior Input

`as_postrank_draws()` validates a complete `applied-0.1` posterior input
list (or revalidates an existing `postrank_draws` object) and returns a
`postrank_draws` object. Use it when constructing separate
criterion-wise draw blocks, an exact finite posterior law, or custom
MCMC draw histories; for an ordinary numeric array of joint draws,
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
with
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
is simpler.

## Usage

``` r
as_postrank_draws(x)
```

## Arguments

- x:

  A complete `applied-0.1` named list, or an existing `postrank_draws`
  object to revalidate.

## Value

A `postrank_draws` object storing the input fields in their declared
order, `input_schema_version` (`"applied-0.1"`), `schema_version`
(`"0.1.0"`), and a `validation` record from
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md).
Invalid input stops with the first reported issue (`code`, `path` and
`message`).

## Details

Three posterior forms are accepted:

- `joint_draws`: equal-weight IID or MCMC draws in an `S x n x K` array
  (keeping `S x n x 1` when `K = 1`), with MCMC chain IDs, iteration
  numbers and warmup/thinning history;

- `criterion_blocks`: separate equal-weight `S_k x n` matrices per
  criterion, preserving joint entity states within each criterion
  without specifying dependence across criteria;

- `finite_law`: an exact discrete posterior listing every positive-mass
  state with safe-integer target values and positive integer probability
  numerators summing to a common denominator (not a Monte Carlo sample;
  evaluating it with
  [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
  requires the optional `gmp` package).

Values must already be oriented so that larger values mean higher
priority. Distinct entities must have zero probability of exact equality
within each criterion, and observed ties stop the call; for posteriors
with positive probability on ties, use
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).
Required descriptions are checked for structure and non-empty text
without the placeholder-word list of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md).

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md),
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md),
[`vignette("m3-posterior-inputs", package = "postrank")`](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md)

## Examples

``` r
# Build a complete synthetic two-criterion input list from the bundled script:
generator <- new.env()
sys.source(system.file("examples", "make-synthetic-input.R",
  package = "postrank"), envir = generator)
input_list <- generator$make_postrank_synthetic_input()
draws <- as_postrank_draws(input_list)
draws$criterion_ids
#> [1] "need_A" "need_B"
dim(draws$joint_draws$tensor$values)
#> [1] 32  3  2
```
