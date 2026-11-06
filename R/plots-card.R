# Report-card views read stored summaries only; they never solve or summarize.

#' @importFrom ggplot2 .data
NULL

#' Plot Posterior Estimates and Grade Membership
#'
#' The figure displays the stored posterior mean and central interval for each
#' selected entity, with one panel per criterion and color indicating grade
#' membership. Grade 1 has highest priority. The intervals describe uncertainty
#' in the targets, whereas a shared grade denotes a withheld comparison without
#' asserting target equality.
#'
#' @param x A `postrank_report_card` or a `postrank_analysis` with a prepared card.
#' @param criteria Optional nonempty subset and display order of criterion IDs.
#' @param order Within-grade order: `"grade"` preserves the stored card order;
#'   `"expected_rank"` uses weighted expected rank across all criteria;
#'   `"mean"` uses one criterion's mean; `"label"` sorts raw entity IDs.
#' @param max_rows Positive integer display limit, default 30. `NULL` shows
#'   every row. Explicit `entities` override this limit.
#' @param show_withheld Logical; include full grade sizes in the subtitle.
#' @param ... Unused; nonempty arguments are rejected.
#' @param entities Optional distinct entity IDs to show. All selected entities
#'   are shown, even if their number exceeds `max_rows`. Their display order
#'   follows `order`, not the order of this vector.
#' @param entity_labels Optional named character vector mapping IDs to display
#'   names. Partial maps retain the other IDs. Final display names must be
#'   distinct; include an ID when names repeat. Newlines can break long labels.
#' @param criterion_labels Optional named criterion-to-label vector. Partial
#'   maps use readable criterion names for the remainder. Final labels must be
#'   distinct. Labels may include units or newlines without changing values.
#' @param ncol Positive integer number of facet columns; default at most three.
#'   Use `ncol = 1` with a taller figure for a narrow page.
#' @param order_by Criterion used with `order = "mean"`. Required when several
#'   criteria are displayed; otherwise the sole displayed criterion is used.
#'   An explicit criterion may be any criterion of the card.
#' @return A `ggplot` object whose data retain raw entity and criterion IDs.
#'   If an analysis has no prepared card, a status panel explains the recorded
#'   reason; a card and grades must already be available.
#' @details
#' The figure uses stored means, interval endpoints and grades without
#' recomputing summaries or solving. Means are never clipped to intervals:
#' a skewed distribution can have its mean outside its central interval.
#' The caption gives the stored interval level and distinguishes supplied
#' central summaries from computed equal-tail posterior intervals.
#' These are not confidence intervals for the grades or solver bounds.
#'
#' All ordering keeps grades contiguous. `order = "expected_rank"` uses the
#' card's weights across all criteria, even when only some panels are shown.
#' `order = "mean"` uses the larger mean first within each grade; means in
#' different units are never added for ordering. Labels affect display only.
#'
#' Automatic row selection spreads up to `max_rows` rows across grades.
#' Where possible, each grade receives a row; remaining rows are allocated
#' by grade size and spaced within each grade. If fewer rows than grades are
#' requested, some grades are omitted. This is a display selection, not a
#' representative sample or a new analysis. Grade colors and subtitle counts
#' refer to the full report. For about 30 rows, consider a 7 by 8 inch output;
#' smaller selections and `ncol = 1` suit narrow pages.
#' @seealso [postrank_report_card()], [postrank_plot_data()],
#'   [postrank_plot_relations()], [postrank_plot_pairwise()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' one <- load_or_compute("tutorial_one")
#' p <- postrank_plot_report_card(one, max_rows = NULL,
#'   criterion_labels = c(score_A = "Score A (standardized units)"))
#' p
#'
#' # The same six sites on two criteria, with one panel per row.
#' two <- load_or_compute("tutorial_two")
#' postrank_plot_report_card(two, ncol = 1, entities = c("A", "C", "F"),
#'   entity_labels = c(A = "Site A", C = "Site C", F = "Site F"),
#'   criterion_labels = c(score_A = "Score A", score_B = "Score B"))
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
