# Required figure fig-method-comparison and the autoplot()/plot() dispatch (Chapter 12).

#' Plot Grading Rules Evaluated Under the Same Loss
#'
#' Stored reports are compared by risk, disclosure and grade count, or by
#' changes in pairwise relations relative to the reference report. Risk values
#' use the comparison object's common posterior and loss settings. The plotting
#' function neither evaluates nor optimizes additional actions.
#'
#' @param x A `postrank_comparison` from [postrank_compare()].
#' @param view `"summary"` for risk, disclosure and grade-count panels;
#'   `"relations"` for pair-relation change counts.
#' @param ... Unused.
#' @param ncol Optional positive integer number of facet columns in the
#'   summary view. Supply by name. `NULL` uses three columns; `ncol = 1`
#'   with a taller output suits a narrow page. Ignored in the relations view.
#' @return A `ggplot` object. Unavailable actions keep their method labels,
#'   statuses and reasons, with unavailable points and relation counts omitted. The
#'   relations view returns a status panel if no comparison has grades.
#' @details
#' The summary view plots risk, `N/M` (disclosed pairs over all unordered
#' pairs), and the number of grades. The reference action's point is filled;
#' other actions are hollow. A tick marks an available stored risk lower bound.
#' Method labels give status, optimization scope and any absolute risk gap.
#' An optimal fixed-order baseline is optimal within its contiguous partitions,
#' not over every possible grading; baselines have no full-family lower bound.
#'
#' The relations view counts unchanged, newly disclosed, newly withheld and
#' reversed pairs from the reference to each alternative. Every bar covers all
#' `M = choose(n, 2)` pairs, including those withheld by both actions.
#'
#' Supplied actions outside the declared grade or budget constraints are
#' marked `outside family`. Their fixed-action risks can be evaluated under
#' the common loss, but do not compare minima over the same feasible family.
#' The absence of feasibility records in older comparison objects is indicated
#' in the plot. These checks require reconstruction of the comparison; they
#' are not performed during plotting.
#' @seealso [postrank_compare()], [postrank_plot_relations()], [postrank_plot_data()]
#' @concept visualization
#' @examples
#' # Read a prepared three-criterion method comparison; no new solve or evaluation.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' comparison <- load_or_compute("comparison_30x3_tau35")
#' postrank_plot_compare(comparison, ncol = 1)
#' postrank_plot_compare(comparison, view = "relations")
#' @export
postrank_plot_compare <- function(x, view = c("summary", "relations"), ..., ncol = NULL) {
  view <- match.arg(view)
  .pr_assert(inherits(x, "postrank_comparison"), "x must be a postrank_comparison", "wrong_class", "$.x")
  .pr_assert(is.null(ncol) || (is.numeric(ncol) && length(ncol) == 1L && is.finite(ncol) &&
    ncol >= 1 && ncol <= .Machine$integer.max && ncol == floor(ncol)),
    "ncol must be NULL or a positive integer", "invalid_display", "$.ncol")
  t <- x$table; methods <- t$method
  family_recorded <- all(c("family_feasible", "feasibility_reason") %in% names(t))
  outside <- if (family_recorded) t[t$family_feasible %in% FALSE, , drop = FALSE] else t[FALSE, , drop = FALSE]
  scope <- ifelse(grepl("full declared family", t$optimality_scope, fixed = TRUE), "full family",
    ifelse(grepl("contiguous partitions", t$optimality_scope, fixed = TRUE), "fixed score order",
      ifelse(grepl("supplied action", t$optimality_scope, fixed = TRUE), "supplied action", t$optimality_scope)))
  numerical <- t$status == "optimal" & scope == "full family"
  status <- paste0(t$status, ifelse(numerical, " (numerical)", ""))
  gap <- ifelse(is.finite(t$risk_absolute_gap), paste0("; gap ", .pr_fmt(t$risk_absolute_gap, "gap")),
    ifelse(scope == "full family", "; gap unavailable", ""))
  display <- stats::setNames(paste(methods, status, paste0(scope, gap), sep = "\n"), methods)
  if (nrow(outside)) display[outside$method] <- paste0(display[outside$method], "\n[outside family]")
  family_note <- if (nrow(outside)) paste("Outside declared family:",
    paste0(outside$method, " (", outside$feasibility_reason, ")", collapse = "; ")) else
    if (!family_recorded) "Family feasibility was not recorded; recreate the comparison to check constraints." else NULL
  missing <- t[!is.finite(t$risk), , drop = FALSE]
  missing_note <- if (nrow(missing)) paste0("no action: ", paste(sprintf("%s (%s%s)", missing$method, missing$status,
    ifelse(is.na(missing$reason), "", paste0(", ", missing$reason))), collapse = "; ")) else NULL
  policy_note <- paste0("tau ", format(x$settings$tau), " | weights ", .pr_weights_text(x$settings$weights))
  cap <- paste("Gap = absolute solver risk gap.",
    if (any(scope == "fixed score order")) "Fixed score orders restrict the action family." else "Supplied actions are evaluated only.")
  if (view == "relations") {
    if (is.null(x$relations) || !nrow(x$relations)) return(.pr_status_panel("Relation changes from reference",
      "no compared action with a grade", caption = missing_note))
    r <- x$relations[!is.na(x$relations$n_same), , drop = FALSE]
    if (!nrow(r)) return(.pr_status_panel("Relation changes from reference", "no compared action with a grade",
      caption = missing_note))
    long <- do.call(rbind, lapply(seq_len(nrow(r)), function(i) data.frame(method = r$method[i],
      change = c("unchanged", "newly disclosed", "newly withheld", "reversed"),
      count = c(r$n_same[i], r$n_new_disclosed[i], r$n_new_withheld[i], r$n_reversed[i]), stringsAsFactors = FALSE)))
    long$change <- factor(long$change, levels = c("unchanged", "newly disclosed", "newly withheld", "reversed"))
    long$method <- factor(long$method, levels = rev(setdiff(methods, x$reference)))
    ref <- which(methods == x$reference)
    reference_note <- paste0("reference ", x$reference, ": ", status[ref], gap[ref])
    return(ggplot2::ggplot(long, ggplot2::aes(y = .data$method, x = .data$count, fill = .data$change)) +
      ggplot2::geom_col(width = 0.6) +
      ggplot2::scale_fill_manual(values = postrank_palette(which = "change"), drop = FALSE, name = "relation change") +
      .pr_labs(title = "Relation changes from reference",
        subtitle = paste(c(reference_note, policy_note, family_note, missing_note), collapse = " | "),
        x = "all unordered entity pairs (M)", y = NULL,
        caption = "Each bar covers all M pairs. Unchanged includes pairs withheld by both actions. Method labels report status and scope; comparisons use the same posterior and loss.") +
      ggplot2::scale_y_discrete(labels = display, drop = FALSE) + theme_postrank() +
      ggplot2::theme(axis.text.y = ggplot2::element_text(size = 9)))
  }
  rows <- t[is.finite(t$risk), , drop = FALSE]
  long <- rbind(
    data.frame(method = rows$method, metric = "risk R", value = rows$risk, stringsAsFactors = FALSE),
    data.frame(method = rows$method, metric = "disclosure N/M", value = rows$disclosure_rate, stringsAsFactors = FALSE),
    data.frame(method = rows$method, metric = "grades G", value = rows$G, stringsAsFactors = FALSE))
  long$metric <- factor(long$metric, levels = c("risk R", "disclosure N/M", "grades G"))
  long$method <- factor(long$method, levels = rev(methods)); long$joint <- long$method == x$reference
  lb <- rows[!is.na(rows$risk_lower_bound), , drop = FALSE]
  lbd <- data.frame(method = factor(lb$method, levels = rev(methods)), metric = factor(rep("risk R", nrow(lb)), levels = levels(long$metric)),
    value = lb$risk_lower_bound)
  sub <- paste(sprintf("%d methods; reference %s", nrow(t), x$reference), policy_note, sep = " | ")
  if (!is.null(family_note)) sub <- paste(sub, family_note, sep = " | ")
  if (!is.null(missing_note)) sub <- paste(sub, missing_note, sep = " | ")
  ggplot2::ggplot(long, ggplot2::aes(x = .data$value, y = .data$method)) +
    ggplot2::geom_point(data = lbd, shape = 124, size = 4, colour = "grey40") +
    ggplot2::geom_point(ggplot2::aes(fill = .data$joint), shape = 21, colour = "#1F6F8B", size = 2.6) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#1F6F8B", `FALSE` = "white"), guide = "none") +
    ggplot2::scale_y_discrete(labels = display, drop = FALSE) +
    ggplot2::facet_wrap(~ metric, scales = "free_x", ncol = ncol %||% 3L, labeller = ggplot2::label_wrap_gen(width = 10)) +
    ggplot2::scale_x_continuous(breaks = scales::breaks_extended(n = 3), guide = ggplot2::guide_axis(check.overlap = TRUE)) +
    .pr_labs(title = "Grading rules at one policy", subtitle = sub, x = NULL, y = NULL,
      caption = paste(cap, "Filled point = reference; tick = stored risk lower bound. N/M uses all pairs.")) +
    theme_postrank() + ggplot2::theme(panel.spacing.x = ggplot2::unit(1.5, "lines"), axis.text.y = ggplot2::element_text(size = 9))
}

#' Draw a Stored postrank Result with autoplot
#'
#' The re-exported [ggplot2::autoplot()] generic dispatches prepared postrank
#' results to the corresponding plotting method and returns a `ggplot`. Base R
#' `plot()` uses the same dispatch, prints the figure and returns it invisibly.
#' Both methods use prepared results without computing a new grading or
#' diagnostic.
#'
#' @param object A prepared postrank analysis, fit, report card, baseline,
#'   frontier, commonality result or method comparison.
#' @param ... Arguments for the selected plotting method. Analyses and fits
#'   accept `type` to choose the view; other arguments, such as `ncol` or
#'   `view`, follow the corresponding plotting function's help.
#' @return For the supported postrank classes, a `ggplot` object.
#' @details
#' An analysis defaults to its prepared report card and also accepts
#' `type = "relations"`, `"profile"` or `"pairwise"`. A fit defaults to
#' relations and accepts `"relations"`, `"profile"` or `"pairwise"`.
#' Report cards, frontiers, commonality results, comparisons and baselines
#' dispatch to their corresponding plotting functions. Other named arguments
#' are passed to that figure, such as `ncol = 1` for a card or
#' `view = "relations"` for a comparison.
#'
#' Missing prepared results are handled according to the corresponding plotting
#' function. Prepared pairwise probabilities remain available for a fit without
#' grades. The seven `postrank_plot_*()` functions provide explicit selection
#' of the figure type.
#' @name reexports
#' @seealso [postrank_plot_report_card()], [postrank_plot_relations()],
#'   [postrank_plot_profile()], [postrank_plot_pairwise()],
#'   [postrank_plot_frontier()], [postrank_plot_compare()],
#'   [postrank_plot_commonality()]
#' @concept visualization
#' @examples
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' one <- load_or_compute("tutorial_one")
#' p <- autoplot(one) # prepared one-criterion report card
#' p
#' two <- load_or_compute("tutorial_two")
#' autoplot(two, type = "relations")
#' @importFrom ggplot2 autoplot
#' @export
ggplot2::autoplot

.pr_autoplot_type <- function(type, allowed) {
  .pr_assert(is.character(type) && length(type) == 1L && type %in% allowed, paste("type must be one of", paste(allowed, collapse = ", ")),
    "invalid_display", "$.type")
  type
}
#' @export
autoplot.postrank_analysis <- function(object, type = "report_card", ...) {
  switch(.pr_autoplot_type(type, c("report_card", "relations", "profile", "pairwise")),
    report_card = postrank_plot_report_card(object, ...), relations = postrank_plot_relations(object, ...),
    profile = postrank_plot_profile(object, ...), pairwise = postrank_plot_pairwise(object, ...))
}
#' @export
autoplot.postrank_fit <- function(object, type = "relations", ...) {
  switch(.pr_autoplot_type(type, c("relations", "profile", "pairwise")),
    relations = postrank_plot_relations(object, ...), profile = postrank_plot_profile(object, ...),
    pairwise = postrank_plot_pairwise(object, ...))
}
#' @export
autoplot.postrank_report_card <- function(object, ...) postrank_plot_report_card(object, ...)
#' @export
autoplot.postrank_frontier <- function(object, ...) postrank_plot_frontier(object, ...)
#' @export
autoplot.postrank_commonality_cost <- function(object, ...) postrank_plot_commonality(object, ...)
#' @export
autoplot.postrank_comparison <- function(object, ...) postrank_plot_compare(object, ...)
#' @export
autoplot.postrank_baseline <- function(object, ...) postrank_plot_relations(object, ...)

.pr_plot_method <- function(x, ...) { p <- ggplot2::autoplot(x, ...); print(p); invisible(p) }
#' @export
plot.postrank_analysis <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_fit <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_report_card <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_frontier <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_commonality_cost <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_comparison <- function(x, ...) .pr_plot_method(x, ...)
#' @export
plot.postrank_baseline <- function(x, ...) .pr_plot_method(x, ...)
