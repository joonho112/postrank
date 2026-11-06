# Pure view of prepared directional-error probabilities, not grade relations.

#' Plot Posterior Directional-Error Probabilities
#'
#' For each possible reporting direction, the figure displays `Pr(row target <=
#' column target)`, the expected error from placing the row entity above the
#' column entity. A separate square matrix is shown for each criterion.
#' Self-comparisons are excluded, with `NA` diagonal entries displayed in gray.
#'
#' @param x A `postrank_analysis`, `postrank_fit`, prepared
#'   `postrank_pairwise`, `postrank_probabilities` or `postrank_coefficients`.
#'   Raw posterior draws and tie-aware equality-neutral inputs are unsupported.
#' @param criteria Optional nonempty subset and display order of criterion IDs.
#' @param entities Optional distinct entity IDs; at least two are required.
#'   Their display order follows the stored input or result, not this vector.
#' @param max_entities Automatic display limit, an integer at least two;
#'   default 20. `NULL` shows all entities. Explicit `entities` override the limit.
#' @param entity_labels,criterion_labels Optional partial named maps from
#'   original IDs to display labels. Final labels must be distinct. The data
#'   retain their original IDs.
#' @param ncol Positive integer number of facet columns; default at most two.
#' @return A `ggplot` object with original entity and criterion IDs and
#'   `error_probability` in its plotted table. No stored input is changed.
#' @details
#' A cell is not a selected grade, a probability of withholding or a claim of
#' equality. Larger target values mean higher priority, so a small cell value
#' supports placing its row entity above its column entity. In this ordinary
#' zero-equality domain, opposite off-diagonal directions sum to one.
#'
#' The figure reads prepared probabilities; it does not aggregate raw draws,
#' fit a model, evaluate an action or solve. A fit without a validated
#' incumbent can still show its prepared input. Analyses with a card use its
#' stored entity order; other validated actions use grade then ID; bare inputs
#' and fits without an action retain input order. No posterior scores are
#' computed for ordering.
#'
#' Automatic selection spreads entities across stored grades, or across input
#' order when no action is available. It is a display selection, not a
#' representative sample. Use a larger figure for a large explicit selection.
#' [postrank_plot_data()] with `which = "pairwise"` returns the complete
#' unfiltered table, including every diagonal sentinel.
#' @seealso [postrank_plot_data()], [postrank_plot_relations()],
#'   [postrank_probabilities()]
#' @concept visualization
#' @examples
#' # Prepared K = 1 and K = 2 Gaussian probabilities for six fictional sites.
#' # No analysis or solver is needed to inspect these inputs.
#' postrank_plot_pairwise(pr_tutorial$one,
#'   criterion_labels = c(score_A = "Score A"))
#' postrank_plot_pairwise(pr_tutorial$two, entities = c("A", "C", "F"), ncol = 1,
#'   criterion_labels = c(score_A = "Score A", score_B = "Score B"))
#' @export
postrank_plot_pairwise <- function(x, criteria = NULL, entities = NULL,
    max_entities = 20L, entity_labels = NULL, criterion_labels = NULL, ncol = NULL) {
  pw <- .pr_pairwise_plot_source(x)
  ids <- pw$entity_ids; ks <- pw$criterion_ids
  if (!is.null(criteria)) {
    .pr_assert(is.character(criteria) && length(criteria) > 0L && !anyNA(criteria) &&
      !anyDuplicated(criteria) && all(criteria %in% ks),
      "criteria must name distinct criteria in the prepared input", "invalid_display", "$.criteria")
    ks <- criteria
  }
  if (!is.null(max_entities)) .pr_assert(is.numeric(max_entities) && length(max_entities) == 1L &&
    is.finite(max_entities) && max_entities >= 2 && max_entities == floor(max_entities),
    "max_entities must be an integer of at least two or NULL", "invalid_display", "$.max_entities")
  if (is.null(ncol)) ncol <- min(2L, length(ks))
  .pr_assert(is.numeric(ncol) && length(ncol) == 1L && is.finite(ncol) &&
    ncol >= 1 && ncol == floor(ncol), "ncol must be a positive integer", "invalid_display", "$.ncol")
  rows <- data.frame(entity_id = ids, grade = 1L, stringsAsFactors = FALSE)
  fit <- if (inherits(x, "postrank_analysis")) x$fit else if (inherits(x, "postrank_fit")) x else NULL
  ordered_by <- "Input entity order"
  if (!is.null(fit) && isTRUE(fit$incumbent_validated)) {
    rows$grade <- unname(fit$grade[ids])
    if (inherits(x, "postrank_analysis") && !is.null(x$report_card)) {
      rows <- rows[match(x$report_card$data$entity_id, rows$entity_id), , drop = FALSE]
      ordered_by <- "Stored report-card order"
    } else {
      rows <- rows[order(rows$grade, rows$entity_id, method = "radix"), , drop = FALSE]
      ordered_by <- "Stored grade, then entity ID"
    }
  }
  selected <- .pr_plot_select_rows(rows, max_rows = max_entities, entities = entities)
  shown <- rows$entity_id[selected]
  .pr_assert(length(shown) >= 2L, "select at least two entities for pairwise comparisons",
    "invalid_display", "$.entities")
  entity_map <- .pr_plot_entity_labels(ids, entity_labels)
  criterion_map <- .pr_plot_entity_labels(pw$criterion_ids, criterion_labels,
    field = "criterion_labels", readable = TRUE)
  d <- .pr_pairwise_plot_long(pw)
  d <- d[d$entity_i %in% shown & d$entity_j %in% shown & d$criterion %in% ks, , drop = FALSE]
  d$entity_i <- factor(d$entity_i, levels = rev(shown))
  d$entity_j <- factor(d$entity_j, levels = shown)
  d$criterion <- factor(d$criterion, levels = ks)
  sub <- sprintf("%d of %d entities; %d %s", length(shown), length(ids), length(ks),
    if (length(ks) == 1L) "criterion" else "criteria")
  ggplot2::ggplot(d, ggplot2::aes(x = .data$entity_j, y = .data$entity_i,
    fill = .data$error_probability)) +
    ggplot2::geom_tile() +
    ggplot2::facet_wrap(~ criterion, ncol = as.integer(ncol),
      labeller = ggplot2::as_labeller(criterion_map)) +
    ggplot2::scale_x_discrete(labels = entity_map, position = "top", expand = c(0, 0)) +
    ggplot2::scale_y_discrete(labels = entity_map, expand = c(0, 0)) +
    ggplot2::scale_fill_gradientn(colours = postrank_palette(which = "sequential"),
      limits = c(0, 1), breaks = c(0, .25, .5, .75, 1),
      labels = scales::label_percent(accuracy = 1), na.value = "grey85", name = "Error probability") +
    ggplot2::guides(fill = ggplot2::guide_colourbar(barwidth = ggplot2::unit(9, "lines"),
      barheight = ggplot2::unit(.6, "lines"))) +
    ggplot2::coord_equal() +
    .pr_labs(title = "Directional-error probabilities", subtitle = sub,
      x = "Column entity", y = "Row entity",
      caption = paste0("Error if row is above column: Pr(row target <= column target). Grey diagonal = not compared. ",
        ordered_by, "; no grade is computed.")) +
    theme_postrank() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 0, vjust = .5, size = 8),
      axis.text.y = ggplot2::element_text(size = 8))
}
