# Pure view of prepared directional-error probabilities, not grade relations.

#' Plot Posterior Directional-Error Probabilities
#'
#' `postrank_plot_pairwise()` draws a square matrix of posterior
#' directional-error probabilities `Pr(row target <= column target)` for each
#' criterion. Each off-diagonal cell gives the posterior expected wrong-direction
#' error from placing the row entity in a higher-priority grade than the column
#' entity; diagonal self-comparisons are `NA` and drawn in gray.
#'
#' @param x A `postrank_analysis`, `postrank_fit`, `postrank_pairwise`
#'   (including objects from [postrank_probabilities()]), or
#'   `postrank_coefficients`. Raw `postrank_draws` (convert with
#'   [postrank_pairwise()] first) and tie-mode inputs (`postrank_tie_*`) are not
#'   accepted.
#' @param criteria Optional character vector of distinct criterion IDs from `x`,
#'   giving the subset and panel order. `NULL` (the default) shows all criteria
#'   in stored order.
#' @param entities Optional character vector of at least two distinct entity IDs
#'   from `x` to display. Axis order follows the stored result or input order,
#'   not `entities`.
#' @param max_entities Integer cap of at least `2` on automatically displayed
#'   entities (`20L` by default), or `NULL` to show all entities. Ignored when
#'   `entities` is supplied.
#' @param entity_labels,criterion_labels Optional named character vectors
#'   mapping raw IDs to display labels. Unmapped criterion IDs replace
#'   underscores with spaces unless that creates duplicate labels. Final labels
#'   must be distinct; `$data` keeps raw IDs.
#' @param ncol Positive integer number of facet columns; `NULL` (the default)
#'   uses `min(2, length(criteria_shown))`.
#' @return A `ggplot` object whose `$data` table contains `entity_i`,
#'   `entity_j`, `criterion`, and `error_probability` for the displayed entities
#'   and criteria.
#' @details
#' Larger target values mean higher priority, so a small value in row `i`,
#' column `j` supports placing entity `i` above entity `j`. Because ordinary
#' `postrank` inputs have zero posterior probability of exact ties, opposite
#' off-diagonal cells `(i, j)` and `(j, i)` sum to `1`. Cells show posterior
#' comparison probabilities rather than chosen grades; see
#' [postrank_plot_relations()] for the pairs ordered or withheld by a grading.
#'
#' The plot reads prepared probabilities without aggregating draws, solving, or
#' evaluating a grading, so a `postrank_fit` without a checked grading can still
#' display its input probabilities. Entity order uses the report card's stored
#' order when `x` is an analysis with a prepared card, grade-then-ID order for
#' other checked fits or analyses, and input entity order otherwise.
#'
#' When `entities` is `NULL` and `x` has more than `max_entities` entities,
#' deterministic display selection spreads rows across stored grades (when
#' available) or across input order for visual layout only. Use
#' `postrank_plot_data(x, "pairwise")` for the complete `n * n * K` table.
#' @seealso [postrank_plot_data()], [postrank_plot_relations()],
#'   [postrank_pairwise()], [postrank_probabilities()]
#' @concept visualization
#' @examples
#' postrank_plot_pairwise(
#'   pr_tutorial$one,
#'   criterion_labels = c(score_A = "Score A")
#' )
#' postrank_plot_pairwise(
#'   pr_tutorial$two,
#'   entities = c("A", "C", "F"),
#'   ncol = 1,
#'   criterion_labels = c(score_A = "Score A", score_B = "Score B")
#' )
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
