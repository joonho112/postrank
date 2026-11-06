# Extract Posterior Loss with Its Solver Bound and Status

The primary risk of the validated grading is returned with the
whole-problem lower bound, absolute risk gap and normalized solver
status. These quantities describe both the available decision and the
extent to which numerical optimality has been established.

## Usage

``` r
get_risk(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis`.

- ...:

  Unused arguments for generic compatibility.

## Value

A named list with numeric `risk`, `lower_bound` and `gap`, and character
`status`. Unavailable numeric values are `NA`.

## Details

`risk` is weighted expected loss for a weighted problem, or the largest
selected criterion risk for minimax. With one criterion and weight 1, it
is that criterion's risk. The gap is an optimization quantity for the
supplied probabilities, not posterior uncertainty or a bound on
true-posterior regret by itself.

A time limit may leave validated grades or none. Without validated
grades, risk and gap are `NA`, while status and any usable lower bound
remain. Missing or rejected bounds can also make the gap unavailable
despite a retained grade. Consult the fit's `objective$bound_source`,
warnings and validation details for the numerical qualifications.

## See also

[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_risk(one)
}
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
