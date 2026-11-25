# Assign Grades to Entities Under Posterior Uncertainty

`postrank()` gives each entity (for example a school, an employer or an
area) an integer grade, using posterior information that you supply:
draws, normal (Gaussian) or mixture posteriors, or comparison
probabilities. Grade 1 is the highest priority; larger values of each
criterion's target (the entity quantity estimated on that criterion)
mean higher priority, as set when the input was built. Entities in
different grades are reported in that order. Entities in the same grade
are left unordered: the report does not say which one is higher, and it
does not say that they are equal.

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

  Posterior information for the entities, one of:

  - a `postrank_draws` object (see
    [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
    and
    [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md));

  - a normal posterior given by means and covariances
    ([`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md))
    or an average of normal posteriors over shared states such as
    hyperparameter draws
    ([`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md));

  - a
    [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
    object holding comparison probabilities computed elsewhere.

- weights:

  Criterion weights: nonnegative numbers that sum to one. They are not
  rescaled for you. Name them by criterion (named weights must name
  every criterion once, including any with weight 0), or give them in
  criterion order. With one criterion, `postrank()` sets the weight to 1
  if you leave it out; with several criteria it is required.

- tau:

  Cost of leaving a pair unordered, relative to a cost of 1 for a pair
  reported in the wrong order. Must satisfy `0 < tau <= 0.5`.

- G_max:

  Largest number of grades. Fewer grades are allowed unless `exact_G` is
  given. A value larger than the number of entities is reduced to that
  number, and a note is added to the result's warnings.

- ...:

  Further settings passed to
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md):
  `q` (per-criterion upper limits in `[0, 1]` on the expected
  wrong-order proportion of ordered pairs, `E_k <= q_k * N`), `exact_G`
  (an exact number of occupied grades), `objective` (`"minimax"`
  minimizes the largest criterion loss instead of the weighted one),
  `minimax_criteria` (subset of criteria included in the minimax
  objective) and `minimax_refine` (whether to refine a minimax solution
  on weighted loss). With normal or mixture posteriors or supplied
  probabilities, only the weighted objective without `q`, `exact_G` or
  `minimax_criteria` is available; other values are an error.

- settings:

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object, used instead of `weights`, `tau`, `G_max` and `...`. Giving
  both, even at their default values, is an error (`settings_conflict`).

- backend:

  Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the default),
  `getOption("postrank.backend")` is used, or `"gurobi"` if that option
  is not set. If the chosen solver is not installed or cannot be loaded,
  the call stops with an error. The fit records the overall solver
  outcome in `fit$status` and stage-specific errors in
  `fit$engine$stages` (see Details). `postrank` never switches to the
  other solver.

- control:

  Solver controls from
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
  such as the time limit, number of threads and seed, or a named list of
  them.

- report_card, fragility, crossfit, diagnostics:

  Whether to request extra summaries. The report card and fragility are
  requested by default; cross-fitting and diagnostics are not. Each one
  is computed only when the input supports it; Details lists what each
  needs.

  - Report card: the posterior means and intervals shown with the
    grades.

  - Fragility: pairs whose wrong-order probability in the likelier
    direction is within Monte Carlo noise of `tau`. On MCMC draws, only
    borderline pairs within `0.1` (`screen_margin`) of `tau` are traced,
    and an informational `"MCMC screen"` note is added to `warnings`.

  - Cross-fitting: grades chosen on one half of the draws and evaluated
    on the other half (the model is not refitted).

  - Diagnostics: for IID or MCMC draws, Monte Carlo standard errors
    (with R-hat and effective sample size for MCMC draws, from the
    `posterior` package); for exact finite posteriors and other inputs,
    see Details.

- level:

  Level of the central posterior intervals in the report card, between 0
  and 1. If the input comes with its own intervals, use their level (for
  95% intervals, `level = 0.95`) or set `report_card = FALSE`.

## Value

A `postrank_analysis` object, a list with these components:

- `input`, `pairwise`, `settings`, `control` and `problem`: the checked
  input, its pairwise probabilities, and the settings, solver controls
  and optimization problem that were used.

- `fit`: the solver result (see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)).

- `evaluation`: loss and error summaries of the chosen grades, or `NULL`
  when no grading passed postrank's checks.

- `report_card`, `fragility`, `crossfit` and `diagnostics`: the extra
  summaries, each `NULL` when it was not computed.

- `extras`: for each extra summary, whether it was `requested`,
  `supported` and `available`, with a `reason` and any error
  `condition`.

- `backend`, `timings` and `warnings`: the solver used, the seconds
  spent in each stage, and any warnings.

- `provenance`: how and when the result was made (postrank and R
  versions, time, solver and how it was chosen).

- `metadata`: a summary of the input's declarations, which extra
  summaries the input supports, and stored display data.

- `schema_version`: the version of this object's layout.

Use
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
and [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) (see
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md))
to extract the usual results, and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) or
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
to plot the report card.

## Details

By default, the grades are chosen to minimize the posterior expected
loss, averaged over all pairs of entities: a pair reported in the wrong
order costs 1 and a pair left unordered costs `tau`. With several
criteria, one common grading is chosen and the criterion losses are
combined with `weights`. `postrank()` computes the pairwise
probabilities, solves the optimization problem and returns the grades,
the loss and optional summaries. It does not fit a model, so the results
are only as good as the posterior you supply.

postrank needs an optimization solver. HiGHS is free: install the
`highs` package and use `backend = "highs"` or
`options(postrank.backend = "highs")`. The default, Gurobi, is
commercial software that needs a license.

**Words in the printed output.** The printed result and
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
use the package's internal terms: "disclosed" pairs are the ordered
pairs, "withheld" pairs are the unordered ones, and "risk" is the loss
described above.

**Solver results.** postrank recomputes the loss of the solver's grading
and checks it before reporting it. The solver also reports a lower bound
(a loss that no grading can beat) and the gap between the returned loss
and that bound; a gap of 0 means that, up to numerical tolerance, no
better grading exists for these probabilities. The status, bound and gap
describe the optimization only, not the uncertainty in the posterior or
the adequacy of the model; see
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
and
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

**Time limits.** When the solver stops at its time limit, the result may
hold a checked grading, or none. Without one, the result keeps the
solver status, any lower bound and the warnings; `evaluation` and the
requested extra summaries are `NULL`, with reason
`"no_validated_incumbent"` (no checked grading). This differs from a
valid grading that leaves every pair unordered, which has one grade and
loss `tau`.

**What each extra summary needs.** A report card needs marginal
posterior intervals: supplied probabilities without interval summaries
can be graded but give no report card. Monte Carlo fragility and
cross-fitting need joint equal-weight IID or MCMC draws, in which every
draw holds a value for every entity and criterion; cross-fitting solves
two more optimization problems. For IID or MCMC draws, `diagnostics`
reports Monte Carlo standard errors (exact finite posteriors have no
Monte Carlo error); for normal or mixture posteriors it evaluates the
expected loss given those posteriors (for hyperparameter-MCMC MCSEs on
mixture posteriors, call
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
directly with `chain_history`). Supplied probabilities have no draws, so
fragility, cross-fitting and diagnostics are not available for them.

**Errors.** Invalid input, invalid settings, an unavailable solver, and
uncaught solver execution errors (such as a missing Gurobi license under
`strategy = "label_mip"` or LP setup) stop the call. Solver termination
outcomes, including infeasibility, numerical trouble and time limits,
appear in `fit$status`. Without a checked grading, `evaluation` is
`NULL`. For a caught error in staged search, check
`fit$engine$stages$lp$status` and its `trace` for LP rounds, or
`fit$engine$stages$mip$error` and `fit$warnings` for the final MIP. If
an extra summary fails unexpectedly, the main grading is kept, the extra
records `reason = "extra_error"` and its condition, and an R warning is
signaled and appended to `warnings`. When the input supplies its own
intervals, a report card at another `level` is an error, raised before
any solving.

## See also

[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)

## Examples

``` r
# Read a stored result without running a solver:
stored <- postrank_example("tutorial_one")
get_grades(stored)
#> A B C D E F 
#> 1 1 2 2 3 3 
get_risk(stored)
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
# Solve directly with the optional highs package:
one <- postrank(pr_tutorial$one, tau = 0.2, G_max = 3, backend = "highs",
  control = postrank_control(time_limit = 10), fragility = FALSE)
get_grades(one)
#> A B C D E F 
#> 1 1 2 2 3 3 
get_risk(one)
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
