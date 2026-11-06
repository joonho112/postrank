# Grade views consume the frozen table prepared by .md_plot_prepare().
# Display columns are separate from the stored IDs and integer grades.
.md_plot_grades <- function(data, title = NULL, base_size = 11) {
  if (is.null(title)) title <- "Domain grade report card"
  d <- data$long
  if (is.null(d) || !nrow(d)) {
    return(ggplot2::ggplot(d) + ggplot2::geom_blank() +
      .pr_labs(title = title, subtitle = "No stored grade report card is available.",
        caption = data$caption) + theme_postrank(base_size = base_size) +
      ggplot2::theme(axis.line = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_blank()))
  }
  unit_labels <- data$unit_labels
  if (is.null(unit_labels)) unit_labels <- stats::setNames(data$unit_ids, data$unit_ids)
  domain_labels <- data$domain_labels
  if (is.null(domain_labels)) domain_labels <- stats::setNames(data$domain_ids, data$domain_ids)
  withheld_domains <- data$domain_ids[data$K[data$domain_ids] == 1L]
  domain_width <- max(7L, min(20L, floor(38L / length(data$domain_ids))))
  display_domains <- vapply(domain_labels[data$domain_ids], .pr_wrap_label, "", width = domain_width)
  display_domains[withheld_domains] <- paste0(display_domains[withheld_domains], "\n(all\nwithheld)")
  display_units <- vapply(unit_labels[data$unit_ids], .pr_wrap_label, "", width = 25L)
  G <- max(data$K)
  d$.domain <- factor(d$domain_id, levels = data$domain_ids)
  d$.unit <- factor(d$unit_id, levels = rev(data$unit_ids))
  d$.grade_label <- as.character(d$grade)
  d$.fill_grade <- factor(d$.grade_label, levels = as.character(seq_len(G)))
  d$.all_withheld <- d$domain_id %in% withheld_domains
  grade_colours <- if (G <= 64L) postrank_palette(G) else
    stats::setNames(rep("grey25", G), as.character(seq_len(G)))
  d$.text_colour <- vapply(grade_colours[d$.grade_label], function(fill)
    if (.pr_contrast("white", fill) >= 4.5) "white" else "black", "")
  d$.text_colour[d$.all_withheld] <- "grey15"
  withheld <- d[d$.all_withheld, , drop = FALSE]
  caption <- paste(.md_plot_caption(data), "Equal grades withhold a comparison.")
  ggplot2::ggplot(d, ggplot2::aes(x = .data$.domain, y = .data$.unit)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$.fill_grade),
      colour = "white", linewidth = .6, width = .95, height = .95) +
    ggplot2::geom_tile(data = withheld, fill = "grey90", colour = "white",
      linewidth = .6, width = .95, height = .95) +
    ggplot2::geom_text(ggplot2::aes(label = .data$.grade_label,
      colour = .data$.text_colour), size = base_size / 3.5) +
    ggplot2::scale_colour_identity() +
    (if (G <= 64L) scale_fill_grade(G) else ggplot2::scale_fill_manual(
      values = stats::setNames(rep("grey25", G), as.character(seq_len(G))), guide = "none")) +
    ggplot2::scale_x_discrete(limits = data$domain_ids, labels = display_domains,
      drop = FALSE, position = "top") +
    ggplot2::scale_y_discrete(limits = rev(data$unit_ids), labels = display_units,
      drop = FALSE) +
    .pr_labs(title = title, subtitle = "Grade 1 has highest reported priority; gray columns withhold every direction.",
      x = NULL, y = NULL, caption = caption) +
    theme_postrank(base_size = base_size) +
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
      axis.line = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(hjust = .5),
      legend.position = if (G <= 12L) "bottom" else "none")
}
