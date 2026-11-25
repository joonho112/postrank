# Extract Posterior Loss with Its Solver Bound and Status

`get_risk()` returns the posterior expected loss (`risk`) of the checked
grading in `x` together with the solver's lower bound across all allowed
gradings, optimization gap and normalized termination status.

## Usage

``` r
get_risk(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` object.

- ...:

  Unused arguments for generic compatibility.

## Value

A named list with four elements:

- `risk`: posterior expected loss of the checked grading (weighted sum
  of criterion losses when `objective == "weighted"`, or largest
  selected criterion loss when `objective == "minimax"`), or `NA_real_`
  when no checked grading is available;

- `lower_bound`: a loss that no allowed grading for `x`'s problem can
  beat (up to solver and floating-point tolerances), or `NA_real_` when
  no usable lower bound is available;

- `gap`: `risk - lower_bound`, or `NA_real_` when either is `NA`;

- `status`: normalized solver status string (`"optimal"`,
  `"feasible_not_certified"`, `"time_limit"`, `"infeasible"`,
  `"unbounded"`, `"numerical_error"` or `"unknown"`).

## Details

`lower_bound`, `gap` and `status` describe optimization over the
supplied pairwise probabilities only; they do not measure posterior
uncertainty, Monte Carlo error, or excess loss ("regret") under the true
posterior when probabilities are estimated from finite draws.

When a solver stops at its time limit without a checked grading, `risk`
and `gap` are `NA_real_` while `status` and any usable `lower_bound` are
kept (distinct from a valid one-grade report leaving all pairs
unordered, which has `risk = tau`). Even with a checked grading,
`lower_bound` and `gap` are `NA_real_` if no bound was computed or if
the reported bound was excluded on numerical checks; inspect
`objective$bound_source` (on a `postrank_fit`, or
`x$fit$objective$bound_source` on a `postrank_analysis`) and
`x$warnings` for details.

## See also

[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
get_risk(one)
#> $risk
#> [1] 0.04165164
#> 
#> $lower_bound
#> [1] 0.04165164
#> 
#> $gap
#> [1] 0
#> 
#> $status
#> [1] "optimal"
#> 
```
