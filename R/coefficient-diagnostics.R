# Typed diagnostics concern conditional EXPECTED risks, never latent loss draws.
.pr_cf_history_layout <- function(index, history) {
  if (is.null(history)) return(list(reason = "missing_original_chain_history", rows = NULL))
  .pr_assert(is.list(history) && !is.data.frame(history) && length(history) > 0L,
    "chain_history must be explicit original retained-history records", "invalid_coefficient_history")
  .pr_cf_attrs(history, "names", "chain_history has hidden attributes")
  ids <- vapply(history, function(h) {
    .pr_cf_record(h, c("chain_id", "retained_iterations"))
    .pr_cf_numeric(h$chain_id, character()); .pr_safe_integer(h$chain_id, TRUE)
    .pr_assert(length(h$chain_id) == 1L, "history chain_id must be scalar", "invalid_coefficient_history")
    .pr_cf_numeric(h$retained_iterations, character()); .pr_safe_integer(h$retained_iterations, TRUE)
    .pr_assert(length(h$retained_iterations) > 0L && !anyDuplicated(h$retained_iterations) &&
      all(diff(h$retained_iterations) > 0), "retained history must be ordered and unique", "invalid_coefficient_history")
    as.numeric(h$chain_id)
  }, numeric(1))
  .pr_assert(!anyDuplicated(ids) && setequal(ids, index$chain_id),
    "history must cover exactly the original chains", "invalid_coefficient_history")
  rows <- lapply(seq_along(ids), function(c) {
    positions <- which(index$chain_id == ids[c])
    positions <- positions[order(index$iteration[positions])]
    .pr_assert(identical(as.numeric(index$iteration[positions]), as.numeric(history[[c]]$retained_iterations)),
      "source coordinates and retained history disagree", "invalid_coefficient_history")
    positions
  })
  lengths <- lengths(rows)
  reason <- if (length(ids) < 2L) "insufficient_original_chains" else if (length(unique(lengths)) != 1L)
    "unequal_chain_lengths" else if (any(lengths < 4L)) "insufficient_retained_iterations" else NULL
  if (is.null(reason)) {
    gaps <- lapply(history, function(h) diff(h$retained_iterations))
    if (any(vapply(gaps, function(g) length(unique(g)) != 1L, logical(1))) ||
        length(unique(vapply(gaps, function(g) g[1L], numeric(1)))) != 1L) reason <- "irregular_or_different_retained_spacing"
  }
  list(reason = reason, rows = if (is.null(reason)) do.call(cbind, rows) else NULL,
       chain_ids = ids, chain_lengths = lengths, original_history = history,
       history_structure_checked = TRUE, history_truth_verified = FALSE)
}

.pr_cf_risk_trace <- function(x, grade, settings, max_trace_bytes) {
  S <- length(x$source$components); K <- length(x$criterion_ids)
  required <- 8 * as.double(S) * (as.double(K) + 1)
  .pr_assert(required <= max_trace_bytes, "conditional-risk trace memory guard exceeded", "coefficient_trace_budget_exceeded")
  criterion <- matrix(0, S, K, dimnames = list(state = names(x$source$components), criterion = x$criterion_ids))
  weighted <- stats::setNames(numeric(S), names(x$source$components))
  M <- choose(length(grade), 2); disclosed <- outer(unname(grade), unname(grade), `<`); N <- sum(disclosed)
  for (s in seq_len(S)) {
    h <- x$source$components[[s]]
    projected <- .pr_cf_project_gaussian(list(kind = "gaussian_conditional", means = h$means,
      covariance = h$covariance, conditional_independence = x$source$conditional_independence))
    E <- vapply(seq_len(K), function(k) sum(projected$e[, , k][disclosed]), numeric(1))
    criterion[s, ] <- (E + settings$tau * (M - N)) / M
    weighted[s] <- (sum(settings$weights * E) + settings$tau * (M - N)) / M
  }
  list(quantity = "RB_conditional_expected_weighted_risk", values = weighted,
       criterion_values = criterion, state_index = x$source$state_index,
       weights = x$source$weights, weighted_mean = sum(x$source$weights * weighted),
       structural_constant_from_action = N == 0,
       interpretation = "Conditional expected risk given each shared hyperstate; not realized target loss draws or target-loss quantiles.")
}

#' Diagnose Integration of a Conditional Expected Risk
#'
#' The conditional expected risk of a fixed grading is evaluated from Gaussian
#' or shared-state mixture coefficients. For a mixture, conditional expected
#' risks are also obtained for the individual shared states. Where the
#' hyperparameter states were obtained using MCMC and the required original chain
#' histories are available, these values support diagnostics of the
#' integration.
#'
#' The diagnostic traces concern conditional expected risk. They do not
#' represent realized target losses or their quantiles. A single Gaussian law
#' has no Monte Carlo trace, and its MCSE is unavailable rather than zero. A
#' fixed finite mixture is evaluated using its specified weights and has no
#' Monte Carlo sampling history.
#'
#' @param x An object from [postrank_gaussian_coefficients()] or
#'   [postrank_mixture_coefficients()].
#' @param fit Optional fit computed from the same input. Its problem, settings,
#'   and released grade are checked; an incumbent is independently revalidated.
#' @param grade Optional named fixed grade vector, with smaller grades indicating
#'   higher priority. It must agree with `fit` when both are supplied.
#' @param settings Weighted-loss settings for a fixed `grade` without `fit`,
#'   including criterion-named `weights`, `tau`, and `G_max`.
#' @param chain_history Original retained-history records, each with `chain_id`
#'   and ordered `retained_iterations`. Required for eligible hyperparameter-MCMC
#'   metrics; not used for a single Gaussian or fixed finite mixture.
#' @param max_trace_bytes Nonnegative integer bound on the numeric conditional-risk
#'   output buffers, in bytes. This is not a bound on total process memory.
#' @return A `postrank_coefficient_diagnostics` object with the fixed-action
#'   `evaluation` when available, a mixture `conditional_risk_trace` where
#'   defined, and `diagnostics` records that distinguish available metrics from
#'   explicit unavailable reasons. It does not certify convergence or a selected
#'   report's frequentist or posterior accuracy.
#' @details MCMC metrics require history matching all original retained source
#'   coordinates, at least two chains with four iterations each, equal chain
#'   lengths, and regular common spacing. Chains are not truncated, padded, or
#'   interpolated. Matching the records checks history structure, not its truth
#'   or sampler convergence. Missing history, unavailable optional libraries,
#'   inadequate chain layouts, and nonfinite raw metrics retain their reasons.
#'
#'   [postrank_diagnose()] dispatches these coefficient inputs here with the
#'   default missing-history behavior. Use this function to supply history.
#'   Target pair-indicator traces, stability solves, cross-fit diagnostics,
#'   target Monte Carlo fragility, and IID target-coefficient bounds are not
#'   supplied by this route. An all-withheld report has structurally constant
#'   risk and cannot diagnose exploration of the target posterior.
#' @seealso [postrank_coefficient_capabilities()], [postrank_diagnose()],
#'   [postrank_report()] for displaying already prepared diagnostics.
#' @examples
#' x <- pr_tutorial$one
#' # A specified report, evaluated without optimization.
#' grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
#' d <- postrank_coefficient_diagnose(x, grade = grade,
#'   settings = list(weights = c(score_A = 1), tau = .25, G_max = 3L))
#' d$evaluation$weighted_risk
#' d$diagnostics$mcse_mean$unavailable_reason
#' @concept coefficients
#' @export
postrank_coefficient_diagnose <- function(x, fit = NULL, grade = NULL, settings = NULL,
    chain_history = NULL, max_trace_bytes = 8 * 1024^2) {
  .pr_cf_diagnose(x, fit, grade, settings, NULL, NULL, chain_history, max_trace_bytes)
}

.pr_cf_diagnose <- function(x, fit = NULL, grade = NULL, settings = NULL, pairs = NULL,
    stability = NULL, chain_history = NULL, max_trace_bytes = 8 * 1024^2) {
  validate_postrank_coefficients(x)
  .pr_assert(is.null(pairs) && is.null(stability),
    "typed coefficients do not support target pair-indicator traces or stability solves", "unsupported_coefficient_diagnostic")
  .pr_assert(typeof(max_trace_bytes) %in% c("integer", "double") && length(max_trace_bytes) == 1L &&
    is.null(attributes(max_trace_bytes)) && is.finite(max_trace_bytes) && max_trace_bytes >= 0 &&
    max_trace_bytes == floor(max_trace_bytes), "max_trace_bytes must be a finite nonnegative integer", "invalid_coefficient_diagnostic")
  problem_identity <- NULL
  if (!is.null(fit)) {
    .pr_assert(inherits(fit, "postrank_fit"), "expected postrank_fit", "invalid_fit")
    .pr_validate_problem(fit$problem)
    .pr_assert(identical(fit$input_identity, x$input_identity) &&
      identical(fit$problem$input_identity, x$input_identity) && identical(fit$problem_identity, fit$problem$problem_identity),
      "fit and coefficient input/problem identity differ", "diagnostic_input_mismatch")
    .pr_assert(identical(fit$settings, fit$problem$settings), "fit settings changed", "stale_fit")
    if (!is.null(settings)) .pr_assert(identical(.pr_diagnostic_settings(settings, x, reference = fit$settings), fit$settings),
      "additional settings disagree with fit", "diagnostic_settings_mismatch")
    settings <- fit$settings; problem_identity <- fit$problem_identity
    if (!is.null(grade)) .pr_assert(!is.null(fit$grade) &&
      identical(canonical_postrank_grade(grade, x$entity_ids), fit$grade), "explicit grade disagrees with fit", "diagnostic_grade_mismatch")
    grade <- if (isTRUE(fit$incumbent_validated)) fit$grade else NULL
    if (isTRUE(fit$incumbent_validated)) {
      independently_checked <- validate_postrank_solution(fit$problem, fit$raw_solution, fit$solution_validation$tolerances)
      .pr_assert(isTRUE(independently_checked$valid) && !is.null(grade) &&
        identical(grade, independently_checked$grade) && identical(grade, fit$solution_validation$grade),
        "fit grade or primal changed after independent validation", "stale_fit")
    }
  } else if (!is.null(grade)) {
    grade <- canonical_postrank_grade(grade, x$entity_ids)
    .pr_assert(!is.null(settings), "fixed grade requires loss settings", "missing_diagnostic_settings")
    settings <- .pr_diagnostic_settings(settings, x, grade)
  } else .pr_assert(is.null(settings), "settings without a fixed grade are ambiguous", "invalid_diagnostic_settings")
  evaluation <- if (is.null(grade)) NULL else postrank_evaluate(grade, x, settings$weights, settings$tau)
  mixture <- identical(x$input_kind, "shared_hyperstate_mixture")
  mcmc <- mixture && identical(x$source$source_regime, "hyperparameter_mcmc")
  .pr_assert(is.null(chain_history) || mcmc, "chain history only applies to declared hyperparameter MCMC", "invalid_coefficient_history")
  trace <- NULL; layout <- NULL
  reason <- if (is.null(grade)) "no_fixed_grade" else if (!mixture) "analytic_Gaussian_no_hyperstate_MC_trace" else
    if (!mcmc) "fixed_finite_mixture_MC_not_used" else NULL
  if (mixture && !is.null(grade)) {
    trace <- .pr_cf_risk_trace(x, grade, settings, max_trace_bytes)
    .pr_assert(abs(trace$weighted_mean - evaluation$weighted_risk) <= 1e-12,
      "conditional-risk trace mean differs from public fixed-action evaluation", "coefficient_trace_projection_mismatch")
    if (mcmc) { layout <- .pr_cf_history_layout(x$source$state_index, chain_history); reason <- layout$reason }
  }
  metrics <- if (!is.null(reason)) .pr_unavailable_diagnostics(reason) else {
    matrix <- matrix(trace$values[layout$rows], nrow = nrow(layout$rows), ncol = ncol(layout$rows))
    .pr_mcmc_trace_metrics(matrix)
  }
  mcse <- metrics$mcse_mean
  out <- list(schema_version = "coefficient-diagnostics-0.1.0", input_identity = x$input_identity,
    problem_identity = problem_identity, input_kind = x$input_kind, grade = grade, settings = settings,
    evaluation = evaluation, conditional_risk_trace = trace, diagnostics = metrics,
    layout = layout, unavailable_reason = if (!is.null(reason)) reason else mcse$unavailable_reason,
    conditional_risk_mcse_available = isTRUE(mcse$available),
    conditional_risk_mcse_unavailable_reason = mcse$unavailable_reason,
    target_loss_trace = list(available = FALSE, reason = "no_latent_target_draws"),
    target_quantiles = list(available = FALSE, reason = "target_state_quantiles_not_implemented"),
    provenance = x$provenance, validation = x$validation, capabilities = x$capabilities,
    post_selection_descriptive = !is.null(fit), convergence_verified = FALSE,
    finite_sample_certificate = FALSE, numerical_certification = FALSE,
    interpretation = c("RB conditional-risk MCSE concerns integration over hyperstates, not target-loss dispersion.",
      "History structure and finite metrics do not establish actual sampling, stationarity or convergence.",
      "A structurally constant all-withheld risk does not diagnose target exploration."))
  class(out) <- c("postrank_coefficient_diagnostics", "list"); out
}
