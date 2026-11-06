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
#' The complete data underlying the seven postrank figure types are returned
#' for inspection or alternative displays. Stored results are read and reshaped
#' without optimization, action evaluation or calculation of posterior
#' summaries. Plot row limits and display labels do not affect the returned
#' tables.
#'
#' @param x A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
#'   `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`,
#'   `postrank_comparison`, or prepared pairwise/coefficient input.
#' @param which Optional component name. Analysis components are
#'   `"report_card"`, `"relations"` and `"profile"`; `"pairwise"` explicitly
#'   requests prepared probabilities. See Details for other classes.
#' @return A data frame, a named list for an analysis with `which = NULL`,
#'   or `NULL` for an unavailable card or relation component. A profile without
#'   a validated incumbent is an empty typed data frame. The analysis list has
#'   an `availability` attribute with an available flag and reason per component.
#' @details
#' For an analysis, `which = NULL` returns `report_card`, `relations` and
#' `profile`. Pairwise probabilities are deliberately separate because the
#' complete table has `n * n * K` rows. A fit defaults to `"relations"` and
#' also accepts `"profile"` or `"pairwise"`. A report card returns its long
#' table; a baseline returns its relations. Frontier and commonality objects
#' return their stored tables. A comparison returns its summary table by
#' default and its change-count table for `which = "relations"`.
#'
#' The report-card table has `entity_id`, `grade`, `sort_rank`, `n_withheld`,
#' `criterion`, `mean`, `lower`, `upper` and `expected_rank`. Rows are grouped
#' by criterion and follow stored card order within each criterion; interval
#' level and source remain on the card object. Relations contain one row per
#' unordered pair with `entity_i`, `entity_j`, `i_pos`, `j_pos`, `code` and
#' `relation`, in grade-then-ID order. Code 1 means the first entity is above
#' the second, 0 means withheld and -1 means below. Profile columns are
#' listed in [get_profile()].
#'
#' `which = "pairwise"` returns `entity_i`, `entity_j`, `criterion` and
#' `error_probability`, including the `NA` diagonal. It preserves input ID
#' order, with `entity_i` varying fastest. This component remains available
#' for fits without a validated grade. Prepared pairwise/probability/coefficient
#' objects return it by default, but raw draws must first be aggregated with
#' [postrank_pairwise()]. The table is not a relation-change map; use
#' [postrank_plot_relations()] with two actions for that view.
#'
#' The designs `"sensitivity"`, `"fragility"`, `"crossfit"`, `"trace"` and
#' `"dispersion"` are reserved and raise `unshipped_figure`. This does not
#' imply that all similarly named numerical diagnostic functions are unavailable.
#' @seealso [postrank_plot_report_card()], [postrank_plot_relations()],
#'   [postrank_plot_pairwise()], [get_profile()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' one <- load_or_compute("tutorial_one")
#' card_data <- postrank_plot_data(one, "report_card")
#' head(card_data)
#'
#' # Complete two-criterion probability table, including its gray diagonal cells.
#' pair_data <- postrank_plot_data(pr_tutorial$two, "pairwise")
#' nrow(pair_data)
#' head(pair_data)
#' attr(postrank_plot_data(one), "availability")
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
