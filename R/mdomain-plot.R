.md_plot_caption <- function(data) {
  short <- attr(data,"display_caption",exact=TRUE)
  if (is.null(short)) data$caption else short
}

#' Plot a Multidomain Profile Report Card
#'
#' Display the validated grades, occupied profile cells, or a specified pair's
#' domain directions. Plots read the stored result and never select a new card.
#'
#' @param x A `postrank_mdomain_evaluation` or `postrank_mdomain_fit`.
#'   For an assessment, use its stored `evaluation`.
#' @param view One of `"grades"`, `"cells"`, or `"pair"`.
#' @param units Optional ordered unit IDs to display. The pair view requires
#'   exactly two distinct IDs.
#' @param domains Optional ordered domain IDs. Cell views use one or two
#'   explicitly selected domains when the full card has more than two.
#' @param ... Named display options `title`, `unit_labels`, `domain_labels`
#'   and `base_size`. Label maps are named character vectors keyed by original
#'   IDs. The plot records the selected IDs independently of their labels.
#' @return A `ggplot` with inspectable plotting data and a
#'   `postrank_mdomain` attribute describing the view and original card scope.
#'   Its `caption` field retains the full context accompanying the shorter figure caption.
#' @details A tied grade withholds a direction. Cell labels locate grade
#'   combinations. Counts sum over any unshown domains. Risk and protection
#'   in the caption refer to the original card even when only a subset is shown.
#'   Smaller grade numbers mean higher reported priority within that domain.
#' @seealso [postrank_mdomain_evaluate()], [postrank_mdomain_solve()],
#'   [theme_postrank()]
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
