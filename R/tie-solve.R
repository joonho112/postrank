#' Solve a Grading Problem Under Equality-Neutral Loss
#'
#' `postrank_tie_solve()` solves a tie-aware grading problem from
#' [postrank_tie_problem()] by mixed-integer programming (`strategy =
#' "label_mip"`) and independently checks any candidate grading before returning
#' it. It minimizes posterior expected equality-neutral loss (where true target
#' equality has zero loss whether the pair is ordered or placed in the same
#' grade), subject to at most `G_max` occupied grades and the active-profile
#' equality constraint (requiring entities declared structurally equal on every
#' positive-weight criterion to share a grade).
#'
#' @param problem A validated `postrank_tie_problem` object from
#'   [postrank_tie_problem()].
#' @param backend Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the
#'   default), `getOption("postrank.backend")` is used, or `"gurobi"` (which
#'   requires a license) when unset; install the `highs` package and pass
#'   `backend = "highs"` to use HiGHS. `postrank` never switches solvers
#'   automatically. Missing or unloadable solver packages and runtime R errors
#'   thrown by the solver (such as Gurobi without an active license) stop the
#'   call with a `postrank_backend_unavailable` error, whereas solver
#'   termination outcomes (`"optimal"`, `"time_limit"`,
#'   `"feasible_not_certified"`, `"infeasible"`, `"numerical_error"`, ...) are
#'   returned in `status$normalized`.
#' @param control Named list of solver controls (`time_limit`, `threads`,
#'   `seed`, `relative_gap`, `absolute_risk_gap`, `tolerances`, `output`,
#'   `strategy`, and `verbose`, although `postrank_tie_solve()` itself prints no
#'   progress messages when `verbose = TRUE`) or a [postrank_control()] object.
#'   Because [postrank_control()] defaults to `strategy = "staged"`, pass
#'   `postrank_control(strategy = "label_mip", ...)` (or pass
#'   `strategy = "label_mip"` explicitly). Staged `engine` options are not
#'   supported: in a plain `list`, omit `engine` or pass `engine = list()`; in
#'   [postrank_control()], leave `engine` at its defaults.
#' @param strategy Must be `"label_mip"` (`"staged"` search is not supported in
#'   tie-aware mode). When `strategy` is omitted in the call and
#'   `control$strategy` is present, `control$strategy` is used and checked.
#' @return A `postrank_tie_fit` list containing `schema_version`, `loss`,
#'   `problem_identity`, `input_identity`, `problem`, `settings`, `backend`,
#'   `engine`, `control`, `capabilities`, `status` (`raw_code`, `raw_message`,
#'   `normalized`, `termination_reason`), `has_incumbent`,
#'   `incumbent_validated`, `raw_solution`, `solution_validation`, `grade`,
#'   `evaluation`, `relations` (`n x n` integer pairwise relation matrix), and
#'   `solution_identity` (the last four are `NULL` unless `incumbent_validated`
#'   is `TRUE`), `objective`, `runtime`, `raw_backend_result`,
#'   `numerical_issues`, and `warnings`. `incumbent_validated` is `TRUE` only
#'   when the rounded candidate passes integer constraint, active-profile
#'   equality, and direct [postrank_tie_evaluate()] loss checks, establishing
#'   feasibility within tolerances (not optimality).
#'
#'   In `objective`, `primary_action_risk` and `risk_upper_bound` give the
#'   verified grading's directly evaluated equality-neutral risk `U` (`NA` when
#'   `incumbent_validated` is `FALSE`), `risk_lower_bound` gives any usable
#'   whole-problem lower bound `L = R0 + raw_lower_bound / M` (a loss no
#'   feasible grading can beat according to the solver, or `NA` when
#'   unavailable), `risk_absolute_gap` gives `U - L` (`NA` when either bound is
#'   `NA`), and `offset` gives the all-withheld risk `R0 = tau * T / M`, where
#'   `M = choose(n, 2)` counts all unordered pairs and `T` is the
#'   criterion-weighted expected number of distinct-target pairs.
#' @details
#' Placing two entities in the same grade leaves them unordered without claiming
#' equal targets. A valid single-grade (`G = 1`) solution has `grade` equal to
#' all `1`s, risk `R0`, and `NA` conditional error ratios (`E_over_N`, expected
#' strict errors per ordered pair, and `E_over_D`, expected strict errors per
#' ordered distinct pair); by contrast, a run without a verified grading (for
#' example, a time limit reached before finding any feasible integer solution)
#' has `incumbent_validated = FALSE` and `grade = NULL`.
#'
#' Read `incumbent_validated`, `status$normalized`, `objective$risk_lower_bound`,
#' and `objective$risk_absolute_gap` together:
#' \itemize{
#'   \item A raw `"optimal"` status becomes `"feasible_not_certified"` (keeping
#'     the verified `grade` and any valid loose `risk_lower_bound`) when a
#'     usable whole-problem lower bound is missing or `risk_absolute_gap`
#'     exceeds `max(absolute_risk_gap, relative_gap * abs(U - R0))` beyond
#'     floating-point comparison roundoff.
#'   \item If a solver's lower bound exceeds `U` by at most the objective
#'     tolerance (scaled to the raw objective magnitude), it is clamped to `U`
#'     (`risk_absolute_gap = 0`, `bound_inversion_within_tolerance = TRUE`) with
#'     a warning. Larger bound inversions, unrounded solver constraint
#'     violations larger than integer-rounding tolerances can explain, or other
#'     backend consistency/numerical issues (such as objective mismatch or
#'     numerical termination) set `status$normalized = "numerical_error"` and
#'     exclude `risk_lower_bound` while keeping a valid rounded `grade`;
#'     non-eligible statuses such as `"unknown"` also exclude
#'     `risk_lower_bound`.
#'   \item Solver statuses and gaps describe optimization of the supplied
#'     problem within floating-point tolerances; they do not provide a formal
#'     numerical certificate or measure posterior or Monte Carlo uncertainty.
#'     Multiple optimal gradings may exist with different occupied grade counts
#'     `G` and different downstream policy or funding mappings.
#' }
#'
#' Tie-aware solving supports weighted at-most-`G_max` problems only (`minimax`,
#' `q` error budgets, and `exact_G` are not supported) and does not verify
#' scientific equality or sampling declarations in the input. Tie-aware fits
#' provide `print()`, `format()`, and `summary()` methods, and expose grades and
#' losses via `fit$grade`, `fit$evaluation`, and `fit$relations`. Ordinary
#' zero-equality functions (`get_grades()`, `postrank_compare()`,
#' `postrank_report()`, `postrank_plot_*()`, Monte Carlo diagnostics, and IID
#' bounds) do not accept `postrank_tie_*` objects; see
#' [postrank_tie_capabilities()].
#' @seealso [postrank_tie_problem()], [postrank_tie_evaluate()],
#'   [validate_postrank_tie_solution()], [postrank_tie_capabilities()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#'   problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
#'   fit <- postrank_tie_solve(
#'     problem,
#'     backend = "highs",
#'     control = postrank_control(strategy = "label_mip", time_limit = 10)
#'   )
#'   print(fit)
#'   fit$grade
#'   fit$objective[c("primary_action_risk", "risk_lower_bound", "risk_absolute_gap")]
#' }
#' @concept tie-aware
#' @export
postrank_tie_solve <- function(problem, backend = NULL, control = list(), strategy = "label_mip") {
  .pr_validate_tie_problem(problem)
  if (missing(strategy) && !is.null(control$strategy)) strategy <- control$strategy
  # The shared control normalizer fills in staged defaults even for label-MIP.
  # Reject user-requested staged options before that normalization, while
  # accepting the default record carried by a typed postrank_control object.
  engine <- control$engine
  unused_engine <- is.null(engine) || !length(engine) ||
    (inherits(control, "postrank_control") && identical(engine, .pr_engine_options(list())))
  cc <- .pr_core_control(control, strategy)
  .pr_assert(identical(cc$strategy, "label_mip") && unused_engine,
    "tie-aware mode supports label_mip only; staged engine controls are unsupported",
    "unsupported_tie_strategy")
  resolved <- .pr_resolve_backend(backend)
  raw <- .pr_with_backend(resolved, switch(resolved$name,
    highs = .pr_tie_backend_highs(problem, cc$core),
    gurobi = .pr_tie_backend_gurobi(problem, cc$core)))
  raw$engine <- list(strategy = "label_mip", loss = "tie_aware_v1",
    guard = "full_active_profile", staged_supported = FALSE)
  fit <- .pr_tie_normalize_solver_result(problem, raw, cc$core)
  fit$capabilities <- postrank_tie_capabilities()
  fit$control <- cc$core
  .pr_fit_annotate(fit, resolved)
}

#' List Supported Features in Tie-Aware Mode
#'
#' `postrank_tie_capabilities()` returns a static list showing which inputs,
#' problem settings, solvers, and downstream summaries are supported in
#' tie-aware mode (the `postrank_tie_*` workflow for posteriors with positive
#' equality probability under equality-neutral loss). It does not probe whether
#' `"gurobi"` or `"highs"` is installed or licensed; use
#' [postrank_backend_available()] for solver checks.
#'
#' @return A named list containing identifiers (`loss = "tie_aware_v1"`,
#'   `input_domain = "tie-aware-input-0.1"`, `backends = c("gurobi", "highs")`,
#'   and `equality_evidence`) and logical support flags:
#' \itemize{
#'   \item `TRUE`: `joint_draws`, `exact_finite_laws`, `weighted_at_most_G`,
#'     `full_active_profile_guard`, and `label_mip`.
#'   \item `FALSE`: `staged`, `criterionwise_inputs`, `typed_coefficients`, `q`,
#'     `minimax`, `exact_G`, `legacy_baselines_reports_plots`, `mc_diagnostics`,
#'     `uniform_iid_bounds`, `regret`, `protection_envelopes`, and
#'     `numerical_certification`.
#' }
#' @details
#' Tie-aware mode supports joint equal-weight draws and complete exact finite
#' laws on one or more criteria under weighted at-most-`G_max` problems solved
#' by `label_mip` with the active-profile equality constraint. Criterion-wise
#' draw blocks, Gaussian or mixture coefficients, criterion error budgets `q`,
#' `minimax` objectives, `exact_G` grade counts, and `"staged"` solving are not
#' implemented for tie-aware inputs.
#'
#' Tie-aware objects have `print()`, `format()`, and `summary()` methods, while
#' ordinary zero-equality baselines, table accessors, HTML reports, plots, Monte
#' Carlo diagnostics, and IID bounds reject `postrank_tie_*` classes rather than
#' reinterpreting their equality-neutral loss.
#' @seealso [postrank_tie_problem()], [postrank_tie_solve()],
#'   [postrank_backend_available()],
#'   `vignette("m4-ties-and-withholding", package = "postrank")`
#' @examples
#' capabilities <- postrank_tie_capabilities()
#' capabilities[c("weighted_at_most_G", "q", "minimax", "exact_G")]
#' capabilities$backends
#' @concept tie-aware
#' @export
postrank_tie_capabilities <- function() {
  list(loss = "tie_aware_v1", input_domain = "tie-aware-input-0.1",
    joint_draws = TRUE, exact_finite_laws = TRUE,
    weighted_at_most_G = TRUE, full_active_profile_guard = TRUE,
    label_mip = TRUE, backends = c("gurobi", "highs"),
    staged = FALSE, criterionwise_inputs = FALSE, typed_coefficients = FALSE,
    q = FALSE, minimax = FALSE, exact_G = FALSE,
    legacy_baselines_reports_plots = FALSE, mc_diagnostics = FALSE,
    uniform_iid_bounds = FALSE, regret = FALSE, protection_envelopes = FALSE,
    numerical_certification = FALSE,
    equality_evidence = c("structural_declaration_checked_against_retained_draws",
      "all_positive_mass_exact_states"))
}
