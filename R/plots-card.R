# Report-card views read stored summaries only; they never solve or summarize.

#' @importFrom ggplot2 .data
NULL

#' Plot Posterior Estimates and Grade Membership
#'
#' `postrank_plot_report_card()` plots the stored posterior mean and central
#' interval for each displayed entity, with one panel per criterion and color
#' showing grade membership. Grade 1 is the highest priority, and larger target
#' values mean higher priority as declared when the input was built. Each
#' horizontal bar summarizes marginal uncertainty for one entity's target at a
#' time; entities in the same grade are left unordered (withheld), which does
#' not mean their targets are equal.
#'
#' @param x A `postrank_report_card` or a `postrank_analysis` with a prepared
#'   report card.
#' @param criteria Optional character vector of distinct criterion IDs from the
#'   card, giving the subset and left-to-right (or top-to-bottom) panel order.
#'   `NULL` (the default) shows all criteria in stored weight order.
#' @param order Ordering of entities within each grade: `"grade"` (the default)
#'   keeps the report card's stored `sort_rank` (`1..n` row order);
#'   `"expected_rank"` sorts by weighted expected rank across all criteria in
#'   the card; `"mean"` sorts by descending posterior mean on one criterion;
#'   `"label"` sorts by raw entity ID in locale-independent byte/ASCII
#'   lexicographic (`"radix"`) order.
#' @param max_rows Positive integer cap on automatically displayed entities
#'   (default `30L`), or `NULL` to show every entity. Ignored when `entities` is
#'   supplied.
#' @param show_withheld Logical scalar (`TRUE` by default). When `TRUE` and the
#'   full card has more than one grade, includes full-report grade sizes in the
#'   subtitle.
#' @param ... Unused; passing any argument in `...` stops with an error. Pass
#'   arguments after `...` by name.
#' @param entities Optional character vector of distinct entity IDs from the
#'   card to display. All named entities are shown even when `length(entities)`
#'   exceeds `max_rows`; their vertical order follows `order`, not the order of
#'   `entities`.
#' @param entity_labels Optional named character vector mapping known raw entity
#'   IDs in the card to non-blank display names. Unmapped IDs keep their raw
#'   IDs. Resulting display names must be distinct across the full card (include
#'   an ID when two names would match); `"\n"` may be used to break long labels.
#' @param criterion_labels Optional named character vector mapping known
#'   criterion IDs in the card to non-blank panel strip labels. Unmapped IDs
#'   replace underscores with spaces unless that would create duplicate labels.
#'   Resulting strip labels must be distinct across all criteria in the card.
#' @param ncol Positive integer number of facet columns. `NULL` (the default)
#'   uses `min(3, length(criteria_shown))`; values above the number of displayed
#'   criteria are capped at that count. Use `ncol = 1` for narrow pages.
#' @param order_by Single criterion ID used when `order = "mean"`. Must be
#'   `NULL` for other `order` choices. Required when `order = "mean"` and more
#'   than one criterion is displayed; when `NULL` with a single displayed
#'   criterion, that criterion is used. An explicit `order_by` may name any
#'   criterion in the card, even one omitted from `criteria`.
#' @return A `ggplot` object whose `$data` table holds the same columns as
#'   `postrank_plot_data(x, "report_card")` for the displayed entities and
#'   criteria, ordered by `order` with `entity_id`, `criterion`, and `grade`
#'   stored as factors (over raw IDs and `1..G`) alongside `sort_rank` (`1..n`
#'   row order stored in the card), `n_withheld` (number of other entities in
#'   the same grade), `mean`, `lower`, `upper`, and `expected_rank`. If `x` is a
#'   `postrank_analysis` whose `report_card` slot is `NULL`, returns an empty
#'   status `ggplot` stating why no report card is available.
#' @details
#' The plot reads stored means, interval endpoints, and grades without solving
#' or recomputing posterior summaries. Points mark posterior means and segments
#' mark central intervals (`lower` to `upper`) on `"Posterior target"`; means
#' are never clipped to interval endpoints because a skewed posterior can have
#' its mean outside its central interval. The caption records the stored
#' percentage level (`100 * card$level`, where `card` is `x` or `x$report_card`)
#' and states whether the intervals came from supplied marginal summaries or
#' computed equal-tail posterior intervals (from draws, an exact finite law, or
#' normal/mixture posteriors). These intervals are marginal posterior summaries
#' for individual targets, not simultaneous intervals and not confidence
#' intervals for grade labels or solver bounds.
#'
#' Grades always stay in contiguous vertical blocks (`1` at the top), with light
#' gray background bands on odd-numbered grades. When `order = "expected_rank"`,
#' expected ranks are combined using the card's criterion weights across all
#' criteria, even if `criteria` displays a subset. When `order = "mean"`, means
#' on different criteria are never added together. Display labels affect axis
#' and strip text only.
#'
#' When `entities` is `NULL` and the card has more than `max_rows` entities,
#' deterministic display selection gives at least one row to each grade when
#' `max_rows >= G`, allocates remaining rows in proportion to grade size, and
#' spaces rows across each grade; if `max_rows < G`, some grades are omitted
#' and the subtitle notes this. That subset is for visual layout only, not a
#' statistical sample or a re-grading. Colors use [scale_colour_grade()] with
#' the full report's grade count `G` up to 64 grades (and neutral dark gray
#' without a legend when `G > 64`), so subsets keep their original grade colors.
#' @seealso [postrank_report_card()], [postrank_plot_data()],
#'   [postrank_plot_relations()], [postrank_plot_pairwise()]
#' @concept visualization
#' @examples
#' one <- postrank_example("tutorial_one")
#' postrank_plot_report_card(
#'   one,
#'   max_rows = NULL,
#'   criterion_labels = c(score_A = "Score A (standardized units)")
#' )
#'
#' two <- postrank_example("tutorial_two")
#' postrank_plot_report_card(
#'   two,
#'   ncol = 1,
#'   entities = c("A", "C", "F"),
#'   entity_labels = c(A = "Site A", C = "Site C", F = "Site F"),
#'   criterion_labels = c(score_A = "Score A", score_B = "Score B")
#' )
#' @export
postrank_plot_report_card <- function(x, criteria = NULL, order = c("grade", "expected_rank", "mean", "label"),
                                      max_rows = 30L, show_withheld = TRUE, ...,
                                      entities = NULL, entity_labels = NULL, criterion_labels = NULL,
                                      ncol = NULL, order_by = NULL) {
  order <- match.arg(order)
  .pr_assert(!length(list(...)), "unused plot arguments; use entity_labels or criterion_labels for display names",
    "invalid_display", "$....")
  .pr_assert(inherits(x, c("postrank_report_card", "postrank_analysis")),
    "x must be a postrank_report_card or postrank_analysis", "wrong_class", "$.x")
  title <- "Grade report card"
  if (inherits(x, "postrank_analysis")) {
    if (is.null(x$report_card)) return(.pr_status_panel(title,
      if (!isTRUE(x$fit$incumbent_validated)) "no validated incumbent" else gsub("_", " ", x$extras$report_card$reason)))
    card <- x$report_card
  } else card <- x
  .pr_assert(is.logical(show_withheld) && length(show_withheld) == 1L && !is.na(show_withheld),
    "show_withheld must be TRUE or FALSE", "invalid_display", "$.show_withheld")
  all_criteria <- names(card$settings$weights); ks <- all_criteria
  if (!is.null(criteria)) {
    .pr_assert(is.character(criteria) && length(criteria) > 0L && !anyNA(criteria) &&
      all(criteria %in% all_criteria) && !anyDuplicated(criteria),
      "criteria must name a nonempty set of criteria in the card", "invalid_display", "$.criteria")
    ks <- criteria
  }
  if (is.null(ncol)) ncol <- min(3L, length(ks))
  .pr_assert(is.numeric(ncol) && length(ncol) == 1L && is.finite(ncol) && ncol >= 1 && ncol == floor(ncol),
    "ncol must be a finite positive integer", "invalid_display", "$.ncol")
  ncol <- min(ncol, length(ks))
  mean_by <- .pr_report_card_mean_criterion(if (is.null(order_by)) ks else all_criteria, order, order_by)
  row_labels <- .pr_plot_entity_labels(card$data$entity_id, entity_labels)
  panel_labels <- .pr_plot_entity_labels(all_criteria, criterion_labels, "criterion_labels", readable = TRUE)
  d <- card$data; n <- nrow(d); G <- max(d$grade); w <- card$settings$weights
  key <- switch(order, grade = d$sort_rank,
    expected_rank = as.numeric(as.matrix(d[paste0("expected_rank_", names(w))]) %*% w),
    mean = -d[[paste0("mean_", mean_by)]], label = match(d$entity_id, sort(d$entity_id, method = "radix")))
  d <- d[order(d$grade, key, d$entity_id, method = "radix"), , drop = FALSE]
  chosen <- .pr_plot_select_rows(d, max_rows, entities)
  d <- d[chosen, , drop = FALSE]; shown <- nrow(d)
  long <- .pr_card_long(structure(list(data = d, settings = card$settings), class = "postrank_report_card"))
  long <- long[long$criterion %in% ks, , drop = FALSE]
  long$criterion <- factor(long$criterion, levels = ks)
  long$entity_id <- factor(long$entity_id, levels = rev(d$entity_id))
  long$grade <- factor(long$grade, levels = as.character(seq_len(G)))
  pos <- stats::setNames(rev(seq_len(shown)), d$entity_id)
  bands <- do.call(rbind, lapply(unique(d$grade), function(g) {
    p <- pos[d$entity_id[d$grade == g]]
    data.frame(grade = g, ymin = min(p) - .5, ymax = max(p) + .5, odd = (g %% 2L) == 1L)
  }))
  bands <- bands[bands$odd, , drop = FALSE]
  sub <- if (G == 1L) sprintf("%d entities; all comparisons withheld", n) else sprintf("%d entities in %d grades", n, G)
  if (shown < n) sub <- paste0(sub, sprintf("; showing %d", shown))
  selection <- if (!is.null(entities)) "Selected entities." else if (shown < n) "Rows spread across grades." else NULL
  ordering <- switch(order, grade = NULL, expected_rank = "weighted expected rank",
    mean = paste0(gsub("\n", " ", panel_labels[[mean_by]], fixed = TRUE), " mean"), label = "entity ID")
  detail <- paste(c(selection, if (!is.null(ordering)) paste0("Within grades: ", ordering, "."),
    if (isTRUE(show_withheld) && G > 1L) paste0("Full grade sizes: ", .pr_sizes_text(card$data$grade), "."),
    if (length(unique(d$grade)) < G) "Some grades are not shown."), collapse = " ")
  lvl <- format(100 * card$level)
  caption <- paste0(lvl, "% ", if (identical(card$interval_source, "supplied_marginal_summaries")) "supplied central" else "equal-tail posterior",
    " intervals; points are means.\nSame grade means withholding, not equality.")
  ggplot2::ggplot(long, ggplot2::aes(y = .data$entity_id)) +
    ggplot2::geom_rect(data = bands, ggplot2::aes(xmin = -Inf, xmax = Inf, ymin = .data$ymin, ymax = .data$ymax),
      inherit.aes = FALSE, fill = "grey95", colour = NA) +
    ggplot2::geom_segment(ggplot2::aes(x = .data$lower, xend = .data$upper, yend = .data$entity_id, colour = .data$grade), linewidth = .5) +
    ggplot2::geom_point(ggplot2::aes(x = .data$mean, colour = .data$grade), size = 1.6) +
    ggplot2::facet_wrap(~ criterion, scales = "free_x", ncol = ncol,
      labeller = ggplot2::as_labeller(panel_labels)) +
    ggplot2::scale_y_discrete(labels = row_labels) +
    ggplot2::scale_x_continuous(breaks = scales::breaks_pretty(n = 4)) +
    (if (G <= 64L) scale_colour_grade(G) else ggplot2::scale_colour_manual(
      values = stats::setNames(rep("grey25", G), as.character(seq_len(G))), guide = "none")) +
    ggplot2::labs(title = title, subtitle = paste(c(sub, strwrap(detail, width = if(ncol == 1L) 49L else 78L)),collapse="\n"),
      x = "Posterior target", y = NULL, caption = caption) +
    theme_postrank() + ggplot2::theme(panel.spacing.x = ggplot2::unit(1.2,"lines"),
      panel.spacing.y = ggplot2::unit(1.4,"lines"), panel.grid.major.y = ggplot2::element_line(colour="grey94",linewidth=.2))
}
