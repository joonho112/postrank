# Solve a Grading Problem Under Equality-Neutral Loss

`postrank_tie_solve()` solves a tie-aware grading problem from
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md)
by mixed-integer programming (`strategy = "label_mip"`) and
independently checks any candidate grading before returning it. It
minimizes posterior expected equality-neutral loss (where true target
equality has zero loss whether the pair is ordered or placed in the same
grade), subject to at most `G_max` occupied grades and the
active-profile equality constraint (requiring entities declared
structurally equal on every positive-weight criterion to share a grade).

## Usage

``` r
postrank_tie_solve(
  problem,
  backend = NULL,
  control = list(),
  strategy = "label_mip"
)
```

## Arguments

- problem:

  A validated `postrank_tie_problem` object from
  [`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md).

- backend:

  Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the default),
  `getOption("postrank.backend")` is used, or `"gurobi"` (which requires
  a license) when unset; install the `highs` package and pass
  `backend = "highs"` to use HiGHS. `postrank` never switches solvers
  automatically. Missing or unloadable solver packages and runtime R
  errors thrown by the solver (such as Gurobi without an active license)
  stop the call with a `postrank_backend_unavailable` error, whereas
  solver termination outcomes (`"optimal"`, `"time_limit"`,
  `"feasible_not_certified"`, `"infeasible"`, `"numerical_error"`, ...)
  are returned in `status$normalized`.

- control:

  Named list of solver controls (`time_limit`, `threads`, `seed`,
  `relative_gap`, `absolute_risk_gap`, `tolerances`, `output`,
  `strategy`, and `verbose`, although `postrank_tie_solve()` itself
  prints no progress messages when `verbose = TRUE`) or a
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  object. Because
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  defaults to `strategy = "staged"`, pass
  `postrank_control(strategy = "label_mip", ...)` (or pass
  `strategy = "label_mip"` explicitly). Staged `engine` options are not
  supported: in a plain `list`, omit `engine` or pass `engine = list()`;
  in
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
  leave `engine` at its defaults.

- strategy:

  Must be `"label_mip"` (`"staged"` search is not supported in tie-aware
  mode). When `strategy` is omitted in the call and `control$strategy`
  is present, `control$strategy` is used and checked.

## Value

A `postrank_tie_fit` list containing `schema_version`, `loss`,
`problem_identity`, `input_identity`, `problem`, `settings`, `backend`,
`engine`, `control`, `capabilities`, `status` (`raw_code`,
`raw_message`, `normalized`, `termination_reason`), `has_incumbent`,
`incumbent_validated`, `raw_solution`, `solution_validation`, `grade`,
`evaluation`, `relations` (`n x n` integer pairwise relation matrix),
and `solution_identity` (the last four are `NULL` unless
`incumbent_validated` is `TRUE`), `objective`, `runtime`,
`raw_backend_result`, `numerical_issues`, and `warnings`.
`incumbent_validated` is `TRUE` only when the rounded candidate passes
integer constraint, active-profile equality, and direct
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
loss checks, establishing feasibility within tolerances (not
optimality).

In `objective`, `primary_action_risk` and `risk_upper_bound` give the
verified grading's directly evaluated equality-neutral risk `U` (`NA`
when `incumbent_validated` is `FALSE`), `risk_lower_bound` gives any
usable whole-problem lower bound `L = R0 + raw_lower_bound / M` (a loss
no feasible grading can beat according to the solver, or `NA` when
unavailable), `risk_absolute_gap` gives `U - L` (`NA` when either bound
is `NA`), and `offset` gives the all-withheld risk `R0 = tau * T / M`,
where `M = choose(n, 2)` counts all unordered pairs and `T` is the
criterion-weighted expected number of distinct-target pairs.

## Details

Placing two entities in the same grade leaves them unordered without
claiming equal targets. A valid single-grade (`G = 1`) solution has
`grade` equal to all `1`s, risk `R0`, and `NA` conditional error ratios
(`E_over_N`, expected strict errors per ordered pair, and `E_over_D`,
expected strict errors per ordered distinct pair); by contrast, a run
without a verified grading (for example, a time limit reached before
finding any feasible integer solution) has `incumbent_validated = FALSE`
and `grade = NULL`.

Read `incumbent_validated`, `status$normalized`,
`objective$risk_lower_bound`, and `objective$risk_absolute_gap`
together:

- A raw `"optimal"` status becomes `"feasible_not_certified"` (keeping
  the verified `grade` and any valid loose `risk_lower_bound`) when a
  usable whole-problem lower bound is missing or `risk_absolute_gap`
  exceeds `max(absolute_risk_gap, relative_gap * abs(U - R0))` beyond
  floating-point comparison roundoff.

- If a solver's lower bound exceeds `U` by at most the objective
  tolerance (scaled to the raw objective magnitude), it is clamped to
  `U` (`risk_absolute_gap = 0`,
  `bound_inversion_within_tolerance = TRUE`) with a warning. Larger
  bound inversions, unrounded solver constraint violations larger than
  integer-rounding tolerances can explain, or other backend
  consistency/numerical issues (such as objective mismatch or numerical
  termination) set `status$normalized = "numerical_error"` and exclude
  `risk_lower_bound` while keeping a valid rounded `grade`; non-eligible
  statuses such as `"unknown"` also exclude `risk_lower_bound`.

- Solver statuses and gaps describe optimization of the supplied problem
  within floating-point tolerances; they do not provide a formal
  numerical certificate or measure posterior or Monte Carlo uncertainty.
  Multiple optimal gradings may exist with different occupied grade
  counts `G` and different downstream policy or funding mappings.

Tie-aware solving supports weighted at-most-`G_max` problems only
(`minimax`, `q` error budgets, and `exact_G` are not supported) and does
not verify scientific equality or sampling declarations in the input.
Tie-aware fits provide [`print()`](https://rdrr.io/r/base/print.html),
[`format()`](https://rdrr.io/r/base/format.html), and
[`summary()`](https://rdrr.io/r/base/summary.html) methods, and expose
grades and losses via `fit$grade`, `fit$evaluation`, and
`fit$relations`. Ordinary zero-equality functions
([`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md),
`postrank_plot_*()`, Monte Carlo diagnostics, and IID bounds) do not
accept `postrank_tie_*` objects; see
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md).

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
  fit <- postrank_tie_solve(
    problem,
    backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10)
  )
  print(fit)
  fit$grade
  fit$objective[c("primary_action_risk", "risk_lower_bound", "risk_absolute_gap")]
}
#> <postrank_tie_fit>  4 entities in 3 grades (sizes 1 / 1 / 2).
#>   Equality-neutral posterior loss: 0.0400.
#>   Disclosed 5 of 6 pairs (83.3%); withheld 1.
#>   All-withheld loss (R0): 0.1750; R0 need not equal tau.
#> Criterion results:
#>    Criterion Loss   Error / disclosed Error / distinct
#>    S         0.0667 0.080             0.080
#>    C         0.0000 0.000             0.000
#> Reading the loss:
#>   True equality incurs no error or withholding cost. Withheld unequal targets
#>     incur the declared cost. A shared grade does not assert true equality.
#>   Error / disclosed divides by the number of disclosed pairs. Error /
#>     distinct divides by their expected unequal-target mass. A zero denominator
#>     remains NA.
#>   Decisions support weighted loss and an upper limit on grades; q limits,
#>     exact grade counts and minimax are unsupported in this path.
#> Computation:
#>   Solver: Optimal within solver tolerances.
#>   Optimization gap: 0.
#>   Loss upper bound: 0.0400; lower bound: 0.0400.
#>   Solver: highs; elapsed time 0.005 seconds.
#>   The gap concerns optimization of the supplied probabilities. It does not
#>     measure posterior uncertainty or Monte Carlo error.
#>   !  1 warning recorded: Reported lower bound exceeded the validated action r...
#>   i  summary(x, details = TRUE) adds the stored technical record.
#> $primary_action_risk
#> [1] 0.04
#> 
#> $risk_lower_bound
#> [1] 0.04
#> 
#> $risk_absolute_gap
#> [1] 0
#> 
```
