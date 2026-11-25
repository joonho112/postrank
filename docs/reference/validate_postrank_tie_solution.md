# Validate a Candidate Solution to a Tie-Aware Problem

`validate_postrank_tie_solution()` checks whether a raw primal solution
vector rounds to a feasible grading for a `postrank_tie_problem` and
matches the equality-neutral loss computed directly by
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md).
A passing result confirms feasibility within numerical tolerances; it
does not test optimality, uniqueness, or scientific equality
declarations.

## Usage

``` r
validate_postrank_tie_solution(problem, solution, tolerances = list())
```

## Arguments

- problem:

  A validated `postrank_tie_problem` object from
  [`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md).

- solution:

  Numeric primal vector in `problem$model` column order (such as
  `fit$raw_solution`), or `NULL` when no candidate solution was returned
  (which records issue `"no_incumbent"`).

- tolerances:

  Optional named list with `feasibility`, `integrality`, and `objective`
  tolerances; omitted entries use package defaults.

## Value

A `postrank_tie_solution_validation` list containing `valid`, `issues`,
`warnings`, `raw_residuals`, `rounded_residuals`,
`integrality_residual`, `rounded_solution`, `raw_labels`, `raw_pairs`,
`grade` and `evaluation` (both `NULL` unless `valid` is `TRUE`),
`recomputed_raw_objective`, `validity_basis`, and `tolerances`. An
absent candidate (`solution = NULL`) has `valid = FALSE` and is distinct
from a valid single-grade all-withheld grading.

## Details

`validate_postrank_tie_solution()` rounds integer and binary variables,
checks `integrality_residual`, variable bounds, sparse linear
constraints, positive integer labels, consistency between pair variables
and canonical grade order `g[i] < g[j]`, `G <= G_max`, and the
active-profile equality constraint (`problem$guard$groups`, checked
directly on `g` independently of the sparse equality rows). It then
evaluates `g` with
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
and checks that both the raw objective `Z` and reconstructed risk
`R0 + Z / M` agree within the scale-aware objective tolerance.

If the unrounded primal exceeds `feasibility` while the rounded integer
solution passes all checks, `valid` is `TRUE` and `warnings` records the
raw residual;
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md)
additionally checks whether raw residuals exceed integrality-rounding
limits when deciding whether to keep a solver's lower bound.

## See also

[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
absent <- validate_postrank_tie_solution(problem, NULL)
absent$valid
#> [1] FALSE
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank_tie_solve(
    problem,
    backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10)
  )
  checked <- validate_postrank_tie_solution(problem, fit$raw_solution)
  checked$valid
  checked$grade
}
#> A B C D 
#> 3 3 2 1 
```
