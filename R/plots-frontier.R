# Frontier and commonality figures.

#' Plot Disclosure, Error and Risk Across Settings
#'
#' A prepared frontier is displayed over a grid of withholding costs or error
#' budgets. The available panels give disclosure `N/M`, criterion error `E_k/N`
#' and risk at each setting. The figure uses stored results without repeating
#' the grid calculations.
#'
#' @param x A `postrank_frontier` with stored grid results.
#' @param panels Nonempty subset of `"disclosure"`, `"error"` and `"risk"`.
#'   Selected panels retain this standard display order.
#' @param highlight Optional value on the displayed horizontal axis (`tau` or
#'   the varied error budget), marked by a dashed line.
#' @param mark_uncertified Logical; draw rows whose recorded status is not
#'   `"optimal"` hollow. `FALSE` gives every available row its ordinary point
#'   style. This legacy argument name does not imply numerical certification.
#' @param ... Unused.
#' @return A `ggplot` object. When no selected panel has an available value,
#'   a status panel explains the missing incumbent or undefined error rate.
#' @details
#' `M` is the number of all unordered pairs and `N` the number disclosed.
#' Point shape distinguishes grade counts; criterion color and line style
#' identify error series. Rows without an incumbent retain their status in
#' the subtitle and receive no point. Lines stop at unavailable rows and at
#' undefined `E_k/N` when `N = 0`; a single available point has no connecting
#' line. Axes start at zero and adapt to the available values.
#'
#' Changing `tau` changes the loss. Risks at different `tau` values therefore
#' do not rank policies under one shared loss. Changing an error budget changes
#' the feasible action family. If a budget grid contains several `tau` values,
#' they receive separate panel columns rather than a common connecting line.
#'
#' Disclosure is nondecreasing in `tau` for exact optima when all other
#' settings are fixed, but the set of disclosed pairs need not be nested.
#' Recorded optimal statuses and numerical gaps do not establish exact
#' monotonicity of the displayed actions or posterior validity. Available
#' statuses and gaps remain visible even when points are styled alike.
#' @seealso [postrank_frontier()], [postrank_plot_data()], [postrank_plot_profile()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' frontier <- load_or_compute("tutorial_frontier")
#' postrank_plot_frontier(frontier, highlight = .2)
#' @export
postrank_plot_frontier <- function(x, panels = c("disclosure", "error", "risk"), highlight = NULL, mark_uncertified = TRUE, ...) {
  .pr_assert(inherits(x, "postrank_frontier"), "x must be a postrank_frontier", "wrong_class", "$.x")
  .pr_assert(is.character(panels) && length(panels) >= 1L && all(panels %in% c("disclosure", "error", "risk")) && !anyDuplicated(panels),
    "panels must be a subset of disclosure, error, risk", "invalid_display", "$.panels")
  t <- x$table
  axis <- if (is.null(x$q_criterion)) "tau" else "q_value"
  ks <- sub("^E_over_N_", "", grep("^E_over_N_", names(t), value = TRUE))
  ok <- !is.na(t$G)
  cert <- t$status %in% "optimal"
  rows <- list()
  tau_lab <- paste0("tau = ", format(t$tau))
  if ("disclosure" %in% panels) rows[[length(rows) + 1L]] <- data.frame(x = t[[axis]], panel = "disclosure N/M", series = "N/M",
    value = t$disclosure_rate, G = t$G, certified = cert, tau_lab = tau_lab, stringsAsFactors = FALSE)
  if ("error" %in% panels) for (k in ks) rows[[length(rows) + 1L]] <- data.frame(x = t[[axis]], panel = "error E_k/N",
    series = k, value = t[[paste0("E_over_N_", k)]], G = t$G, certified = cert, tau_lab = tau_lab, stringsAsFactors = FALSE)
  if ("risk" %in% panels) rows[[length(rows) + 1L]] <- data.frame(x = t[[axis]], panel = "risk", series = "risk",
    value = t$primary_risk, G = t$G, certified = cert, tau_lab = tau_lab, stringsAsFactors = FALSE)
  d <- do.call(rbind, rows)
  d$available <- is.finite(d$value) & !is.na(d$G)
  title <- "Disclosure and error frontier"
  if (!any(d$available)) return(.pr_status_panel(title, "no grid point has a value for the selected panels (no incumbent, or nothing disclosed)"))
  # On a q grid, rows with different tau are different losses: they get separate panels, never one line.
  by_tau <- axis == "q_value" && length(unique(t$tau)) > 1L
  d$panel <- factor(d$panel, levels = c("disclosure N/M", "error E_k/N", "risk")[c("disclosure", "error", "risk") %in% panels])
  d$G <- factor(d$G); if (!isTRUE(mark_uncertified)) d$certified <- TRUE
  missing <- t[!ok, , drop = FALSE]
  sub <- sprintf("%d grid points over %s", nrow(t), if (axis == "tau") "tau" else paste0("q_", x$q_criterion))
  if (axis == "q_value") sub <- paste0(sub, if (by_tau) " | one panel column per tau (different losses)" else paste0(" | tau ", format(unique(t$tau))))
  shapes <- c(16, 17, 15, 18, 3, 4, 8, 7, 9, 10, 12, 13, 14, 0, 1, 2, 5, 6)
  many_G <- nlevels(d$G) > length(shapes)
  if (many_G) sub <- paste0(sub, " | grade counts G in the table (more than ", length(shapes), " values)")
  if (nrow(missing)) sub <- paste0(sub, sprintf(" | %d without incumbent (%s)", nrow(missing), paste(unique(missing$status), collapse = ", ")))
  unfinished <- which(ok & !cert)
  if (length(unfinished)) sub <- paste0(sub, " | unfinished: ", paste(vapply(unfinished, function(i)
    paste0(if (by_tau) paste0("tau ", t$tau[i], ", ") else "", if (axis == "tau") "tau " else "q ",
      t[[axis]][i], " ", t$status[i], " (gap ", .pr_fmt(t$risk_absolute_gap[i], "gap"), ")"), ""), collapse = "; "))
  gaps <- t$risk_absolute_gap[ok & is.finite(t$risk_absolute_gap)]
  if (!length(unfinished) && length(gaps)) sub <- paste0(sub, " | available points: optimal (numerical); max gap ", .pr_fmt(max(gaps), "gap"))
  n_zero <- sum(t$N == 0, na.rm = TRUE)
  if ("error" %in% panels && n_zero) sub <- paste0(sub, " | E/N undefined at ", n_zero, " grid points with N=0")
  if (!is.null(highlight)) sub <- paste0(sub, " | highlighted ", axis, " = ", format(highlight))
  # Internal keys separate criterion IDs from the two aggregate metric labels.
  criterion_keys <- paste0("criterion:", seq_along(ks))
  d$series_id <- ifelse(as.character(d$panel) == "error E_k/N", criterion_keys[match(d$series, ks)],
    ifelse(as.character(d$panel) == "risk", "metric:risk", "metric:disclosure"))
  colours <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#D55E00", "#F0E442")
  if (length(ks) > length(colours)) colours <- grDevices::hcl.colors(length(ks), "Dark 3")
  lines <- rep_len(c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "11"), length(ks))
  policy_group <- if (by_tau) paste(d$series_id, d$tau_lab) else d$series_id
  # Keep unavailable rows until consecutive runs are known. Dropping them first
  # would connect the valid observations on either side of a missing solve.
  d$line_group <- character(nrow(d))
  for (key in unique(policy_group)) {
    ii <- which(policy_group == key); ii <- ii[order(d$x[ii])]
    d$line_group[ii] <- paste(key, cumsum(!d$available[ii]), sep = ":run:")
  }
  line_data <- d[d$available, , drop = FALSE]
  counts <- table(line_data$line_group)
  line_data <- line_data[counts[line_data$line_group] >= 2L, , drop = FALSE]
  point_data <- d[d$available, , drop = FALSE]
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$value, group = .data$line_group)) +
    ggplot2::geom_line(data = line_data, ggplot2::aes(colour = .data$series_id, linetype = .data$series_id), linewidth = 0.5) +
    (if (many_G) ggplot2::geom_point(data = point_data[point_data$certified, , drop = FALSE], ggplot2::aes(colour = .data$series_id), shape = 16, size = 2)
     else ggplot2::geom_point(data = point_data[point_data$certified, , drop = FALSE], ggplot2::aes(colour = .data$series_id, shape = .data$G), size = 2)) +
    ggplot2::geom_point(data = point_data[!point_data$certified, , drop = FALSE], ggplot2::aes(colour = .data$series_id), shape = 1, size = 2.4) +
    (if (by_tau) ggplot2::facet_grid(panel ~ tau_lab, scales = "free_y", labeller = ggplot2::labeller(panel = c(`disclosure N/M` = "disclosure N/M", `error E_k/N` = "error E_k/N", risk = "risk at each policy"))) else ggplot2::facet_wrap(~ panel, scales = "free_y", ncol = 1,
      labeller = ggplot2::as_labeller(c(`disclosure N/M` = "disclosure N/M", `error E_k/N` = "error E_k/N", risk = "risk at each policy")))) +
    ggplot2::scale_y_continuous(limits = function(limits) {
      upper <- max(limits[is.finite(limits)], 0)
      c(0, if (upper == 0) 1 else min(1, upper * 1.12))
    }, expand = ggplot2::expansion(mult = 0), breaks = scales::breaks_pretty(n = 3L),
      labels = scales::label_number()) +
    ggplot2::scale_colour_manual(values = c(`metric:disclosure` = "grey30", `metric:risk` = "grey30",
      stats::setNames(colours[seq_along(ks)], criterion_keys)),
      breaks = criterion_keys, labels = ks, name = "criterion") +
    (if (nrow(line_data)) ggplot2::scale_linetype_manual(values = c(`metric:disclosure` = "solid", `metric:risk` = "solid",
      stats::setNames(lines, criterion_keys)), breaks = criterion_keys, labels = ks, name = "criterion")) +
    ggplot2::scale_shape_manual(values = shapes[seq_len(min(nlevels(d$G), length(shapes)))], name = "grades G", drop = FALSE) +
    .pr_labs(title = title, subtitle = sub, x = if (axis == "tau") expression(tau) else paste0("q_", x$q_criterion), y = NULL,
      caption = paste(if (axis == "tau") "Changing tau changes the loss: risks do not rank policies on a shared loss." else
        "Changing q changes the feasible set; changing tau changes the loss.",
        "M = all unordered pairs; N = disclosed pairs. Lines join adjacent available results only.",
        if (isTRUE(mark_uncertified)) "Hollow = status other than optimal; optimal is numerical." else
          "Point styles do not encode status; optimal is numerical.")) +
    ggplot2::coord_cartesian(clip = "off") + theme_postrank()
  if (!is.null(highlight)) p <- p + ggplot2::geom_vline(xintercept = highlight, linetype = "dashed", colour = "grey40")
  p
}

#' Plot the Extra Criterion Risk of a Common Grading
#'
#' The criterion-specific increase in risk under the stored common action is
#' compared with a criterion-specific optimization. Bounds for the increase are
#' obtained from each criterion's own optimization. The intervals represent
#' numerical optimization uncertainty rather than posterior uncertainty about
#' targets or grades.
#'
#' @param x A `postrank_commonality_cost` with stored common-action evaluations
#'   and criterion-specific optimization results.
#' @param ... Unused.
#' @return A `ggplot` object with one labeled row per criterion. A finite
#'   `cost_lower` is shown as a hollow point; the segment to `cost_upper` appears
#'   only when both endpoints are available. Missing bounds remain unavailable.
#' @details
#' The lower endpoint is `max(0, common_grade_risk - own_best_risk)`: it
#' subtracts the criterion's own incumbent risk and is clipped at zero because
#' the common action is available in that comparison family. The upper endpoint
#' subtracts the own solve's lower bound. Thus the own incumbent is not assumed to equal
#' the unknown minimum. A zero line provides a reference, and labels retain
#' the own solve's status and available absolute risk gap. The comparison
#' inherits the stored action families, protection setting and numerical
#' limitations; the plot does not perform another criterion-specific solve.
#' @seealso [postrank_commonality_cost()], [postrank_plot_data()],
#'   [postrank_plot_compare()]
#' @concept visualization
#' @examples
#' # Read prepared tutorial results; no model fitting or optimization.
#' source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
#'   local = TRUE)
#' commonality <- load_or_compute("tutorial_commonality")
#' postrank_plot_commonality(commonality)
#' @export
postrank_plot_commonality <- function(x, ...) {
  .pr_assert(inherits(x, "postrank_commonality_cost"), "x must be a postrank_commonality_cost", "wrong_class", "$.x")
  d <- x$table; d$criterion_id <- factor(d$criterion_id, levels = rev(d$criterion_id))
  no_upper <- d$criterion_id[is.na(d$cost_upper)]
  s <- x$settings
  sub <- sprintf("tau %s | grade cap %s | protection = %s", format(s$tau), s$G_max, x$protection)
  if (length(no_upper)) sub <- paste0(sub, " | upper bound unavailable: ", paste(no_upper, collapse = ", "))
  own_gap <- d$own_best_risk - d$own_lower_bound
  labels <- stats::setNames(paste0(as.character(d$criterion_id), "\n", d$own_status,
    ifelse(d$own_status == "optimal", " (numerical)", ""), "\ngap ",
    ifelse(is.finite(own_gap), .pr_fmt(own_gap, "gap"), "unavailable")), as.character(d$criterion_id))
  ggplot2::ggplot(d, ggplot2::aes(y = .data$criterion_id)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50") +
    ggplot2::geom_segment(data = d[is.finite(d$cost_lower) & is.finite(d$cost_upper), , drop = FALSE],
      ggplot2::aes(x = .data$cost_lower, xend = .data$cost_upper, yend = .data$criterion_id), colour = "#153653", linewidth = 0.8) +
    ggplot2::geom_point(data = d[is.finite(d$cost_lower), , drop = FALSE], ggplot2::aes(x = .data$cost_lower), shape = 21, fill = "white", colour = "#153653", size = 2.6) +
    ggplot2::scale_y_discrete(labels = labels, drop = FALSE) +
    ggplot2::scale_x_continuous(breaks = scales::breaks_pretty(n = 3L), labels = function(values) {
      magnitude <- max(abs(values[is.finite(values)]), 0)
      if (magnitude > 0 && magnitude < 1e-3) scales::label_scientific(digits = 2)(values)
      else scales::label_number()(values)
    }) +
    .pr_labs(title = "Cost of a common grade", subtitle = sub, x = "extra criterion risk", y = NULL,
      caption = "Extra criterion risk from using the common action. Endpoints come from the own solve's incumbent and lower bound; these are solver bounds, not posterior intervals.") +
    theme_postrank()
}
