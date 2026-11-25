# Method-comparison plots and autoplot()/plot() S3 dispatch.

#' Plot Grading Rules Evaluated Under the Same Loss
#'
#' `postrank_plot_compare()` plots stored grading rules from
#' [postrank_compare()] side by side on risk, disclosure rate (`N / M`), and
#' grade count (`G`), or by pairwise relation changes relative to the reference
#' rule. All risk values come from `x`'s shared posterior and loss settings
#' without solving or evaluating new gradings.
#'
#' @param x A `postrank_comparison` from [postrank_compare()].
#' @param view `"summary"` (the default) for risk, disclosure, and grade-count
#'   panels, or `"relations"` for stacked counts of pairwise relation changes
#'   from `x$reference` to each other rule.
#' @param ... Unused; unnamed extra arguments are ignored. Pass `ncol` by name.
#' @param ncol Positive integer number of facet columns in `view = "summary"`,
#'   or `NULL` (the default, which uses 3 columns). Use `ncol = 1` for narrow
#'   pages. Ignored when `view = "relations"`.
#' @return A `ggplot` object. Rules without a finite risk (`!is.finite(risk)`)
#'   keep their y-axis labels, statuses, and reasons in the subtitle while their
#'   points and bars are omitted. When `view = "relations"` and no compared rule
#'   has grades, returns an empty status `ggplot` stating why.
#' @details
#' In `view = "summary"`, the reference rule (`x$reference`) is drawn as a
#' filled circle and other rules as hollow circles; a vertical tick marks any
#' stored `risk_lower_bound`. Y-axis labels show the rule name, solver status
#' (`"optimal (numerical)"` for full-family optimal solves), optimization scope
#' (`"full family"`, `"fixed score order"`, or `"supplied action"`), and any
#' absolute solver risk gap. A score-order baseline searches only contiguous
#' cuts of its fixed score order rather than all gradings, so it has no
#' full-family lower bound.
#'
#' In `view = "relations"`, each bar covers all `M = choose(n, 2)` unordered
#' pairs across `"unchanged"`, `"newly disclosed"`, `"newly withheld"`, and
#' `"reversed"` relative to `x$reference`; `"unchanged"` includes pairs left
#' unordered by both rules.
#'
#' Rules recorded with `family_feasible == FALSE` (for example, exceeding
#' `G_max` or violating an error budget `q_k`) are tagged `"[outside family]"`
#' on the y-axis and listed in the subtitle: their fixed-action risks are
#' evaluated under the same loss, but they are outside the constrained feasible
#' set. If `family_feasible` is absent from an older comparison object, the
#' subtitle notes that constraint checks require rebuilding `x` with
#' [postrank_compare()].
#' @seealso [postrank_compare()], [postrank_plot_relations()],
#'   [postrank_plot_data()]
#' @concept visualization
#' @examples
#' comparison <- postrank_example("comparison_30x3_tau35")
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
#' `autoplot()` (re-exported from [ggplot2::autoplot()]) dispatches stored
#' `postrank` objects to the matching `postrank_plot_*()` function and returns a
#' `ggplot` object. Base R `plot()` uses the same dispatch, prints the figure,
#' and returns the `ggplot` invisibly. Neither method solves or computes new
#' posterior summaries.
#'
#' @param object A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
#'   `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`, or
#'   `postrank_comparison`.
#' @param ... Arguments passed on to the target plotting function. Analyses and
#'   fits accept `type` to select the figure; other arguments (such as `ncol` or
#'   `view`) follow the target `postrank_plot_*()` function.
#' @return For supported `postrank` classes, a `ggplot` object (`plot()` returns
#'   it invisibly after printing).
#' @details
#' Dispatch by class:
#' \itemize{
#'   \item `postrank_analysis`: `type = "report_card"` (default), `"relations"`,
#'     `"profile"`, or `"pairwise"`.
#'   \item `postrank_fit`: `type = "relations"` (default), `"profile"`, or
#'     `"pairwise"`.
#'   \item `postrank_report_card`: [postrank_plot_report_card()].
#'   \item `postrank_baseline`: [postrank_plot_relations()].
#'   \item `postrank_frontier`: [postrank_plot_frontier()].
#'   \item `postrank_commonality_cost`: [postrank_plot_commonality()].
#'   \item `postrank_comparison`: [postrank_plot_compare()].
#' }
#'
#' Objects missing a report card or checked grading return the same status
#' `ggplot` as the underlying `postrank_plot_*()` function, while
#' `type = "pairwise"` remains available on fits without grades.
#' @name reexports
#' @seealso [postrank_plot_report_card()], [postrank_plot_relations()],
#'   [postrank_plot_profile()], [postrank_plot_pairwise()],
#'   [postrank_plot_frontier()], [postrank_plot_compare()],
#'   [postrank_plot_commonality()]
#' @concept visualization
#' @examples
#' one <- postrank_example("tutorial_one")
#' autoplot(one)
#'
#' two <- postrank_example("tutorial_two")
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
