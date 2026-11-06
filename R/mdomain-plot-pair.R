# The pair table already contains the verified report directions and identities.
# Symbols and display labels never replace its original ID/grade/sign columns.
.md_plot_pair <- function(data, title = NULL, base_size = 11) {
  if (is.null(title)) title <- "Pairwise reported directions"
  d <- data$pair
  if (is.null(d) || !nrow(d)) {
    return(ggplot2::ggplot(d) + ggplot2::geom_blank() +
      .pr_labs(title = title, subtitle = "No stored pair directions are available.",
        caption = data$caption) + theme_postrank(base_size = base_size) +
      ggplot2::theme(axis.line = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_blank()))
  }
  unit_labels <- data$unit_labels
  if (is.null(unit_labels)) unit_labels <- stats::setNames(data$unit_ids, data$unit_ids)
  domain_labels <- data$domain_labels
  if (is.null(domain_labels)) domain_labels <- stats::setNames(data$domain_ids, data$domain_ids)
  display_domains <- vapply(domain_labels[data$domain_ids], .pr_wrap_label, "", width = 25L)
  d$.domain <- factor(d$domain_id, levels = rev(data$domain_ids))
  d$.symbol <- ifelse(d$sign > 0L, "+", ifelse(d$sign < 0L, "-", "0"))
  d$.state <- ifelse(d$sign == 0L, "withheld", "disclosed")
  d$.direction_text <- ifelse(d$sign > 0L,
    paste("Favors", unname(unit_labels[d$unit_i])),
    ifelse(d$sign < 0L, paste("Favors", unname(unit_labels[d$unit_j])),
      ifelse(d$structural_identity, "Same modeled target (direction withheld)", "Direction withheld")))
  d$.direction_text <- vapply(d$.direction_text, .pr_wrap_label, "", width = 25L)
  crossing <- any(d$sign > 0L) && any(d$sign < 0L)
  pair_names <- unname(unit_labels[data$unit_ids])
  caption <- .md_plot_caption(data)
  subtitle <- paste(c(paste(pair_names, collapse = " versus "),
    if (crossing) "Opposite reported directions occur across these domains."), collapse = ". ")
  ggplot2::ggplot(d, ggplot2::aes(y = .data$.domain)) +
    ggplot2::geom_point(ggplot2::aes(x = 0, fill = .data$.state),
      shape = 21, size = 7, colour = "grey25", stroke = .5) +
    ggplot2::geom_text(ggplot2::aes(x = 0, label = .data$.symbol),
      size = base_size / 3.3, fontface = "bold", colour = "grey10") +
    ggplot2::geom_text(ggplot2::aes(x = .13, label = .data$.direction_text),
      hjust = 0, lineheight = 1, size = base_size / 3.5) +
    ggplot2::scale_fill_manual(values = c(disclosed = "#9CC2D1", withheld = "grey90"), guide = "none") +
    ggplot2::scale_x_continuous(limits = c(-.08, 1), breaks = NULL, expand = c(0, 0)) +
    ggplot2::scale_y_discrete(limits = rev(data$domain_ids), labels = display_domains,
      drop = FALSE, expand = ggplot2::expansion(add = .7)) +
    .pr_labs(title = title, subtitle = subtitle, x = NULL, y = NULL, caption = caption) +
    theme_postrank(base_size = base_size) +
    ggplot2::theme(axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "grey93", linewidth = .3))
}
