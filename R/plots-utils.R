# Shared pure-view helpers for the plotting families.

.pr_status_panel <- function(title, reason, caption = NULL) {
  ggplot2::ggplot() + ggplot2::geom_blank() +
    .pr_labs(title = title, subtitle = paste("Unavailable:", reason), caption = caption) +
    theme_postrank() + ggplot2::theme(axis.line = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank())
}
.pr_weights_text <- function(w) paste(names(w), formatC(unname(w), digits = 2, format = "f"), sep = " ", collapse = ", ")
.pr_sizes_text <- function(grade) paste(tabulate(grade, nbins = max(grade)), collapse = "/")


# Deterministic display selection and ID-preserving label maps.
.pr_plot_select_rows <- function(data, max_rows = 30L, entities = NULL) {
  if (!is.null(max_rows)) .pr_assert(is.numeric(max_rows) && length(max_rows) == 1L &&
    is.finite(max_rows) && max_rows >= 1 && max_rows == floor(max_rows),
    "max_rows must be a finite positive integer or NULL", "invalid_display", "$.max_rows")
  n <- nrow(data)
  if (!is.null(entities)) {
    .pr_assert(is.character(entities) && length(entities) > 0L && !anyNA(entities) &&
      !anyDuplicated(entities) && all(entities %in% data$entity_id),
      "entities must be distinct IDs from the prepared data", "invalid_display", "$.entities")
    return(which(data$entity_id %in% entities))
  }
  if (is.null(max_rows) || max_rows >= n) return(seq_len(n))
  limit <- as.integer(max_rows)
  groups <- split(seq_len(n), factor(data$grade, levels = sort(unique(data$grade))))
  sizes <- lengths(groups); G <- length(groups)
  spread <- function(n, count) if (count == 1L) ceiling(n / 2) else as.integer(round(seq(1, n, length.out = count)))
  if (limit < G) {
    chosen <- spread(G, limit)
    return(unname(sort(vapply(groups[chosen], function(rows) rows[ceiling(length(rows) / 2)], 1L))))
  }
  counts <- rep(1L, G)
  target <- limit * sizes / sum(sizes)
  while (sum(counts) < limit) {
    deficit <- target - counts; deficit[counts >= sizes] <- -Inf
    k <- which.max(deficit); counts[k] <- counts[k] + 1L
  }
  sort(unlist(Map(function(rows, count) rows[spread(length(rows), count)], groups, counts), use.names = FALSE))
}

.pr_plot_entity_labels <- function(ids, entity_labels = NULL, field = "entity_labels", readable = FALSE) {
  labels <- stats::setNames(if (readable) gsub("_", " ", ids, fixed = TRUE) else ids, ids)
  collisions <- duplicated(unname(labels)) | duplicated(unname(labels), fromLast = TRUE)
  labels[collisions] <- ids[collisions]
  if (!is.null(entity_labels)) {
    .pr_assert(is.character(entity_labels) && !is.null(names(entity_labels)) &&
      !anyNA(entity_labels) && !anyNA(names(entity_labels)) && all(nzchar(trimws(entity_labels))) &&
      all(nzchar(names(entity_labels))) && !anyDuplicated(names(entity_labels)) && all(names(entity_labels) %in% ids),
      paste(field, "must be a named character vector for known IDs, with no missing or empty labels"),
      "invalid_display", paste0("$.", field))
    labels[names(entity_labels)] <- entity_labels
  }
  .pr_assert(!anyDuplicated(unname(labels)),
    paste(field, "must give distinct display labels; include IDs when names repeat"), "invalid_display", paste0("$.", field))
  labels
}

