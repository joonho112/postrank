# Solve Protection Envelopes and Bound Regret

`postrank_protection_analysis()` solves the tightened (`inner`) and
relaxed (`outer`) problems in a protection envelope from
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
(a pair of empirical problems that shift criterion error budgets `q_k`
by `-epsilon_k` and `+epsilon_k`) to compute an analytic upper bound on
weighted-risk regret relative to the true budget-constrained family. The
two solves run sequentially, and both attempt records are kept even if
the inner solve fails or is infeasible.

## Usage

``` r
postrank_protection_analysis(envelopes, backend = NULL, control = list())
```

## Arguments

- envelopes:

  A `postrank_protection_envelopes` object from
  [`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md).

- backend:

  Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the default),
  `getOption("postrank.backend")` is used, or `"gurobi"` (which requires
  a license) when unset; install the `highs` package and pass
  `backend = "highs"` to use HiGHS. If the chosen solver package is not
  installed or cannot be loaded, `postrank_protection_analysis()` stops
  with an error before attempting either solve. `postrank` never
  switches solvers automatically. Uncaught runtime errors escaping
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  (for example under `strategy = "label_mip"` or LP setup) leave
  `inner_fit` or `outer_fit` as `NULL`, populate that solve's
  `attempts$*$error`, and record `"inner_solve_error"` or
  `"outer_solve_error"` in `reasons`; under the default
  `strategy = "staged"`, runtime errors caught during LP cut rounds or
  Stage-C MIP return a `postrank_fit` with warnings and record
  `"outer_whole_problem_lower_unavailable"` in `reasons`.

- control:

  A
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  object or named control list passed to each of the two
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  calls (`time_limit` applies separately to the inner solve and the
  outer solve).

## Value

A `postrank_protection_analysis` list containing `inner_fit` and
`outer_fit` (`NULL` when an uncaught solve error occurred), per-solve
metadata in `attempts` (`inner` and `outer`), `backend`, `control`,
`solve_count`, `public_q`, `thresholds`, `inner_risk_upper`,
`outer_whole_problem_risk_lower`,
`empirical_inner_upper_minus_outer_lower`, `delta_w`, `computed_value`,
`formula`, `status`, `reasons`, `interpretation`, `assumptions`,
identity hashes (`analysis_identity`, `envelope_identity`,
`input_identity`, `public_problem_identity`,
`coefficient_bound_identity`), `schema_version`, and status flags. When
usable bounds are available, `status` and `guarantee_status` are
`"diagnostic_only"` and `bound_computed` is `TRUE` (`guarantee_issued`,
`numerically_verified`, `numerical_certification`, and
`finite_sample_certificate` remain `FALSE`); otherwise `computed_value`
is `NA_real_`, `status` and `guarantee_status` are `"not_established"`,
and `reasons` lists every missing or failed check.

## Details

Let \\U\_{\mathrm{inner}}\\ be the evaluated empirical risk of the
verified inner grading (`analysis$inner_fit$grade`, or
`get_grades(analysis$inner_fit)`), \\L\_{\mathrm{outer}}\\ be a
whole-problem empirical risk lower bound from `outer_problem`, and
\\\delta_w = \sum_k w_k \varepsilon_k\\. When both endpoints are valid
and \\U\_{\mathrm{inner}} \ge L\_{\mathrm{outer}}\\, `computed_value` is
\$\$(U\_{\mathrm{inner}} - L\_{\mathrm{outer}}) + 2 \delta_w.\$\$ On the
simultaneous `1 - alpha` IID coefficient event of `envelopes$bounds`
(assuming valid numerical feasibility of the inner grading), the inner
grading `analysis$inner_fit$grade` satisfies the true posterior `q`
budgets. Under the same event and a valid solver-reported whole-outer
lower bound, its true posterior weighted risk exceeds the minimum true
posterior weighted risk over the true `q`-protected family by at most
`computed_value`.

Computing `computed_value` requires a checked inner grading without
numerical issues and a usable whole-problem outer lower bound
(`outer_fit$status$normalized` in `"optimal"`,
`"feasible_not_certified"`, or `"time_limit"`, a recognized
whole-problem `outer_fit$objective$bound_source`, and no numerical
issues; a solver `"optimal"` status label alone is insufficient).
Neither the inner problem's lower bound nor an outer grading's risk is
ever substituted for \\L\_{\mathrm{outer}}\\; if \\U\_{\mathrm{inner}}
\< L\_{\mathrm{outer}}\\, `computed_value` is `NA_real_` with reason
`"outer_lower_above_inner_upper"`. An infeasible inner problem records
`"inner_infeasible"` and does not prove that the true protected family
is empty.

See
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
and
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
for the fixed-sample IID design requirements and signed (unclipped)
`q_k -/+ epsilon_k` threshold construction. Because feasibility
tolerances and solver bounds use ordinary floating-point arithmetic
without interval arithmetic to bound floating-point rounding, this
function does not provide a formal numerical certificate, a posterior
probability of constraint satisfaction, or calibration on new data.

## See also

[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md),
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
[`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md)

## Examples

``` r
bounds <- postrank_iid_bounds(
  postrank_toy,
  alpha = 0.05,
  alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
  design = list(
    sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE,
    adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"
  )
)
problem <- postrank_problem(
  postrank_pairwise(postrank_toy),
  weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25,
  G_max = 3L,
  q = c(need_A = 0.2)
)
envelopes <- postrank_protection_envelopes(problem, bounds)
analysis <- postrank_protection_analysis(
  envelopes,
  backend = "highs",
  control = postrank_control(time_limit = 10, threads = 1)
)
analysis[c("status", "computed_value", "reasons", "guarantee_issued")]
#> $status
#> [1] "diagnostic_only"
#> 
#> $computed_value
#> [1] 0.6227691
#> 
#> $reasons
#> character(0)
#> 
#> $guarantee_issued
#> [1] FALSE
#> 
```
