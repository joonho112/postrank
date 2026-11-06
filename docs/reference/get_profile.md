# Extract Expected Errors and Loss for Each Criterion

The stored grade report is summarized by criterion. A one-criterion
analysis has one row; for several criteria, the rows give the expected
errors and withholding loss associated with the common grading. The
calculation uses the stored evaluation without recalculating grades or
posterior summaries.

## Usage

``` r
get_profile(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis`.

- ...:

  Unused arguments for generic compatibility.

## Value

A data frame in input criterion order with columns: `criterion`,
`weight`, `E`, `E_over_M`, `E_over_N`, `risk`, `q`, `budget_slack` and
`is_minimax_max`. Returns zero rows with these same columns when no
validated grade is available.

## Details

`E` is the posterior expected number of wrong disclosed directions.
`E_over_M` divides by all unordered pairs; `E_over_N` divides by
disclosed pairs and is `NA` when N=0. Criterion `risk` adds the
withholding cost: `(E + tau * (M - N)) / M`. These describe the supplied
posterior and loss, not realized error rates or simultaneous guarantees.

`q` is the criterion's error budget and `budget_slack = q * N - E`; both
are `NA` without a budget. A nonnegative slack satisfies that count
constraint before numerical tolerance is considered. `is_minimax_max`
identifies included criteria attaining the minimax maximum within the
comparison tolerance; it is false for weighted problems.

## See also

[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  two <- postrank(pr_tutorial$two, weights = c(score_A = .5, score_B = .5),
    tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_profile(two)
}
#>   criterion weight         E   E_over_M   E_over_N       risk  q budget_slack
#> 1   score_A    0.5 0.1596996 0.01064664 0.01774440 0.09064664 NA           NA
#> 2   score_B    0.5 0.2405960 0.01603973 0.02673289 0.09603973 NA           NA
#>   is_minimax_max
#> 1          FALSE
#> 2          FALSE
```
