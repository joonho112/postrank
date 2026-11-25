# Interface and Version Compatibility Notes

This file summarizes compatibility across `postrank` releases (`1.1.0` to `1.3.0`)
as well as interface updates for scripts written against pre-1.0 development
builds (`0.9.x`, which was not publicly released).

## Moving from `postrank` 1.1.0 / 1.2.0 to 1.3.0

- **Unchanged common-grade workflow.** Existing calls to `postrank()`,
  `postrank_draws()`, `postrank_probabilities()`, `get_grades()`, `get_profile()`,
  `get_relations()`, `get_risk()`, and all plotting functions keep their
  signatures, defaults, and numerical behavior.
- **New convenience helpers in 1.3.0.** `postrank_example()` lists and loads the
  21 precomputed analysis objects shipped with the package without calling an
  optimization solver. `postrank_describe()` assembles the eight required
  scientific description blocks for numeric draw arrays from plain arguments and
  passes them to `postrank_declarations()` (every substantive statement is still
  written by the user).
- **Multidomain profile report cards (added in 1.2.0).** For separate grades in
  each domain rather than one shared common grade, use `postrank_mdomain_input()`,
  `postrank_mdomain_decision()`, `postrank_mdomain_evaluate()`,
  `postrank_mdomain_grades()`, `postrank_mdomain_family()`,
  `postrank_mdomain_solve()`, `postrank_mdomain_assess()`, and
  `postrank_plot_mdomain()`; see `vignette("mdomain-quickstart", package = "postrank")`
  and `vignette("mdomain-decisions", package = "postrank")`.
  - Supply complete joint unit-by-domain states when evaluating joint cross-domain
    protection events (`J <= alpha`); matching row numbers across separate domain
    fits do not create a joint posterior.
  - Pass exact rational or decimal strings (such as `"1/10"` or `"0.1"`) when a
    policy threshold is an exact rational number; R numeric values keep their
    IEEE binary representation.
  - Optimality in `postrank_mdomain_solve()` holds within the declared candidate
    set, and exact arithmetic (`gmp`) over a supplied finite distribution or
    empirical sample does not verify model specification or calibrate an upstream
    posterior.
- **Stored 1.1.0 results.** The 21 precomputed example objects retain their
  original `postrank 1.1.0` computation metadata, timestamps, and solver records
  and are verified on load without re-running a solver.

## Updating pre-1.0 (`0.9.x`) scripts

| Area | Current interface (`1.0.0` through `1.3.0`) |
|:--|:--|
| Grade and report-card tables | `as.data.frame(x)` returns a two-column `(entity_id, grade)` data frame in original input entity order (`postrank_analysis`, `postrank_fit`, and `postrank_baseline`). Request `as.data.frame(x, what = "report_card")` for posterior means, equal-tail marginal intervals, and pair counts (ordered by `grade` and `sort_rank`). Supplied intervals keep their fixed level (`0.90` in `pr_case_cde` and `pr_case_krw`; `0.95` in `pr_case_alabama`). |
| Criterion weights | In `postrank()`, a single-criterion input defaults `weights` to `1` when omitted. Multi-criterion analyses and lower-level functions (`postrank_problem()`, `postrank_evaluate()`) require criterion weights summing to `1` (never auto-rescaled). Supply policy through `settings` or individual arguments, not conflicting values of both. |
| Solver choice and console verbosity | `backend = NULL` checks `getOption("postrank.backend")` and defaults to `"gurobi"`; select `"highs"` explicitly (`backend = "highs"` or `options(postrank.backend = "highs")`). There is no automatic solver fallback. Progress messages are off by default; `postrank_control(verbose = NULL)` reads `getOption("postrank.verbose")` at solve time, while `output` controls raw solver output. |
| Solver status vs. all-withheld grades | A raw optimal solver termination without a verified whole-family lower bound or small enough gap is reported as `"feasible_not_certified"`. Placing every entity in Grade 1 (`N = 0`, `E_over_N = NA`, `risk = tau`) is a valid one-grade report, distinct from a run with no checked grading (`get_grades(x)` is `NULL`). |
| Figures, plot data, and text capture | `postrank_plot_report_card()` shows up to `max_rows = 30` entities by default, spread across occupied grades; `order = "mean"` requires one displayed criterion or `order_by`. `postrank_plot_pairwise()` plots stored directional-error probabilities without computing new ones, and `postrank_plot_data()` returns full unfiltered tables. `format(x, width = 72, tier = 2)` matches the `format_postrank_*_cli()` wrappers; `summary(x, details = TRUE)` adds provenance fields. |
| Probability inputs and exact ties | `postrank_probabilities()` imports precomputed tie-free comparison probabilities for weighted `G_max` grading (and `postrank_cuts()`). Posteriors with positive probability of exact equality use the separate `postrank_tie_*` functions (`R0`-centered loss; see `vignette("m4-ties-and-withholding", package = "postrank")`). |
| Case-study data conditions | Third-party data attributions and license terms remain separate from the MIT code license (`system.file("extdata", "case-studies", "DATA-NOTICE.md", package = "postrank")`): CDE source attribution, KRW `CC-BY-NC` (version unspecified), and Alabama `CC BY 4.0`. |
