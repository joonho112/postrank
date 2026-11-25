# Entity-level report cards (postrank_report_card). Marginal summaries are
# computed once here from the input posterior; views only read the stored table.

.pr_report_card_fields <- c("data", "level", "interval_source", "secondary_order", "settings", "grade_identity",
  "input_identity", "schema_version", "provenance", "warnings")

.pr_fit_of <- function(x) {
  if (inherits(x, "postrank_analysis")) return(x$fit)
  .pr_assert(inherits(x, "postrank_fit"), "expected a postrank_fit or postrank_analysis", "invalid_fit")
  x
}
.pr_input_identity_of <- function(x) {
  if (inherits(x, "postrank_probabilities")) {
    validate_postrank_probabilities(x)
    return(x$input_identity)
  }
  if (inherits(x, "postrank_coefficients")) x$coefficient_identity else x$validation$input_identity
}

#' Prepare an Entity Report Card with Posterior Intervals
#'
#' `postrank_report_card()` combines a checked grading with marginal posterior
#' means, central intervals and expected ranks in an entity-level table. Each
#' row gives an entity's grade, how many other entities are reported above it,
#' below it or in the same grade, and per-criterion posterior summaries. For a
#' basic two-column grade table, use [postrank_tables].
#'
#' @param x A `postrank_fit` or `postrank_analysis` object with a checked
#'   grading (`incumbent_validated = TRUE`; otherwise stops with
#'   `no_validated_incumbent`).
#' @param draws Optional posterior input matching `x`'s `input_identity`: a
#'   `postrank_draws`, `postrank_coefficients`, or [postrank_probabilities()]
#'   object with marginal interval summaries. Required when `x` is a
#'   `postrank_fit` built from a `postrank_pairwise` object that does not store
#'   the original draws.
#' @param level Central posterior interval level in `(0, 1)` (default `0.90`).
#'   For a [postrank_probabilities()] input with supplied intervals, `level`
#'   must equal the stored `summaries$level`.
#' @param order Secondary sort order within each grade: `"expected_rank"`
#'   (weighted expected rank, the default), `"mean"` (descending posterior mean
#'   on one criterion) or `"label"` (entity ID).
#' @param order_by Criterion ID used when `order = "mean"` (required when
#'   several criteria are present, optional with one; must be `NULL` for other
#'   `order` values).
#' @returns A `postrank_report_card` object with the full data frame in `data`,
#'   plus `level`, `interval_source`, `secondary_order`, `settings`,
#'   `grade_identity`, `input_identity`, `schema_version`, `provenance`
#'   (recording `ordering_criterion` when `order = "mean"`) and `warnings`.
#' @details
#' Rows are sorted first by `grade` (grade 1 is highest priority; shared grades
#' leave pairs unordered), then by `order`, with `entity_id` breaking remaining
#' ties. In `data`, `n_above` counts entities graded below this entity
#' (`grade[i] < grade[j]`), `n_below` counts entities graded above it, and
#' `n_withheld` counts other entities sharing its grade; for every row,
#' `n_above + n_below + n_withheld == n - 1`. Per-criterion columns are named
#' `mean_<k>`, `lower_<k>`, `upper_<k>` and `expected_rank_<k>`, where expected
#' rank is \eqn{1 + \sum_{j \ne i} e_{ij,k}}. When `order = "expected_rank"`,
#' rows within a grade are ordered by weighted expected rank rather than adding
#' means across criteria in different units.
#'
#' Cached summaries on a `postrank_analysis` at the requested `level` are
#' reused; otherwise summaries are computed from the posterior source without
#' re-solving for grades. Intervals summarize marginal target uncertainty (a
#' posterior mean can lie outside an equal-tail interval), not Monte Carlo
#' error or the probability that a grade assignment is right. `data` always
#' retains all `n` entities; row caps in [postrank_plot_report_card()] affect
#' only the plot.
#' @seealso [postrank()], [postrank_tables], [postrank_plot_report_card()],
#'   [postrank_posterior_means()]
#' @concept reporting
#' @examples
#' one <- postrank_example("tutorial_one")
#' card <- postrank_report_card(one, level = 0.80, order = "mean")
#' as.data.frame(card)
#' card$interval_source
#' @export
postrank_report_card <- function(x, draws = NULL, level = 0.90, order = c("expected_rank", "mean", "label"), order_by = NULL) {
  order <- match.arg(order); level <- .pr_level(level)
  fit <- .pr_fit_of(x)
  if (!isTRUE(fit$incumbent_validated) || is.null(fit$grade))
    .pr_abort("a report card needs a validated grade; this fit has no validated incumbent", "no_validated_incumbent", "$.fit")
  src <- if (!is.null(draws)) draws else if (inherits(x, "postrank_analysis")) x$input else
    if (inherits(fit$problem$pairwise, "postrank_coefficients") ||
      inherits(fit$problem$pairwise, "postrank_probabilities")) fit$problem$pairwise else NULL
  if (is.null(src)) .pr_abort(paste("this fit was built from a pairwise object and carries no posterior law;",
    "supply draws = the postrank_draws or postrank_coefficients it came from"), "missing_posterior_source", "$.draws")
  .pr_assert(identical(.pr_input_identity_of(src), fit$input_identity),
    "draws must be the input the fit was computed from (input identities differ)", "diagnostic_input_mismatch", "$.draws")
  summaries <- if (inherits(x, "postrank_analysis")) .pr_cached_summaries(x, level) else NULL
  if (is.null(summaries)) summaries <- .pr_posterior_summaries(src, level)
  .pr_report_card_build(fit, summaries, order, order_by)
}

.pr_report_card_mean_criterion <- function(criteria, order, order_by = NULL) {
  if (order != "mean") {
    .pr_assert(is.null(order_by), "order_by is only used with order = 'mean'", "invalid_display", "$.order_by")
    return(NULL)
  }
  if (is.null(order_by) && length(criteria) == 1L) order_by <- criteria
  .pr_assert(is.character(order_by) && length(order_by) == 1L && !is.na(order_by) && order_by %in% criteria,
    "order = 'mean' needs order_by = one criterion when several criteria are present",
    "invalid_display", "$.order_by")
  order_by
}

.pr_report_card_build <- function(fit, summaries, order, order_by = NULL) {
  pw <- fit$problem$pairwise; ids <- pw$entity_ids; ks <- pw$criterion_ids; n <- length(ids)
  order_by <- .pr_report_card_mean_criterion(ks, order, order_by)
  g <- fit$grade[ids]
  w <- fit$problem$settings$weights[ks]
  er <- vapply(ks, function(k) 1 + rowSums(pw$e[, , k], na.rm = TRUE), numeric(n))
  er <- matrix(er, n, length(ks), dimnames = list(ids, ks))
  above <- vapply(seq_len(n), function(i) sum(g[i] < g[-i]), 1L)
  below <- vapply(seq_len(n), function(i) sum(g[i] > g[-i]), 1L)
  tied <- vapply(seq_len(n), function(i) sum(g[i] == g[-i]), 1L)
  df <- data.frame(entity_id = ids, grade = as.integer(g), sort_rank = NA_integer_, n_above = as.integer(above),
    n_below = as.integer(below), n_withheld = as.integer(tied), stringsAsFactors = FALSE)
  for (k in ks) {
    df[[paste0("mean_", k)]] <- unname(summaries$means[ids, k])
    df[[paste0("lower_", k)]] <- unname(summaries$lower[ids, k])
    df[[paste0("upper_", k)]] <- unname(summaries$upper[ids, k])
    df[[paste0("expected_rank_", k)]] <- unname(er[ids, k])
  }
  key <- switch(order,
    expected_rank = as.numeric(er[ids, , drop = FALSE] %*% w),
    mean = -as.numeric(summaries$means[ids, order_by]),
    label = rep(0, n))
  o <- order(df$grade, key, match(ids, sort(ids, method = "radix")), method = "radix")
  df <- df[o, , drop = FALSE]; df$sort_rank <- seq_len(n); rownames(df) <- NULL
  .pr_assert(all(df$n_above + df$n_below + df$n_withheld == n - 1L), "relation counts must sum to n - 1", "invalid_report_card")
  provenance <- .pr_provenance("postrank_report_card")
  if (!is.null(order_by)) provenance$ordering_criterion <- order_by
  out <- list(data = df, level = summaries$level, interval_source = summaries$source, secondary_order = order,
    settings = .pr_settings_from_problem(fit$problem),
    grade_identity = fit$solution_identity$relation_identity, input_identity = fit$input_identity,
    schema_version = "1", provenance = provenance, warnings = character())
  class(out) <- c("postrank_report_card", "list")
  .pr_validate_report_card(out)
  out
}

.pr_validate_report_card <- function(x) {
  .pr_assert(inherits(x, "postrank_report_card") && identical(names(x), .pr_report_card_fields),
    "expected a postrank_report_card with its documented ordered fields", "invalid_report_card")
  d <- x$data
  .pr_assert(is.data.frame(d) && identical(names(d)[1:6], c("entity_id", "grade", "sort_rank", "n_above", "n_below", "n_withheld")),
    "report card table has unexpected leading columns", "invalid_report_card")
  for (k in names(x$settings$weights)) {
    lo <- d[[paste0("lower_", k)]]; up <- d[[paste0("upper_", k)]]
    .pr_assert(!is.null(lo) && !is.null(up) && all(lo <= up), paste("interval columns invalid for", k), "invalid_report_card")
  }
  .pr_assert(x$interval_source %in% c("draws_equal_tail", "exact_finite_law", "gaussian_analytic", "mixture_analytic",
    "supplied_marginal_summaries", "unavailable"),
    "unknown interval_source", "invalid_report_card")
  invisible(TRUE)
}
