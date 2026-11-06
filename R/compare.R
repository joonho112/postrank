# Several grading rules on one posterior and one loss (Chapter 6/10/11, PR-DEC-11-C).
# Every action is evaluated under the reference settings; relation differences are read
# from the reference to the compared action.

.pr_comparison_fields <- c("reference", "table", "relations", "grades", "relation_codes", "settings", "input_identity",
  "schema_version", "provenance", "warnings")
# A canonical policy key: named weights and budgets in name order (unnamed weights keep their
# order), and a minimax criterion set as a sorted set, NULL meaning every weighted criterion,
# as the problem constructor normalizes it.
.pr_policy_key <- function(s) {
  by_name <- function(v) if (is.null(v) || is.null(names(v))) v else v[sort(names(v))]
  minimax <- identical(s$objective, "minimax")
  list(weights = by_name(s$weights), tau = s$tau, G_max = s$G_max, q = by_name(s$q), exact_G = s$exact_G, objective = s$objective,
    minimax_criteria = if (minimax) sort(s$minimax_criteria %||% names(s$weights)) else s$minimax_criteria,
    minimax_refine = if (minimax) s$minimax_refine else NULL)
}

# Relation accounting from reference grade g0 to grade g1 over unordered pairs i < j.
.pr_relation_change <- function(g0, g1) {
  if (is.null(g1)) return(c(n_same = NA_real_, n_new_disclosed = NA_real_, n_new_withheld = NA_real_, n_reversed = NA_real_))
  r0 <- .pr_relations(g0); r1 <- .pr_relations(g1[names(g0)])
  up <- upper.tri(r0); a <- r0[up]; b <- r1[up]
  c(n_same = sum(a == b), n_new_disclosed = sum(a == 0L & b != 0L), n_new_withheld = sum(a != 0L & b == 0L),
    n_reversed = sum(a != 0L & b != 0L & a != b))
}

# Row labels become keys only after suffixes are checked against all caller labels.
.pr_unique_comparison_methods <- function(labels) {
  .pr_assert(is.character(labels) && !anyNA(labels) && all(nzchar(labels)),
    "comparison method labels must be nonempty strings", "invalid_method")
  reserved <- unique(labels); used <- character(); out <- labels
  for (i in seq_along(labels)) {
    candidate <- labels[i]
    if (candidate %in% used) {
      suffix <- 2L
      while (paste0(candidate, "_", suffix) %in% c(reserved, used)) suffix <- suffix + 1L
      candidate <- paste0(candidate, "_", suffix)
    }
    out[i] <- candidate; used <- c(used, candidate)
  }
  out
}

# Descriptive family membership of an evaluated action, not an optimizer certificate.
# The raw E - q*N residual uses one recorded reference-fit tolerance for all rows.
.pr_comparison_family <- function(ev, settings, tolerance) {
  if (is.null(ev)) return(list(family_feasible = NA, feasibility_reason = NA_character_))
  reasons <- character()
  if (ev$G > settings$G_max) reasons <- c(reasons, "grade_limit_violation")
  if (!is.null(settings$exact_G) && ev$G != settings$exact_G)
    reasons <- c(reasons, "exact_grade_count_violation")
  if (!is.null(settings$q)) {
    residual <- ev$E[names(settings$q)] - settings$q * ev$N
    violations <- names(residual)[residual > tolerance]
    if (length(violations)) reasons <- c(reasons, paste0("protection_violation:", violations))
  }
  list(family_feasible = !length(reasons),
    feasibility_reason = if (length(reasons)) paste(reasons, collapse = "; ") else NA_character_)
}

.pr_comparison_row <- function(method, ev, status, scope, reason, lower = NA_real_, gap = NA_real_, risk = NULL, ks, family = list(family_feasible = NA, feasibility_reason = NA_character_)) {
  # risk is the primary risk of the declared objective (weighted risk, or the largest criterion risk for minimax),
  # the same quantity for every row and for the solver's lower bound.
  base <- data.frame(method = method, risk = if (!is.null(risk)) risk else if (is.null(ev)) NA_real_ else ev$primary_risk,
    N = if (is.null(ev)) NA_real_ else ev$N, disclosure_rate = if (is.null(ev)) NA_real_ else ev$disclosure_rate,
    G = if (is.null(ev)) NA_integer_ else as.integer(ev$G), status = status, optimality_scope = scope,
    reason = if (is.null(reason)) NA_character_ else reason, risk_lower_bound = lower, risk_absolute_gap = gap,
    stringsAsFactors = FALSE)
  eon <- if (is.null(ev)) rep(NA_real_, length(ks)) else unname(ev$E_over_N[ks])
  eom <- if (is.null(ev)) rep(NA_real_, length(ks)) else unname(ev$E_over_M[ks])
  cbind(base, stats::setNames(as.data.frame(as.list(eon)), paste0("E_over_N_", ks)),
    stats::setNames(as.data.frame(as.list(eom)), paste0("E_over_M_", ks)),
    as.data.frame(family, stringsAsFactors = FALSE))
}

.pr_compare_means <- function(x, fit, means) {
  pw <- fit$problem$pairwise
  if (!is.null(means)) {
    .pr_assert(is.matrix(means) && is.numeric(means) && all(is.finite(means)) && !is.null(rownames(means)) &&
      !is.null(colnames(means)) && setequal(rownames(means), pw$entity_ids) && setequal(colnames(means), pw$criterion_ids) &&
      !anyDuplicated(rownames(means)) && !anyDuplicated(colnames(means)),
      "means must be a finite n x K matrix whose dimnames are exactly the input entities and criteria", "invalid_means", "$.means")
    return(means[pw$entity_ids, pw$criterion_ids, drop = FALSE])
  }
  if (inherits(x, "postrank_analysis")) return(postrank_posterior_means(x$input))
  if (inherits(pw, "postrank_coefficients")) return(pw$means[pw$entity_ids, pw$criterion_ids, drop = FALSE])
  NULL
}

#' Compare Grading Rules on One Posterior and Loss
#'
#' Alternative reports are evaluated under a common reference posterior and
#' loss, and changes in their pairwise relations are recorded. By default,
#' score-order baselines with optimal cuts are also calculated. With `baselines
#' = character()`, evaluation is restricted to the reference and supplied
#' actions, without optimization of cuts.
#'
#' @details The common grade of `x` is labelled `"joint"`. Built-in
#' baselines use the same coefficients and policy: expected rank +
#' optimal cuts and posterior-mean composite + optimal cuts (`scales = 1`,
#' `centers = 0`), plus any baselines, fits or named grade vectors supplied
#' through `...`. Every action is evaluated under the reference settings, and
#' relation changes are read from the reference to the compared action.
#'
#' Each row retains its status and scope: the joint row records solver status,
#' bounds and gap; an optimal-cuts baseline has `status = "optimal"` with its restricted
#' optimality scope; quantile and supplied-action rows have status `"evaluated"`. Baseline
#' rows have no full-family bound (`NA`). A supplied fit without a validated
#' grade stays as a status row with `NA` action metrics and reason
#' `"no_validated_incumbent"`; an impossible requested baseline is
#' `"not_comparable"` with its error code as reason. A supplied fit or baseline
#' must match the reference policy and input identity. A named grade vector
#' carries no such policy record and is explicitly evaluated under the
#' reference loss, even if it was originally chosen for another objective.
#'
#' A supplied grade may be evaluated even when it is outside the reference
#' action family. `table$family_feasible` records grade-cap, exact-grade and
#' error-budget feasibility, with codes in `feasibility_reason`; no-action
#' rows have `NA`. All rows use the reference fit's recorded feasibility
#' tolerance for the raw budget residual `E_k - q_k * N`. This tolerance is
#' stored as `provenance$family_feasibility_tolerance` (the usual validator
#' default is used only if the reference receipt lacks it). Grade counts are
#' checked exactly. This is a numerical check, not a certificate. Outside-family
#' actions retain their risk and relations, and are marked in print and figures;
#' they do not support claims about minima over the same feasible family.
#'
#' Composite scores need posterior means: an explicit `means` matrix, the input
#' of a `postrank_analysis`, or the stored means of typed coefficients. A fit
#' built from empirical pairwise coefficients alone has no means; requesting
#' the composite baseline then raises `missing_posterior_means`.
#'
#' @param x A `postrank_fit` or `postrank_analysis` with a validated grade.
#' @param ... Further `postrank_baseline` or `postrank_fit` objects, or named
#'   integer grade vectors (named arguments set the method label).
#' @param baselines Built-in baselines to add: any of `"expected_rank"` and
#'   `"composite"`; `character()` for none.
#' @param means Optional `n x K` posterior mean matrix for the composite.
#' @return A `postrank_comparison` object. Its `table` includes method, risk,
#'   disclosure, grade count, status, bounds, criterion error profiles,
#'   `family_feasible` and `feasibility_reason`; `grades`, `relation_codes` and
#'   `relations` use the same unique method IDs. `grades` is an entity-by-method
#'   integer matrix and `relation_codes` an entity-by-entity-by-method array;
#'   no-action columns are `NA`. `relations` has one row per non-reference
#'   method, with `n_same`, `n_new_disclosed`, `n_new_withheld`, `n_reversed`
#'   and `agreement` (the unchanged fraction of all unordered pairs).
#'   `reference`, bound `settings`, `input_identity`, `schema_version`,
#'   `provenance` and `warnings` complete the object. Select table columns by
#'   name rather than relying on their positions.
#'
#'   `reason` explains an unavailable action; `feasibility_reason` explains an
#'   evaluated action outside the declared family. They are separate fields.
#'   Duplicate method labels receive collision-free suffixes shared by all
#'   result components. Use the returned IDs instead of predicting a suffix.
#'   Older saved comparisons without feasibility metadata remain displayable,
#'   with the absence of these records indicated. Checking constraints requires
#'   recreating the comparison; displays do not calculate missing metadata.
#' @seealso [postrank_cuts()], [postrank_sensitivity()]
#' @concept baselines
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   fit <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25,
#'     G_max = 3L, backend = "highs", fragility = FALSE)
#'   cmp <- postrank_compare(fit)
#'   cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
#' }
#' @export
postrank_compare <- function(x, ..., baselines = c("expected_rank", "composite"), means = NULL) {
  fit <- .pr_fit_of(x)
  if (!isTRUE(fit$incumbent_validated) || is.null(fit$grade))
    .pr_abort("postrank_compare() needs a reference fit with a validated grade", "no_validated_incumbent", "$.x")
  .pr_assert(is.character(baselines) && all(baselines %in% c("expected_rank", "composite")) && !anyDuplicated(baselines),
    "baselines must be a subset of expected_rank and composite", "invalid_baselines", "$.baselines")
  pw <- fit$problem$pairwise; ids <- pw$entity_ids; ks <- pw$criterion_ids
  settings <- if (inherits(x, "postrank_analysis")) x$settings else .pr_settings_from_problem(fit$problem)
  bound <- .pr_settings_bind(settings, pw)$settings
  key <- .pr_policy_key(fit$problem$settings)
  family_tolerance <- fit$solution_validation$tolerances$feasibility %||%
    .pr_solution_tolerances(list())$feasibility
  .pr_assert(is.numeric(family_tolerance) && length(family_tolerance) == 1L &&
    is.finite(family_tolerance) && family_tolerance >= 0,
    "the reference fit must record a nonnegative feasibility tolerance", "invalid_tolerances")
  ev0 <- fit$evaluation; g0 <- fit$grade[ids]
  rows <- list(.pr_comparison_row("joint", ev0, fit$status$normalized, "full declared family (numerical solve)", NULL,
    fit$objective$risk_lower_bound %||% NA_real_, fit$objective$risk_absolute_gap %||% NA_real_,
    risk = fit$objective$primary_action_risk, ks = ks, family = .pr_comparison_family(ev0, bound, family_tolerance)))
  grades <- list(joint = g0); warnings <- character()
  add_action <- function(label, grade, status, scope, reason = NULL, lower = NA_real_, gap = NA_real_) {
    ev <- if (is.null(grade)) NULL else postrank_evaluate(grade[ids], pw, settings = bound)
    rows[[length(rows) + 1L]] <<- .pr_comparison_row(label, ev, status, scope, reason, lower, gap, ks = ks,
      family = .pr_comparison_family(ev, bound, family_tolerance))
    grades[length(grades) + 1L] <<- list(if (is.null(ev)) NULL else ev$grade[ids])
    names(grades)[length(grades)] <<- label
  }
  add_baseline <- function(b, label = NULL) {
    .pr_validate_baseline(b)
    .pr_assert(identical(b$input_identity, fit$input_identity), "a compared baseline must use the same input identity",
      "comparison_input_mismatch", "$...")
    .pr_assert(identical(.pr_policy_key(.pr_settings_bind(b$settings, pw)$policy), key),
      "a compared baseline must use the same policy settings (weights, tau, grade rule, objective)", "comparison_settings_mismatch", "$...")
    lab <- if (!is.null(label)) label else paste0(b$method, if (identical(b$cut_rule, "quantile")) "_quantile" else "")
    add_action(lab, b$grade, if (identical(b$cut_rule, "optimal")) "optimal" else "evaluated", b$optimality_scope)
  }
  for (bname in baselines) {
    scores <- if (bname == "expected_rank") postrank_expected_rank(pw, bound$weights[ks]) else {
      m <- .pr_compare_means(x, fit, means)
      if (is.null(m)) .pr_abort(paste("the composite baseline needs posterior means: pass means =, use the postrank_analysis",
        "(whose input supplies them), or request baselines = \"expected_rank\" only"), "missing_posterior_means", "$.means")
      postrank_composite(m, bound$weights[ks])
    }
    b <- tryCatch(postrank_cuts(scores, pw, bound, direction = if (bname == "expected_rank") "ascending" else "descending"),
      postrank_input_error = function(e) e)
    if (inherits(b, "postrank_input_error")) {
      rows[[length(rows) + 1L]] <- .pr_comparison_row(bname, NULL, "not_comparable", "not computed", b$code, ks = ks)
      grades[bname] <- list(NULL)
    } else add_baseline(b)
  }
  extra <- list(...); labels <- names(extra); if (is.null(labels)) labels <- rep("", length(extra))
  .pr_assert(!anyNA(labels), "supplied method labels must not be NA", "invalid_method", "$...")
  for (i in seq_along(extra)) {
    a <- extra[[i]]; lab <- if (nzchar(labels[i])) labels[i] else NULL
    if (inherits(a, "postrank_baseline")) add_baseline(a, lab)
    else if (inherits(a, c("postrank_fit", "postrank_analysis"))) {
      f <- .pr_fit_of(a)
      .pr_assert(identical(f$input_identity, fit$input_identity), "a compared fit must use the same input identity",
        "comparison_input_mismatch", "$...")
      .pr_assert(identical(.pr_policy_key(f$problem$settings), key), "a compared fit must use the same policy settings",
        "comparison_settings_mismatch", "$...")
      ok <- isTRUE(f$incumbent_validated) && !is.null(f$grade)
      add_action(lab %||% paste0("fit_", i), if (ok) f$grade else NULL, f$status$normalized,
        "full declared family (numerical solve)", if (ok) NULL else "no_validated_incumbent",
        f$objective$risk_lower_bound %||% NA_real_, if (ok) f$objective$risk_absolute_gap %||% NA_real_ else NA_real_)
    } else {
      .pr_assert(is.numeric(a) && !is.null(names(a)) && !anyDuplicated(names(a)) && setequal(names(a), ids), "supplied grades must be named by the entities",
        "invalid_grade", "$...")
      add_action(lab %||% paste0("grades_", i), a, "evaluated", "supplied action; evaluated only")
    }
  }
  table <- do.call(rbind, rows); rownames(table) <- NULL
  # Unique method labels: suffix _2, _3, ... on duplicates.
  table$method <- .pr_unique_comparison_methods(table$method)
  names(grades) <- table$method
  gm <- matrix(NA_integer_, length(ids), nrow(table), dimnames = list(entity = ids, method = table$method))
  rc <- array(NA_integer_, c(length(ids), length(ids), nrow(table)), dimnames = list(entity_i = ids, entity_j = ids, method = table$method))
  for (m in seq_len(nrow(table))) if (!is.null(grades[[m]])) { gm[, m] <- grades[[m]][ids]; rc[, , m] <- .pr_relations(grades[[m]][ids]) }
  M <- choose(length(ids), 2)
  rel <- do.call(rbind, lapply(seq_len(nrow(table))[-1L], function(m) {
    ch <- .pr_relation_change(g0, grades[[m]])
    data.frame(method = table$method[m], n_same = ch[["n_same"]], n_new_disclosed = ch[["n_new_disclosed"]],
      n_new_withheld = ch[["n_new_withheld"]], n_reversed = ch[["n_reversed"]], agreement = ch[["n_same"]] / M,
      stringsAsFactors = FALSE)
  }))
  if (is.null(rel)) rel <- data.frame(method = character(), n_same = numeric(), n_new_disclosed = numeric(),
    n_new_withheld = numeric(), n_reversed = numeric(), agreement = numeric())
  out <- list(reference = "joint", table = table, relations = rel, grades = gm, relation_codes = rc, settings = bound,
    input_identity = fit$input_identity, schema_version = "1", provenance = .pr_provenance("postrank_compare", family_feasibility_tolerance = family_tolerance),
    warnings = unique(c(fit$warnings, warnings)))
  class(out) <- c("postrank_comparison", "list")
  .pr_validate_comparison(out)
  out
}

.pr_validate_comparison <- function(x) {
  .pr_assert(inherits(x, "postrank_comparison") && identical(names(x), .pr_comparison_fields),
    "expected a postrank_comparison with its documented ordered fields", "invalid_comparison")
  .pr_assert(identical(x$table$method[1L], x$reference), "the first table row must be the reference", "invalid_comparison")
  methods <- x$table$method
  .pr_assert(!anyDuplicated(methods) && identical(colnames(x$grades), methods) &&
    identical(dimnames(x$relation_codes)[[3L]], methods) && identical(x$relations$method, methods[-1L]),
    "comparison table, grades and relations must have the same unique method IDs", "invalid_comparison")
  .pr_assert(is.logical(x$table$family_feasible) && is.character(x$table$feasibility_reason) &&
    length(x$table$family_feasible) == length(methods) && length(x$table$feasibility_reason) == length(methods),
    "comparison rows must record family feasibility", "invalid_comparison")
  .pr_assert(all(is.na(x$table$family_feasible) == is.na(x$table$risk)) &&
    all(is.na(x$table$feasibility_reason) == !(x$table$family_feasible %in% FALSE)),
    "family-feasibility flags, reasons and action availability disagree", "invalid_comparison")
  M <- choose(nrow(x$grades), 2)
  ok <- !is.na(x$relations$n_same)
  .pr_assert(all(abs(rowSums(x$relations[ok, c("n_same", "n_new_disclosed", "n_new_withheld", "n_reversed"), drop = FALSE]) - M) < 1e-9),
    "relation counts must sum to M", "invalid_comparison")
  invisible(TRUE)
}
