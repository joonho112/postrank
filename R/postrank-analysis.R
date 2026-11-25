# One-call grading workflow and its composite result class postrank_analysis.
# Underlying input, pairwise, problem, and fit objects remain unchanged;
# declaration summaries, display caches, capabilities, and notes live in analysis$metadata.

.pr_analysis_fields <- c("input", "pairwise", "settings", "control", "problem", "fit", "evaluation", "report_card",
  "fragility", "crossfit", "diagnostics", "backend", "metadata", "extras", "timings", "schema_version",
  "provenance", "warnings")
.pr_extra_names <- c("report_card", "fragility", "crossfit", "diagnostics")
.pr_extra_fields <- c("requested", "supported", "available", "reason", "condition")

# Input kind and supported extras per representation.
.pr_input_kind <- function(x) {
  if (inherits(x, "postrank_probabilities")) return("precomputed_probabilities")
  if (inherits(x, "postrank_coefficients")) return(x$input_kind)
  if (identical(x$input_kind, "exact_finite_posterior")) return("exact_finite_law")
  if (identical(x$dependence_mode, "joint_model")) return(paste0("joint_", x$joint_draws$sampling$regime))
  "criterionwise"
}
.pr_capabilities <- function(x) {
  if (inherits(x, "postrank_probabilities")) {
    validate_postrank_probabilities(x)
    return(list(input_kind = "precomputed_probabilities",
      can_report_card = isTRUE(x$capabilities$posterior_intervals),
      can_fragility = FALSE, can_crossfit = FALSE, can_diagnostics = FALSE,
      interval_source = if (isTRUE(x$capabilities$posterior_intervals))
        "supplied_marginal_summaries" else "unavailable"))
  }
  kind <- .pr_input_kind(x); joint <- kind %in% c("joint_iid", "joint_mcmc")
  list(input_kind = kind, can_report_card = TRUE, can_fragility = joint, can_crossfit = joint, can_diagnostics = TRUE,
    interval_source = .pr_summary_source(x))
}

.pr_as_typed_control <- function(control) {
  if (inherits(control, "postrank_control")) { .pr_validate_control(control); return(control) }
  cc <- .pr_core_control(control, NULL)
  postrank_control(time_limit = cc$core$time_limit, threads = cc$core$threads, seed = cc$core$seed,
    absolute_risk_gap = cc$core$absolute_risk_gap, relative_gap = cc$core$relative_gap, strategy = cc$strategy,
    engine = cc$core$engine, verbose = cc$verbose, output = cc$core$output, tolerances = cc$core$tolerances)
}

.pr_declaration_summary <- function(x) {
  if (inherits(x, "postrank_probabilities"))
    return(list(status = "declared", source = "postrank_probabilities",
      kind = x$input_kind, targets = x$targets, probability_source = x$source,
      event = x$event, correction = x$correction,
      note = "The supplied probabilities and summaries are not a scientific or numerical certification."))
  if (inherits(x, "postrank_coefficients"))
    return(list(status = "declared", source = "postrank_coefficients", kind = x$input_kind,
      conditional_independence = x$source$conditional_independence, provenance = x$provenance,
      note = "Declarations are recorded as supplied; they are not scientifically verified."))
  list(status = "declared", source = "postrank_draws", kind = .pr_input_kind(x),
    targets = lapply(x$targets, function(t) t[intersect(c("criterion_id", "estimand", "units", "source_transform"), names(t))]),
    context = x$context, identification = x$identification$note, tie_justification = x$tie_policy$justification,
    provenance = x$provenance[intersect(c("producer", "artifact_id", "created_at"), names(x$provenance))],
    note = "Declarations are recorded as supplied; they are not scientifically verified.")
}

.pr_extra_record <- function(requested, supported, available = FALSE, reason = NULL, condition = NULL)
  list(requested = isTRUE(requested), supported = isTRUE(supported), available = isTRUE(available),
    reason = reason, condition = condition)

#' Assign Grades to Entities Under Posterior Uncertainty
#'
#' `postrank()` gives each entity (for example a school, an employer or an
#' area) an integer grade, using posterior information that you supply: draws,
#' normal (Gaussian) or mixture posteriors, or comparison probabilities. Grade
#' 1 is the highest priority; larger values of each criterion's target (the
#' entity quantity estimated on that criterion) mean higher priority, as set
#' when the input was built. Entities in different grades are reported in that
#' order. Entities in the same grade are left unordered: the report does not
#' say which one is higher, and it does not say that they are equal.
#'
#' By default, the grades are chosen to minimize the posterior expected loss,
#' averaged over all pairs of entities: a pair reported in the wrong order
#' costs 1 and a pair left unordered costs `tau`. With several criteria, one
#' common grading is chosen and the criterion losses are combined with
#' `weights`. `postrank()` computes the pairwise probabilities, solves the
#' optimization problem and returns the grades, the loss and optional
#' summaries. It does not fit a model, so the results are only as good as the
#' posterior you supply.
#'
#' postrank needs an optimization solver. HiGHS is free: install the `highs`
#' package and use `backend = "highs"` or `options(postrank.backend = "highs")`.
#' The default, Gurobi, is commercial software that needs a license.
#'
#' @param x Posterior information for the entities, one of:
#'   * a `postrank_draws` object (see [postrank_draws()] and
#'     [as_postrank_draws()]);
#'   * a normal posterior given by means and covariances
#'     ([postrank_gaussian_coefficients()]) or an average of normal
#'     posteriors over shared states such as hyperparameter draws
#'     ([postrank_mixture_coefficients()]);
#'   * a [postrank_probabilities()] object holding comparison probabilities
#'     computed elsewhere.
#' @param weights Criterion weights: nonnegative numbers that sum to one. They
#'   are not rescaled for you. Name them by criterion (named weights must name
#'   every criterion once, including any with weight 0), or give them in
#'   criterion order. With one criterion, `postrank()` sets the weight to 1 if
#'   you leave it out; with several criteria it is required.
#' @param tau Cost of leaving a pair unordered, relative to a cost of 1 for a
#'   pair reported in the wrong order. Must satisfy `0 < tau <= 0.5`.
#' @param G_max Largest number of grades. Fewer grades are allowed unless
#'   `exact_G` is given. A value larger than the number of entities is reduced
#'   to that number, and a note is added to the result's warnings.
#' @param ... Further settings passed to [postrank_settings()]: `q`
#'   (per-criterion upper limits in `[0, 1]` on the expected wrong-order
#'   proportion of ordered pairs, `E_k <= q_k * N`), `exact_G` (an exact number
#'   of occupied grades), `objective` (`"minimax"` minimizes the largest
#'   criterion loss instead of the weighted one), `minimax_criteria` (subset of
#'   criteria included in the minimax objective) and `minimax_refine` (whether
#'   to refine a minimax solution on weighted loss). With normal or mixture
#'   posteriors or supplied probabilities, only the weighted objective without
#'   `q`, `exact_G` or `minimax_criteria` is available; other values are an
#'   error.
#' @param settings A [postrank_settings()] object, used instead of `weights`,
#'   `tau`, `G_max` and `...`. Giving both, even at their default values, is an
#'   error (`settings_conflict`).
#' @param backend Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the
#'   default), `getOption("postrank.backend")` is used, or `"gurobi"` if that
#'   option is not set. If the chosen solver is not installed or cannot be
#'   loaded, the call stops with an error. The fit records the overall solver
#'   outcome in `fit$status` and stage-specific errors in `fit$engine$stages`
#'   (see Details). `postrank` never switches to the other solver.
#' @param control Solver controls from [postrank_control()], such as the time
#'   limit, number of threads and seed, or a named list of them.
#' @param report_card,fragility,crossfit,diagnostics Whether to request extra
#'   summaries. The report card and fragility are requested by default;
#'   cross-fitting and diagnostics are not. Each one is computed only when the
#'   input supports it; Details lists what each needs.
#'   * Report card: the posterior means and intervals shown with the grades.
#'   * Fragility: pairs whose wrong-order probability in the likelier direction
#'     is within Monte Carlo noise of `tau`. On MCMC draws, only borderline
#'     pairs within `0.1` (`screen_margin`) of `tau` are traced, and an
#'     informational `"MCMC screen"` note is added to `warnings`.
#'   * Cross-fitting: grades chosen on one half of the draws and evaluated on
#'     the other half (the model is not refitted).
#'   * Diagnostics: for IID or MCMC draws, Monte Carlo standard errors (with
#'     R-hat and effective sample size for MCMC draws, from the `posterior`
#'     package); for exact finite posteriors and other inputs, see Details.
#' @param level Level of the central posterior intervals in the report card,
#'   between 0 and 1. If the input comes with its own intervals, use their
#'   level (for 95% intervals, `level = 0.95`) or set `report_card = FALSE`.
#' @returns A `postrank_analysis` object, a list with these components:
#'   * `input`, `pairwise`, `settings`, `control` and `problem`: the checked
#'     input, its pairwise probabilities, and the settings, solver controls and
#'     optimization problem that were used.
#'   * `fit`: the solver result (see [postrank_solve()]).
#'   * `evaluation`: loss and error summaries of the chosen grades, or `NULL`
#'     when no grading passed postrank's checks.
#'   * `report_card`, `fragility`, `crossfit` and `diagnostics`: the extra
#'     summaries, each `NULL` when it was not computed.
#'   * `extras`: for each extra summary, whether it was `requested`,
#'     `supported` and `available`, with a `reason` and any error `condition`.
#'   * `backend`, `timings` and `warnings`: the solver used, the seconds spent
#'     in each stage, and any warnings.
#'   * `provenance`: how and when the result was made (postrank and R versions,
#'     time, solver and how it was chosen).
#'   * `metadata`: a summary of the input's declarations, which extra summaries
#'     the input supports, and stored display data.
#'   * `schema_version`: the version of this object's layout.
#'
#'   Use [get_grades()], [get_risk()], [get_profile()], and [as.data.frame()]
#'   (see [postrank_tables]) to extract the usual results, and `plot()` or
#'   [postrank_plot_report_card()] to plot the report card.
#' @details
#' **Words in the printed output.** The printed result and [get_risk()] use the
#' package's internal terms: "disclosed" pairs are the ordered pairs,
#' "withheld" pairs are the unordered ones, and "risk" is the loss described
#' above.
#'
#' **Solver results.** postrank recomputes the loss of the solver's grading
#' and checks it before reporting it. The solver also reports a lower bound
#' (a loss that no grading can beat) and the gap between the returned loss and
#' that bound; a gap of 0 means that, up to numerical tolerance, no better
#' grading exists for these probabilities. The status, bound and gap describe
#' the optimization only, not the uncertainty in the posterior or the adequacy
#' of the model; see [get_risk()] and [postrank_solve()].
#'
#' **Time limits.** When the solver stops at its time limit, the result may hold
#' a checked grading, or none. Without one, the result keeps the solver status,
#' any lower bound and the warnings; `evaluation` and the requested extra
#' summaries are `NULL`, with reason `"no_validated_incumbent"` (no checked
#' grading). This differs from a valid grading that leaves every pair
#' unordered, which has one grade and loss `tau`.
#'
#' **What each extra summary needs.** A report card needs marginal posterior
#' intervals: supplied probabilities without interval summaries can be graded
#' but give no report card. Monte Carlo fragility and cross-fitting need joint
#' equal-weight IID or MCMC draws, in which every draw holds a value for every
#' entity and criterion; cross-fitting solves two more optimization problems.
#' For IID or MCMC draws, `diagnostics` reports Monte Carlo standard errors
#' (exact finite posteriors have no Monte Carlo error); for normal or mixture
#' posteriors it evaluates the expected loss given those posteriors (for
#' hyperparameter-MCMC MCSEs on mixture posteriors, call
#' [postrank_coefficient_diagnose()] directly with `chain_history`). Supplied
#' probabilities have no draws, so fragility, cross-fitting and diagnostics are
#' not available for them.
#'
#' **Errors.** Invalid input, invalid settings, an unavailable solver, and
#' uncaught solver execution errors (such as a missing Gurobi license under
#' `strategy = "label_mip"` or LP setup) stop the call. Solver termination
#' outcomes, including infeasibility, numerical trouble and time limits, appear
#' in `fit$status`. Without a checked grading, `evaluation` is `NULL`. For a
#' caught error in staged search, check `fit$engine$stages$lp$status` and its
#' `trace` for LP rounds, or `fit$engine$stages$mip$error` and `fit$warnings`
#' for the final MIP. If an extra
#' summary fails unexpectedly, the main grading is kept, the extra records
#' `reason = "extra_error"` and its condition, and an R warning is signaled and
#' appended to `warnings`. When the input supplies its own intervals, a report
#' card at another `level` is an error, raised before any solving.
#' @seealso [postrank_example()], [postrank_settings()], [postrank_control()],
#'   [postrank_solve()], [postrank_report_card()], [get_risk()]
#' @examples
#' # Read a stored result without running a solver:
#' stored <- postrank_example("tutorial_one")
#' get_grades(stored)
#' get_risk(stored)
#' @examplesIf requireNamespace("highs", quietly = TRUE)
#' # Solve directly with the optional highs package:
#' one <- postrank(pr_tutorial$one, tau = 0.2, G_max = 3, backend = "highs",
#'   control = postrank_control(time_limit = 10), fragility = FALSE)
#' get_grades(one)
#' get_risk(one)
#' @concept decision
#' @export
postrank <- function(x, weights = NULL, tau = 0.25, G_max = 4L, ..., settings = NULL, backend = NULL,
                     control = postrank_control(), report_card = TRUE, fragility = TRUE, crossfit = FALSE,
                     diagnostics = FALSE, level = 0.90) {
  started <- proc.time()[["elapsed"]]
  dots <- list(...)
  allowed_dots <- c("q", "exact_G", "objective", "minimax_criteria", "minimax_refine")
  .pr_assert(!length(dots) || (!is.null(names(dots)) && all(nzchar(names(dots))) && all(names(dots) %in% allowed_dots)),
    paste("... may contain only", paste(allowed_dots, collapse = ", ")), "invalid_settings", "$...")
  for (f in c("report_card", "fragility", "crossfit", "diagnostics"))
    .pr_assert(is.logical(get(f)) && length(get(f)) == 1L && !is.na(get(f)), paste(f, "must be TRUE or FALSE"), "invalid_request", paste0("$.", f))
  level <- .pr_level(level)
  if (inherits(x, "postrank_probabilities")) {
    validate_postrank_probabilities(x)
    if (report_card && isTRUE(x$capabilities$posterior_intervals))
      .pr_posterior_summaries(x, level)
  } else if (inherits(x, "postrank_coefficients")) validate_postrank_coefficients(x) else {
    .pr_assert(inherits(x, "postrank_draws"), "x must be a postrank_draws, postrank_coefficients, or postrank_probabilities object",
      "invalid_input", "$")
    x <- as_postrank_draws(x)
  }
  if (is.null(settings)) {
    if (is.null(weights) && length(x$criterion_ids) == 1L)
      weights <- stats::setNames(1, x$criterion_ids)
    .pr_assert(!is.null(weights), "weights are required unless settings is supplied", "invalid_weights", "$.weights")
    settings <- do.call(postrank_settings, c(list(weights = weights, tau = tau, G_max = G_max), dots))
  } else {
    .pr_settings_conflict(c(.pr_supplied(c("weights", "tau", "G_max")), names(dots)))
    .pr_validate_settings(settings)
  }
  ctrl <- .pr_as_typed_control(control)
  resolved <- .pr_resolve_backend(backend)
  t <- c(pairwise = NA_real_, build = NA_real_, solve = NA_real_, validate = NA_real_, extras = NA_real_)
  tick <- function() proc.time()[["elapsed"]]
  .pr_with_resolution(resolved, {
    s0 <- tick(); pw <- postrank_pairwise(x); t[["pairwise"]] <- tick() - s0
    s0 <- tick(); bound <- .pr_settings_bind(settings, pw); problem <- postrank_problem(pw, settings = bound$settings)
    t[["build"]] <- tick() - s0
    s0 <- tick(); fit <- postrank_solve(problem, backend = resolved$name, control = ctrl); t[["solve"]] <- tick() - s0
  }, progress = TRUE)
  s0 <- tick()
  .pr_validate_problem(problem)
  .pr_assert(identical(fit$problem_identity, problem$problem_identity), "fit and problem identities disagree", "invalid_analysis")
  has_grade <- isTRUE(fit$incumbent_validated) && !is.null(fit$grade)
  evaluation <- if (has_grade) fit$evaluation else NULL
  t[["validate"]] <- tick() - s0
  caps <- .pr_capabilities(x)
  requested <- list(report_card = report_card, fragility = fragility, crossfit = crossfit, diagnostics = diagnostics)
  supported <- list(report_card = caps$can_report_card, fragility = caps$can_fragility, crossfit = caps$can_crossfit,
    diagnostics = caps$can_diagnostics)
  results <- stats::setNames(vector("list", 4L), .pr_extra_names)
  extras <- stats::setNames(vector("list", 4L), .pr_extra_names)
  warns <- c(fit$warnings, bound$settings$warnings)
  summaries <- NULL
  s0 <- tick()
  for (e in .pr_extra_names) {
    rec <- .pr_extra_record(requested[[e]], supported[[e]])
    if (!requested[[e]]) rec$reason <- "not_requested"
    else if (!has_grade) rec$reason <- "no_validated_incumbent"
    else if (!supported[[e]]) rec$reason <- if (inherits(x, "postrank_probabilities")) {
      if (e == "report_card") "supplied_marginal_intervals_unavailable" else
        "supplied_probabilities_have_no_target_draws"
    } else "unsupported_input_kind"
    else {
      value <- tryCatch(.pr_with_resolution(resolved, switch(e,
        report_card = {
          summaries <- .pr_posterior_summaries(x, level)
          .pr_report_card_build(fit, summaries, "expected_rank")
        },
        fragility = postrank_mc_fragility(x, fit = fit),
        crossfit = postrank_crossfit(x, fit = fit, backend = resolved$name, control = ctrl),
        diagnostics = postrank_diagnose(x, fit = fit))),
        error = function(err) structure(list(class = class(err), code = if (is.null(err$code)) NA_character_ else err$code,
          message = conditionMessage(err)), class = "postrank_extra_failure"))
      if (inherits(value, "postrank_extra_failure")) {
        rec$reason <- "extra_error"; rec$condition <- unclass(value)
        msg <- sprintf("The %s extra failed and is unavailable (%s); the fit is kept.", e, value$message)
        warns <- c(warns, msg); warning(msg, call. = FALSE)
      } else { results[[e]] <- value; rec$available <- TRUE }
    }
    extras[[e]] <- rec
  }
  t[["extras"]] <- tick() - s0
  input_identity <- .pr_input_identity_of(x)
  display_cache <- if (is.null(summaries)) list() else list(list(key = list(input_identity = input_identity,
    level = summaries$level, method = summaries$source), means = summaries$means, lower = summaries$lower, upper = summaries$upper))
  out <- list(input = x, pairwise = pw, settings = bound$settings, control = ctrl, problem = problem, fit = fit,
    evaluation = evaluation, report_card = results$report_card, fragility = results$fragility,
    crossfit = results$crossfit, diagnostics = results$diagnostics,
    backend = list(name = fit$backend$name, wrapper_version = if (is.null(fit$backend$wrapper_version)) NA_character_ else fit$backend$wrapper_version,
      solver_version = if (is.null(fit$backend$solver_version)) NA_character_ else fit$backend$solver_version,
      resolution = fit$backend$resolution, channel = fit$backend$channel),
    metadata = list(declarations = .pr_declaration_summary(x), display_cache = display_cache,
      capabilities = caps[c("can_report_card", "can_fragility", "can_crossfit", "can_diagnostics", "interval_source")],
      notes = character()),
    extras = extras, timings = t, schema_version = "1",
    provenance = .pr_provenance("postrank", backend = resolved$name, backend_resolution = resolved$resolution,
      total_seconds = tick() - started),
    warnings = unique(c(warns, unlist(lapply(results, function(v) if (is.list(v)) v$warnings else NULL), use.names = FALSE))))
  class(out) <- c("postrank_analysis", "list")
  .pr_validate_analysis(out)
  out
}

# Cached report-card summaries of an analysis, keyed by input identity, level and method.
.pr_cached_summaries <- function(x, level) {
  for (entry in x$metadata$display_cache) {
    k <- entry$key
    level_matches <- if (inherits(x$input, "postrank_probabilities")) identical(k$level, level) else
      isTRUE(all.equal(k$level, level))
    if (identical(k$input_identity, .pr_input_identity_of(x$input)) && level_matches &&
        identical(k$method, .pr_summary_source(x$input)))
      return(list(means = entry$means, lower = entry$lower, upper = entry$upper, source = k$method, level = k$level,
        input_identity = k$input_identity))
  }
  NULL
}

.pr_validate_analysis <- function(x) {
  .pr_assert(inherits(x, "postrank_analysis") && identical(names(x), .pr_analysis_fields),
    "expected a postrank_analysis with its documented ordered fields", "invalid_analysis")
  input_identity <- .pr_input_identity_of(x$input)
  .pr_assert(identical(x$pairwise$input_identity, input_identity) && identical(x$problem$input_identity, input_identity) &&
    identical(x$fit$input_identity, input_identity), "input, pairwise, problem and fit identities disagree", "invalid_analysis")
  .pr_assert(identical(x$fit$problem_identity, x$problem$problem_identity), "fit and problem identities disagree", "invalid_analysis")
  .pr_validate_settings(x$settings); .pr_validate_control(x$control)
  has_grade <- isTRUE(x$fit$incumbent_validated) && !is.null(x$fit$grade)
  if (has_grade) .pr_assert(identical(x$evaluation$grade, x$fit$grade), "evaluation grade differs from the fit grade", "invalid_analysis")
  else .pr_assert(is.null(x$evaluation) && is.null(x$report_card) && is.null(x$fragility) && is.null(x$crossfit) &&
    is.null(x$diagnostics), "without a validated incumbent every grade-dependent result must be NULL", "invalid_analysis")
  .pr_assert(identical(names(x$extras), .pr_extra_names), "extras must record the four stages in order", "invalid_analysis")
  for (e in .pr_extra_names) {
    r <- x$extras[[e]]
    .pr_assert(identical(names(r), .pr_extra_fields), paste("extra record", e, "has unexpected fields"), "invalid_analysis")
    .pr_assert(identical(r$available, !is.null(x[[e]])), paste("extra", e, "availability disagrees with its value"), "invalid_analysis")
    if (r$available) .pr_assert(is.null(r$reason) && is.null(r$condition), paste("available extra", e, "carries a reason"), "invalid_analysis")
    else .pr_assert(is.character(r$reason) && length(r$reason) == 1L, paste("unavailable extra", e, "needs a reason"), "invalid_analysis")
    v <- x[[e]]
    if (!is.null(v) && !is.null(v$input_identity))
      .pr_assert(identical(v$input_identity, input_identity), paste("extra", e, "has a different input identity"), "invalid_analysis")
  }
  .pr_assert(identical(.pr_policy_key(.pr_settings_bind(x$settings, x$pairwise)$policy), .pr_policy_key(x$problem$settings)),
    "typed settings disagree with the problem's policy", "invalid_analysis")
  caps <- .pr_capabilities(x$input)
  for (e in .pr_extra_names) .pr_assert(identical(x$extras[[e]]$supported, isTRUE(caps[[paste0("can_", e)]])),
    paste("extra", e, "support disagrees with the capability table"), "invalid_analysis")
  if (!is.null(x$report_card)) .pr_assert(identical(x$report_card$grade_identity, x$fit$solution_identity$relation_identity) &&
    identical(x$report_card$input_identity, input_identity), "report card belongs to another grade or input", "invalid_analysis")
  .pr_assert(identical(names(x$timings), c("pairwise", "build", "solve", "validate", "extras")) && is.numeric(x$timings),
    "timings must record pairwise, build, solve, validate and extras", "invalid_analysis")
  .pr_assert(is.list(x$backend) && identical(names(x$backend), c("name", "wrapper_version", "solver_version", "resolution", "channel")),
    "backend record has unexpected fields", "invalid_analysis")
  .pr_assert(is.character(x$warnings) && is.list(x$provenance), "audit slots have unexpected types", "invalid_analysis")
  .pr_assert(identical(names(x$metadata), c("declarations", "display_cache", "capabilities", "notes")),
    "metadata must hold declarations, display_cache, capabilities and notes", "invalid_analysis")
  invisible(TRUE)
}
