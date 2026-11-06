# The one-call path (Chapter 11) and its composite result postrank_analysis
# (Chapter 10). Legacy objects are nested unchanged; every added declaration summary,
# display cache, capability record and note lives in analysis$metadata.

.pr_analysis_fields <- c("input", "pairwise", "settings", "control", "problem", "fit", "evaluation", "report_card",
  "fragility", "crossfit", "diagnostics", "backend", "metadata", "extras", "timings", "schema_version",
  "provenance", "warnings")
.pr_extra_names <- c("report_card", "fragility", "crossfit", "diagnostics")
.pr_extra_fields <- c("requested", "supported", "available", "reason", "condition")

# Input kind and the capability table of Chapter 11.
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

#' Choose Posterior Grades and Prepare Their Summaries
#'
#' Entities are assigned to ordered groups by balancing expected
#' wrong-direction loss against the cost of withholding comparisons under a
#' supplied posterior. Grade 1 has highest priority. A shared grade withholds
#' the comparison between the corresponding entities without asserting equality
#' of their latent targets.
#'
#' The function prepares pairwise probabilities, constructs and solves the main
#' problem, and returns the resulting grades, loss and supported summaries. A
#' posterior representation is supplied externally; the function does not fit a
#' statistical model. An omitted weight is set to one for a single criterion,
#' whereas weights must be specified for several criteria. `G_max` bounds the
#' number of grades from above and does not require that the bound be attained.
#'
#' @param x A validated `postrank_draws`, Gaussian/mixture
#'   `postrank_coefficients`, or [postrank_probabilities()] object.
#' @param weights,tau,G_max Decision choices when `settings` is not given.
#'   Weights are nonnegative and sum to one, without automatic normalization;
#'   names identify criteria, or unnamed values follow criterion order.
#'   This one-call function supplies weight 1 when it is omitted for one
#'   criterion. The withholding cost satisfies `0 < tau <= 0.5`.
#'   An oversized `G_max` is capped at the number of entities.
#' @param ... Optional `q`, `exact_G`, `objective`, `minimax_criteria` and
#'   `minimax_refine`, as described in [postrank_settings()]. These modes are
#'   input-dependent: Gaussian/mixture coefficients and supplied probabilities
#'   support only weighted at-most-G problems through this function.
#' @param settings A [postrank_settings()] object instead of separate decision
#'   arguments. Explicitly supplying both is a `settings_conflict` error.
#' @param backend `NULL`, `"gurobi"` or `"highs"`. An explicit choice takes precedence;
#'   otherwise `getOption("postrank.backend")` is used, then Gurobi if unset.
#'   Choose HiGHS explicitly for that backend. There is no automatic fallback
#'   after an unavailable, failed or timed-out backend.
#' @param control A [postrank_control()] object or a named control list.
#' @param report_card,fragility,crossfit,diagnostics Logical requests for
#'   additional summaries. Report cards and Monte Carlo fragility are requested
#'   by default; cross-fitting and diagnostics are off by default. See Details
#'   for the input requirements and extra computation.
#' @param level Central posterior interval level for a report card, in `(0, 1)`.
#'   Supplied marginal intervals have a fixed level; request that same level.
#' @return A `postrank_analysis` list with `input`, `pairwise`, `settings`,
#'   `control`, `problem` and the main `fit`. `evaluation` is the fixed-action
#'   evaluation of its validated grade. `report_card`, `fragility`, `crossfit`
#'   and `diagnostics` contain prepared summaries or `NULL`.
#'
#'   Each entry of `extras` records `requested`, `supported`, `available`,
#'   `reason` and `condition`, which describe the availability of that component. `backend`,
#'   `timings`, `provenance` and `warnings` describe the run. `metadata` contains
#'   declaration/capability summaries and prepared display data; `schema_version`
#'   identifies the analysis structure. Common results are extracted through
#'   [get_grades()], [get_risk()], [get_profile()] and [postrank_tables].
#' @details A time limit can leave a validated grade, or no grade at all.
#'   Without a validated candidate, the fit's status, any usable lower bound
#'   and warnings are retained, while evaluation and grade-dependent extras
#'   are `NULL` with reason `"no_validated_incumbent"`. A valid report that
#'   withholds every comparison is different: it has one grade and risk tau.
#'   Read the fit's bounds and gap as well as its status; see [postrank_solve()].
#'
#' A report card requires marginal posterior intervals, so supplied
#' probabilities without these summaries permit optimization but cannot produce
#' a report card. Monte Carlo fragility and cross-fitting require joint
#' equal-weight IID or MCMC draws; cross-fitting entails two additional
#' optimizations. For typed coefficients, diagnostics concern conditional
#' expected risk through [postrank_coefficient_diagnose()]. Target draws and
#' simulation diagnostics are unavailable from probability-only inputs.
#'
#'   If an extra fails unexpectedly, a valid main fit is retained, the extra
#'   records `reason = "extra_error"` and its condition, and a warning is added.
#'   Core input, backend and solve failures still stop the call. Requested
#'   intervals must be compatible with the source before analysis proceeds.
#' @seealso [postrank_settings()], [postrank_control()], [postrank_solve()],
#'   [postrank_report_card()], [get_risk()]
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   get_grades(one)
#'   get_risk(one)
#' }
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
  # Input.
  if (inherits(x, "postrank_probabilities")) {
    validate_postrank_probabilities(x)
    if (report_card && isTRUE(x$capabilities$posterior_intervals))
      .pr_posterior_summaries(x, level)
  } else if (inherits(x, "postrank_coefficients")) validate_postrank_coefficients(x) else {
    .pr_assert(inherits(x, "postrank_draws"), "x must be a postrank_draws, postrank_coefficients, or postrank_probabilities object",
      "invalid_input", "$")
    x <- as_postrank_draws(x)
  }
  # Policy.
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
