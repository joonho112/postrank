# Compare grading rules on one shared posterior and loss.
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
#' `postrank_compare()` evaluates alternative gradings under the same posterior
#' probabilities and loss settings as a reference fit or analysis `x` (labeled
#' `"joint"`), and counts how many pairwise orderings change relative to
#' `"joint"`. By default it adds optimal-cut baselines on expected rank and on
#' the posterior-mean composite; no external optimization solver is called.
#'
#' @param x Reference `postrank_fit` or `postrank_analysis` object with a
#'   checked grading (`incumbent_validated = TRUE`).
#' @param ... Additional `postrank_baseline`, `postrank_fit` or
#'   `postrank_analysis` objects (which must match `x`'s input identity and
#'   loss settings), or positive integer grade vectors named by `entity_ids`.
#'   Argument names set the method labels.
#' @param baselines Character vector of built-in optimal-cut baselines to
#'   include: subset of `c("expected_rank", "composite")` (both by default), or
#'   `character()` for none.
#' @param means Optional `n x K` matrix of posterior means for the
#'   `"composite"` baseline when `x` is a `postrank_fit` built from a bare
#'   `postrank_pairwise` object (otherwise `missing_posterior_means` is raised).
#' @returns A `postrank_comparison` object containing:
#'   * `reference`: `"joint"`;
#'   * `table`: one row per method with `method`, `risk` (primary loss), `N`,
#'     `disclosure_rate`, `G`, `status`, `optimality_scope`, `reason`,
#'     `risk_lower_bound`, `risk_absolute_gap`, `E_over_N_<k>`, `E_over_M_<k>`,
#'     `family_feasible` and `feasibility_reason`;
#'   * `relations`: one row per non-reference method with `n_same`,
#'     `n_new_disclosed`, `n_new_withheld`, `n_reversed` (summing to `M`) and
#'     `agreement` (`n_same / M`);
#'   * `grades` (`n x methods` integer matrix) and `relation_codes`
#'     (`n x n x methods` array);
#'   * `settings`, `input_identity`, `schema_version`, `provenance` and
#'     `warnings`.
#' @details
#' Built-in `"expected_rank"` and `"composite"` (`scales = 1`, `centers = 0`)
#' baselines call [postrank_cuts()] with `rule = "optimal"`; if `x` uses
#' settings that [postrank_cuts()] does not optimize (such as `q` or
#' `"minimax"`), the built-in row is recorded with `status = "not_comparable"`
#' and `reason` giving the error code rather than stopping.
#'
#' Supplied grade vectors are evaluated under `x`'s loss even if they violate
#' `G_max`, `exact_G` or `q` (checked within `family_feasibility_tolerance`).
#' `table$family_feasible` (`TRUE`/`FALSE`/`NA`) and `feasibility_reason` flag
#' rows outside `x`'s constraint family, whereas `reason` explains rows with no
#' grading (`NA` loss). Duplicate method labels receive unique `_2`, `_3`, ...
#' suffixes across all components.
#' @seealso [postrank_cuts()], [postrank_plot_compare()],
#'   [postrank_sensitivity()]
#' @concept baselines
#' @examples
#' toy <- postrank_example("toy_analysis")
#' cmp <- postrank_compare(toy)
#' cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
#' cmp$relations
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
