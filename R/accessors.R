# Accessors (Chapter 11): defined for postrank_fit and postrank_analysis (get_grades also
# for postrank_baseline). Without a validated incumbent, grades and relations are NULL,
# the profile and grade table are zero-row data frames with their normal columns, and
# get_risk() keeps the status and bound fields. No accessor manufactures an all-tie grade.

#' Extract the Grade Assigned to Each Entity
#'
#' The stored grades are returned as a named vector for subsequent analysis or
#' export. Grade 1 has highest priority. Entities assigned the same grade have
#' their comparison withheld; a common grade does not imply equality of their
#' latent targets.
#'
#' @param x A `postrank_fit`, `postrank_analysis` or `postrank_baseline`.
#' @param ... Unused arguments for generic compatibility.
#' @return An integer vector named by entity ID, or `NULL` when a fit has no
#'   validated candidate. Fit/analysis grades retain the input's entity order.
#' @details This accessor does not solve or choose a new grade report. A valid
#'   all-withheld report returns grade 1 for every entity; `NULL` instead means
#'   that no validated grades are available. Console truncation does not limit
#'   this vector. Use [postrank_tables] for a two-column data frame.
#' @seealso [get_relations()], [get_profile()], [get_risk()]
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   grades <- get_grades(one)
#'   grades
#' }
#' @concept reporting
#' @export
get_grades <- function(x, ...) UseMethod("get_grades")
#' @export
get_grades.postrank_fit <- function(x, ...) if (isTRUE(x$incumbent_validated)) x$grade else NULL
#' @export
get_grades.postrank_analysis <- function(x, ...) get_grades(x$fit)

#' Extract Which Pairwise Directions the Grades Disclose
#'
#' The stored grading is represented as a matrix of disclosed directions. Entry
#' `(i, j)` is 1 when row entity i has higher priority than column entity j, -1
#' for the opposite direction, and 0 when the comparison is withheld. The
#' entries represent reporting decisions rather than posterior comparison
#' probabilities.
#'
#' @param x A `postrank_fit` or `postrank_analysis`.
#' @param ... Unused arguments for generic compatibility.
#' @return An integer matrix with one row and column per entity, named and
#'   ordered as the input. Its diagonal is zero. Returns `NULL` when no
#'   validated grade is available.
#' @details Smaller grades mean higher priority. Shared grades give zero in
#'   both directions without asserting latent equality. A valid all-withheld
#'   report has an all-zero relation matrix, distinct from `NULL` after a solve
#'   without validated grades. This accessor does not run a solver.
#' @seealso [get_grades()], [get_profile()]
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   relations <- get_relations(one)
#'   relations[c("A", "B", "C"), c("A", "B", "C")]
#' }
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
#' The stored grade report is summarized by criterion. A one-criterion analysis
#' has one row; for several criteria, the rows give the expected errors and
#' withholding loss associated with the common grading. The calculation uses
#' the stored evaluation without recalculating grades or posterior summaries.
#'
#' @param x A `postrank_fit` or `postrank_analysis`.
#' @param ... Unused arguments for generic compatibility.
#' @return A data frame in input criterion order with columns:
#'   `criterion`, `weight`, `E`, `E_over_M`, `E_over_N`, `risk`, `q`,
#'   `budget_slack` and `is_minimax_max`. Returns zero rows with these same
#'   columns when no validated grade is available.
#' @details `E` is the posterior expected number of wrong disclosed directions.
#'   `E_over_M` divides by all unordered pairs; `E_over_N` divides by disclosed
#'   pairs and is `NA` when N=0. Criterion `risk` adds the withholding cost:
#'   `(E + tau * (M - N)) / M`. These describe the supplied posterior and loss,
#'   not realized error rates or simultaneous guarantees.
#'
#'   `q` is the criterion's error budget and `budget_slack = q * N - E`;
#'   both are `NA` without a budget. A nonnegative slack satisfies that count
#'   constraint before numerical tolerance is considered. `is_minimax_max`
#'   identifies included criteria attaining the minimax maximum within the
#'   comparison tolerance; it is false for weighted problems.
#' @seealso [get_risk()], [postrank_evaluate()]
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   two <- postrank(pr_tutorial$two, weights = c(score_A = .5, score_B = .5),
#'     tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   get_profile(two)
#' }
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
#' The primary risk of the validated grading is returned with the whole-problem
#' lower bound, absolute risk gap and normalized solver status. These
#' quantities describe both the available decision and the extent to which
#' numerical optimality has been established.
#'
#' @param x A `postrank_fit` or `postrank_analysis`.
#' @param ... Unused arguments for generic compatibility.
#' @return A named list with numeric `risk`, `lower_bound` and `gap`, and
#'   character `status`. Unavailable numeric values are `NA`.
#' @details `risk` is weighted expected loss for a weighted problem, or the
#'   largest selected criterion risk for minimax. With one criterion and
#'   weight 1, it is that criterion's risk. The gap is an optimization quantity
#'   for the supplied probabilities, not posterior uncertainty or a bound on
#'   true-posterior regret by itself.
#'
#'   A time limit may leave validated grades or none. Without validated grades,
#'   risk and gap are `NA`, while status and any usable lower bound remain.
#'   Missing or rejected bounds can also make the gap unavailable despite a
#'   retained grade. Consult the fit's `objective$bound_source`, warnings and
#'   validation details for the numerical qualifications.
#' @seealso [get_profile()], [postrank_solve()]
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   get_risk(one)
#' }
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
#' The `as.data.frame()` methods return complete tables of stored results. For
#' a fit, analysis or baseline, the default table has exactly two columns,
#' `entity_id` and integer `grade`, in the original input order. Grade 1 has
#' highest priority. A shared grade withholds the comparison without asserting
#' equality of the latent targets.
#'
#' @param x A `postrank_fit`, `postrank_analysis`, `postrank_baseline` or
#'   `postrank_report_card`.
#' @param row.names Optional row names for the returned table; their length
#'   must match its number of rows. `NULL` uses default row names.
#' @param optional Logical; accepted by the `as.data.frame()` generic. Basic
#'   table names are already valid R names; report-card column names are retained.
#' @param ... Unused arguments for generic compatibility.
#' @param what For an analysis, either `"grades"` (default) or
#'   `"report_card"`. Supply this argument by name.
#' @return A data frame. The basic table has character `entity_id` and integer
#'   `grade` columns. The report-card table has all columns of the prepared card.
#' @details For an analysis, `what = "report_card"` selects the full prepared
#'   card, ordered by grade and then its recorded secondary key. Calling
#'   `as.data.frame()` on a report card returns the same full table. The table
#'   retains raw entity IDs, regardless of labels used in a figure. Select
#'   rows or columns from the returned data frame using ordinary R indexing.
#'
#'   A fit or analysis without a validated grade returns zero rows with the
#'   basic column types; it does not substitute an all-withheld grade. A
#'   request for an unavailable card gives an explanatory error. Conversion
#'   does not solve a problem, evaluate a grade or compute missing summaries.
#'   Unlike a shortened console display or a plot with a row limit, table
#'   conversion includes every available row and has no paging limit.
#'
#'   **Migration to 1.0:** an analysis previously returned its full report
#'   card by default when available. The default now always returns the basic
#'   grade table. Use `as.data.frame(analysis, what = "report_card")` for the
#'   former report-card output. CSV preserves a table; RDS preserves the complete
#'   object, including settings and solver qualifications, for later views.
#' @seealso [get_grades()], [get_profile()], [get_risk()], [postrank_report_card()]
#' @concept reporting
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   grades <- as.data.frame(one)
#'   card <- as.data.frame(one, what = "report_card")
#'   grades
#'   card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
#'   csv <- tempfile(fileext = ".csv")
#'   rds <- tempfile(fileext = ".rds")
#'   write.csv(grades, csv, row.names = FALSE)
#'   saveRDS(one, rds)
#'   identical(read.csv(csv), grades)
#'   identical(as.data.frame(readRDS(rds)), grades)
#'   unlink(c(csv, rds))
#' }
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
