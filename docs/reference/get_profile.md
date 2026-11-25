# Extract Expected Errors and Loss for Each Criterion

`get_profile()` returns a one-row-per-criterion table of posterior
expected wrong-order errors, losses and error-budget margins for the
checked grading stored in `x`, without running a solver or recomputing
probabilities.

## Usage

``` r
get_profile(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` object.

- ...:

  Unused arguments for generic compatibility.

## Value

A data frame in input criterion order with columns `criterion`,
`weight`, `E`, `E_over_M`, `E_over_N`, `risk`, `q`, `budget_slack` and
`is_minimax_max`. When no checked grading is available, a zero-row data
frame with these same columns and types is returned.

## Details

For each criterion, `E` is the posterior expected number of wrong-order
ordered (`disclosed`) pairs, `E_over_M` divides `E` by all `M` unordered
pairs, `E_over_N` divides `E` by the `N` ordered pairs (`NA` when
`N = 0`), and `risk` is the posterior expected loss
`(E + tau * (M - N)) / M`.

`q` is the criterion's expected-error budget from
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
and `budget_slack` is `q * N - E` (both `NA` when no `q` budget was set
for that criterion). `is_minimax_max` is `TRUE` for included criteria
within `1e-12` of the maximum criterion loss when
`objective == "minimax"`, and `FALSE` for weighted problems.

## See also

[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)

## Examples

``` r
two <- postrank_example("tutorial_two")
get_profile(two)
#>   criterion weight         E   E_over_M   E_over_N       risk  q budget_slack
#> 1   score_A    0.5 0.1596996 0.01064664 0.01774440 0.09064664 NA           NA
#> 2   score_B    0.5 0.2405960 0.01603973 0.02673289 0.09603973 NA           NA
#>   is_minimax_max
#> 1          FALSE
#> 2          FALSE
```
