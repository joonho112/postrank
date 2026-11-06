# The entity-level report card (Chapter 10 postrank_report_card). Summaries are
# computed once here from the declared input law; views only read the stored table.

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
#' A validated grading is combined with marginal posterior summaries in an
#' entity-level report card. The table contains every entity, its grade, counts
#' of comparisons reported above or below it or withheld, and each criterion's
#' posterior mean, interval and expected rank. The table is used for detailed
#' reporting and plotting; [postrank_tables] supplies the basic two-column
#' grade table.
#'
#' @param x A `postrank_fit` or `postrank_analysis` with a validated grade.
#' @param draws Optional source input: `postrank_draws`,
#'   `postrank_coefficients`, or `postrank_probabilities` with supplied marginal
#'   intervals. It must have the same input identity as the fit.
#' @param level Central posterior interval level in `(0, 1)`; default `0.90`.
#'   For supplied marginal summaries, it must exactly match their stored level.
#' @param order Secondary sort key within each grade: `"expected_rank"`
#'   (weighted expected rank, default), `"mean"` (one criterion's posterior
#'   mean, larger first) or `"label"` (entity ID).
#' @param order_by Criterion used with `order = "mean"`. Required with several
#'   criteria, optional with one. Leave `NULL` for other ordering rules.
#' @return A `postrank_report_card` with the full table in `data`. Its other
#'   fields record `level`, `interval_source`, `secondary_order`, `settings`,
#'   `grade_identity`, `input_identity`, `schema_version`, `provenance` and
#'   `warnings`. A selected mean-ordering criterion is recorded in
#'   `provenance$ordering_criterion`.
#' @details The table is ordered first by grade, then the secondary key, with
#'   entity ID breaking remaining ties. Grade 1 has highest priority. Shared
#'   grades withhold comparisons and do not establish latent equality.
#'   `n_above` counts other entities this entity is reported above; `n_below`
#'   counts those it is reported below. Together with `n_withheld`, they sum
#'   to n-1 for each row. Columns `mean_`, `lower_`, `upper_` and
#'   `expected_rank_` are suffixed with the criterion ID. Expected rank is
#'   \eqn{1 + \sum_{j \ne i} e_{ij,k}}. Weighted ranks can set the row order;
#'   means in different units are never added for this purpose.
#'
#'   The source comes from `draws`, then the analysis input, then a typed
#'   coefficient or supplied-probability object stored in the fit. A bare
#'   pairwise object contains no marginal posterior law, so supply its
#'   original input through `draws`. Matching cached summaries are reused;
#'   otherwise this function computes summaries from the source. It does not
#'   solve for new grades. Figures and table conversion subsequently read the
#'   prepared card without recomputing these summaries.
#'
#'   Intervals describe the supplied marginal posterior, not Monte Carlo
#'   error or the probability that a grade is correct. A mean can lie outside
#'   an equal-tail interval. Supplied probability matrices require genuine
#'   same-target marginal intervals at their recorded level: a posterior law
#'   or chain history is not inferred from the matrices. Without a validated
#'   grade, the function stops with `no_validated_incumbent`.
#'
#'   The card always contains all entities. Row limits and display labels in
#'   [postrank_plot_report_card()] affect only the figure.
#' @seealso [postrank()], [postrank_posterior_means()], [postrank_tables]
#' @concept reporting
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   card <- postrank_report_card(one, level = .8, order = "mean")
#'   as.data.frame(card)
#'   card$interval_source
#' }
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
