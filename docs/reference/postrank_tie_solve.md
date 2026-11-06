# Choose Grades Under Equality-Neutral Loss

A prepared tie-aware problem is solved by mixed-integer optimization,
and its candidate is checked independently before grades are returned.
The objective minimizes weighted expected strict errors and
distinct-comparison withholding costs, subject to the grade cap and
active-profile equality guard. A validated candidate may remain
available when optimization terminates early.

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

  A validated object from
  [`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md).

- backend:

  `NULL`, `"highs"` or `"gurobi"`. The explicit argument takes
  precedence over `getOption("postrank.backend")`, then the default
  Gurobi. Choose `"highs"` explicitly to use HiGHS. There is no backend
  fallback.

- control:

  Named time, thread, seed, gap and tolerance controls, or a
  `postrank_control` with `strategy = "label_mip"`. Nonempty
  staged-engine controls are unsupported in this mode.

- strategy:

  `"label_mip"` only. When omitted, an explicit strategy in `control` is
  used and checked; otherwise the label model is used.

## Value

A `postrank_tie_fit` with the problem, settings, backend, raw solver
result, status, validation, objective records and numerical warnings.
`incumbent_validated` indicates whether `grade` and `evaluation` are
available. Only a candidate passing independent rounded-primal,
active-profile and direct-loss checks receives grades.

The objective record includes validated action risk as an upper bound,
any usable whole-problem lower bound, the absolute risk gap, and raw
units/scale/offset. Bounds convert as `R0 + raw_bound/M`, where
`R0 = tau * T/M` is the all-withheld baseline. Unavailable action or
bound quantities are `NA`.

## Details

A shared grade withholds a comparison; it does not assert latent
equality. A valid single-grade action has risk R0 and undefined
conditional error ratios. A solve without validated grades instead has
`grade = NULL`; it is not reported as an all-withheld action.

Inspect `incumbent_validated`, `status`, `objective$risk_lower_bound`
and `objective$risk_absolute_gap` together. A validated candidate
establishes feasibility within tolerance, not optimality. A rejected
solver bound can coexist with a retained grade. A raw optimal status
becomes `"feasible_not_certified"` when a usable whole-problem lower
bound is missing or the risk gap exceeds the requested threshold,
allowing only comparison roundoff. The threshold is the larger of
`absolute_risk_gap` and `relative_gap * abs(U - R0)`, where `U` is the
validated action risk. The valid grade, raw status, and any valid loose
lower bound are retained. Other termination statuses are not promoted.
An optimal result remains subject to floating-point tolerances,
including the existing tolerance-scale bound-inversion clamp, and does
not constitute a numerical certificate; the gap concerns the supplied
optimization problem, not posterior or Monte Carlo uncertainty. Multiple
optima may have different grade counts and imply different funding
mappings.

This route supports weighted at-most-G decisions only. It does not run
the staged engine, minimax refinement, q protection or exact-G
decisions. Ordinary baselines, accessors, HTML reports, plots and Monte
Carlo guarantees do not accept tie-aware objects. Read `fit$grade` and
`fit$evaluation`, or use the tie-aware print, format and summary
methods. The optimizer does not verify the scientific declarations in
the input.

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE) &&
    requireNamespace("highs", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, c(S = .6, C = .4), tau = .25, G_max = 3L)
  fit <- postrank_tie_solve(problem, backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10))
  fit
  fit$grade
  fit$objective[c("primary_action_risk", "risk_lower_bound", "risk_absolute_gap")]
}
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
