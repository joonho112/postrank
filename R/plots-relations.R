# Pair-relation and relation-change figures.

# Shared by the two relation/profile views; these labels never replace IDs.
.pr_relation_profile_labels <- function(ids, labels, what, width = NULL) {
  out <- stats::setNames(ids, ids)
  if (!is.null(labels)) {
    .pr_assert(is.character(labels) && is.null(dim(labels)) && length(labels) > 0L &&
      !anyNA(labels) && all(nzchar(trimws(labels))) && !is.null(names(labels)) &&
      !anyNA(names(labels)) && !anyDuplicated(names(labels)) &&
      all(nzchar(names(labels))) && all(names(labels) %in% ids),
      paste0(what, " must be a nonempty character vector with unique names drawn from the raw IDs"),
      "invalid_display", paste0("$.", what))
    out[names(labels)] <- labels
  }
  if (!is.null(width)) out[] <- vapply(out, function(text) {
    lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
    paste(vapply(lines, function(line) {
      # Underscores offer a useful display break without humanizing IDs that
      # may collide (for example "a_b" and "a b").
      words <- strsplit(gsub("_", "_ ", line, fixed = TRUE), "[[:space:]]+")[[1L]]
      words <- unlist(lapply(words, function(word) {
        if (nchar(word) <= width) return(word)
        starts <- seq.int(1L, nchar(word), by = width)
        substring(word, starts, pmin(nchar(word), starts + width - 1L))
      }), use.names = FALSE)
      gsub("_ ", "_", paste(strwrap(paste(words, collapse = " "), width = width), collapse = "\n"), fixed = TRUE)
    }, ""), collapse = "\n")
  }, "")
  out
}

.pr_grade_of <- function(x, what) {
  if (inherits(x, "postrank_analysis")) x <- x$fit
  if (inherits(x, "postrank_fit")) return(if (isTRUE(x$incumbent_validated)) x$grade else NULL)
  if (inherits(x, "postrank_baseline")) return(x$grade)
  if (is.numeric(x) && !is.null(names(x))) return(stats::setNames(as.integer(x), names(x)))
  .pr_abort(paste(what, "must be a postrank_fit, postrank_analysis, postrank_baseline or named grade vector"), "wrong_class", paste0("$.", what))
}

#' Plot Disclosed Comparisons or Their Changes
#'
#' The matrix displays the pairwise directions disclosed or withheld by a
#' grading. When a second report is supplied, each relation is classified as
#' unchanged, newly disclosed, newly withheld or reversed. The tiles represent
#' selected actions. Posterior comparison probabilities are displayed
#' separately by [postrank_plot_pairwise()].
#'
#' @param x A `postrank_fit`, `postrank_analysis`, `postrank_baseline`, or a
#'   complete named integer grade vector. Grade 1 has highest priority.
#' @param y Optional second fit, analysis, baseline or named grade vector on
#'   exactly the same entities. Changes run from `x` to `y`.
#' @param labels `"auto"` shows IDs or display names for at most 15 entities
#'   when every label has at most 20 characters; otherwise it shows positions
#'   in grade order. `"ids"` always shows the labels. `"none"` hides ticks and
#'   axis labels. Increase the canvas size when explicitly showing many IDs.
#' @param ... Unused.
#' @param entity_labels Optional partial named character vector mapping raw
#'   entity IDs to display names. Unmapped IDs keep their text. Names are
#'   wrapped on explicit ID axes and never alter data or ordering. Supply
#'   this argument by name.
#' @return A `ggplot` object. If either fitted object lacks a validated grade,
#'   a status panel explains which result is unavailable.
#' @details
#' Both axes follow the first object's grade, then raw entity ID. Only the
#' upper triangle is drawn, so every unordered pair appears once. In a
#' single-report view, gray means that the comparison is withheld. A shared
#' grade does not assert latent equality.
#'
#' In a change map, light gray means unchanged and medium gray means newly
#' withheld. Unchanged includes pairs that were disclosed in the same direction
#' and pairs withheld by both reports. Agreement uses all `M = choose(n, 2)`
#' pairs. A relation change is not itself a loss improvement: reports from
#' different policies need evaluation under a common loss for a risk comparison.
#' The function reads grades and does not solve or calculate new posterior scores.
#' @seealso [postrank_plot_compare()], [get_relations()], [postrank_plot_pairwise()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' one <- load_or_compute("tutorial_one")
#' postrank_plot_relations(one)
#' two <- load_or_compute("tutorial_two")
#' postrank_plot_relations(one, two, labels = "ids",
#'   entity_labels = c(A = "Site A", F = "Site F"))
#' @export
postrank_plot_relations <- function(x, y = NULL, labels = c("auto", "ids", "none"), ..., entity_labels = NULL) {
  labels <- match.arg(labels)
  g0 <- .pr_grade_of(x, "x")
  if (is.null(g0)) {
    fit <- if (inherits(x, "postrank_analysis")) x$fit else x
    status <- fit$status$normalized
    return(.pr_status_panel("Pair relations", paste0("no validated incumbent",
      if (!is.null(status)) paste0(" (", gsub("_", " ", status), ")") else "")))
  }
  n <- length(g0)
  ids <- names(g0)[order(g0, names(g0), method = "radix")]
  display <- .pr_relation_profile_labels(ids, entity_labels, "entity_labels")
  show_ids <- labels == "ids" || (labels == "auto" && n <= 15L && max(nchar(display)) <= 20L)
  border <- if (n <= 30L) "white" else NA_character_
  axis_note <- if (labels == "auto" && !show_ids) "Axes show positions in grade order." else "Axes follow grade, then ID."
  if (is.null(y)) {
    d <- .pr_relations_long(g0)
    N <- sum(d$code != 0L); M <- nrow(d)
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$j_pos, y = .data$i_pos, fill = .data$relation)) +
      ggplot2::geom_tile(colour = border, linewidth = 0.2) +
      ggplot2::scale_fill_manual(values = postrank_palette(which = "relation"),
        breaks = levels(d$relation)[levels(d$relation) %in% as.character(d$relation)], drop = TRUE,
        labels = function(z) unname(c(above = "higher priority", withheld = "withheld", below = "lower priority")[z]), name = "Row relative to column") +
      .pr_labs(title = "Pair relations",
        subtitle = sprintf("%d entities in %d grades | disclosed %d/%d pairs", n, max(g0), N, M),
        caption = paste("Gray = comparison withheld, not equality.", axis_note))
  } else {
    g1 <- .pr_grade_of(y, "y")
    if (is.null(g1)) return(.pr_status_panel("Pair relation changes", "the second object has no validated grade"))
    .pr_assert(setequal(names(g1), names(g0)), "x and y must grade the same entities", "invalid_display", "$.y")
    d <- .pr_change_long(g0, g1); tab <- table(d$change); M <- nrow(d)
    sub <- if (tab[["unchanged"]] == M) sprintf("identical relations (agreement %s)", .pr_fmt(1, "ratio")) else
      sprintf("unchanged %d, newly disclosed %d, newly withheld %d, reversed %d | agreement %s",
        tab[["unchanged"]], tab[["newly disclosed"]], tab[["newly withheld"]], tab[["reversed"]], .pr_fmt(tab[["unchanged"]] / M, "ratio"))
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$j_pos, y = .data$i_pos, fill = .data$change)) +
      ggplot2::geom_tile(colour = border, linewidth = 0.2) +
      ggplot2::scale_fill_manual(values = postrank_palette(which = "change"),
        breaks = levels(d$change)[levels(d$change) %in% as.character(d$change)], drop = TRUE, name = "Relation change") +
      ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2L, byrow = TRUE)) +
      .pr_labs(title = "Pair relation changes", subtitle = sub,
        caption = paste("Light gray = unchanged; medium gray = newly withheld. Unchanged pairs may be disclosed or withheld.",
          "Withholding is not equality.", axis_note))
  }
  ticks <- if (show_ids) seq_len(n) else if (labels == "auto") unique(as.integer(round(seq(1, n, length.out = min(4L, n))))) else NULL
  tick_labels <- if (show_ids) unname(.pr_relation_profile_labels(ids, entity_labels, "entity_labels", 18L)) else ticks
  p + ggplot2::scale_x_continuous(breaks = ticks, labels = tick_labels, limits = c(.5, n + .5),
      expand = c(0, 0), position = "top") +
    ggplot2::scale_y_reverse(breaks = ticks, labels = tick_labels, limits = c(n + .5, .5), expand = c(0, 0)) +
    ggplot2::coord_equal() + .pr_labs(x = NULL, y = NULL) + theme_postrank() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = if (show_ids) 90 else 0,
      hjust = if (show_ids) 0 else .5, vjust = .5), panel.grid.major.y = ggplot2::element_blank())
}
