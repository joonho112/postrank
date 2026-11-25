# Criterion-Wise Cost of a Common Grade

`postrank_commonality_cost()` measures how much posterior expected loss
a single common grading adds on each criterion compared with grading
that criterion on its own under the same `tau` and grade-count rules. It
solves one single-criterion optimization problem per criterion, seeding
each search with the common grading.

## Usage

``` r
postrank_commonality_cost(
  fit,
  backend = NULL,
  control = list(),
  strategy = NULL,
  protection = c("drop", "keep")
)
```

## Arguments

- fit:

  A `postrank_fit` or `postrank_analysis` object of a public
  common-grade problem with a checked grading
  (`incumbent_validated = TRUE`).

- backend, control, strategy:

  Solver, controls and search strategy used for each criterion solve,
  resolved as in
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

- protection:

  How `q` error budgets from `fit` are treated in the single-criterion
  problems: `"drop"` (the default, solving without `q` rows) or `"keep"`
  (retaining all `q` rows). In either case, the common grading is
  feasible for every criterion problem.

## Value

A `postrank_commonality_cost` list containing `table` (one row per
criterion with `criterion_id`, `common_grade_risk`, `own_best_risk` `U`,
`own_lower_bound` `L`, `cost_lower` `max(0, common - U)`, `cost_upper`
`common - L`, `own_status`, `own_G`, `own_disclosures` and
`relation_agreement`), plus `settings`, `protection`, `backend`,
`strategy`, `interpretation`, `input_identity`, `problem_identity` and
`schema_version`.

## Details

Solving requires an optimization solver: install the free `highs`
package (`install.packages("highs")`) and use `backend = "highs"` or
`options(postrank.backend = "highs")`, or provide a licensed Gurobi
installation (the default). `postrank` never switches solvers on its
own.

For criterion `k`, the cost of imposing the common grading lies in
`[max(0, common_k - U_k), common_k - L_k]`, whose width is at most the
solver's absolute gap `U_k - L_k` on criterion `k`'s own problem. That
interval reflects optimization bounds on criterion `k`'s solve, not
posterior uncertainty about the cost.

## See also

[`postrank_plot_commonality()`](https://joonho112.github.io/postrank/reference/postrank_plot_commonality.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md),
[`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md)

## Examples

``` r
# Inspect a stored commonality-cost result without running a solver:
cc <- postrank_example("toy_commonality")
cc$table[, c("criterion_id", "common_grade_risk", "own_best_risk",
  "cost_lower", "cost_upper")]
#>   criterion_id common_grade_risk own_best_risk cost_lower cost_upper
#> 1       need_A         0.1041667     0.1041667  0.0000000  0.0000000
#> 2       need_B         0.3750000     0.1041667  0.2708333  0.2708333
# Solve directly with the optional highs package:
toy <- postrank_example("toy_analysis")
postrank_commonality_cost(toy, backend = "highs",
  control = postrank_control(time_limit = 10))
#> <postrank_commonality_cost>  2 criteria sharing one grade assignment
#>   Each criterion's separate calculation uses the same withholding cost and
#>     grade limit.
#>   Criterion error limits in separate calculations: removed.
#>    Criterion Common loss Own loss Cost lower Cost upper
#>    need_A    0.1042      0.1042   0.0000     0.0000
#>    need_B    0.3750      0.1042   0.2708     0.2708
#>   Own loss is the best validated separate action. Cost limits use its solver
#>     lower bound, so an unfinished solve can leave a range or NA.
#>   i x$table also records solver status, disclosure and agreement for each
#>     separate calculation.
```
