#' Choose Grades Under Equality-Neutral Loss
#'
#' A prepared tie-aware problem is solved by mixed-integer optimization, and
#' its candidate is checked independently before grades are returned. The
#' objective minimizes weighted expected strict errors and distinct-comparison
#' withholding costs, subject to the grade cap and active-profile equality
#' guard. A validated candidate may remain available when optimization
#' terminates early.
#'
#' @param problem A validated object from [postrank_tie_problem()].
#' @param backend `NULL`, `"highs"` or `"gurobi"`. The explicit argument takes
#'   precedence over `getOption("postrank.backend")`, then the default Gurobi.
#'   Choose `"highs"` explicitly to use HiGHS. There is no backend fallback.
#' @param control Named time, thread, seed, gap and tolerance controls, or a
#'   `postrank_control` with `strategy = "label_mip"`. Nonempty staged-engine
#'   controls are unsupported in this mode.
#' @param strategy `"label_mip"` only. When omitted, an explicit strategy in
#'   `control` is used and checked; otherwise the label model is used.
#' @return A `postrank_tie_fit` with the problem, settings, backend, raw solver
#'   result, status, validation, objective records and numerical warnings.
#'   `incumbent_validated` indicates whether `grade` and `evaluation` are
#'   available. Only a candidate passing independent rounded-primal,
#'   active-profile and direct-loss checks receives grades.
#'
#'   The objective record includes validated action risk as an upper bound,
#'   any usable whole-problem lower bound, the absolute risk gap, and raw
#'   units/scale/offset. Bounds convert as `R0 + raw_bound/M`, where
#'   `R0 = tau * T/M` is the all-withheld baseline. Unavailable action or bound
#'   quantities are `NA`.
#' @details A shared grade withholds a comparison; it does not assert latent
#'   equality. A valid single-grade action has risk R0 and undefined
#'   conditional error ratios. A solve without validated grades instead has
#'   `grade = NULL`; it is not reported as an all-withheld action.
#'
#'   Inspect `incumbent_validated`, `status`, `objective$risk_lower_bound` and
#'   `objective$risk_absolute_gap` together. A validated candidate establishes
#'   feasibility within tolerance, not optimality. A rejected solver bound can
#'   coexist with a retained grade. A raw optimal status becomes
#'   `"feasible_not_certified"` when a usable whole-problem lower bound is
#'   missing or the risk gap exceeds the requested threshold, allowing only
#'   comparison roundoff. The threshold is the larger of `absolute_risk_gap`
#'   and `relative_gap * abs(U - R0)`, where `U` is the validated action risk.
#'   The valid grade, raw status, and any valid loose lower bound are retained.
#'   Other termination statuses are not promoted. An optimal result remains
#'   subject to floating-point tolerances, including the existing tolerance-scale
#'   bound-inversion clamp, and does not constitute a numerical certificate;
#'   the gap concerns the supplied optimization problem, not posterior or
#'   Monte Carlo uncertainty. Multiple optima may have different grade counts
#'   and imply different funding mappings.
#'
#'   This route supports weighted at-most-G decisions only. It does not run
#'   the staged engine, minimax refinement, q protection or exact-G decisions.
#'   Ordinary baselines, accessors, HTML reports, plots and Monte Carlo
#'   guarantees do not accept tie-aware objects. Read `fit$grade` and
#'   `fit$evaluation`, or use the tie-aware print, format and summary methods.
#'   The optimizer does not verify the scientific declarations in the input.
#' @seealso [postrank_tie_problem()], [postrank_tie_evaluate()],
#'   [validate_postrank_tie_solution()], [postrank_tie_capabilities()]
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE) &&
#'     requireNamespace("highs", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#'   problem <- postrank_tie_problem(pw, c(S = .6, C = .4), tau = .25, G_max = 3L)
#'   fit <- postrank_tie_solve(problem, backend = "highs",
#'     control = postrank_control(strategy = "label_mip", time_limit = 10))
#'   fit
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

#' Check Which Tie-Aware Operations Are Available
#'
#' This fixed record describes the input types, decisions and numerical
#' operations supported by the separate `postrank_tie_*` functions. It does not
#' inspect installed solvers, check a license or run an optimization.
#'
#' @return A named list of capability flags, supported backend names, loss
#'   and input-domain identifiers, and accepted equality-evidence types.
#'   A `TRUE` flag describes implemented support, not scientific validation
#'   or a numerical certificate.
#' @details Joint draws and complete exact finite laws support weighted
#'   at-most-G label models with the full active-profile guard, using HiGHS
#'   or Gurobi. One criterion is allowed, with its named weight equal to 1.
#'   Criterionwise input blocks, typed coefficients, q budgets, minimax,
#'   exact-G and staged solving are not supported by this route.
#'
#'   Core tie-aware objects have print, format and summary methods. Ordinary
#'   baselines, accessors, reports and plots, and Monte Carlo diagnostics,
#'   uniform IID bounds, regret bounds and protection envelopes do not apply
#'   to these classes. The record reports these limits explicitly.
#'
#'   Equality evidence is either a structural declaration checked against
#'   retained draws or equality across all positive-mass states of a complete
#'   finite law. Coincidence in finitely many sampled values alone is not
#'   proof of almost-sure equality. Using this route does not reinterpret
#'   ordinary postrank objects or silently replace their weak-error loss.
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
