# Criterion-Wise Cost of a Common Grade

The criterion-wise posterior-risk cost of a common grading is assessed
by solving a separate problem for each criterion. Each optimization
assigns all weight to that criterion while retaining the common
problem's tau and grade-count settings. A working optimizer backend is
required.

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

  A `postrank_fit` or `postrank_analysis` of the common weighted or
  minimax problem, with a validated grade.

- backend, control, strategy:

  Resolved as in
  [`postrank_solve`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  (`backend = NULL`: option, then Gurobi; `strategy = NULL`:
  `control$strategy`) and used for the criterion problems.

- protection:

  `"drop"` (default) solves each criterion problem without the common
  problem's q rows; `"keep"` keeps them. Either way the common grade is
  feasible for the criterion problem. These choices define different
  own-criterion comparison families; record which was used.

## Value

A `postrank_commonality_cost` list whose `table` has, per criterion: the
common grade's criterion risk, the criterion's own best risk (upper
bound U) and lower bound L, the cost interval `[common - U, common - L]`
(its width is at most the criterion problem's risk gap, less when the
lower end is clipped at zero; a certified problem's gap is within the
absolute or relative gap control), the own grade's status, grade count
and disclosures, and the relation agreement between the own and common
grades. The interval reflects optimization bounds, not posterior
uncertainty about the cost.

## Details

The cost is the increase in criterion risk associated with imposing a
common grade. This is a descriptive comparison under the same posterior
and has no welfare interpretation. The lower endpoint is clipped at zero
because the common action belongs to each comparison family. An
unfinished solve may yield an interval rather than a single cost. With
one criterion there is no conflict between criteria, although an
unfinished common solve can still be suboptimal.

## Examples

``` r
draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
  package = "postrank", mustWork = TRUE))
pairwise <- postrank_pairwise(draws)
weights <- c(need_A = .6, need_B = .4)
if (requireNamespace("highs", quietly = TRUE)) {
  problem <- postrank_problem(pairwise, weights, tau = .25, G_max = 3L)
  fit <- postrank_solve(problem, backend = "highs", control = list(time_limit = 10))
  postrank_commonality_cost(fit, backend = "highs", control = list(time_limit = 10))
}
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
