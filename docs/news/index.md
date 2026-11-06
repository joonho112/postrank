# Changelog

## postrank 1.2.0

### Multidomain profile report cards

- [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  retains identified unit-by-domain states, declared target laws,
  structural identities and actual coupling/sampling provenance.
- [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  specifies weights, withholding loss, mean guards, direct joint
  exceedance thresholds and scopes using exact policy values.
- [`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
  evaluates one fixed grade matrix, and
  [`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md)
  extracts a verified evaluated or selected matrix.
- [`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
  constructs explicit or ordered-cut product banks;
  [`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)
  examines the complete declared bank with hard workload caps. Public
  selection uses additive risk A and direct joint protection. Optimality
  is restricted to that bank.
- [`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)
  separates complete finite-law evaluation, conditional fixed-sample iid
  count assurance and descriptive MCMC diagnostics. Producer
  declarations remain declarations; no model-calibration certificate is
  inferred. Exact represented-measure arithmetic is distinct from
  numerical assurance about an intended posterior.
- [`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)
  displays stored grades, cell counts or pair directions.
  Filtering/labels preserve original grades and denominators. Stored
  plots need neither a solver nor optional exact-arithmetic tooling.
- The quickstart and decision vignettes explain separable domain
  decisions, dependence-sensitive protection, crossed priorities and the
  permitted synthetic 40-site illustration. Raw posterior archives are
  not bundled.

### Compatibility

- The existing 97 exports, 127 S3 registrations, P1 signatures, eight
  datasets and common-grade behavior are retained. Eight exports and 15
  stored-summary methods are added; the package now has 105 exports and
  142 S3 registrations.
- P1
  [`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)
  summarizes criterion contributions to a common grading. P2 uses a
  unit-by-domain grade matrix; it does not replace that accessor.
- Original prepared P1 results retain their computation versions, source
  IDs, backend records and timestamps. A separately sealed,
  exact-version reader compatibility receipt records their validation by
  the new reader.
- Numeric policy inputs mean their stored binary values. Use
  decimal/fraction strings when the scientific policy is an exact
  decimal or fraction. Numeric weights retain the existing normalization
  rule when bound to an input.
- Existing P1 solver defaults are preserved. P2 finite-bank evaluation
  and selection use optional `gmp` arithmetic and require no MIP
  backend.

## postrank 1.1.0

- Remove the 13 pilot simulation summary objects, their dedicated
  article and associated extraction, documentation and tests. The
  package retains eight example and case-study datasets and 18
  vignettes. Statistical functions and retained inputs and stored
  analyses are unchanged.

This version revises the prose and presentation of the README, vignettes
and reference documentation. The statistical definitions, supported
computations, public interfaces and case-study data are unchanged from
version 1.0.0. The public distribution includes the synthetic examples,
stored simulation summaries and all three public-source case studies.
Source-specific attribution and data conditions accompany CDE, KRW and
Alabama. Documentation and data inventories describe this distribution.

## postrank 1.0.0

- Tie-aware fits now qualify a raw optimal status when a usable
  whole-problem lower bound is missing or the positive risk gap exceeds
  the requested precision. Valid grades, valid loose bounds and raw
  status are retained. Relative controls use the tie-aware R0-centered
  objective; existing tiny inversion warnings and other termination
  statuses retain their meanings.

- README and the package introduction begin with one criterion, then add
  a second for the same six sites. Applied and Methods tracks, a
  migration guide and a gallery organize the documentation. The
  ivory/teal sticker appears in the README and website.

- Six methodological guides explain scalar loss and the KRW
  correspondence, several criteria, posterior information, genuine ties,
  computation and Monte Carlo diagnostics. The thirteen new
  Applied/Methods guides link to each other and render mathematical
  expressions without remote scripts.

- Seven applied guides cover a first one-criterion analysis, its
  extension to several criteria, the three case studies, posterior
  inputs, exports and sensitivity figures. The new synthetic
  `pr_tutorial` keeps the same six sites and first-criterion law when
  adding a second criterion. Default article builds read prepared grade
  results; SVG export uses optional svglite.

- [`postrank_plot_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_plot_pairwise.md)
  shows prepared directional-error probabilities by criterion without
  computing new probabilities or grades. Report cards now spread a
  bounded display selection across grades, accept display names and
  facet layouts, and require one criterion for mean ordering.
  Probability axes, missing frontier segments and method-status displays
  are clearer.

- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on an
  analysis now returns a stable ID/grade table; request
  `what = "report_card"` for the prepared richer table. Console
  summaries and tie-aware views prioritize results and retain technical
  details on request.

- Progress defaults to quiet; `postrank_control(verbose = NULL)`
  inherits the option at solve time, while an explicit TRUE/FALSE takes
  precedence.

- Three compact case-study inputs retain their source laws, directions
  and archived-result qualifications. CDE source attribution, the KRW
  source’s CC-BY-NC notice and Alabama’s CC BY 4.0 attribution are
  preserved. The scoped LICENSE and installed DATA-NOTICE distinguish
  the MIT code license from third-party data conditions.

- [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  accepts previously calculated tie-free pairwise probabilities for one
  or several criteria.
  [`validate_postrank_probabilities()`](https://joonho112.github.io/postrank/reference/validate_postrank_probabilities.md)
  checks the stored input, corrections and optional supplied marginal
  summaries. The initial scope is weighted expected loss with an
  at-most-G limit.

- A single-criterion analysis can omit its weight, which is one. Several
  criteria still require declared loss weights.

- A backend optimal status is qualified as feasible but uncertified when
  its recorded lower bound and gap do not support the requested
  precision. Raw status, independently validated grades and usable
  bounds are preserved.

## postrank 0.9.0

GitHub release candidate. The reviewed mathematical kernels and the
legacy scientific payload identities are preserved; every inherited
behavioral case remains an obligation, with reviewed public-adapter and
English presentation expectation migrations. Acceptance of the new API
precedes any 1.0.0 label.

### Opt-in tie-aware mode (development addition)

- The separate `tie_aware_v1` domain adds
  [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md),
  [`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md),
  [`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)
  and
  [`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)
  for explicitly declared genuine ties in joint IID/MCMC inputs or
  complete exact finite laws. Legacy schemas and readers remain
  unchanged. No sampled coincidence establishes structural identity.
- [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
  and
  [`validate_postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_pairwise.md)
  retain strict reversal, equality and distinct probabilities, their
  source and separate content seals. Exact finite laws retain
  integer-mass/rational metadata.
- [`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
  [`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
  [`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md)
  and
  [`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md)
  implement weighted at-most-G with a mandatory full active-profile
  same-grade guard. The label-MIP uses pair-specific withholding costs
  and the all-withhold offset R0. All original entities and pair
  multiplicities are preserved. Zero-tie loss reduces mathematically to
  the legacy loss; calculations remain subject to floating-point
  arithmetic.
- [`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)
  records the narrow initial boundary. Staged solving, q, minimax,
  exact-G, typed analytic inputs, legacy extras and uniform guarantees
  are unsupported. New classes never inherit legacy input, pairwise,
  problem or fit classes. Existing 0.9 defaults, behavioral cases,
  golden hashes, public signatures and cached assets retain their
  original meaning.

### One-call analysis, strict inputs and settings

- [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
  builds the pairwise coefficients, solves, validates the incumbent and
  attaches the default extras (report card on; Monte Carlo fragility for
  joint IID or MCMC input; cross-fitting and diagnostics off), recording
  why each extra is or is not available.
- [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  is a bookkeeping front end for arrays, criterionwise matrix lists,
  `posterior` draws and existing objects; it always ends in the strict
  constructors.
  [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
  bundles the eight required scientific declarations, which have no
  defaults. The bundle and friendly array route reject generic
  placeholder tokens; direct legacy constructors, canonical JSON and
  metadata routes retain their existing declaration and structural
  checks. No route verifies scientific truth.
- [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  (policy: weights, tau, `G_max`, optional modes) and
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  (computation) are separate typed objects; loose arguments that
  conflict with `settings` raise `settings_conflict`.
- The 0.0.1.9003 typed coefficients are ported:
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
  [`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md),
  [`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)
  and
  [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).

### Baselines, comparisons and grids

- [`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md),
  [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
  and
  [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
  give baseline scores;
  [`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
  cuts a score order optimally (exact dynamic program) or by quantiles
  under the same loss.
- [`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)
  puts the joint rule and the baselines on one posterior and policy,
  keeping status, optimality scope and reason separate. Its table now
  records `family_feasible` and `feasibility_reason` using the reference
  fit’s stored feasibility tolerance. Supplied actions outside the
  declared family keep their values and relations and are marked in
  views; old objects without the metadata are labeled as not recorded.
  Duplicate method labels receive collision-free IDs throughout the
  result.
- [`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md)
  and
  [`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)
  run declared settings grids. Losses or feasible sets may change
  between rows, so risks are compared only within one loss. Profile
  names such as `base` are ordinary labels; distinct policy values
  retain distinct display labels. Invalid fractional grade caps and
  malformed named axes are rejected before coercion.
- [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
  matches named scales and centers by criterion ID; named vectors must
  cover every criterion exactly once. Use an unnamed scalar for
  recycling. Quantile cuts must satisfy the declared `G_max` and
  `exact_G` after exact-score blocks are preserved.

### Reporting, accessors and console

- [`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)
  lists each entity’s grade, its disclosed relation counts and its
  posterior means and central intervals. Mixture interval inversion uses
  standardized coordinates and verifies the probability residual after
  rounding to target units; unrepresentable endpoints raise
  `posterior_quantile_failure` instead of returning an inaccurate
  interval.
- [`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
  [`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md),
  [`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)
  and
  [`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
  read results from analyses, fits and baselines.
- `format(x, width = 72, tier = 2)` is the preferred capture interface
  across result classes. The 24 named formatter wrappers return the same
  lines as [`format()`](https://rdrr.io/r/base/format.html) with the
  same arguments; none is deprecated in this release.
- Every printed class has a result-first English console view, with
  exported capture formatters:
  [`format_postrank_analysis_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_backend_availability_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_baseline_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_coefficient_diagnostics_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_coefficients_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_commonality_cost_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_comparison_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_control_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_crossfit_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_declarations_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_diagnostics_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_draws_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_fit_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_frontier_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_guarantee_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_mc_fragility_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_pairwise_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_problem_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_report_card_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_report_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_sensitivity_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_settings_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md),
  [`format_postrank_summary_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  and
  [`format_postrank_validation_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md).
- [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
  writes a standalone English HTML report with eleven sections and
  embeds the report-card and criterion-profile figures as base64 PNG
  images when they are available; it never overwrites an existing file.
  Prepared coefficient diagnostics are accepted with schema/source
  checks, conditional-risk scope and explicit unavailable metric
  reasons. Reports do not recompute risks, diagnostics or report cards.

### Figures

- Six shipped `ggplot2` figures:
  [`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
  [`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md),
  [`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md),
  [`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md),
  [`postrank_plot_commonality()`](https://joonho112.github.io/postrank/reference/postrank_plot_commonality.md)
  and
  [`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md),
  with
  [`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md)
  for their data,
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods
  for seven classes,
  [`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md),
  [`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md),
  [`scale_colour_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md),
  [`scale_color_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)
  and
  [`scale_fill_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md).
  Views read stored results and never solve.

### Data and documentation

- Seventeen bundled data objects: the 32-state toy, a sealed 4,000-draw
  example (`pr_example_draws`) with its known law as Gaussian
  coefficients (`pr_example_gaussian`), the two-state MCMC diagnostic
  toy (`pr_toy_mcmc`), ten pilot summary tables, two pilot lookups and
  `pilot_headline`.
- Four vignettes: a seven-step quickstart, strict inputs and producers,
  baselines and criterion burden, and the pilot evidence with its claim
  limits. Ordinary builds read sealed cached results and solve nothing.
  The 0.0.1.9002 guide is retired; its chunks moved into these articles.
- Core return schemas, solver-free evaluation/diagnostic recipes and
  route validation contracts are documented. The installed pilot source
  register identifies every headline/claim-limit source ID and
  explicitly marks the original sources as not publicly available;
  summary redraw is distinct from regeneration of the full pilot
  experiment.

### Intentional compatibility changes

- Backend resolution is explicit argument, then
  `getOption("postrank.backend")`, then `"gurobi"`, for every solving
  verb. An unavailable backend is an error with remedies; there is no
  fallback.
- Official output is English only: `lang = "ko"` (or any other language)
  raises `unsupported_language`, and
  [`print()`](https://rdrr.io/r/base/print.html) on a fit no longer
  writes a report.
- `cmdstanr` is no longer suggested: no installed code calls Stan.
- The help pages of the inherited and ported functions are generated
  from roxygen; their tests are self-contained.

### Evidence and limitations

- Solver bounds are numerical bounds, not certificates or unique-optimum
  claims; a zero gap does not enumerate other optima.
- The pilot tables describe a finite simulation roster; they are not
  evidence of general superiority of any rule.
- The continuous-integration workflow installs HiGHS and excludes the
  optional non-CRAN Gurobi package from dependency resolution, so it
  does not validate the Gurobi backend.
- A constructor for arbitrary user-supplied coefficient arrays is
  deferred.

## postrank 0.0.1.9003

Main-study candidate (never released or checked on its own). This entry
was written for 0.9.0, which ports the candidate’s coefficient API.

### New features

- Typed conditional-law coefficients:
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
  [`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md),
  [`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)
  and
  [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).
  These artifacts carry their own content identity and capability record
  and never fabricate target draws or sample sizes.
- [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md),
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
  [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
  and
  [`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
  accept typed coefficients for weighted expected risk and weighted
  at-most-G problems only; minimax, protection rows, exact grade counts,
  cross-fit, target MC-fragility and IID target bounds refuse typed
  input with an explicit error. Legacy draw-based paths are unchanged.

## postrank 0.0.1.9002

Development version with independent audit corrections and an LP
time-budget repair.

### Audit corrections

- AUD-01: minimax refinement preserves the original weighted secondary
  objective. Zero weights no longer trigger a perturbation of that
  objective. A separate Pareto tie-break, when applicable, preserves the
  preceding objectives, and certification describes the action actually
  released.
- AUD-02: cross-fit unbiasedness is conditional on independent IID folds
  and a linear weighted or criterion-specific risk functional. Empirical
  minimax maxima and MCMC fold comparisons are descriptive; no exact
  unbiasedness guarantee is claimed for them. Numerical cross-fit
  summaries are unchanged.
- Regression tests include the zero/tiny-weight minimax counterexample
  and exact enumeration of the minimax cross-fit bias example.

## postrank 0.0.1.9001

Development version with an LP time-budget repair following version
0.0.1.9000.

### Changes that affect existing code

- When the staged engine’s MIP stage cannot run
  (`control$engine$mip = "never"`, or `"auto"` with more than
  `mip_max_n` entities, 200 by default), the LP relaxation now gets the
  remaining time less a reserve, and never less than `lp_time_share` of
  it. The reserve covers the incumbent candidates built from the
  relaxation’s solution and the final validation; it is the largest of 1
  second, 1% of `time_limit` and twice the time the incumbent stage
  took. Before, the relaxation got only `lp_time_share` (0.5), so these
  runs stopped at about half of `control$time_limit`. When the
  relaxation does not close the gap first, they now use nearly all of
  it: lower bounds can be tighter, and wall time roughly doubles (also
  for
  [`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md),
  [`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)
  and
  [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md)
  on such problems).
- With the default minimax second stage, stage 1 now uses nearly all of
  its three quarters of the time limit on such problems, so stage 2 gets
  about the last quarter instead of the larger remainder it had before
  (n = 250 with a 60 s limit: 15 s instead of 34 s; the whole run took
  59.5 s instead of 45.3 s).
- `lp_time_share` sets the relaxation’s share when the MIP stage may
  follow; otherwise it is only a lower bound on its budget.
  `fit$engine$stages$lp` records the budget the relaxation received
  (`time_budget`) and the rule that set it (`time_budget_rule`); each
  round in its `trace` records the solver time limit for that call
  (`time_limit`).
- The HiGHS LP stage resets the solver’s time limit before each call to
  the run time used so far plus the remaining budget. HiGHS counts the
  limit against the solver object’s cumulative run time, so the cut
  separation between calls was never charged and the stage could overrun
  its budget (in the weighted and q runs of the 014 Phase 2 benchmark,
  by 10-13 s at n = 400 and 74-88 s at n = 807). A call that still runs
  more than a second past the budget adds a warning. Gurobi already
  received the remaining budget on each call.
- Without a MIP stage, the LP stage separates no more cuts once its
  budget is spent; they could only have served a MIP stage.

## postrank 0.0.1.9000

Development version following a review of the solver and validation
routines.

### Changes that affect existing code

- [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  gains `strategy = c("staged", "label_mip")`. The default `"staged"`
  engine builds incumbents by an order dynamic program and local search,
  bounds them with a weak-order LP, and calls a strengthened label MIP
  only when a gap remains on small problems. `"label_mip"` keeps the
  0.0.1 formulation.
- Minimax problems are solved in two stages by default
  (`postrank_problem(minimax_refine = "weighted")`). Stage 1 receives
  three quarters of `control$time_limit`, and `fit$backend$options`
  records stage 1’s options; `fit$minimax_refine$time_limits` records
  the budgets of both stages. `minimax_refine = "none"` returns the
  stage-1 incumbent.
- `fit$objective$risk_upper_bound` is the risk of the released action
  (for minimax, the largest selected criterion risk of the grade). The
  solver’s epigraph value is reported separately as
  `fit$objective$epigraph_value`.
- `fit$objective$raw_bound_minus_recomputed_incumbent` and
  `risk_bound_minus_recomputed_incumbent` are renamed
  `raw_bound_minus_action_raw` and `risk_bound_minus_action_risk`.
- A reported lower bound above the validated action risk by at most the
  scale-aware objective tolerance is clamped to that risk (gap 0; the
  `bound_source` ends in `_clamped`) instead of being discarded. Larger
  inversions remain numerical issues, and a clamped inversion larger
  than the gap controls (absolute, or relative on the raw objective)
  adds a warning.
- An infeasible fit reports no lower bound (`bound_source = "missing"`)
  from either strategy or backend; the backend’s raw value stays in
  `fit$objective$raw_lower_bound`.
- Lower-bound source labels are checked against a fixed list; an unknown
  label, an infeasible status with a validated incumbent, or an
  excessive raw primal residual is recorded as a numerical issue and the
  bound is not used.
- Gurobi and HiGHS receive half the validator’s feasibility and
  integrality tolerances. HiGHS `mip_feasibility_tolerance` is tied to
  the requested absolute risk gap.

### New functions

- [`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md)
  builds a validated draws object from an `S x n x K` array; the
  scientific declarations remain required arguments, and for MCMC so is
  the chain layout (`chains`, `warmup_per_chain`, `thin`).
- [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md)
  and
  [`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md)
  are practical Monte Carlo diagnostics: out-of-fold optimism and pairs
  whose decision margin is within a few Monte Carlo standard errors of
  `tau`.
- [`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)
  reports, per criterion, the extra risk of using one common grade;
  [`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md)
  solves along a grid of `tau` or `q`.

### Other changes

- Observed within-criterion ties are still rejected; the message now
  names the usual cause (reduced output precision) and the fix
  (re-export at full precision).
- Minimax problems record degenerate criteria
  (`problem$minimax_diagnostics`), and fits warn about them.
- The Gurobi model conversion is vectorized.
- The regret consistency check compares risk differences in risk units.
- `inst/CITATION` cites Kline, Rose and Walters (2024); the README and
  vignette cover the staged engine, the minimax second stage and the new
  tools.

## postrank 0.0.1

- Local research development edition
  (`p1-applied-local-development-2026-10-19-r1`); see
  `registry/release-manifest.json`.
