# Theme, palettes and named grade scales (Chapter 12, PR-DEC-12-B).

#' Use the postrank Figure Theme
#'
#' The theme specifies the typography and white background used in postrank
#' figures. It extends [ggplot2::theme_minimal()] with a light horizontal grid,
#' axis lines, a left-aligned bold title and a bottom legend.
#'
#' @param base_size Base font size in points; default 11.
#' @param base_family Font family passed to ggplot2; the default `""` uses
#'   the graphics device's default family.
#' @return A ggplot2 `theme` that can be added to a plot.
#' @details White plot and panel backgrounds preserve the contrast of the grade
#' palette. The theme affects presentation only: grades, entity order and
#' plotted values are retained. Additional ggplot2 theme settings can be
#' applied subsequently to modify individual figures.
#' @seealso [postrank_palette()], [scale_colour_grade()]
#' @concept visualization
#' @examples
#' # A prepared one-criterion probability matrix, with larger text.
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
#' The palettes define the colors used for grades, relations, relation changes
#' and probabilities. Grade colors progress from dark for the highest-priority
#' grade 1 to lighter colors for larger grade numbers.
#'
#' @param n Number of grades, from 1 to 64, for `which = "grade"`.
#'   Ignored for other palettes and may be omitted for them.
#' @param which `"grade"`, `"relation"`, `"change"` or `"sequential"`.
#' @return A character vector of R color specifications. Grade colors are
#'   named `"1"` through `"n"`; relation and change colors are named by state.
#'   The seven-stop sequential vector is unnamed. Some state colors use R
#'   gray names rather than hexadecimal notation.
#' @details
#' The grade palette interpolates sRGB channels from `#153653` to `#4F879E`.
#' Across its supported sizes, luminance increases with grade number and
#' colors retain at least 3:1 contrast against white. For a single grade,
#' the sole color is `#153653`.
#'
#' The relation palette names `above`, `withheld` and `below`, with gray for
#' withholding. The change palette names `unchanged`, `newly disclosed`,
#' `newly withheld` and `reversed`; unchanged is light gray, newly withheld
#' is medium gray. Unchanged pairs may be ordered or withheld. The colored
#' states use selected Okabe-Ito colors. `"sequential"` provides a light-to-dark
#' Blues ramp used for probabilities. A grade palette supports at most 64
#' grades; the report-card view uses neutral ink and labels beyond that limit.
#' @seealso [scale_colour_grade()], [theme_postrank()], [postrank_plot_relations()]
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
#' Discrete color and fill scales represent grade membership. The number of
#' grades in the full report is supplied so that subsets retain the original
#' grade colors and legend. `scale_color_grade()` is the spelling alias of
#' `scale_colour_grade()`; `scale_fill_grade()` uses the same palette for fill.
#'
#' @param n_grades Number of grades in the full object, from 1 to 64.
#'   With `NULL`, colors follow the discrete levels present in the data;
#'   specify the full count when a displayed subset omits grades.
#' @param ... Additional arguments passed to [ggplot2::discrete_scale()].
#'   The helper already sets `aesthetics`, `palette`, `drop` and `name`, and
#'   sets `limits` when `n_grades` is supplied; do not pass those arguments again.
#' @return A ggplot2 discrete color or fill scale.
#' @details
#' Map grades as discrete labels, for example `factor(grade)`. With an explicit
#' full count, limits are `as.character(seq_len(n_grades))` and `drop = FALSE`.
#' Absent grades remain on the scale. The same full count must be used across
#' views; inferring a count from a displayed subset can assign different colors.
#' Grade 1 has highest priority. Equal colors indicate shared grade membership,
#' which withholds comparisons rather than asserting target equality.
#' @seealso [postrank_palette()], [theme_postrank()]
#' @concept visualization
#' @examples
#' # Grade 2 is absent from the display, but keeps its place in the full scale.
#' d <- data.frame(entity = c("A", "C"), value = c(2, 1), grade = factor(c(1, 3)))
#' ggplot2::ggplot(d, ggplot2::aes(value, entity, colour = grade)) +
#'   ggplot2::geom_point(size = 3) + scale_colour_grade(n_grades = 3) +
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
