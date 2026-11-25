# ggplot2 theme, grade palettes, and named color/fill scales.

#' Use the postrank Figure Theme
#'
#' `theme_postrank()` returns the `ggplot2` theme used across `postrank`
#' figures, extending [ggplot2::theme_minimal()] with white backgrounds, a light
#' horizontal grid, axis lines and ticks, left-aligned bold titles, and a bottom
#' legend.
#'
#' @param base_size Base font size in points (`11` by default).
#' @param base_family Font family passed to `ggplot2` (`""` by default, using
#'   the graphics device's default family).
#' @return A `ggplot2` `theme` object that can be added to a plot with `+`.
#' @details
#' White plot and panel backgrounds (`"#FFFFFF"`) keep at least 3:1 contrast
#' with the grade color ramp from [postrank_palette()]. The theme changes
#' visual styling only and leaves grades, entity order, and plotted data
#' untouched; add further [ggplot2::theme()] calls afterward to customize
#' individual elements.
#' @seealso [postrank_palette()], [scale_colour_grade()]
#' @concept visualization
#' @examples
#' p <- postrank_plot_pairwise(pr_tutorial$one)
#' p + theme_postrank(base_size = 12)
#' @export
theme_postrank <- function(base_size = 11, base_family = "") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(), panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "grey90", linewidth = 0.3),
      axis.line = ggplot2::element_line(colour = "grey20", linewidth = 0.4),
      axis.ticks = ggplot2::element_line(colour = "grey20", linewidth = 0.3),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0), plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(colour = "grey30", hjust = 0),
      plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0), plot.caption.position = "plot",
      legend.position = "bottom", legend.box = "vertical", legend.title.position = "top",
      legend.key.size = ggplot2::unit(0.9, "lines"), plot.margin = ggplot2::margin(5.5, 12, 5.5, 5.5),
      strip.text = ggplot2::element_text(face = "bold"),
      plot.background = ggplot2::element_rect(fill = "#FFFFFF", colour = NA),
      panel.background = ggplot2::element_rect(fill = "#FFFFFF", colour = NA))
}

.pr_grade_ends <- c("#153653", "#4F879E")
.pr_relation_colours <- c(above = "#0072B2", withheld = "grey80", below = "#E69F00")
.pr_change_colours <- c(unchanged = "grey92", `newly disclosed` = "#0072B2", `newly withheld` = "#999999", reversed = "#D55E00")
.pr_sequential_colours <- c("#EFF3FF", "#C6DBEF", "#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#084594")

.pr_rel_luminance <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  as.numeric(c(0.2126, 0.7152, 0.0722) %*% lin)
}
.pr_contrast <- function(a, b) { la <- .pr_rel_luminance(a); lb <- .pr_rel_luminance(b); (max(la, lb) + 0.05) / (min(la, lb) + 0.05) }

#' Choose Colors for Grades and Pair Relations
#'
#' `postrank_palette()` returns the color vectors used in `postrank` figures for
#' grades, pair relations, relation changes, and directional-error
#' probabilities. Grade colors run from dark blue (`"#153653"`) for the
#' highest-priority grade `1` to lighter blue-teal (`"#4F879E"`) for larger
#' grade numbers.
#'
#' @param n Integer number of grades from `1` to `64` when `which = "grade"`.
#'   Ignored (and may be omitted) for the other palettes.
#' @param which Palette to return: `"grade"` (the default), `"relation"`,
#'   `"change"`, or `"sequential"`.
#' @return A character vector of R color specifications (hexadecimal strings and,
#'   for neutral states, R gray names):
#' \itemize{
#'   \item `"grade"`: named `"1"` through `as.character(n)`.
#'   \item `"relation"`: named `"above"`, `"withheld"`, and `"below"`.
#'   \item `"change"`: named `"unchanged"`, `"newly disclosed"`,
#'     `"newly withheld"`, and `"reversed"`.
#'   \item `"sequential"`: unnamed seven-stop light-to-dark blue ramp.
#' }
#' @details
#' For `which = "grade"`, sRGB channels are linearly interpolated from
#' `"#153653"` to `"#4F879E"` (`"#153653"` when `n = 1`), giving strictly
#' increasing luminance with grade number and at least 3:1 contrast against
#' white across `1..64`. Values of `n` outside `1..64` stop with an error;
#' [postrank_plot_report_card()] switches to neutral dark gray above 64 grades.
#'
#' In `"relation"`, `"above"` (`"#0072B2"`) and `"below"` (`"#E69F00"`) use
#' Okabe-Ito colors and `"withheld"` uses `"grey80"`. In `"change"`,
#' `"unchanged"` (`"grey92"`, covering pairs ordered the same way or withheld in
#' both gradings) is light gray, `"newly withheld"` (`"#999999"`) is medium
#' gray, `"newly disclosed"` is `"#0072B2"`, and `"reversed"` is `"#D55E00"`.
#' `"sequential"` runs from `"#EFF3FF"` to `"#084594"` for probability heat
#' maps.
#' @seealso [scale_colour_grade()], [theme_postrank()],
#'   [postrank_plot_relations()]
#' @concept visualization
#' @examples
#' postrank_palette(1)
#' postrank_palette(4)
#' postrank_palette(which = "relation")
#' postrank_palette(which = "change")
#' @export
postrank_palette <- function(n, which = c("grade", "relation", "change", "sequential")) {
  which <- match.arg(which)
  if (which == "relation") return(.pr_relation_colours)
  if (which == "change") return(.pr_change_colours)
  if (which == "sequential") return(.pr_sequential_colours)
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n != floor(n) || n < 1 || n > 64)
    .pr_abort("the grade palette supports 1 to 64 grades; above 64 views use neutral ink and explicit labels",
      "invalid_palette_size", "$.n")
  n <- as.integer(n)
  a <- grDevices::col2rgb(.pr_grade_ends[1L])[, 1]; b <- grDevices::col2rgb(.pr_grade_ends[2L])[, 1]
  t <- if (n == 1L) 0 else (seq_len(n) - 1) / (n - 1)
  cols <- vapply(t, function(ti) { ch <- floor(a + (b - a) * ti + 0.5); grDevices::rgb(ch[1], ch[2], ch[3], maxColorValue = 255) }, "")
  stats::setNames(cols, as.character(seq_len(n)))
}

#' Keep Grade Colors Consistent Across Views
#'
#' `scale_colour_grade()`, `scale_color_grade()`, and `scale_fill_grade()`
#' construct discrete `ggplot2` color and fill scales for grade membership using
#' [postrank_palette()]. Passing the full report's grade count `n_grades` keeps
#' grade colors and legend entries identical when plotting a subset of entities
#' that omits one or more grades.
#'
#' @param n_grades Integer number of grades in the full grading (`1` to `64`),
#'   or `NULL` (the default) to size the palette from the discrete levels
#'   present in the plotted data.
#' @param ... Additional arguments passed to [ggplot2::discrete_scale()]. Do not
#'   pass `aesthetics`, `palette`, `drop`, `name`, or (when `n_grades` is
#'   supplied) `limits`, which are set by the scale helper.
#' @return A `ggplot2` discrete color or fill scale.
#' @details
#' Map grades as discrete values such as `factor(grade)`. When `n_grades` is
#' supplied, the scale fixes `limits = as.character(seq_len(n_grades))` and
#' `drop = FALSE` so missing grades retain their slot on the color ramp. Grade
#' `1` has highest priority; shared color indicates shared grade membership
#' (withheld ordering, not equal targets).
#' @seealso [postrank_palette()], [theme_postrank()]
#' @concept visualization
#' @examples
#' d <- data.frame(entity = c("A", "C"), value = c(2, 1), grade = factor(c(1, 3)))
#' ggplot2::ggplot(d, ggplot2::aes(value, entity, colour = grade)) +
#'   ggplot2::geom_point(size = 3) +
#'   scale_colour_grade(n_grades = 3) +
#'   theme_postrank()
#' @export
scale_colour_grade <- function(n_grades = NULL, ...) .pr_grade_scale("colour", n_grades, ...)
#' @rdname scale_colour_grade
#' @export
scale_color_grade <- function(n_grades = NULL, ...) .pr_grade_scale("colour", n_grades, ...)
#' @rdname scale_colour_grade
#' @export
scale_fill_grade <- function(n_grades = NULL, ...) .pr_grade_scale("fill", n_grades, ...)
.pr_grade_scale <- function(aesthetic, n_grades, ...) {
  if (is.null(n_grades)) return(ggplot2::discrete_scale(aesthetics = aesthetic, palette = function(n) unname(postrank_palette(n)),
    drop = FALSE, name = "grade", ...))
  pal <- postrank_palette(n_grades)
  ggplot2::discrete_scale(aesthetics = aesthetic, palette = function(n) unname(pal[seq_len(n)]),
    limits = names(pal), drop = FALSE, name = "grade", ...)
}

# Wrap figure titles, subtitles and captions so that they also fit the 3.4-inch canvas
# (about 32 title, 42 subtitle and 48 caption characters per line at the default sizes).
.pr_wrap_label <- function(text, width = 100L) if (is.null(text)) NULL else paste(strwrap(text, width = width), collapse = "\n")
.pr_labs <- function(...) {
  a <- list(...)
  if (is.character(a$title)) a$title <- .pr_wrap_label(a$title, 32L)
  if (!is.null(a$subtitle)) a$subtitle <- .pr_wrap_label(a$subtitle, 42L)
  if (!is.null(a$caption)) a$caption <- .pr_wrap_label(a$caption, 48L)
  do.call(ggplot2::labs, a)
}
