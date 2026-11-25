# Accessors for postrank_fit and postrank_analysis (get_grades also accepts
# postrank_baseline). Without a validated grading, grades and relations are NULL,
# the profile and grade table are zero-row data frames with their normal columns, and
# get_risk() keeps the status and bound fields. No accessor manufactures an all-tie grade.

#' Extract the Grade Assigned to Each Entity
#'
#' `get_grades()` extracts the checked integer grade vector from a fit,
#' analysis or baseline result. Grade 1 is the highest priority; entities given
#' the same grade are left unordered without claiming they are equal.
#'
#' @param x A `postrank_fit`, `postrank_analysis` or `postrank_baseline`
#'   object.
#' @param ... Unused arguments for generic compatibility.
#' @returns An integer vector named by `entity_id` in input entity order, or
#'   `NULL` when `x` has no checked grading (`incumbent_validated = FALSE`).
#' @details `get_grades()` reads stored grades without running a solver. A
#'   valid grading that leaves all pairs unordered returns `1L` for every
#'   entity, whereas `NULL` means no checked grading is available. Unlike
#'   printed console output, the returned vector is never truncated; use
#'   [postrank_tables] (`as.data.frame(x)`) for a two-column data frame.
#' @seealso [get_risk()], [get_profile()], [get_relations()],
#'   [postrank_tables]
#' @examples
#' one <- postrank_example("tutorial_one")
#' get_grades(one)
#' @concept reporting
#' @export
get_grades <- function(x, ...) UseMethod("get_grades")
#' @export
get_grades.postrank_fit <- function(x, ...) if (isTRUE(x$incumbent_validated)) x$grade else NULL
#' @export
get_grades.postrank_analysis <- function(x, ...) get_grades(x$fit)

#' Extract Which Pairwise Directions the Grades Disclose
#'
#' `get_relations()` converts the checked grades in `x` into an
#' entity-by-entity matrix of reported ordering decisions: `1L` when row entity
#' `i` has a higher-priority grade than column entity `j` (`grade[i] < grade[j]`),
#' `-1L` when `grade[i] > grade[j]`, and `0L` when the pair is left unordered
#' (`grade[i] == grade[j]`, including the diagonal).
#'
#' @param x A `postrank_fit` or `postrank_analysis` object.
#' @param ... Unused arguments for generic compatibility.
#' @returns An `n x n` integer matrix named and ordered by `entity_id`, with
#'   `0L` on the diagonal, or `NULL` when no checked grading is available.
#' @details Entries record the reported grading decisions, not posterior
#'   comparison probabilities. A valid one-grade report leaving all pairs
#'   unordered returns an all-`0L` matrix, whereas `NULL` means no checked
#'   grading is available. `get_relations()` does not run a solver.
#' @seealso [get_grades()], [get_profile()]
#' @examples
#' one <- postrank_example("tutorial_one")
#' rel <- get_relations(one)
#' rel[c("A", "B", "C"), c("A", "B", "C")]
#' @concept reporting
#' @export
get_relations <- function(x, ...) UseMethod("get_relations")
#' @export
get_relations.postrank_fit <- function(x, ...) if (isTRUE(x$incumbent_validated)) .pr_relations(x$grade) else NULL
#' @export
get_relations.postrank_analysis <- function(x, ...) get_relations(x$fit)

.pr_profile_columns <- c("criterion", "weight", "E", "E_over_M", "E_over_N", "risk", "q", "budget_slack", "is_minimax_max")
.pr_empty_profile <- function() {
  data.frame(criterion = character(), weight = numeric(), E = numeric(), E_over_M = numeric(), E_over_N = numeric(),
    risk = numeric(), q = numeric(), budget_slack = numeric(), is_minimax_max = logical(), stringsAsFactors = FALSE)
}

#' Extract Expected Errors and Loss for Each Criterion
#'
#' `get_profile()` returns a one-row-per-criterion table of posterior expected
#' wrong-order errors, losses and error-budget margins for the checked grading
#' stored in `x`, without running a solver or recomputing probabilities.
#'
#' @param x A `postrank_fit` or `postrank_analysis` object.
#' @param ... Unused arguments for generic compatibility.
#' @returns A data frame in input criterion order with columns `criterion`,
#'   `weight`, `E`, `E_over_M`, `E_over_N`, `risk`, `q`, `budget_slack` and
#'   `is_minimax_max`. When no checked grading is available, a zero-row data
#'   frame with these same columns and types is returned.
#' @details
#' For each criterion, `E` is the posterior expected number of wrong-order
#' ordered (`disclosed`) pairs, `E_over_M` divides `E` by all `M` unordered
#' pairs, `E_over_N` divides `E` by the `N` ordered pairs (`NA` when `N = 0`),
#' and `risk` is the posterior expected loss `(E + tau * (M - N)) / M`.
#'
#' `q` is the criterion's expected-error budget from [postrank_settings()] and
#' `budget_slack` is `q * N - E` (both `NA` when no `q` budget was set for that
#' criterion). `is_minimax_max` is `TRUE` for included criteria within `1e-12`
#' of the maximum criterion loss when `objective == "minimax"`, and `FALSE` for
#' weighted problems.
#' @seealso [get_risk()], [get_grades()], [postrank_evaluate()]
#' @examples
#' two <- postrank_example("tutorial_two")
#' get_profile(two)
#' @concept reporting
#' @export
get_profile <- function(x, ...) UseMethod("get_profile")
#' @export
get_profile.postrank_fit <- function(x, ...) {
  ev <- if (isTRUE(x$incumbent_validated)) x$evaluation else NULL
  if (is.null(ev)) return(.pr_empty_profile())
  s <- x$problem$settings; ks <- x$problem$pairwise$criterion_ids
  q <- stats::setNames(rep(NA_real_, length(ks)), ks); if (!is.null(s$q)) q[names(s$q)] <- s$q
  sel <- if (identical(s$objective, "minimax")) s$minimax_criteria else ks
  risk <- unname(ev$criterion_risk[ks])
  is_max <- identical(s$objective, "minimax") & ks %in% sel & abs(risk - max(ev$criterion_risk[sel])) <= 1e-12
  data.frame(criterion = ks, weight = unname(s$weights[ks]), E = unname(ev$E[ks]), E_over_M = unname(ev$E_over_M[ks]),
    E_over_N = unname(ev$E_over_N[ks]), risk = risk, q = unname(q), budget_slack = unname(q * ev$N - ev$E[ks]),
    is_minimax_max = is_max, stringsAsFactors = FALSE)
}
#' @export
get_profile.postrank_analysis <- function(x, ...) get_profile(x$fit)

#' Extract Posterior Loss with Its Solver Bound and Status
#'
#' `get_risk()` returns the posterior expected loss (`risk`) of the checked
#' grading in `x` together with the solver's lower bound across all allowed
#' gradings, optimization gap and normalized termination status.
#'
#' @param x A `postrank_fit` or `postrank_analysis` object.
#' @param ... Unused arguments for generic compatibility.
#' @returns A named list with four elements:
#'   * `risk`: posterior expected loss of the checked grading (weighted sum of
#'     criterion losses when `objective == "weighted"`, or largest selected
#'     criterion loss when `objective == "minimax"`), or `NA_real_` when no
#'     checked grading is available;
#'   * `lower_bound`: a loss that no allowed grading for `x`'s problem can beat
#'     (up to solver and floating-point tolerances), or `NA_real_` when no
#'     usable lower bound is available;
#'   * `gap`: `risk - lower_bound`, or `NA_real_` when either is `NA`;
#'   * `status`: normalized solver status string (`"optimal"`,
#'     `"feasible_not_certified"`, `"time_limit"`, `"infeasible"`,
#'     `"unbounded"`, `"numerical_error"` or `"unknown"`).
#' @details
#' `lower_bound`, `gap` and `status` describe optimization over the supplied
#' pairwise probabilities only; they do not measure posterior uncertainty,
#' Monte Carlo error, or excess loss ("regret") under the true posterior when
#' probabilities are estimated from finite draws.
#'
#' When a solver stops at its time limit without a checked grading, `risk` and
#' `gap` are `NA_real_` while `status` and any usable `lower_bound` are kept
#' (distinct from a valid one-grade report leaving all pairs unordered, which
#' has `risk = tau`). Even with a checked grading, `lower_bound` and `gap` are
#' `NA_real_` if no bound was computed or if the reported bound was excluded on
#' numerical checks; inspect `objective$bound_source` (on a `postrank_fit`, or
#' `x$fit$objective$bound_source` on a `postrank_analysis`) and `x$warnings`
#' for details.
#' @seealso [get_profile()], [get_grades()], [postrank_solve()]
#' @examples
#' one <- postrank_example("tutorial_one")
#' get_risk(one)
#' @concept reporting
#' @export
get_risk <- function(x, ...) UseMethod("get_risk")
#' @export
get_risk.postrank_fit <- function(x, ...) {
  num <- function(v) if (is.null(v) || !length(v)) NA_real_ else as.numeric(v)[1L]
  ok <- isTRUE(x$incumbent_validated)
  list(risk = if (ok) num(x$objective$primary_action_risk) else NA_real_, lower_bound = num(x$objective$risk_lower_bound),
    gap = if (ok) num(x$objective$risk_absolute_gap) else NA_real_, status = as.character(x$status$normalized))
}
#' @export
get_risk.postrank_analysis <- function(x, ...) get_risk(x$fit)

.pr_grade_data_frame <- function(grade, ids, row.names, optional) {
  if (is.null(grade)) {
    ids <- character(); grade <- integer()
  } else grade <- as.integer(grade[ids])
  out <- data.frame(entity_id = ids, grade = grade,
    check.names = !optional, stringsAsFactors = FALSE)
  as.data.frame(out, row.names = row.names, optional = optional)
}

#' Convert Stored Results to Tables
#'
#' `as.data.frame()` extracts complete data frames from stored `postrank`
#' results without row limits or solver calls. For a `postrank_fit`,
#' `postrank_analysis` or `postrank_baseline`, the default table has two
#' columns, `entity_id` and integer `grade`, in input entity order. Grade 1 is
#' the highest priority; entities sharing a grade are left unordered without
#' claiming they are equal.
#'
#' @param x A `postrank_fit`, `postrank_analysis`, `postrank_baseline` or
#'   `postrank_report_card` object.
#' @param row.names Optional row names matching the number of returned rows, or
#'   `NULL` for default row names.
#' @param optional Logical passed to [base::as.data.frame()].
#' @param ... Unused arguments for generic compatibility.
#' @param what For a `postrank_analysis`, `"grades"` (the default two-column
#'   table) or `"report_card"` (the full stored report-card table). Pass by
#'   name.
#' @returns A data frame: `data.frame(entity_id, grade)` (zero rows when `x`
#'   has no checked grading), or the full report-card table when `x` is a
#'   `postrank_report_card` or `what = "report_card"`.
#' @details
#' `as.data.frame(analysis, what = "report_card")` and
#' `as.data.frame(report_card)` return every entity row of the prepared report
#' card, ordered by `grade` and then the card's secondary sort key, keeping raw
#' `entity_id` values regardless of plot display labels. Requesting
#' `what = "report_card"` when `analysis$report_card` is `NULL` stops with
#' `report_card_unavailable`.
#'
#' Unlike console printing or plot row limits, `as.data.frame()` always returns
#' all available rows. Note that before postrank 1.0, `as.data.frame(analysis)`
#' returned the report card when present; pass `what = "report_card"` to obtain
#' that table. Saving to CSV exports a table, whereas `saveRDS()` preserves the
#' full object with its settings, bounds and warnings.
#' @seealso [get_grades()], [get_profile()], [get_risk()],
#'   [postrank_report_card()]
#' @concept reporting
#' @examples
#' one <- postrank_example("tutorial_one")
#' grades <- as.data.frame(one)
#' grades
#'
#' card <- as.data.frame(one, what = "report_card")
#' card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
#' @name postrank_tables
NULL

#' @rdname postrank_tables
#' @export
as.data.frame.postrank_fit <- function(x, row.names = NULL, optional = FALSE, ...) {
  .pr_grade_data_frame(get_grades(x), x$problem$pairwise$entity_ids, row.names, optional)
}

#' @rdname postrank_tables
#' @export
as.data.frame.postrank_analysis <- function(x, row.names = NULL, optional = FALSE, ...,
    what = c("grades", "report_card")) {
  what <- match.arg(what)
  if (identical(what, "grades")) return(as.data.frame(x$fit, row.names = row.names, optional = optional))
  if (is.null(x$report_card)) {
    reason <- x$extras$report_card$reason
    message <- if (identical(reason, "no_validated_incumbent"))
      "A report card needs a validated grade. Inspect get_risk(x) for the stored solver status and bound." else
      if (identical(reason, "supplied_marginal_intervals_unavailable"))
        paste("No marginal intervals were supplied with these probabilities.",
          "Use as.data.frame(x) for the grades; a report card requires same-target marginal summaries in postrank_probabilities().") else
      if (identical(reason, "extra_error"))
        paste("The report-card extra failed. Inspect x$extras$report_card$condition and address its cause",
          "before calling postrank_report_card(x); use as.data.frame(x) for the stored grades.") else
        paste("No prepared report card is available. Use as.data.frame(x) for the stored grades.",
          "If marginal intervals are available, prepare a card with postrank_report_card(x), then convert that card to a data frame.")
    .pr_abort(message, "report_card_unavailable", "$.report_card")
  }
  as.data.frame(x$report_card, row.names = row.names, optional = optional)
}

#' @rdname postrank_tables
#' @export
as.data.frame.postrank_baseline <- function(x, row.names = NULL, optional = FALSE, ...) {
  .pr_grade_data_frame(get_grades(x), names(x$scores), row.names, optional)
}

#' @rdname postrank_tables
#' @export
as.data.frame.postrank_report_card <- function(x, row.names = NULL, optional = FALSE, ...) {
  as.data.frame(x$data, row.names = row.names, optional = optional)
}
