# Disclosure and Error Frontier Over Tau or One Budget

`postrank_frontier()` solves a grading problem across a grid of
unordered-pair costs `tau` (and/or a grid of error budgets `q_grid` on
one criterion `q_criterion`), summarizing how the fraction of ordered
pairs `N / M` and expected wrong-order rates `E_k / N` vary across
settings.

## Usage

``` r
postrank_frontier(
  pairwise,
  weights = NULL,
  tau,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  q_criterion = NULL,
  q_grid = NULL,
  backend = NULL,
  control = list(),
  strategy = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
```

## Arguments

- pairwise:

  Pairwise directional-error source accepted by
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
  or a `postrank_fit` / `postrank_analysis` whose pairwise probabilities
  and base policy are reused (when reusing a fit or analysis, supply
  only `tau` and/or `q_criterion` + `q_grid`).

- weights, G_max, objective, q, exact_G, minimax_criteria,
  minimax_refine:

  Policy arguments passed to
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
  when neither `settings` nor a fit/analysis is supplied.

- tau:

  Numeric vector of unordered-pair costs in `(0, 0.5]`. May be omitted
  only when `q_criterion` and `q_grid` are supplied together with
  `settings` or a fit/analysis (whose `tau` is then held fixed).

- q_criterion, q_grid:

  Optional criterion ID and numeric vector of expected-error budgets in
  `[0, 1]` (supply both together or omit both). When both `tau` and
  `q_grid` have multiple values, all combinations are solved.

- backend, control, strategy:

  Solver, controls and search strategy, resolved as in
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

- settings:

  Optional
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object supplying the base policy (`tau` and/or `q_criterion` +
  `q_grid` may accompany it, whereas separate policy arguments stop with
  `settings_conflict`).

## Value

A `postrank_frontier` list whose `table` has one row per solved setting
with columns `tau`, `q_value`, `status`, `G`, `N`, `disclosure_rate`
(`N / M`), `primary_risk`, `weighted_risk`, `risk_absolute_gap`,
`relation_identity`, `E_over_N_<k>` and `risk_<k>`, alongside `weights`,
`G_max`, `objective`, `q`, `exact_G`, `q_criterion`, `backend`,
`strategy`, `interpretation`, `input_identity` and `schema_version`.

## Details

Solving requires an optimization solver: install the free `highs`
package (`install.packages("highs")`) and use `backend = "highs"` or
`options(postrank.backend = "highs")`, or provide a licensed Gurobi
installation (the default). `postrank` never switches solvers on its
own.

Because changing `tau` changes the loss definition itself, compare
frontier rows by their ordered pair counts `N`, error rates `E_k / N`
and grade relations rather than ranking rows by `primary_risk`. Holding
the input and constraint family fixed, exact optima have nondecreasing
`N` as `tau` increases; if two rows at `tau_2 > tau_1` both have valid
`risk_absolute_gap` at most \\\epsilon\\, then \\N_2 - N_1 \ge -2
\epsilon M / (\tau_2 - \tau_1)\\. Rows without a checked grading record
`NA` action metrics.

## See also

[`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md),
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md),
[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)

## Examples

``` r
# Inspect a stored frontier without running a solver:
fr <- postrank_example("toy_frontier")
fr$table[, c("tau", "G", "N", "disclosure_rate", "primary_risk", "status")]
#>    tau G N disclosure_rate primary_risk  status
#> 1 0.15 1 0       0.0000000       0.1500 optimal
#> 2 0.25 2 2       0.6666667       0.2125 optimal
#> 3 0.40 2 2       0.6666667       0.2625 optimal
# Solve a three-point tau frontier with the optional highs package:
pw <- postrank_pairwise(postrank_toy)
postrank_frontier(pw, c(need_A = 0.6, need_B = 0.4), tau = c(0.1, 0.25, 0.4),
  G_max = 3L, backend = "highs", control = postrank_control(time_limit = 10))
#> <postrank_frontier>  3 choices of withholding cost
#>    Tau  Loss   Disclosed Grades Gap
#>    0.1  0.1000 0.0%      1      1.39e-17
#>    0.25 0.2125 66.7%     2      0
#>    0.4  0.2625 66.7%     2      0
#>   Changing tau changes the loss. Compare grades and disclosure across rows;
#>     do not rank methods by losses computed at different tau values.
#>   Solver gaps limit comparisons; missing bounds or grades leave the
#>     corresponding conclusions unavailable.
#>   i x$table retains each status, criterion loss and error among disclosed
#>     pairs.
```
