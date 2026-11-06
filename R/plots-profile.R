# Criterion profiles of a stored grade.

#' Plot Criterion-Wise Error Rates or Risk
#'
#' The figure displays criterion-specific expected directional-error rates or
#' risks for the stored grading. Each criterion is represented by one point.
#' Point area indicates a positive criterion weight; zero-weight criteria are
#' retained as small hollow points.
#'
#' @param x A `postrank_fit` or `postrank_analysis` with a stored evaluation.
#' @param show `"E_over_N"` for expected errors per disclosed pair;
#'   `"E_over_M"` for expected errors per all unordered pairs; or `"risk"`
#'   for criterion risk, including the cost of withholding.
#' @param budgets Logical; show available error-budget ticks for
#'   `show = "E_over_N"`.
#' @param ... Unused.
#' @param criterion_labels Optional partial named character vector mapping
#'   raw criterion IDs to display names. Text is wrapped; IDs and numerical
#'   plot data remain unchanged. Supply this argument by name.
#' @return A `ggplot` object. Without a validated incumbent, it is a status
#'   panel. When `N = 0`, the `E_over_N` view explains that the ratio is
#'   undefined and omits the corresponding point.
#' @details
#' `E_k` is the stored expected number of wrong-direction comparisons on
#' criterion `k`, `N` counts disclosed pairs, and `M = choose(n, 2)` counts
#' all unordered pairs. These are posterior expectations for the selected
#' action, not observed error counts. Withholding is not a claim of equality.
#'
#' For `E_over_N`, a declared budget `q_k` appears as a tick connected to its
#' criterion's point. For `risk`, a dashed line marks `tau`, the ordinary
#' all-withheld risk. In minimax mode, orange rings identify criteria attaining
#' the largest criterion risk. All axes begin at zero. The figure reads the
#' stored evaluation without selecting a new grade or recomputing its risk.
#' @seealso [get_profile()], [postrank_plot_data()], [postrank_plot_frontier()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' one <- load_or_compute("tutorial_one")
#' postrank_plot_profile(one)
#' two <- load_or_compute("tutorial_two")
#' postrank_plot_profile(two, show = "E_over_M",
#'   criterion_labels = c(score_A = "Score A", score_B = "Score B"))
#' @export
postrank_plot_profile <- function(x, show = c("E_over_N", "E_over_M", "risk"), budgets = TRUE, ..., criterion_labels = NULL) {
  show <- match.arg(show)
  .pr_assert(inherits(x, c("postrank_fit", "postrank_analysis")), "x must be a postrank_fit or postrank_analysis", "wrong_class", "$.x")
  .pr_assert(is.logical(budgets) && length(budgets) == 1L && !is.na(budgets), "budgets must be TRUE or FALSE", "invalid_display", "$.budgets")
  fit <- .pr_fit_of(x)
  title <- "Criterion error profile"
  if (!isTRUE(fit$incumbent_validated)) return(.pr_status_panel(title, paste0("no validated incumbent",
    if (!is.null(fit$status$normalized)) paste0(" (", gsub("_", " ", fit$status$normalized), ")") else "")))
  pr <- get_profile(fit); ev <- fit$evaluation; tau <- fit$problem$settings$tau
  display <- .pr_relation_profile_labels(pr$criterion, criterion_labels, "criterion_labels", 22L)
  pr$criterion <- factor(pr$criterion, levels = rev(pr$criterion))
  pr$value <- pr[[show]]
  sub <- sprintf("%d/%d pairs disclosed; %d withheld", ev$N, ev$M, ev$M - ev$N)
  if (!is.null(fit$status$normalized) && !identical(fit$status$normalized, "optimal"))
    sub <- paste0(sub, " | ", gsub("_", " ", fit$status$normalized))
  xlab <- switch(show, E_over_N = expression(E[k]/N), E_over_M = expression(E[k]/M), risk = expression(R[k]))
  caption <- switch(show,
    E_over_N = sprintf("E/N: expected errors per disclosed pair (N = %d).", ev$N),
    E_over_M = sprintf("E/M: expected errors per all unordered pairs (M = %d).", ev$M),
    risk = "Criterion risk includes the cost of withheld comparisons. Dashed line = all comparisons withheld.")
  p <- ggplot2::ggplot(pr, ggplot2::aes(y = .data$criterion)) +
    ggplot2::scale_y_discrete(limits = levels(pr$criterion), labels = display)
  if (show == "E_over_N" && ev$N == 0) {
    p <- p + ggplot2::geom_blank() + ggplot2::scale_x_continuous(limits = c(0, 1), expand = ggplot2::expansion(mult = 0))
    sub <- paste(sub, "| E/N NA: no disclosed pairs")
    caption <- "E/N is undefined because no pair is disclosed; no zero error point is substituted."
  } else {
    values <- pr$value
    if (isTRUE(budgets) && show == "E_over_N" && any(!is.na(pr$q))) {
      qd <- pr[!is.na(pr$q), , drop = FALSE]
      values <- c(values, qd$q)
      p <- p + ggplot2::geom_segment(data = qd, ggplot2::aes(x = .data$q, xend = .data$value, yend = .data$criterion), colour = "grey50") +
        ggplot2::geom_point(data = qd, ggplot2::aes(x = .data$q), shape = 124, size = 5, colour = "grey20")
      caption <- paste(caption, "Ticks mark declared error budgets.")
    }
    if (show == "risk") {
      values <- c(values, tau)
      p <- p + ggplot2::geom_vline(xintercept = tau, linetype = "dashed", colour = "grey40")
    }
    upper <- max(values[is.finite(values)], 0)
    upper <- if (upper == 0) 1 else if (show == "risk") upper * 1.12 else min(1, upper * 1.12)
    p <- p + ggplot2::geom_point(data = pr[pr$weight > 0, , drop = FALSE],
      ggplot2::aes(x = .data$value, size = .data$weight), colour = "#153653") +
      ggplot2::scale_size_area(max_size = 5, name = "Criterion weight", breaks = sort(unique(pr$weight[pr$weight > 0])),
        guide = if (nrow(pr) == 1L) "none" else "legend") +
      ggplot2::scale_x_continuous(limits = c(0, upper), expand = ggplot2::expansion(mult = 0),
        breaks = scales::breaks_pretty(n = 3L), labels = scales::label_number()) +
      ggplot2::coord_cartesian(clip = "off")
    zero_weight <- pr[pr$weight == 0 & is.finite(pr$value), , drop = FALSE]
    if (nrow(zero_weight)) {
      p <- p + ggplot2::geom_point(data = zero_weight, ggplot2::aes(x = .data$value),
        shape = 1, size = 2.5, stroke = .6, colour = "#153653", show.legend = FALSE)
      caption <- paste(caption, "Hollow points mark zero-weight criteria.")
    }
    if (identical(fit$problem$settings$objective, "minimax") && any(pr$is_minimax_max)) {
      p <- p + ggplot2::geom_point(data = pr[pr$is_minimax_max, , drop = FALSE], ggplot2::aes(x = .data$value), shape = 1, size = 7, colour = "#D55E00")
      caption <- paste(caption, "Orange rings mark criteria attaining the maximum risk.")
    }
  }
  p + .pr_labs(title = title, subtitle = sub, x = xlab, y = NULL,
    caption = paste(caption, "Withholding is not equality.")) +
    theme_postrank()
}

