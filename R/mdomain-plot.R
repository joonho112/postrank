.md_plot_caption <- function(data) {
  short <- attr(data,"display_caption",exact=TRUE)
  if (is.null(short)) data$caption else short
}

#' Plot a Multidomain Grade Profile
#'
#' `postrank_plot_mdomain()` plots a stored multidomain report card as a
#' unit-by-domain grade table (`view = "grades"`), a one- or two-domain cell
#' occupancy chart (`view = "cells"`), or a domain-by-domain directional
#' comparison of two units (`view = "pair"`), without re-evaluating or searching
#' candidates.
#'
#' @param x A `postrank_mdomain_evaluation` or `postrank_mdomain_fit` (for a
#'   `postrank_mdomain_assessment`, pass `x$evaluation`).
#' @param view One of `"grades"` (the default), `"cells"`, or `"pair"`.
#' @param units Optional character vector of distinct unit IDs from `x` in the
#'   desired display order. Required with exactly two distinct unit IDs when
#'   `view = "pair"`.
#' @param domains Optional character vector of distinct domain IDs from `x` in
#'   the desired display order. Required with one or two domain IDs when
#'   `view = "cells"` and `x` has more than two domains.
#' @param ... Optional named display arguments chosen from `title` (character
#'   scalar or `NULL`), `unit_labels` (named character vector keyed by raw unit
#'   IDs), `domain_labels` (named character vector keyed by raw domain IDs), and
#'   `base_size` (positive finite number, default `11`). Passing any other
#'   argument stops with an error.
#' @return A `ggplot` object with underlying plot data in `$data` and a
#'   `"postrank_mdomain"` attribute containing `view`, `unit_ids`, `domain_ids`,
#'   `original_units`, `original_pairs`, full `caption` text, and
#'   `uses_stored_card = TRUE`.
#' @details
#' Within each domain, grade `1` has highest priority and equal grades leave a
#' pair unordered rather than claiming equal targets:
#' \itemize{
#'   \item `view = "grades"`: draws a unit-by-domain tile grid labeled with
#'     integer grades (`scale_fill_grade()` up to 64 grades); any domain with a
#'     single occupied grade (`K_d = 1`) is shaded light gray and marked
#'     `"(all withheld)"`.
#'   \item `view = "cells"`: counts displayed units in each grade (bar chart for
#'     one domain) or `(grade_x, grade_y)` cell (tile chart with reversed y-axis
#'     for two domains). Cell coordinates locate per-domain grade combinations
#'     without defining a total order across cells, and counts sum over any
#'     domains omitted from `domains`.
#'   \item `view = "pair"`: compares `units[1]` against `units[2]` on each
#'     displayed domain, marking `"+"` (`"Favors <units[1]>"`), `"-"`
#'     (`"Favors <units[2]>"`), or `"0"` (`"Direction withheld"`, or
#'     `"Same modeled target (direction withheld)"` when the pair shares a
#'     structural equality class on that domain), and notes in the subtitle when
#'     opposite directions appear across domains.
#' }
#' Figure captions report the original full-card risk `risk` and joint
#' exceedance probability `J` even when a subset of `units` or `domains` is
#' displayed.
#' @seealso [postrank_mdomain_evaluate()], [postrank_mdomain_solve()],
#'   [postrank_mdomain_grades()], [theme_postrank()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' inp <- postrank_mdomain_input(
#'   postrank_toy,
#'   provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
#' )
#' G <- matrix(
#'   c(1L, 1L, 2L, 3L, 1L, 2L),
#'   nrow = 3L,
#'   ncol = 2L,
#'   dimnames = list(inp$unit_ids, inp$domain_ids)
#' )
#' ev <- postrank_mdomain_evaluate(inp, G)
#' postrank_plot_mdomain(ev, view = "grades")
#' postrank_plot_mdomain(ev, view = "cells", domains = c("need_A", "need_B"))
#' postrank_plot_mdomain(ev, view = "pair", units = c("001", "site-B"))
#' @concept multidomain
#' @export
postrank_plot_mdomain <- function(x, view=c("grades","cells","pair"),
                                  units=NULL, domains=NULL, ...) {
  view <- tryCatch(match.arg(view), error=function(e)
    .md_error(conditionMessage(e),"mdomain_plot_invalid","view"))
  dots <- list(...)
  allowed <- c("title","unit_labels","domain_labels","base_size")
  if (length(dots) && (is.null(names(dots)) || anyNA(names(dots)) ||
      any(!nzchar(names(dots))) || anyDuplicated(names(dots)) ||
      any(!names(dots) %in% allowed)))
    .md_error(paste("Use named display options:",paste(allowed,collapse=", ")),
              "mdomain_plot_invalid","...")
  title <- dots$title
  if (!is.null(title) && (!is.character(title) || length(title)!=1L || is.na(title)))
    .md_error("title must be NULL or one character string.","mdomain_plot_invalid","title")
  base_size <- if (is.null(dots$base_size)) 11 else dots$base_size
  if (!is.numeric(base_size) || length(base_size)!=1L || !is.finite(base_size) || base_size<=0)
    .md_error("base_size must be one positive finite number.","mdomain_plot_invalid","base_size")
  data <- .md_plot_prepare(x,units=units,domains=domains,view=view)
  labels <- function(ids,map,field) tryCatch(
    .pr_plot_entity_labels(ids,map,field=field), error=function(e)
      .md_error(conditionMessage(e),"mdomain_plot_invalid",field))
  data$unit_labels <- labels(rownames(data$full_grades),dots$unit_labels,"unit_labels")[data$unit_ids]
  data$domain_labels <- labels(colnames(data$full_grades),dots$domain_labels,"domain_labels")[data$domain_ids]
  render <- switch(view,grades=.md_plot_grades,cells=.md_plot_cells,pair=.md_plot_pair)
  p <- render(data,title=title,base_size=base_size)
  attr(p,"postrank_mdomain") <- list(view=view,unit_ids=data$unit_ids,
    domain_ids=data$domain_ids,original_units=data$n_original,
    original_pairs=data$M,caption=data$caption,uses_stored_card=TRUE)
  p
}
