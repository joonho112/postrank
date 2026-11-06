# Check a Solver Candidate for the Grading Problem

A numerical solver candidate is checked for feasible grades under the
specified problem, and its pairwise relations and posterior risk are
recomputed. The check is performed within
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
and can also be applied directly to a returned raw solution. Feasibility
of a candidate does not establish optimality.

## Usage

``` r
validate_postrank_solution(problem, solution, tolerances = list())
```

## Arguments

- problem:

  A validated `postrank_problem`.

- solution:

  Numeric primal vector in the problem's model-column order, such as
  `fit$raw_solution`, or `NULL` when no candidate was returned. A named
  grade vector alone is not a primal vector; use
  [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
  to score grades without validating the optimization variables.

- tolerances:

  Named list of nonnegative finite `feasibility`, `integrality` and
  `objective` tolerances. Defaults are `1e-7`, `1e-6` and `1e-7`,
  respectively.

## Value

A `postrank_solution_validation` list with `valid`, `issues`,
`warnings`, raw/rounded residuals, `integrality_residual`,
`rounded_solution`, raw labels/pair variables, and `tolerances`. For a
valid candidate, `grade`, `evaluation` and `recomputed_raw_objective`
describe the checked action. `epigraph_shortfall` and
`epigraph_repaired` record any permitted minimax adjustment.
`validity_basis` is `"rounded_integer_solution"`. Invalid or absent
candidates have `grade` and `evaluation` set to `NULL`; malformed
problems or tolerance settings raise input errors.

## Details

Integer residuals must be within tolerance before the rounded variables
are accepted. The rounded solution must satisfy bounds and rows,
reconstruct the same pair relations as its grades, and meet the grade
cap, any exact count and error-budget constraints. Raw-primal residuals
are retained as diagnostics and can produce warnings even if the rounded
action passes. Thus `valid` refers to the checked action within the
tolerances.

For minimax, a shortfall of the continuous auxiliary variable within the
objective tolerance is raised to the action's maximum criterion risk
before checking the rounded constraints. Larger shortfalls are not
repaired. This function checks neither a solver lower bound nor
optimality, posterior calibration or the scientific accuracy of the
supplied probabilities.

## See also

[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)

## Examples

``` r
problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = .2, G_max = 3L)
absent <- validate_postrank_solution(problem, NULL)
absent$valid
#> [1] FALSE
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank_solve(problem, backend = "highs",
    control = postrank_control(time_limit = 10))
  checked <- validate_postrank_solution(problem, fit$raw_solution)
  checked$valid
}
#> [1] TRUE
```
