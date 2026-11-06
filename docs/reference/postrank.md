# Choose Posterior Grades and Prepare Their Summaries

Entities are assigned to ordered groups by balancing expected
wrong-direction loss against the cost of withholding comparisons under a
supplied posterior. Grade 1 has highest priority. A shared grade
withholds the comparison between the corresponding entities without
asserting equality of their latent targets.

## Usage

``` r
postrank(
  x,
  weights = NULL,
  tau = 0.25,
  G_max = 4L,
  ...,
  settings = NULL,
  backend = NULL,
  control = postrank_control(),
  report_card = TRUE,
  fragility = TRUE,
  crossfit = FALSE,
  diagnostics = FALSE,
  level = 0.9
)
```

## Arguments

- x:

  A validated `postrank_draws`, Gaussian/mixture
  `postrank_coefficients`, or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object.

- weights, tau, G_max:

  Decision choices when `settings` is not given. Weights are nonnegative
  and sum to one, without automatic normalization; names identify
  criteria, or unnamed values follow criterion order. This one-call
  function supplies weight 1 when it is omitted for one criterion. The
  withholding cost satisfies `0 < tau <= 0.5`. An oversized `G_max` is
  capped at the number of entities.

- ...:

  Optional `q`, `exact_G`, `objective`, `minimax_criteria` and
  `minimax_refine`, as described in
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md).
  These modes are input-dependent: Gaussian/mixture coefficients and
  supplied probabilities support only weighted at-most-G problems
  through this function.

- settings:

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object instead of separate decision arguments. Explicitly supplying
  both is a `settings_conflict` error.

- backend:

  `NULL`, `"gurobi"` or `"highs"`. An explicit choice takes precedence;
  otherwise `getOption("postrank.backend")` is used, then Gurobi if
  unset. Choose HiGHS explicitly for that backend. There is no automatic
  fallback after an unavailable, failed or timed-out backend.

- control:

  A
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  object or a named control list.

- report_card, fragility, crossfit, diagnostics:

  Logical requests for additional summaries. Report cards and Monte
  Carlo fragility are requested by default; cross-fitting and
  diagnostics are off by default. See Details for the input requirements
  and extra computation.

- level:

  Central posterior interval level for a report card, in `(0, 1)`.
  Supplied marginal intervals have a fixed level; request that same
  level.

## Value

A `postrank_analysis` list with `input`, `pairwise`, `settings`,
`control`, `problem` and the main `fit`. `evaluation` is the
fixed-action evaluation of its validated grade. `report_card`,
`fragility`, `crossfit` and `diagnostics` contain prepared summaries or
`NULL`.

Each entry of `extras` records `requested`, `supported`, `available`,
`reason` and `condition`, which describe the availability of that
component. `backend`, `timings`, `provenance` and `warnings` describe
the run. `metadata` contains declaration/capability summaries and
prepared display data; `schema_version` identifies the analysis
structure. Common results are extracted through
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)
and
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md).

## Details

The function prepares pairwise probabilities, constructs and solves the
main problem, and returns the resulting grades, loss and supported
summaries. A posterior representation is supplied externally; the
function does not fit a statistical model. An omitted weight is set to
one for a single criterion, whereas weights must be specified for
several criteria. `G_max` bounds the number of grades from above and
does not require that the bound be attained.

A time limit can leave a validated grade, or no grade at all. Without a
validated candidate, the fit's status, any usable lower bound and
warnings are retained, while evaluation and grade-dependent extras are
`NULL` with reason `"no_validated_incumbent"`. A valid report that
withholds every comparison is different: it has one grade and risk tau.
Read the fit's bounds and gap as well as its status; see
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

A report card requires marginal posterior intervals, so supplied
probabilities without these summaries permit optimization but cannot
produce a report card. Monte Carlo fragility and cross-fitting require
joint equal-weight IID or MCMC draws; cross-fitting entails two
additional optimizations. For typed coefficients, diagnostics concern
conditional expected risk through
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).
Target draws and simulation diagnostics are unavailable from
probability-only inputs.

If an extra fails unexpectedly, a valid main fit is retained, the extra
records `reason = "extra_error"` and its condition, and a warning is
added. Core input, backend and solve failures still stop the call.
Requested intervals must be compatible with the source before analysis
proceeds.

## See also

[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_grades(one)
  get_risk(one)
}
#> $risk
#> [1] 0.04165164
#> 
#> $lower_bound
#> [1] 0.04165164
#> 
#> $gap
#> [1] 0
#> 
#> $status
#> [1] "optimal"
#> 
```
