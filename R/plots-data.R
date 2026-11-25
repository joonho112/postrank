# Tidy plot data behind the seven shipped figure verbs. Reads
# stored slots and reshapes them; never computes posterior summaries, risks or diagnostics.

.pr_reserved_figures <- c(sensitivity = "fig-settings-lattice",
  fragility = "fig-fragile-pairs", crossfit = "fig-crossfit", trace = "fig-mc-trace", dispersion = "fig-dispersion")

.pr_unshipped <- function(which) .pr_abort(sprintf("'%s' (%s) is a reserved figure design that is not currently shipped in postrank",
  which, .pr_reserved_figures[[which]]), "unshipped_figure", "$.which")

.pr_card_long <- function(card) {
  d <- card$data; ks <- names(card$settings$weights)
  do.call(rbind, lapply(ks, function(k) data.frame(entity_id = d$entity_id, grade = d$grade, sort_rank = d$sort_rank,
    n_withheld = d$n_withheld, criterion = k, mean = d[[paste0("mean_", k)]], lower = d[[paste0("lower_", k)]],
    upper = d[[paste0("upper_", k)]], expected_rank = d[[paste0("expected_rank_", k)]], stringsAsFactors = FALSE)))
}

.pr_relations_long <- function(grade) {
  ids <- names(grade); o <- order(grade, ids, method = "radix"); ids <- ids[o]; g <- grade[ids]
  r <- .pr_relations(g); n <- length(ids)
  idx <- which(upper.tri(r), arr.ind = TRUE)
  code <- r[idx]
  data.frame(entity_i = ids[idx[, 1]], entity_j = ids[idx[, 2]], i_pos = idx[, 1], j_pos = idx[, 2], code = as.integer(code),
    relation = factor(ifelse(code == 1L, "above", ifelse(code == 0L, "withheld", "below")), levels = c("above", "withheld", "below")),
    stringsAsFactors = FALSE)
}

.pr_change_long <- function(g0, g1) {
  base <- .pr_relations_long(g0)
  r1 <- .pr_relations(g1[names(g0)])
  b <- r1[cbind(base$entity_i, base$entity_j)]
  a <- base$code
  base$change <- factor(ifelse(a == b, "unchanged", ifelse(a == 0L, "newly disclosed", ifelse(b == 0L, "newly withheld", "reversed"))),
    levels = c("unchanged", "newly disclosed", "newly withheld", "reversed"))
  base
}

.pr_pairwise_plot_source <- function(x) {
  if (inherits(x, "postrank_analysis")) x <- x$pairwise
  else if (inherits(x, "postrank_fit")) x <- x$problem$pairwise
  .pr_assert(inherits(x, c("postrank_pairwise", "postrank_coefficients")),
    "use an analysis, fit, or prepared tie-free pairwise/coefficient input; raw draws and tie-aware inputs are not supported by this view",
    "unsupported_plot_input", "$.x")
  .pr_validate_pairwise(x)
  x
}

.pr_pairwise_plot_long <- function(x) {
  pw <- .pr_pairwise_plot_source(x)
  out <- expand.grid(entity_i = pw$entity_ids, entity_j = pw$entity_ids,
    criterion = pw$criterion_ids, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  out$error_probability <- as.numeric(pw$e)
  out
}

#' Extract Stored Data for a Figure
#'
#' `postrank_plot_data()` returns the complete data frame (or named list of data
#' frames) underlying the seven `postrank` plot types without solving,
#' evaluating gradings, or recomputing posterior summaries. Plot display caps
#' (`max_rows`, `max_entities`) and label maps do not filter or rename the
#' returned tables.
#'
#' @param x A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
#'   `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`,
#'   `postrank_comparison`, `postrank_pairwise` (including
#'   [postrank_probabilities()]), or `postrank_coefficients`.
#' @param which Optional single string naming the component to extract. For a
#'   `postrank_analysis`, `NULL` returns a named list of `"report_card"`,
#'   `"relations"`, and `"profile"`, or pass one of `"report_card"`,
#'   `"relations"`, `"profile"`, or `"pairwise"`. See Details for other classes.
#' @return A data frame, a named list of three components (with an
#'   `"availability"` attribute) when `x` is a `postrank_analysis` and
#'   `which = NULL`, or `NULL` when a requested `"report_card"` or `"relations"`
#'   table has no underlying report card or checked grading. When `profile` is
#'   requested without a checked grading, returns the zero-row data frame from
#'   [get_profile()].
#' @details
#' Accepted `which` values by input class:
#' \itemize{
#'   \item `postrank_analysis`: `NULL` returns `list(report_card = ...,
#'     relations = ..., profile = ...)` whose `"availability"` attribute gives
#'     `list(available, reason)` for each slot; `"pairwise"` must be requested
#'     by name because its table has `n * n * K` rows.
#'   \item `postrank_fit`: defaults to `"relations"` and also accepts
#'     `"profile"` or `"pairwise"`.
#'   \item `postrank_report_card`: returns the long report-card table.
#'   \item `postrank_baseline`: returns the pair-relations table.
#'   \item `postrank_frontier` and `postrank_commonality_cost`: return
#'     `x$table`.
#'   \item `postrank_comparison`: returns `x$table` by default, or
#'     `x$relations` when `which = "relations"`.
#'   \item `postrank_pairwise` and `postrank_coefficients`: accept `NULL` or
#'     `"pairwise"` and return the pairwise probability table (aggregate raw
#'     `postrank_draws` with [postrank_pairwise()] first).
#' }
#'
#' Returned columns for reshaped views:
#' \itemize{
#'   \item `report_card`: `entity_id`, `grade`, `sort_rank`, `n_withheld`,
#'     `criterion`, `mean`, `lower`, `upper`, and `expected_rank`, stacked by
#'     criterion in stored card order (interval `level` and `interval_source`
#'     stay on the `postrank_report_card` object).
#'   \item `relations`: one row per unordered pair (`i_pos < j_pos`) in
#'     grade-then-ID order with `entity_i`, `entity_j`, `i_pos`, `j_pos`,
#'     integer `code` (`1L` = `"above"`, `0L` = `"withheld"`, `-1L` = `"below"`),
#'     and factor `relation`.
#'   \item `profile`: same columns as [get_profile()].
#'   \item `pairwise`: `entity_i`, `entity_j`, `criterion`, and
#'     `error_probability` (`n * n * K` rows in input order with `entity_i`
#'     varying fastest, including `NA` diagonal entries; available even when a
#'     fit has no checked grading).
#' }
#'
#' Passing `which` equal to `"sensitivity"`, `"fragility"`, `"crossfit"`,
#' `"trace"`, or `"dispersion"` stops with condition code `"unshipped_figure"`;
#' those figure names are not implemented as plot views, although the numerical
#' functions [postrank_sensitivity()], [postrank_mc_fragility()], and
#' [postrank_crossfit()] are available.
#' @seealso [postrank_plot_report_card()], [postrank_plot_relations()],
#'   [postrank_plot_pairwise()], [get_profile()]
#' @concept visualization
#' @examples
#' one <- postrank_example("tutorial_one")
#' card_data <- postrank_plot_data(one, "report_card")
#' head(card_data)
#' attr(postrank_plot_data(one), "availability")
#'
#' pair_data <- postrank_plot_data(pr_tutorial$two, "pairwise")
#' nrow(pair_data)
#' head(pair_data)
#' @export
postrank_plot_data <- function(x, which = NULL) {
  if (!is.null(which)) {
    .pr_assert(is.character(which) && length(which) == 1L, "which must be one string", "invalid_display", "$.which")
    if (which %in% names(.pr_reserved_figures)) .pr_unshipped(which)
  }
  if (identical(which, "pairwise")) return(.pr_pairwise_plot_long(x))
  if (inherits(x, c("postrank_pairwise", "postrank_coefficients"))) {
    .pr_assert(is.null(which), "prepared pairwise input supports which = 'pairwise' only", "invalid_display", "$.which")
    return(.pr_pairwise_plot_long(x))
  }
  if (inherits(x, "postrank_analysis")) {
    avail <- list(report_card = !is.null(x$report_card), relations = isTRUE(x$fit$incumbent_validated), profile = isTRUE(x$fit$incumbent_validated))
    get1 <- function(w) switch(w, report_card = if (avail$report_card) .pr_card_long(x$report_card) else NULL,
      relations = if (avail$relations) .pr_relations_long(x$fit$grade) else NULL, profile = get_profile(x),
      .pr_abort(paste("unknown plot data component:", w), "invalid_display", "$.which"))
    if (is.null(which)) {
      out <- lapply(c(report_card = "report_card", relations = "relations", profile = "profile"), get1)
      attr(out, "availability") <- lapply(names(avail), function(n) list(available = avail[[n]],
        reason = if (avail[[n]]) NULL else if (!isTRUE(x$fit$incumbent_validated)) "no_validated_incumbent" else x$extras$report_card$reason))
      names(attr(out, "availability")) <- names(avail)
      return(out)
    }
    return(get1(which))
  }
  if (inherits(x, "postrank_report_card")) return(.pr_card_long(x))
  if (inherits(x, "postrank_fit")) {
    w <- if (is.null(which)) "relations" else which
    if (w == "relations") return(if (isTRUE(x$incumbent_validated)) .pr_relations_long(x$grade) else NULL)
    if (w == "profile") return(get_profile(x))
    .pr_abort(paste("unknown plot data component for a fit:", w), "invalid_display", "$.which")
  }
  if (inherits(x, "postrank_baseline")) return(.pr_relations_long(x$grade))
  if (inherits(x, "postrank_frontier")) return(x$table)
  if (inherits(x, "postrank_commonality_cost")) return(x$table)
  if (inherits(x, "postrank_comparison")) return(if (identical(which, "relations")) x$relations else x$table)
  .pr_abort(sprintf("no shipped figure for class %s", class(x)[1L]), "wrong_class", "$.x")
}
