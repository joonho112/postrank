# Monte Carlo cross-fitting and pairwise fragility diagnostics.
# Both are descriptive summaries; neither is a finite-sample bound.

# Problem settings from a fit or an explicit settings list.
.pr_mc_settings <- function(fit, settings, need_G = TRUE) {
  .pr_assert(xor(is.null(fit), is.null(settings)), "supply exactly one of fit or settings", "invalid_mc_diagnostic")
  if (!is.null(fit)) {
    .pr_assert(inherits(fit, "postrank_fit"), "expected postrank_fit", "invalid_fit")
    .pr_validate_problem(fit$problem)
    .pr_assert(is.null(fit$problem$protection_envelope) && is.null(fit$problem$settings$risk_caps),
      "MC diagnostics need a public problem, not an internal envelope or second-stage problem", "invalid_mc_diagnostic")
    s <- fit$problem$settings
    # Saved minimax fits without a minimax_refine slot used single-stage optimization.
    if (identical(s$objective, "minimax") && is.null(s$minimax_refine)) s$minimax_refine <- "none"
    return(s)
  }
  .pr_fields(settings, c("weights", "tau", if (need_G) "G_max"),
    c("weights", "tau", "G_max", "objective", "q", "exact_G", "minimax_criteria", "minimax_refine",
      "weight_sum", "weight_sum_tolerance"), "$.settings")
  if (is.null(settings$objective)) settings$objective <- "weighted"
  settings
}

# Weights and tau checked against the criteria of the draws (names, sum to
# one, tau in (0, 1/2]); the fragility screen relies on these.
.pr_mc_check_loss <- function(pairwise, s) invisible(.pr_loss_settings(pairwise, s$weights, s$tau))

.pr_mc_problem <- function(pairwise, s) postrank_problem(pairwise, s$weights, s$tau, s$G_max, s$objective, s$q, s$exact_G,
  s$minimax_criteria, if (is.null(s$minimax_refine)) "weighted" else s$minimax_refine)

.pr_mc_joint_draws <- function(draws) {
  if(inherits(draws,"postrank_coefficients")) {
    validate_postrank_coefficients(draws)
    .pr_abort("typed coefficients have no latent target draws for cross-fit or target MC-fragility", "unsupported_coefficient_diagnostic")
  }
  draws <- as_postrank_draws(draws)
  .pr_assert(identical(draws$input_kind, "equal_weight_draws") && identical(draws$dependence_mode, "joint_model"),
    "MC diagnostics require joint equal-weight draws", "unsupported_mc_diagnostic_input")
  draws
}

# Storage-order slots arranged by chain: regime, chain ids and (for equal
# chains) an iteration x chain matrix of row indices.
.pr_mc_layout <- function(draws) {
  block <- draws$joint_draws; S <- block$tensor$shape$S
  if (!identical(block$sampling$regime, "mcmc")) return(list(regime = "iid", S = S))
  slots <- block$tensor$dimnames$draw
  index <- block$draw_index[match(slots, vapply(block$draw_index, `[[`, character(1L), "slot_id"))]
  chain <- vapply(index, `[[`, character(1L), "chain_id")
  iteration <- vapply(index, function(z) as.numeric(z$iteration), numeric(1L))
  ids <- vapply(block$sampling$chain_history, `[[`, character(1L), "chain_id")
  ids <- ids[ids %in% chain]
  lengths <- vapply(ids, function(c) sum(chain == c), integer(1L))
  rows <- if (length(unique(lengths)) == 1L) vapply(ids, function(c) {
    r <- which(chain == c); r[order(iteration[r])]
  }, integer(lengths[[1L]])) else NULL
  if (!is.null(rows)) rows <- matrix(rows, ncol = length(ids))
  list(regime = "mcmc", S = S, chains = ids, chain = chain, lengths = lengths, rows = rows)
}

.pr_mc_mcse <- function(z, layout) {
  if (identical(layout$regime, "iid")) return(if (length(z) > 1L) stats::sd(z) / sqrt(length(z)) else NA_real_)
  if (is.null(layout$rows) || !requireNamespace("posterior", quietly = TRUE)) return(NA_real_)
  value <- tryCatch(suppressWarnings(posterior::mcse_mean(matrix(z[layout$rows], ncol = ncol(layout$rows)))),
    error = function(e) NA_real_)
  if (length(value) == 1L && is.finite(value)) as.numeric(value) else NA_real_
}

# Relation of each unordered pair in a grade: 1 = i ahead, -1 = j ahead, 0 = tied.
.pr_mc_relation <- function(grade) sign(outer(unname(grade), unname(grade), `-`)) * -1

.pr_mc_agreement <- function(a, b) {
  ra <- .pr_mc_relation(a); rb <- .pr_mc_relation(b); up <- upper.tri(ra)
  mean(ra[up] == rb[up])
}

#' Select and Evaluate Gradings on Two Draw Folds
#'
#' `postrank_crossfit()` splits posterior draws into two folds (`A` and `B`),
#' solves the grading problem on each fold, and evaluates each fold's grading on
#' the held-out fold. It measures sensitivity of the chosen grading and its risk
#' to finite posterior simulation without refitting your statistical model to
#' held-out observations. Running `postrank_crossfit()` executes two solver
#' runs.
#'
#' @param draws Joint equal-weight posterior draws from [postrank_draws()] or
#'   [as_postrank_draws()] (`dependence_mode = "joint_model"`), so each draw
#'   contains a joint state across all entities and criteria. Criterion-wise
#'   blocks, exact finite laws, Gaussian or mixture coefficients, pre-computed
#'   probabilities, and tie-mode inputs are not accepted.
#' @param fit Optional `postrank_fit` or `postrank_analysis` solved on `draws`
#'   (for an original public problem, without protection envelopes or
#'   second-stage risk caps). Supplies the problem settings and, when a checked
#'   grading is present, also evaluates that full-draw grading on each fold.
#'   Supply `fit` or `settings`, not both.
#' @param settings A [postrank_settings()] object or named list with `weights`,
#'   `tau`, `G_max`, and optional `objective`, `q`, `exact_G`,
#'   `minimax_criteria`, and `minimax_refine`. Supply `fit` or `settings`, not
#'   both.
#' @param backend,control,strategy Solver choice, [postrank_control()] options,
#'   and search strategy passed to [postrank_solve()] on each fold. `backend =
#'   NULL` (the default) uses `getOption("postrank.backend")` or Gurobi (which
#'   requires a license); install `highs` and pass `backend = "highs"` to use
#'   HiGHS. `postrank` never switches solvers automatically.
#' @return A `postrank_crossfit` list containing `split` metadata, per-fold
#'   records in `folds` (`draws`, `status`, `incumbent_validated`,
#'   `risk_absolute_gap`, and when a checked grading exists, `grade`, `G`,
#'   `in_fold_risk`, `out_of_fold_risk`, `optimism = out_of_fold_risk -
#'   in_fold_risk`, plus `out_of_fold_protection` when `q` is set and
#'   `full_grade_risk_on_fold` when `fit` has grades), `agreement`
#'   (`between_folds`, plus `full_vs_A` and `full_vs_B` when `fit` has grades),
#'   `folds_with_incumbent`, `mean_optimism`, `mean_abs_optimism`, and
#'   `warnings`.
#' @details
#' For IID draws (`S >= 4`), fold `A` is the first `floor(S / 2)` draws and fold
#' `B` is the remainder. For MCMC draws with at least two chains, fold `A` holds
#' the first `ceiling(C / 2)` whole chains and fold `B` holds the remaining
#' chains; single-chain MCMC (`S >= 4`) splits iterations into first and second
#' halves with an autocorrelation warning.
#'
#' When `A` and `B` are independent IID folds from the same posterior and
#' `objective = "weighted"` with loss settings fixed beforehand, out-of-fold
#' weighted risk is conditionally unbiased for that fold grading's true
#' posterior risk (computed from roughly `S / 2` draws rather than all `S`
#' draws). When both folds select the exact same grading, their two signed
#' `optimism` values have opposite signs and cancel in `mean_optimism`; check
#' `mean_abs_optimism` for the noise scale. Under `objective = "minimax"` (a
#' maximum of empirical criterion risks) or MCMC folds, out-of-fold risk is not
#' unbiased. When `q` budgets are present, `out_of_fold_protection` reports
#' held-out `E_k / N` descriptively.
#'
#' Cross-fitting is a descriptive summary of Monte Carlo sensitivity and does
#' not adjust the full-sample risk or provide a finite-sample guarantee.
#' @seealso [postrank_diagnose()], [postrank_mc_fragility()],
#'   [postrank_iid_bounds()]
#' @examples
#' cf <- postrank_example("toy_crossfit")
#' cf[c("folds_with_incumbent", "mean_optimism", "mean_abs_optimism")]
#' cf$agreement
#' @concept diagnostics
#' @export
postrank_crossfit <- function(draws, fit = NULL, settings = NULL, backend = NULL, control = list(), strategy = NULL) {
  if (inherits(fit, "postrank_analysis")) fit <- fit$fit
  if (inherits(settings, "postrank_settings")) settings <- .pr_settings_legacy_list(settings, draws)
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, strategy)
  .pr_with_backend(resolved, .pr_crossfit_core(draws, fit, settings, resolved$name, cc$core, cc$strategy))
}

.pr_crossfit_core <- function(draws, fit = NULL, settings = NULL, backend = c("gurobi", "highs"), control = list(),
                              strategy = c("staged", "label_mip")) {
  draws <- .pr_mc_joint_draws(draws); backend <- match.arg(backend); strategy <- match.arg(strategy)
  s <- .pr_mc_settings(fit, settings)
  if (!is.null(fit)) .pr_assert(identical(fit$input_identity, draws$validation$input_identity),
    "fit and draws have different input identity", "diagnostic_input_mismatch")
  layout <- .pr_mc_layout(draws); S <- layout$S; warnings <- character()
  if (identical(layout$regime, "mcmc") && length(layout$chains) >= 2L) {
    first <- layout$chains[seq_len(ceiling(length(layout$chains) / 2))]
    folds <- list(A = which(layout$chain %in% first), B = which(!layout$chain %in% first))
    method <- "mcmc_chain_groups"
  } else {
    .pr_assert(S >= 4L, "cross-fitting needs at least four draws", "insufficient_draws")
    half <- S %/% 2L; folds <- list(A = seq_len(half), B = (half + 1L):S)
    method <- if (identical(layout$regime, "mcmc")) "mcmc_single_chain_halves" else "iid_halves"
    if (identical(layout$regime, "mcmc")) warnings <- c(warnings,
      "Only one MCMC chain: folds are the first and second halves of its iterations, which are autocorrelated.")
  }
  parts <- lapply(folds, function(keep) .pr_subset_joint_draws(draws, keep, list(purpose = "postrank_crossfit", method = method)))
  pairwise <- lapply(parts, function(p) postrank_pairwise(p$draws))
  .pr_mc_check_loss(pairwise[[1L]], s)
  full_grade <- if (is.null(fit) || is.null(fit$grade)) NULL else fit$grade[draws$entity_ids]
  primary <- function(grade, pw) {
    ev <- postrank_evaluate(grade, pw, s$weights, s$tau, s$objective, s$minimax_criteria)
    list(risk = ev$primary_risk, E_over_N = ev$E_over_N, N = ev$N)
  }
  other <- c(A = "B", B = "A")
  results <- lapply(names(folds), function(f) {
    fold_fit <- postrank_solve(.pr_mc_problem(pairwise[[f]], s), backend, control, strategy)
    out <- list(fold = f, draws = length(folds[[f]]), status = fold_fit$status$normalized,
      incumbent_validated = isTRUE(fold_fit$incumbent_validated), risk_absolute_gap = fold_fit$objective$risk_absolute_gap)
    if (!isTRUE(fold_fit$incumbent_validated)) return(c(out, list(reason = "fold_fit_without_validated_incumbent")))
    grade <- fold_fit$grade[draws$entity_ids]
    oof <- primary(grade, pairwise[[other[[f]]]])
    out <- c(out, list(grade = grade, G = length(unique(grade)), in_fold_risk = fold_fit$objective$primary_action_risk,
      out_of_fold_risk = oof$risk, optimism = oof$risk - fold_fit$objective$primary_action_risk))
    if (!is.null(s$q)) out$out_of_fold_protection <- data.frame(criterion_id = names(s$q), q = unname(s$q),
      out_of_fold_E_over_N = unname(oof$E_over_N[names(s$q)]), N = oof$N)
    if (!is.null(full_grade)) out$full_grade_risk_on_fold <- primary(full_grade, pairwise[[f]])$risk
    out
  })
  names(results) <- names(folds)
  grades <- lapply(results, `[[`, "grade")
  agreement <- list(between_folds = if (all(!vapply(grades, is.null, logical(1L)))) .pr_mc_agreement(grades$A, grades$B) else NA_real_)
  if (!is.null(full_grade)) for (f in names(folds))
    agreement[[paste0("full_vs_", f)]] <- if (is.null(grades[[f]])) NA_real_ else .pr_mc_agreement(full_grade, grades[[f]])
  optimism <- vapply(results, function(r) if (is.null(r$optimism)) NA_real_ else r$optimism, numeric(1L))
  available <- is.finite(optimism)
  if (!all(available)) warnings <- c(warnings, "At least one fold has no validated incumbent; the optimism summaries use the remaining fold.")
  linear_risk <- identical(s$objective, "weighted")
  support <- list(risk_functional = if (linear_risk) "linear_weighted" else "empirical_maximum",
    fold_optimism_unbiasedness = if (linear_risk && identical(layout$regime, "iid"))
      "conditional_on_independent_target_iid_folds" else "not_claimed")
  risk_interpretation <- if (linear_risk)
    "Only with independent IID folds from the target posterior is linear weighted out-of-fold risk conditionally unbiased for the selected fold grade's true risk; the difference then estimates that fold grade's optimism."
  else "Minimax uses the maximum of empirical criterion risks, which is generally biased upward; its cross-fit difference is descriptive and has no unbiasedness claim."
  sampling_interpretation <- if (identical(layout$regime, "mcmc"))
    "No exact unbiasedness is claimed for MCMC folds: single-chain halves can be dependent, and whole-chain groups alone establish neither independence nor target stationarity nor removal of initialization bias."
  else "The IID declaration and fold split do not independently verify target sampling or fold independence."
  out <- list(schema_version = "0.1.0", input_identity = draws$validation$input_identity, settings = s,
    split = list(method = method, sizes = vapply(folds, length, integer(1L)),
      chains = if (identical(method, "mcmc_chain_groups")) lapply(folds, function(k) unique(layout$chain[k])) else NULL,
      receipts = lapply(parts, `[[`, "receipt")),
    folds = results, agreement = agreement, folds_with_incumbent = sum(available),
    interpretation_support = support,
    mean_optimism = if (any(available)) mean(optimism[available]) else NA_real_,
    mean_abs_optimism = if (any(available)) mean(abs(optimism[available])) else NA_real_,
    backend = backend, strategy = strategy,
    warnings = warnings,
    interpretation = c("Optimism = out-of-fold risk minus in-fold risk of the grade selected in that fold; positive values mean the in-sample risk was optimistic.",
      "Each fold uses about half of the draws; this indicates, but does not equal, the Monte Carlo optimism of the full-data grade.",
      "Relation agreement is the share of unordered pairs with the same relation (ahead, tied, behind) in both grades.",
      "When both folds select the same grade the two signed optimism values cancel; mean_abs_optimism then carries the scale of Monte Carlo risk error.",
      risk_interpretation, sampling_interpretation,
      "Read cross-fit values as the scale of Monte Carlo sensitivity, not as a correction to the full-data grade risk or a finite-sample bound."))
  class(out) <- c("postrank_crossfit", "list")
  out
}

#' Find Pairwise Decisions Near the Monte Carlo Noise Scale
#'
#' `postrank_mc_fragility()` identifies unordered entity pairs whose estimated
#' wrong-direction error in the better ordering direction lies close to the
#' withholding cost `tau` relative to its Monte Carlo standard error (MCSE),
#' without running a solver. Because grades are chosen jointly across all pairs,
#' a flagged pair need not change the selected grading.
#'
#' @param draws Joint equal-weight posterior draws from [postrank_draws()] or
#'   [as_postrank_draws()] (`dependence_mode = "joint_model"`). Criterion-wise
#'   blocks, exact finite laws, Gaussian or mixture coefficients, pre-computed
#'   probabilities, and tie-mode inputs are not accepted.
#' @param fit,settings Supply `fit` (`postrank_fit` or `postrank_analysis` on
#'   `draws`) or `settings` ([postrank_settings()] or named list with `weights`
#'   and `tau`), not both. When `fit` has a checked grading, each traced pair is
#'   also labeled by its relation in `fit$grade`.
#' @param z Positive numeric MCSE multiplier (`2` by default) setting the
#'   descriptive flagging threshold `|d - tau| < z * mcse`.
#' @param screen_margin Positive numeric pre-screen threshold: only pairs with
#'   `|d - tau| < screen_margin` have per-draw indicator traces built. When
#'   `NULL` (the default), IID inputs with `S > 1` use
#'   `z * 0.5 / sqrt(S - 1)` (the maximum sample SD of a `[0, 1]` indicator, so
#'   no pair that could be flagged is skipped), and MCMC inputs use `0.1` (a
#'   working screen accompanied by a warning, not an upper bound).
#' @return A `postrank_mc_fragility` list with `pairs` (data frame of traced
#'   pairs containing `entity_i`, `entity_j`, `better_direction`,
#'   `weighted_error`, `margin`, `disclose_preferred`, `mcse`, `ratio`, and
#'   `fragile`, plus `relation_in_grade` when `fit` has grades), `summary`
#'   (`pairs`, `traced`, `fragile`, `fragile_share`, `mcse_unavailable`, plus
#'   `fragile_disclosed` and `fragile_tied` when `fit` has grades), `regime`,
#'   `draws`, `z`, `screen_margin`, `mcse_method`, and `warnings`.
#' @details
#' For each unordered pair `(i, j)`, let
#' \eqn{\bar e_{ij} = \sum_k w_k e_{ij,k}} be the criterion-weighted
#' directional-error probability and \eqn{d = \min(\bar e_{ij}, \bar e_{ji})}.
#' Taken in isolation, ordering the pair in its better direction beats
#' withholding when \eqn{d < \tau}. For pairs passing `screen_margin`,
#' `postrank_mc_fragility()` builds the per-draw weighted indicator trace for
#' that empirically better direction and flags `|d - tau| < z * mcse`.
#'
#' IID MCSE is `sd(trace) / sqrt(S)`. MCMC MCSE uses `posterior::mcse_mean()` on
#' equal-length chains; unequal chain lengths or an uninstalled `posterior`
#' package leave `mcse` and `fragile` as `NA` with a warning rather than
#' truncating chains or substituting zero. Pairwise fragility flags are
#' descriptive summaries and do not assess global grade stability, account for
#' `G_max` or error budgets `q`, or provide simultaneous confidence levels or a
#' finite-sample guarantee.
#' @seealso [postrank_diagnose()], [postrank_crossfit()],
#'   [postrank_iid_bounds()]
#' @examples
#' fragility <- postrank_mc_fragility(
#'   postrank_toy,
#'   settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
#' )
#' fragility$summary
#' fragility$pairs
#' @concept diagnostics
#' @export
postrank_mc_fragility <- function(draws, fit = NULL, settings = NULL, z = 2, screen_margin = NULL) {
  if (inherits(fit, "postrank_analysis")) fit <- fit$fit
  if (inherits(settings, "postrank_settings")) settings <- .pr_settings_legacy_list(settings, draws)
  .pr_mc_fragility_core(draws, fit, settings, z, screen_margin)
}

.pr_mc_fragility_core <- function(draws, fit = NULL, settings = NULL, z = 2, screen_margin = NULL) {
  draws <- .pr_mc_joint_draws(draws); s <- .pr_mc_settings(fit, settings, need_G = FALSE)
  if (!is.null(fit)) .pr_assert(identical(fit$input_identity, draws$validation$input_identity),
    "fit and draws have different input identity", "diagnostic_input_mismatch")
  .pr_assert(typeof(z) %in% c("integer", "double") && length(z) == 1L && is.finite(z) && z > 0, "z must be a positive number", "invalid_mc_diagnostic")
  layout <- .pr_mc_layout(draws); S <- layout$S; warnings <- character()
  if (is.null(screen_margin)) screen_margin <- if (identical(layout$regime, "iid")) z * .5 / sqrt(max(1, S - 1)) else .1
  .pr_assert(typeof(screen_margin) %in% c("integer", "double") && length(screen_margin) == 1L && is.finite(screen_margin) && screen_margin > 0,
    "screen_margin must be a positive number", "invalid_mc_diagnostic")
  mcse_method <- if (identical(layout$regime, "iid")) "iid_sample_sd_over_sqrt_S" else "posterior::mcse_mean"
  if (identical(layout$regime, "mcmc") && is.null(layout$rows)) {
    warnings <- c(warnings, "Unequal MCMC chain lengths: no cross-chain MCSE is computed (no truncation or padding); flags are unavailable.")
    mcse_method <- "not_computed_unequal_chain_lengths"
  } else if (identical(layout$regime, "mcmc") && !requireNamespace("posterior", quietly = TRUE)) {
    warnings <- c(warnings, "The posterior package is unavailable: no MCMC MCSE is computed; flags are unavailable.")
    mcse_method <- "not_computed_posterior_unavailable"
  }
  if (identical(layout$regime, "mcmc") && identical(screen_margin, .1)) warnings <- c(warnings,
    "MCMC screen: pairs with margin at least 0.1 are not traced; this is a working default, not a bound.")
  pw <- postrank_pairwise(draws); n <- length(draws$entity_ids); K <- length(draws$criterion_ids)
  .pr_mc_check_loss(pw, s)
  w <- s$weights[draws$criterion_ids]
  ebar <- Reduce(`+`, lapply(seq_len(K), function(k) w[[k]] * pw$e[, , k]))
  up <- which(upper.tri(ebar), arr.ind = TRUE)
  forward <- ebar[up]; backward <- ebar[up[, 2:1, drop = FALSE]]
  ahead_i <- forward <= backward
  d <- ifelse(ahead_i, forward, backward); margin <- abs(d - s$tau)
  traced <- which(margin < screen_margin)
  values <- draws$joint_draws$tensor$values
  mcse <- vapply(traced, function(p) {
    a <- if (ahead_i[p]) up[p, 1L] else up[p, 2L]; b <- if (ahead_i[p]) up[p, 2L] else up[p, 1L]
    trace <- numeric(S)
    for (k in seq_len(K)) trace <- trace + w[[k]] * as.numeric(values[, a, k] <= values[, b, k])
    .pr_mc_mcse(trace, layout)
  }, numeric(1L))
  ids <- draws$entity_ids
  table <- data.frame(entity_i = ids[up[traced, 1L]], entity_j = ids[up[traced, 2L]],
    better_direction = ifelse(ahead_i[traced], "i_ahead", "j_ahead"), weighted_error = d[traced],
    margin = margin[traced], disclose_preferred = d[traced] < s$tau, mcse = mcse, ratio = margin[traced] / mcse,
    fragile = margin[traced] < z * mcse, stringsAsFactors = FALSE)
  if (!is.null(fit) && !is.null(fit$grade)) {
    g <- unname(fit$grade[ids]); rel <- .pr_mc_relation(g)[up[traced, , drop = FALSE]]
    table$relation_in_grade <- ifelse(rel == 0, "tied", ifelse((rel == 1) == ahead_i[traced], "disclosed_better_direction", "disclosed_reverse"))
  }
  fragile <- !is.na(table$fragile) & table$fragile
  unavailable <- length(traced) > 0L && all(is.na(table$mcse))
  summary <- list(pairs = nrow(up), traced = length(traced), fragile = if (unavailable) NA_integer_ else sum(fragile),
    fragile_share = if (unavailable) NA_real_ else sum(fragile) / nrow(up), mcse_unavailable = sum(is.na(table$mcse)))
  if (!is.null(table$relation_in_grade)) {
    summary$fragile_disclosed <- if (unavailable) NA_integer_ else sum(fragile & table$relation_in_grade != "tied")
    summary$fragile_tied <- if (unavailable) NA_integer_ else sum(fragile & table$relation_in_grade == "tied")
  }
  out <- list(schema_version = "0.1.0", input_identity = draws$validation$input_identity, weights = w, tau = s$tau,
    regime = layout$regime, draws = S, z = z, screen_margin = screen_margin, mcse_method = mcse_method,
    pairs = table, summary = summary, warnings = warnings,
    interpretation = c("A fragile pair's disclose-or-tie comparison is within z Monte Carlo standard errors of tau; more draws could reverse it.",
      "Flags are pairwise and descriptive. The grade is chosen jointly over all pairs, so a fragile pair need not change the grade.",
      "Pairs with margin at or above screen_margin are not traced."))
  class(out) <- c("postrank_mc_fragility", "list")
  out
}


