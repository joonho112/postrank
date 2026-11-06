# Occupancy views of stored domain grades. Cell coordinates are the original
# per-domain grade integers; neither cell membership nor labels imply a total
# ordering of multidomain report cells.

.md_plot_cell_table <- function(data) {
  domains <- data$domain_ids
  if (!length(domains) %in% c(1L, 2L))
    .md_error("The cells view requires one or two domains; select domains explicitly.",
      "mdomain_plot_invalid", "domains")
  grid <- expand.grid(grade_x = seq_len(data$K[[domains[1L]]]),
    grade_y = if (length(domains) == 2L) seq_len(data$K[[domains[2L]]]) else NA_integer_,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid$domain_x <- domains[1L]
  grid$domain_y <- if (length(domains) == 2L) domains[2L] else NA_character_
  grid$unit_ids <- I(lapply(seq_len(nrow(grid)), function(i) {
    keep <- data$grades[, domains[1L]] == grid$grade_x[i]
    if (length(domains) == 2L)
      keep <- keep & data$grades[, domains[2L]] == grid$grade_y[i]
    data$unit_ids[keep]
  }))
  grid$count <- as.integer(lengths(grid$unit_ids))
  unit_labels <- data$unit_labels
  if (is.null(unit_labels)) unit_labels <- stats::setNames(data$unit_ids, data$unit_ids)
  grid$unit_labels <- I(lapply(grid$unit_ids, function(ids) unname(unit_labels[ids])))
  grid$cell_label <- if (length(domains) == 2L)
    paste0("(", grid$grade_x, ", ", grid$grade_y, ")") else as.character(grid$grade_x)
  attr(grid, "grades") <- data$grades
  attr(grid, "full_grades") <- data$full_grades
  attr(grid, "grade_rows") <- data$long
  attr(grid, "domain_ids") <- domains
  attr(grid, "K") <- data$K
  grid
}

.md_plot_cells <- function(data, title = NULL, base_size = 11) {
  d <- .md_plot_cell_table(data)
  domains <- data$domain_ids
  domain_labels <- data$domain_labels
  if (is.null(domain_labels)) domain_labels <- stats::setNames(domains, domains)
  axis_label <- function(domain) paste0(.pr_wrap_label(unname(domain_labels[domain]), 28L),
    "\nGrade")
  caption <- .md_plot_caption(data)
  if (is.null(title)) title <- "Grade cell counts"
  subtitle <- sprintf("%d displayed %s; original grades",
    length(data$unit_ids), if (length(data$unit_ids) == 1L) "unit" else "units")
  if (length(domains) == 1L) {
    if (data$K[[domains[1L]]] == 1L)
      subtitle <- paste(subtitle, "All comparisons withheld in this domain.", sep = ". ")
    return(ggplot2::ggplot(d, ggplot2::aes(x = .data$grade_x, y = .data$count)) +
      ggplot2::geom_col(width = .75, fill = "#2171B5") +
      ggplot2::geom_text(ggplot2::aes(label = .data$count), vjust = -.4,
        colour = "grey15", size = base_size / 3.5) +
      ggplot2::scale_x_continuous(breaks = seq_len(data$K[[domains[1L]]]),
        limits = c(.5, data$K[[domains[1L]]] + .5), expand = c(0, 0)) +
      ggplot2::scale_y_continuous(breaks = function(limits) {
        breaks <- pretty(limits, n = 5L)
        breaks[breaks >= 0 & breaks == floor(breaks)]
      },
        expand = ggplot2::expansion(mult = c(0, .15))) +
      .pr_labs(title = title, subtitle = subtitle, x = axis_label(domains[1L]),
        y = "Count", caption = caption) +
      theme_postrank(base_size = base_size))
  }
  max_count <- max(d$count)
  palette <- postrank_palette(which = "sequential")
  fill_colours <- scales::gradient_n_pal(palette)(d$count / max_count)
  # Count labels remain legible independently of color perception. Prefer
  # neutral dark ink, white on dark cells, and black at a crossover where
  # neither the dark gray nor white reaches normal-text contrast.
  d$count_colour <- vapply(fill_colours, function(fill) {
    if (.pr_contrast("grey15", fill) >= 4.5) "grey15"
    else if (.pr_contrast("white", fill) >= 4.5) "white" else "black"
  }, "")
  count_breaks <- unique(as.integer(round(seq(0, max_count,
    length.out = min(5L, max_count + 1L)))))
  ggplot2::ggplot(d, ggplot2::aes(x = .data$grade_x, y = .data$grade_y,
      fill = .data$count)) +
    ggplot2::geom_tile(colour = "grey65", linewidth = .35) +
    ggplot2::geom_text(ggplot2::aes(label = .data$count, colour = .data$count_colour),
      size = base_size / 3.5) +
    ggplot2::scale_fill_gradientn(colours = palette, limits = c(0, max_count),
      breaks = count_breaks, name = "Count") +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_x_continuous(breaks = seq_len(data$K[[domains[1L]]]),
      limits = c(.5, data$K[[domains[1L]]] + .5), expand = c(0, 0)) +
    ggplot2::scale_y_reverse(breaks = seq_len(data$K[[domains[2L]]]),
      limits = c(data$K[[domains[2L]]] + .5, .5), expand = c(0, 0)) +
    ggplot2::coord_equal() +
    .pr_labs(title = title, subtitle = subtitle, x = axis_label(domains[1L]),
      y = axis_label(domains[2L]), caption = caption) +
    theme_postrank(base_size = base_size) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}
