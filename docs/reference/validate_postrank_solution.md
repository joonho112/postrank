# Check a Solver Candidate for the Grading Problem

`validate_postrank_solution()` checks whether a raw primal vector
returned by an optimization solver defines a feasible grading for
`problem`, and recomputes its pairwise relations and posterior expected
loss.
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
runs this check automatically on every candidate.

## Usage

``` r
validate_postrank_solution(problem, solution, tolerances = list())
```

## Arguments

- problem:

  A validated `postrank_problem` object from
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md).

- solution:

  Numeric primal vector in the column order of `problem$model` (such as
  `fit$raw_solution`), or `NULL` when no candidate was returned. To
  evaluate a named grade vector directly without primal model variables,
  use
  [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md).

- tolerances:

  Named list of nonnegative finite tolerances overriding the defaults
  `feasibility = 1e-7`, `integrality = 1e-6` and `objective = 1e-7`.

## Value

A `postrank_solution_validation` list containing:

- `valid`: `TRUE` when the rounded integer solution passes all variable,
  constraint, grade-relation and objective checks;

- `issues` and `warnings`: list of failure records and character vector
  of raw-primal residual notes;

- `grade`, `evaluation` and `recomputed_raw_objective`: the checked
  grade vector and its
  [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
  summary (`NULL` / `NA` when `valid` is `FALSE`);

- `raw_residuals`, `rounded_residuals`, `integrality_residual`,
  `rounded_solution`, `raw_labels`, `raw_pairs`, `epigraph_shortfall`,
  `epigraph_repaired`, `validity_basis` (`"rounded_integer_solution"`)
  and `tolerances`.

## Details

Integer and binary variables must lie within `tolerances$integrality` of
an integer before rounding. The rounded solution must satisfy variable
bounds and linear constraints within `tolerances$feasibility`, match the
pair orderings implied by its grades, satisfy `G_max`, any `exact_G` and
any `q` error budgets, and match the recomputed objective within
`tolerances$objective`. Raw (unrounded) primal residuals exceeding
`tolerances$feasibility` are recorded in `warnings`. For minimax
problems, an auxiliary `t` variable falling below the maximum selected
criterion loss by at most `tolerances$objective` is raised to that value
before checking rounded constraints.

Passing `validate_postrank_solution()` confirms feasibility of the
candidate grading, not solver optimality, lower-bound validity or model
adequacy.

## See also

[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
checked <- validate_postrank_solution(one$problem, one$fit$raw_solution)
checked$valid
#> [1] TRUE

absent <- validate_postrank_solution(one$problem, NULL)
absent$valid
#> [1] FALSE
absent$issues[[1]]$code
#> [1] "no_incumbent"
```
