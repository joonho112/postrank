# Result-first English console (Chapter 13, PR-DEC-13-A). For every print-bearing class:
# format_postrank_<class>_cli() builds the lines, format.<class>() returns them and
# print.<class>() writes them and returns the object invisibly. summary.<class>() returns
# a typed postrank_<class>_summary. All are pure views over stored slots.

#' Format postrank Results for Reading in the Console
#'
#' The `print(x)` method gives a concise display, `summary(x)` describes the
#' results and settings, and `format(x)` returns the display as text. The
#' methods use stored results without optimization or recalculation of
#' posterior probabilities. Grade 1 has highest priority and shared grades
#' withhold comparisons. Valid all-withheld grades are distinguished from fits
#' for which no validated grades are available.
#'
#' @param x An object of the class named by the formatter. A wrong class
#'   raises `wrong_class`.
#' @param ... Additional display arguments.
#' @param details For the summary formatter, include technical source records
#'   and identities. `NULL` follows the summary object's stored preference.
#' @param width Line width; `NULL` follows `getOption("width")`. Widths are
#'   floored at 40 characters.
#' @param tier Styling: `NULL` detects the context, `1` uses ANSI styling,
#'   `2` is plain text, and `3` is for knitted documents.
#' @param n_head Maximum number of rows displayed in table bodies. This affects
#'   applicable displays only; it does not select or remove stored entities.
#' @return Each formatter returns a character vector with one element per
#'   console line. The matching `format()` method returns the same lines for
#'   the same arguments. `print()` writes those lines and invisibly returns
#'   its input. `summary()` returns a structured summary with its own display.
#' @details Default summaries emphasize grades, disclosure, expected loss and
#'   solver qualifications. Use `summary(x, details = TRUE)` to add technical
#'   details; structured fields remain available with either display setting.
#'   An optimization gap concerns the supplied numerical problem, separately
#'   from posterior uncertainty and Monte Carlo error.
#'
#'   Large grade memberships and table bodies may be shortened for reading.
#'   Accessors and [postrank_tables] return the complete stored results, so use
#'   those for calculations, row selection or export. Console text is not a
#'   stable data format. Fix `width` and `tier = 2` when saving plain text.
#'
#'   Styling tiers have the same content; stripping tier 1's ANSI styling gives
#'   tier 2. Entity IDs and stored warning text are preserved. The named
#'   formatter functions on this page remain available alongside `format()`.
#'   The validation formatter handles input and solution validations; the
#'   guarantee formatter handles conditional risk, regret and protection
#'   records; the summary formatter handles structured summaries.
#' @seealso [get_grades()], [get_profile()], [get_risk()], [postrank_report()]
#' @name format_postrank_cli
#' @concept reporting
#' @examples
#' lines <- format(pr_tutorial$one, width = 72, tier = 2)
#' cat(lines, sep = "\n")
#' identical(lines,
#'   format_postrank_coefficients_cli(pr_tutorial$one, width = 72, tier = 2))
#' summary(pr_tutorial$one)
#' technical <- summary(pr_tutorial$one, details = TRUE)
#' names(technical)
NULL

.pr_status_words <- function(status) {
  labels <- c(optimal = "Optimal within solver tolerances", feasible_not_certified = "Feasible grades; optimality not established",
    time_limit = "Time limit reached", infeasible = "No grades satisfy the requested constraints",
    unbounded = "Solver reported an unbounded problem", numerical_error = "Numerical checks require attention",
    unknown = "Solver outcome is unknown")
  if (is.null(status) || !length(status) || is.na(status)) return("Solver outcome is unavailable")
  if (status %in% names(labels)) unname(labels[[status]]) else gsub("_", " ", status)
}
.pr_criteria_words <- function(ids) {
  if (length(ids) == 1L) paste0("One criterion: ", ids, ".") else paste0(length(ids), " criteria: ", paste(ids, collapse = ", "), ".")
}
.pr_loss_words <- function(objective) if (identical(objective, "minimax")) "Largest criterion loss" else "Posterior loss"
.pr_gap_lines <- function(fit, requested_gap = NULL, full = FALSE) {
  o <- fit$objective
  lines <- paste0("Solver: ", .pr_status_words(fit$status$normalized), ".")
  if (is.finite(o$risk_absolute_gap %||% NA_real_))
    lines <- c(lines, paste0("Optimization gap: ", .pr_fmt(o$risk_absolute_gap, "gap"),
      if (!is.null(requested_gap)) paste0("; requested absolute gap ", .pr_fmt(requested_gap, "gap")) else "", "."))
  else lines <- c(lines, if (is.finite(o$risk_lower_bound %||% NA_real_))
    paste0("Lower bound: ", .pr_fmt(o$risk_lower_bound, "risk"), "; optimization gap is NA without validated grades.") else
      "Optimization gap: NA; no usable lower bound is available.")
  if (full) lines <- c(lines,
    paste0("Loss upper bound: ", .pr_fmt(o$risk_upper_bound, "risk"),
      "; lower bound: ", .pr_fmt(o$risk_lower_bound, "risk"), "."),
    paste0("Solver: ", fit$backend$name %||% "unrecorded", "; elapsed time ", .pr_fmt(fit$runtime, "num"), " seconds."),
    "The gap concerns optimization of the supplied probabilities. It does not measure posterior uncertainty or Monte Carlo error.")
  lines
}
.pr_fit_result_lines <- function(fit) {
  ev <- fit$evaluation; ok <- isTRUE(fit$incumbent_validated) && !is.null(fit$grade)
  pw <- fit$problem$pairwise
  if (!ok) return(c(paste0(length(pw$entity_ids), " entities. ", .pr_criteria_words(pw$criterion_ids)),
    "No validated grades are available. Loss, grade sizes and disclosed comparisons are unavailable."))
  c(.pr_criteria_words(pw$criterion_ids),
    paste0(.pr_loss_words(fit$problem$settings$objective), ": ", .pr_fmt(fit$objective$primary_action_risk, "risk"),
      if (!identical(fit$status$normalized, "optimal")) " (the validated action's upper bound)" else "", "."),
    if (identical(fit$problem$settings$objective, "minimax"))
      paste0("Weighted average loss: ", .pr_fmt(fit$objective$weighted_auxiliary_risk, "risk"), "."),
    paste0("Disclosed ", .pr_fmt(ev$N, "count"), " of ", .pr_fmt(ev$M, "count"), " pairs (", .pr_fmt(ev$disclosure_rate, "pct"),
      "); withheld ", .pr_fmt(ev$M - ev$N, "count"), "."),
    if (ev$N == 0) "Expected error among disclosed pairs: NA (N = 0); no pairs were disclosed." else
      paste0("Expected error among disclosed pairs: ", paste(names(ev$E_over_N), .pr_fmt(ev$E_over_N, "ratio"), collapse = "; "), "."),
    if (ev$N == 0) "A single shared grade withholds every comparison; it is not an error-free ranking.")
}
.pr_extra_words <- function(name, record) {
  label <- c(report_card = "Report card", fragility = "Monte Carlo fragility", crossfit = "Cross-fit check", diagnostics = "Monte Carlo diagnostics")[[name]]
  reason <- record$reason %||% "unavailable"
  value <- if (isTRUE(record$available)) "available" else switch(reason,
    not_requested = "not requested", no_validated_incumbent = "unavailable without validated grades",
    supplied_marginal_intervals_unavailable = "unavailable; marginal intervals were not supplied",
    supplied_probabilities_have_no_target_draws = "unsupported; the input contains probabilities, not target draws",
    unsupported_input_kind = "unsupported for this input", extra_error = "unavailable; its calculation failed",
    gsub("_", " ", reason))
  paste0(label, ": ", value, ".")
}
.pr_fmt_fit_lines <- function(fit, width, requested_gap = NULL, cls = "postrank_fit", extra = character(), pointer = NULL,
                              warnings = fit$warnings) {
  ok <- isTRUE(fit$incumbent_validated) && !is.null(fit$grade)
  head <- if (!ok) "No validated grades" else if (fit$evaluation$G == 1L)
    sprintf("%d entities in 1 grade; all comparisons withheld", length(fit$grade)) else
    sprintf("%d entities in %d grades (sizes %s)", length(fit$grade), fit$evaluation$G, .pr_grade_sizes(fit$grade))
  c(.pr_cli_header(cls, head), .pr_cli_line(.pr_fit_result_lines(fit)),
    .pr_cli_line(.pr_gap_lines(fit, requested_gap)), extra,
    if (ok) .pr_cli_line("Grade 1 has highest priority; a shared grade withholds the comparison."),
    if (ok) .pr_members(fit$grade, fit$problem$pairwise$entity_ids, width),
    .pr_cli_warning_line(warnings, width),
    .pr_cli_pointer(pointer %||% "summary(x) explains the loss, settings and bounds; get_grades(x) returns all grades."))
}

#' @rdname format_postrank_cli
#' @export
format_postrank_fit_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_fit", "format_postrank_fit_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(.pr_fmt_fit_lines(x, width), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_analysis_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_analysis", "format_postrank_analysis_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  available <- names(x$extras)[vapply(x$extras, function(r) isTRUE(r$available), TRUE)]
  extra <- if (length(available)) paste0("Prepared: ", paste(gsub("_", " ", available), collapse = ", "), ".") else
    "No optional result tables or checks are available; see summary(x) for reasons."
  .pr_cli_finish(.pr_fmt_fit_lines(x$fit, width, requested_gap = x$control$absolute_risk_gap, cls = "postrank_analysis",
    extra = .pr_cli_line(extra), warnings = x$warnings), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_draws_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_draws","format_postrank_draws_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  sampling <- if(identical(x$input_kind,"exact_finite_posterior")) paste0(length(x$finite_law$states)," states with declared exact finite probabilities.") else
    if(identical(x$dependence_mode,"joint_model")) paste0(dim(x$joint_draws$tensor$values)[1L]," retained ",
      toupper(x$joint_draws$sampling$regime)," draws; each draw contains all entities and criteria.") else
      paste0("Separate criterion histories: ",paste(vapply(x$criterion_blocks,function(b) paste0(b$criterion_id," (",b$matrix$shape$S," draws)"),""),collapse="; "),".")
  .pr_cli_finish(c(.pr_cli_header("postrank_draws",paste0(length(x$entity_ids)," entities with posterior input")),
    .pr_cli_line(.pr_criteria_words(x$criterion_ids)),.pr_cli_line(sampling),
    .pr_cli_line("The input structure has been checked. The declared sampling history and statistical model have not been independently verified."),
    .pr_cli_pointer("summary(x) describes the targets; details = TRUE adds source records.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_validation_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,c("postrank_validation","postrank_solution_validation"),"format_postrank_validation_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  solution <- inherits(x,"postrank_solution_validation"); issues <- length(x$issues)
  .pr_cli_finish(c(.pr_cli_header(if(solution)"postrank_solution_validation" else "postrank_validation",
    if(isTRUE(x$valid)) "Checks passed" else "Checks found a problem"),
    .pr_cli_line(issues," issue",if(issues==1L)" recorded." else "s recorded."),
    .pr_cli_line(if(solution) "These checks concern the returned grades and numerical constraints." else
      "These checks concern input structure and required declarations."),
    .pr_cli_line("They do not verify the statistical model or sampling history."),
    .pr_cli_pointer("x$issues records any failures; summary(x, details = TRUE) adds the technical record.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_pairwise_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_pairwise","format_postrank_pairwise_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  supplied <- inherits(x,"postrank_probabilities")
  .pr_cli_finish(c(.pr_cli_header(if(supplied)"postrank_probabilities" else "postrank_pairwise",
    paste0(length(x$entity_ids)," entities with directional-error probabilities")),
    .pr_cli_line(.pr_criteria_words(x$criterion_ids)),
    .pr_cli_line("e[i,j,k] is the probability that entity i does not exceed j on criterion k. Larger targets have higher priority; diagonal entries are NA."),
    if(supplied) .pr_cli_line(c("Probabilities were supplied directly; no target draws or sample sizes are inferred.",
      "Supported decisions use weighted loss and an upper limit on grades.",
      if(is.null(x$summaries)) "Marginal means and intervals were not supplied." else if(is.null(x$summaries$level))
        "Marginal means were supplied; intervals were not." else paste0("Marginal means and fixed ",.pr_fmt(x$summaries$level,"pct")," intervals were supplied."),
      if(identical(x$correction$method,"symmetric")) "Small reverse-probability discrepancies were corrected explicitly; the raw values remain stored.")) else
      .pr_cli_line(if(!is.null(x$exact)) "Exact finite-law coefficients are retained alongside their numeric representation." else "The probabilities summarize the retained posterior draws."),
    .pr_cli_pointer("x$e contains the probability array; summary(x) describes the input.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_coefficients_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_coefficients","format_postrank_coefficients_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(c(.pr_cli_header("postrank_coefficients",paste0(length(x$entity_ids)," entities under a declared conditional law")),
    .pr_cli_line(.pr_criteria_words(x$criterion_ids)),
    .pr_cli_line(if(identical(x$input_kind,"gaussian_conditional")) "Gaussian comparison probabilities and marginal summaries are available." else
      "Shared-state mixture probabilities and marginal summaries are available."),
    .pr_cli_line("Supported decisions use weighted loss and an upper limit on grades. Target draws, q constraints, exact grade counts and minimax decisions are unsupported here."),
    .pr_cli_pointer("summary(x, details = TRUE) retains the conditional-law declarations and source records.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_coefficient_diagnostics_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_coefficient_diagnostics","format_postrank_coefficient_diagnostics_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); m <- x$diagnostics$mcse_mean
  .pr_cli_finish(c(.pr_cli_header("postrank_coefficient_diagnostics","Conditional expected-loss checks"),
    .pr_cli_line("Weighted posterior loss: ",.pr_fmt(x$evaluation$weighted_risk,"risk"),"."),
    .pr_cli_line("Monte Carlo standard error: ",.pr_metric_text(m),"."),
    .pr_cli_line("These checks concern integration over shared parameter states. They do not create target draws or verify convergence."),
    .pr_cli_warning_line(x$warnings,width),.pr_cli_pointer("summary(x) explains available and unavailable diagnostics.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_declarations_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_declarations","format_postrank_declarations_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(c(.pr_cli_header("postrank_declarations","Required source declarations are recorded"),
    .pr_cli_line("Their presence does not verify the target definitions, model or sampling history."),
    .pr_cli_pointer("Inspect the structured declaration fields for the supplied descriptions.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_settings_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_settings", "format_postrank_settings_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  weights <- data.frame(Criterion = names(x$weights) %||% as.character(seq_along(x$weights)), Weight = unname(x$weights))
  .pr_cli_finish(c(.pr_cli_header("postrank_settings", "Choices for the grading decision"),
    .pr_cli_line(.pr_policy_lines(x)), .pr_table_lines(weights, n_head, width),
    .pr_cli_line("Tau prices a withheld comparison; it is not an error-rate limit."),
    .pr_cli_warning_line(x$warnings, width), .pr_cli_pointer("Use these choices with postrank(settings = x).")), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_control_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_control", "format_postrank_control_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(c(.pr_cli_header("postrank_control", "Computation settings"),
    .pr_cli_line("Time limit: ", .pr_fmt(x$time_limit, "num"), " seconds; ", x$threads,
      if (x$threads == 1L) " thread." else " threads."),
    .pr_cli_line("Search: ", if (identical(x$strategy, "label_mip")) "joint integer optimization." else "candidate search, relaxation bounds and optional integer optimization."),
    .pr_cli_line("Absolute loss gap: ", .pr_fmt(x$absolute_risk_gap, "gap"), "; relative objective gap: ", .pr_fmt(x$relative_gap, "gap"), "."),
    .pr_cli_line("Progress messages: ", if (is.null(x$verbose)) "inherit option (quiet by default)" else if (isTRUE(x$verbose)) "on" else "off", "."),
    .pr_cli_line("Solver output: ", if (isTRUE(x$output)) "on." else "off."),
    .pr_cli_pointer("summary(x, details = TRUE) shows the seed, search options and tolerances.")), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_problem_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_problem", "format_postrank_problem_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(c(.pr_cli_header("postrank_problem", "Ready to solve; no grades calculated yet"),
    .pr_cli_line(length(x$pairwise$entity_ids), " entities; ", .pr_fmt(x$M, "count"), " unordered pairs."),
    .pr_cli_line(.pr_criteria_words(x$pairwise$criterion_ids)), .pr_cli_line(.pr_policy_lines(x$settings)),
    .pr_cli_pointer("postrank_solve(x, backend = \"highs\") solves this problem with HiGHS.")), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_report_card_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_report_card", "format_postrank_report_card_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); n_head <- .pr_cli_n_head(n_head)
  d <- x$data; n <- nrow(d); ks <- names(x$settings$weights)
  tab <- d[, c("entity_id", "grade", "n_above", "n_below", "n_withheld"), drop = FALSE]
  names(tab) <- c("Entity", "Grade", "Above", "Below", "Withheld")
  .pr_cli_finish(c(.pr_cli_header("postrank_report_card", sprintf("%d entities with grades and marginal intervals", n)),
    .pr_cli_line(.pr_fmt(x$level, "pct"), " central intervals; ",
      if (identical(x$interval_source, "supplied_marginal_summaries")) "summaries supplied by the caller." else "summaries of the declared posterior."),
    .pr_table_lines(tab, n_head, width),
    .pr_cli_line("Above and below count disclosed relations; withheld counts entities sharing the grade."),
    .pr_cli_pointer("as.data.frame(x) includes every criterion's mean, interval and expected rank.")), width, tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_baseline_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_baseline", "format_postrank_baseline_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); ev <- x$evaluation
  .pr_cli_finish(c(.pr_cli_header("postrank_baseline", paste0(length(x$grade), " entities in ", ev$G,
    if (ev$G == 1L) " grade" else " grades", " (sizes ", .pr_grade_sizes(x$grade), ")")),
    .pr_cli_line("Score order: ", gsub("_", " ", x$method), "; ", x$cut_rule, " cuts."),
    .pr_cli_line("Posterior loss: ", .pr_fmt(x$risk, "risk"), ". Disclosed ", .pr_fmt(ev$N,"count"), " of ",
      .pr_fmt(ev$M,"count"), " pairs (", .pr_fmt(ev$disclosure_rate,"pct"), "); withheld ", .pr_fmt(ev$M-ev$N,"count"), "."),
    .pr_cli_line(if (identical(x$cut_rule, "optimal")) "The cuts minimize loss within this score order. Other orders were not searched." else
      "Quantile cuts divide this score order by position; they do not minimize posterior loss."),
    .pr_cli_line("Equal scores stay together. Grade 1 has highest priority."),
    .pr_cli_warning_line(x$warnings,width), .pr_cli_pointer("get_grades(x) returns every grade; postrank_compare() compares methods under one loss.")), width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_comparison_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x, "postrank_comparison", "format_postrank_comparison_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); n_head <- .pr_cli_n_head(n_head)
  t <- data.frame(Method=x$table$method, Loss=.pr_fmt(x$table$risk,"risk"),
    Disclosed=.pr_fmt(x$table$disclosure_rate,"pct"), Grades=x$table$G,
    Status=vapply(x$table$status,.pr_status_words,""), stringsAsFactors=FALSE)
  recorded <- all(c("family_feasible","feasibility_reason") %in% names(x$table))
  outside <- if(recorded) x$table[x$table$family_feasible %in% FALSE,,drop=FALSE] else x$table[FALSE,,drop=FALSE]
  if (recorded) t$Constraints <- ifelse(is.na(x$table$family_feasible),"unknown",ifelse(x$table$family_feasible,"within","outside"))
  ag <- x$relations
  changed <- if(nrow(ag)) paste0(ag$method, ": ", .pr_fmt(ag$agreement,"pct"), " of pair relations agree with ", x$reference,
    "; ", .pr_fmt(ag$n_new_disclosed+ag$n_new_withheld+ag$n_reversed,"count"), " changed.") else character()
  .pr_cli_finish(c(.pr_cli_header("postrank_comparison", sprintf("%d methods on one posterior and loss",nrow(t))),
    .pr_cli_line("Reference method: ",x$reference,". The weights and withholding cost are held fixed."),
    .pr_table_lines(t,n_head,width), .pr_cli_line(changed),
    if(nrow(outside)) .pr_cli_line("Outside declared family: ",paste0(outside$method," (",outside$feasibility_reason,")",collapse="; "),"."),
    if(!recorded) .pr_cli_line("Constraint membership was not recorded; recreate the comparison to check it."),
    .pr_cli_line("A score-order baseline searches only partitions of its declared order. Rows outside the constraints are not eligible solutions."),
    if(any(!is.na(x$table$reason))) .pr_cli_line("No grades available for: ",paste(x$table$method[!is.na(x$table$reason)],collapse=", "),"."),
    .pr_cli_warning_line(x$warnings,width), .pr_cli_pointer("x$table retains bounds, constraints and reasons; x$relations retains pair counts.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_frontier_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_frontier","format_postrank_frontier_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); t <- x$table
  shown <- data.frame(Tau=t$tau, Loss=.pr_fmt(t$primary_risk,"risk"), Disclosed=.pr_fmt(t$disclosure_rate,"pct"),
    Grades=t$G, Gap=.pr_fmt(t$risk_absolute_gap,"gap"), stringsAsFactors=FALSE)
  if(!is.null(x$q_criterion)) shown$`Error limit` <- t$q_value
  .pr_cli_finish(c(.pr_cli_header("postrank_frontier",paste0(nrow(t)," choices of withholding cost",if(!is.null(x$q_criterion)) " and error limit" else "")),
    if(!is.null(x$q_criterion)) .pr_cli_line("Error limit applies to ",x$q_criterion,"."),
    .pr_table_lines(shown,n_head,width),
    .pr_cli_line("Changing tau changes the loss. Compare grades and disclosure across rows; do not rank methods by losses computed at different tau values."),
    .pr_cli_line("Solver gaps limit comparisons; missing bounds or grades leave the corresponding conclusions unavailable."),
    .pr_cli_pointer("x$table retains each status, criterion loss and error among disclosed pairs.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_commonality_cost_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_commonality_cost","format_postrank_commonality_cost_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); t <- x$table
  shown <- data.frame(Criterion=t$criterion_id, `Common loss`=.pr_fmt(t$common_grade_risk,"risk"),
    `Own loss`=.pr_fmt(t$own_best_risk,"risk"), `Cost lower`=.pr_fmt(t$cost_lower,"risk"),
    `Cost upper`=.pr_fmt(t$cost_upper,"risk"), check.names=FALSE)
  .pr_cli_finish(c(.pr_cli_header("postrank_commonality_cost",paste0(nrow(t)," criteria sharing one grade assignment")),
    .pr_cli_line("Each criterion's separate calculation uses the same withholding cost and grade limit."),
    .pr_cli_line("Criterion error limits in separate calculations: ",if(identical(x$protection,"keep")) "retained." else "removed."),
    .pr_table_lines(shown,n_head,width),
    .pr_cli_line("Own loss is the best validated separate action. Cost limits use its solver lower bound, so an unfinished solve can leave a range or NA."),
    .pr_cli_pointer("x$table also records solver status, disclosure and agreement for each separate calculation.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_sensitivity_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_sensitivity","format_postrank_sensitivity_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  t <- data.frame(Setting=x$grid$label,Loss=.pr_fmt(x$table$risk,"risk"),Disclosed=.pr_fmt(x$table$disclosure_rate,"pct"),
    Grades=x$table$G,Changed=.pr_fmt(x$changes$change_fraction,"pct"),stringsAsFactors=FALSE)
  ref <- match(x$reference_id,x$grid$setting_id)
  label <- if(length(ref)==1L && !is.na(ref)) x$grid$label[ref] else "the declared reference setting"
  .pr_cli_finish(c(.pr_cli_header("postrank_sensitivity",paste0(nrow(t)," grading settings")),
    .pr_cli_line("Reference: ",label,". Changed is the fraction of pair relations that differ."),
    .pr_table_lines(t,n_head,width),
    .pr_cli_line("Changing weights or tau changes the loss. Use these rows to assess decision changes, not to rank methods under different losses."),
    .pr_cli_warning_line(x$warnings,width), .pr_cli_pointer("x$grid retains each complete setting; x$table retains solver statuses and bounds.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_crossfit_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_crossfit","format_postrank_crossfit_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  tab <- do.call(rbind,lapply(x$folds,function(f) data.frame(Fold=f$fold,
    `Training loss`=.pr_fmt(f$in_fold_risk,"risk"),`Held-out loss`=.pr_fmt(f$out_of_fold_risk,"risk"),
    Optimism=.pr_fmt(f$optimism,"risk"),Status=.pr_status_words(f$status),check.names=FALSE)))
  .pr_cli_finish(c(.pr_cli_header("postrank_crossfit",paste0(length(x$folds)," posterior-draw folds")),
    .pr_cli_line("Fold sizes: ",paste(x$split$sizes,collapse=" / "),"; split: ",gsub("_"," ",x$split$method),"."),
    .pr_table_lines(tab,n_head,width),
    .pr_cli_line("Each grade is chosen on its training fold and evaluated on held-out posterior draws. This is not a check on new observed data."),
    .pr_cli_line("Mean optimism: ",.pr_fmt(x$mean_optimism,"risk"),"; mean absolute optimism: ",.pr_fmt(x$mean_abs_optimism,"risk"),"."),
    .pr_cli_warning_line(x$warnings,width),.pr_cli_pointer("x$interpretation_support records the sampling assumptions for this comparison.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_mc_fragility_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_mc_fragility","format_postrank_mc_fragility_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); s <- x$summary
  pairs <- x$pairs
  top <- if(is.data.frame(pairs)&&nrow(pairs)&&"fragile"%in%names(pairs)&&any(pairs$fragile%in%TRUE)) {
    t <- pairs[pairs$fragile%in%TRUE,,drop=FALSE]
    if("ratio"%in%names(t)) t <- t[order(-t$ratio),,drop=FALSE]
    c(.pr_cli_line("Most fragile pairs:"),.pr_table_lines(t[,intersect(c("entity_i","entity_j","margin","mcse","ratio"),names(t)),drop=FALSE],n_head,width))
  } else character()
  .pr_cli_finish(c(.pr_cli_header("postrank_mc_fragility",paste0(s$fragile," of ",s$traced," examined pairs are sensitive to Monte Carlo variation")),
    .pr_cli_line("This check compares pairwise decision margins with estimated Monte Carlo error; it does not measure posterior certainty."),
    .pr_cli_line("Retained draws: ",.pr_fmt(x$draws,"count"),"; multiplier: ",.pr_fmt(x$z,"num"),"."),
    if(isTRUE(s$mcse_unavailable>0)) .pr_cli_line("Monte Carlo standard errors are unavailable for ",s$mcse_unavailable," pairs."),
    top,.pr_cli_warning_line(x$warnings,width),.pr_cli_pointer("x$pairs retains all examined margins, errors and unavailable reasons.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_diagnostics_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_diagnostics","format_postrank_diagnostics_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  val <- function(name) unlist(lapply(x$summaries,function(s){ d<-s$diagnostics[[name]];if(isTRUE(d$available))d$value else NULL }))
  rh <- val("rhat"); es <- val("ess_bulk"); total <- x$summaries[[x$total_loss$trace_id %||% ""]]
  .pr_cli_finish(c(.pr_cli_header("postrank_diagnostics",paste0(length(x$summaries)," posterior decision traces")),
    .pr_cli_line("Sampling regime: ",paste(toupper(unique(x$regimes)),collapse=" / "),"."),
    .pr_cli_line("Largest available Rhat: ",if(length(rh)).pr_fmt(max(rh),"num") else "NA", "; smallest bulk effective sample size: ",
      if(length(es)).pr_fmt(min(es),"num") else "NA","."),
    .pr_cli_line("Total-loss Monte Carlo standard error: ",.pr_metric_text(total$diagnostics$mcse_mean),"."),
    .pr_cli_line("NA means unavailable. Effective sample size is not an IID draw count; these diagnostics do not verify convergence."),
    .pr_cli_warning_line(x$warnings,width),.pr_cli_pointer("summary(x) lists the stored diagnostic results for each trace.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_report_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_report","format_postrank_report_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  ok <- isTRUE(x$incumbent_validated)&&!is.null(x$grade)
  figures <- sum(vapply(x$figures %||% list(),function(f)isTRUE(f$available),TRUE))
  .pr_cli_finish(c(.pr_cli_header("postrank_report",if(is.null(x$output_file))"Prepared result report; no file written" else paste0("Report saved as ",basename(x$output_file))),
    .pr_cli_line(length(x$sections %||% character())," sections; ",figures,if(figures==1L)" available figure." else " available figures."),
    .pr_cli_line(if(!ok) "No validated grades are available." else paste0(length(x$grade)," entities in ",x$disclosure$G,
      if(x$disclosure$G==1L)" grade" else " grades","; disclosed ",.pr_fmt(x$disclosure$disclosure_rate,"pct")," of pairs.")),
    if(ok && isTRUE(x$disclosure$N == 0)) .pr_cli_line("All comparisons withheld; conditional error ratios are NA (N = 0)."),
    .pr_cli_line(.pr_status_words(x$status$normalized),"."),
    .pr_cli_warning_line(x$warnings,width),.pr_cli_pointer("Use output_file in postrank_report() to save the English HTML report.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_guarantee_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  cls <- c("postrank_iid_bounds","postrank_protection_envelopes","postrank_protection_analysis","postrank_regret_bound")
  .pr_cli_assert_class(x,cls,"format_postrank_guarantee_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  kind <- cls[inherits(x,cls,which=TRUE)>0][1L]
  body <- switch(kind,
    postrank_iid_bounds = c(.pr_cli_line("Fixed-size IID coefficient-error reference; total error budget ",.pr_fmt(x$alpha,"num"),"."),
      .pr_table_lines(data.frame(Criterion=names(x$epsilon),Draws=unname(x$S),Radius=unname(x$epsilon)),n_head,width),
      .pr_cli_line("The calculation assumes IID target draws, a sample size fixed in advance and a predeclared error budget. MCMC effective sample size cannot replace the draw count.")),
    postrank_protection_envelopes = c(.pr_cli_line("Two weighted problems use the error limits minus or plus their coefficient-error radii."),
      .pr_table_lines(data.frame(Criterion=names(x$public_q),Requested=unname(x$public_q),
        Inner=unname(x$thresholds$inner),Outer=unname(x$thresholds$outer)),n_head,width),
      .pr_cli_line("Signed thresholds are kept without clipping. The inner problem can have no feasible grades.")),
    postrank_protection_analysis = .pr_cli_line(c(paste0("Inner action loss: ",.pr_fmt(x$inner_risk_upper,"risk"),"; whole outer-problem lower bound: ",
      .pr_fmt(x$outer_whole_problem_risk_lower,"risk"),"."),paste0("Conditional regret reference: ",.pr_fmt(x$computed_value,"risk"),"."),
      if(length(x$reasons))paste0("Unavailable because: ",paste(gsub("_"," ",x$reasons),collapse="; "),"."),
      "The reference uses the inner action, the whole outer-problem lower bound and weighted coefficient-error radii.")),
    postrank_regret_bound = .pr_cli_line(c(paste0("Conditional regret reference: ",.pr_fmt(x$regret_upper_bound,"risk"),"."),
      paste0("Optimization gap contribution: ",.pr_fmt(x$eta,"gap"),"; weighted coefficient-error radius: ",.pr_fmt(x$delta_w,"gap"),"."),
      if(!is.null(x$unavailable_reason))paste0("Unavailable because: ",gsub("_"," ",x$unavailable_reason),"."))))
  .pr_cli_finish(c(.pr_cli_header(kind,"Conditional reference calculation"),body,
    .pr_cli_line("The statistical assumptions and numerical enclosure have not been verified. This calculation is not a numerical certificate."),
    .pr_cli_pointer("summary(x, details = TRUE) retains the recorded assumptions and status flags.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_backend_availability_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L) {
  .pr_cli_assert_class(x,"postrank_backend_availability","format_postrank_backend_availability_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  .pr_cli_finish(c(.pr_cli_header("postrank_backend_availability",paste0(x$backend,if(isTRUE(x$installed))paste0(" package installed (",x$wrapper_version,")") else " package is not installed")),
    .pr_cli_line(if(isTRUE(x$available_for_attempt))"The package can be selected for a solve attempt." else
      "This package cannot currently be selected for a solve attempt."),
    if(identical(x$runtime_check$status,"blocked_known_R_runtime_mismatch")) .pr_cli_line("Its compiled R runtime does not match this R session."),
    .pr_cli_line("This inspection did not run a solver or check a license. Package installation alone does not establish that a solve will succeed."),
    .pr_cli_pointer("summary(x, details = TRUE) includes the package path and recorded checks.")),width,tier)
}

#' @rdname format_postrank_cli
#' @export
format_postrank_summary_cli <- function(x, ..., width = NULL, tier = NULL, n_head = 10L, details = NULL) {
  .pr_cli_assert_class(x, "postrank_summary", "format_postrank_summary_cli")
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier); n_head <- .pr_cli_n_head(n_head)
  if (is.null(details)) details <- isTRUE(attr(x, "details"))
  .pr_cli_details(details)
  view <- attr(x, "console_view")
  # Older saved summaries keep their structured fields but have no prepared view.
  if (is.null(view)) view <- list(Result = .pr_summary_legacy_lines(x))
  lines <- paste0("<", class(x)[1L], ">")
  for (title in names(view)) {
    body <- view[[title]]
    if (!length(body)) next
    lines <- c(lines, paste0(title, ":"), if (is.data.frame(body)) .pr_table_lines(body, n_head, width) else .pr_cli_line(body))
  }
  if (length(x$warnings)) lines <- c(lines, "Recorded warnings:", .pr_cli_line(x$warnings))
  if (details) {
    one <- function(v) {
      u <- unlist(v); if (!length(u)) return("none")
      values <- if (is.numeric(u)) format(u, digits = 6) else as.character(u)
      if (!is.null(names(u)) && all(nzchar(names(u)))) paste(names(u), values, sep = "=", collapse = ", ") else paste(values, collapse = ", ")
    }
    for (name in c("headline", "settings", "declarations", "provenance", "identities")) {
      lines <- c(lines, paste0("Technical ", name, ":"), if (!length(x[[name]])) .pr_cli_line("none") else
        vapply(names(x[[name]]), function(k) .pr_cli_line(k, ": ", one(x[[name]][[k]])), ""))
    }
    lines <- c(lines, .pr_cli_line("Summary schema: ", x$schema_version), .pr_cli_line(x$interpretation))
  } else lines <- c(lines, .pr_cli_pointer("summary(x, details = TRUE) adds source records and identities; structured fields remain available."))
  .pr_cli_finish(lines, width, tier)
}

# ---- print / format methods ------------------------------------------------------------------
.pr_formatter_of <- c(postrank_draws = "draws", postrank_validation = "validation", postrank_pairwise = "pairwise",
  postrank_coefficients = "coefficients", postrank_coefficient_diagnostics = "coefficient_diagnostics",
  postrank_declarations = "declarations", postrank_settings = "settings", postrank_control = "control",
  postrank_problem = "problem", postrank_fit = "fit", postrank_solution_validation = "validation",
  postrank_analysis = "analysis", postrank_report_card = "report_card", postrank_baseline = "baseline",
  postrank_comparison = "comparison", postrank_frontier = "frontier", postrank_commonality_cost = "commonality_cost",
  postrank_sensitivity = "sensitivity", postrank_crossfit = "crossfit", postrank_mc_fragility = "mc_fragility",
  postrank_diagnostics = "diagnostics", postrank_report = "report", postrank_iid_bounds = "guarantee",
  postrank_protection_envelopes = "guarantee", postrank_protection_analysis = "guarantee",
  postrank_regret_bound = "guarantee", postrank_backend_availability = "backend_availability",
  postrank_summary = "summary")
.pr_format_dispatch <- function(x, cls, ...) {
  f <- get(paste0("format_postrank_", .pr_formatter_of[[cls]], "_cli"), mode = "function")
  f(x, ...)
}
.pr_print_dispatch <- function(x, cls, ..., width = NULL, n_head = 10L) {
  cat(.pr_format_dispatch(x, cls, ..., width = width, n_head = n_head), sep = "\n")
  invisible(x)
}

#' @export
print.postrank_draws <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_draws", ..., width = width, n_head = n_head)
#' @export
format.postrank_draws <- function(x, ...) .pr_format_dispatch(x, "postrank_draws", ...)
#' @export
print.postrank_validation <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_validation", ..., width = width, n_head = n_head)
#' @export
format.postrank_validation <- function(x, ...) .pr_format_dispatch(x, "postrank_validation", ...)
#' @export
print.postrank_pairwise <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_pairwise", ..., width = width, n_head = n_head)
#' @export
format.postrank_pairwise <- function(x, ...) .pr_format_dispatch(x, "postrank_pairwise", ...)
#' @export
print.postrank_coefficients <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_coefficients", ..., width = width, n_head = n_head)
#' @export
format.postrank_coefficients <- function(x, ...) .pr_format_dispatch(x, "postrank_coefficients", ...)
#' @export
print.postrank_coefficient_diagnostics <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_coefficient_diagnostics", ..., width = width, n_head = n_head)
#' @export
format.postrank_coefficient_diagnostics <- function(x, ...) .pr_format_dispatch(x, "postrank_coefficient_diagnostics", ...)
#' @export
print.postrank_declarations <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_declarations", ..., width = width, n_head = n_head)
#' @export
format.postrank_declarations <- function(x, ...) .pr_format_dispatch(x, "postrank_declarations", ...)
#' @export
print.postrank_settings <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_settings", ..., width = width, n_head = n_head)
#' @export
format.postrank_settings <- function(x, ...) .pr_format_dispatch(x, "postrank_settings", ...)
#' @export
print.postrank_control <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_control", ..., width = width, n_head = n_head)
#' @export
format.postrank_control <- function(x, ...) .pr_format_dispatch(x, "postrank_control", ...)
#' @export
print.postrank_problem <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_problem", ..., width = width, n_head = n_head)
#' @export
format.postrank_problem <- function(x, ...) .pr_format_dispatch(x, "postrank_problem", ...)
#' @export
print.postrank_fit <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_fit", ..., width = width, n_head = n_head)
#' @export
format.postrank_fit <- function(x, ...) .pr_format_dispatch(x, "postrank_fit", ...)
#' @export
print.postrank_solution_validation <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_solution_validation", ..., width = width, n_head = n_head)
#' @export
format.postrank_solution_validation <- function(x, ...) .pr_format_dispatch(x, "postrank_solution_validation", ...)
#' @export
print.postrank_analysis <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_analysis", ..., width = width, n_head = n_head)
#' @export
format.postrank_analysis <- function(x, ...) .pr_format_dispatch(x, "postrank_analysis", ...)
#' @export
print.postrank_report_card <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_report_card", ..., width = width, n_head = n_head)
#' @export
format.postrank_report_card <- function(x, ...) .pr_format_dispatch(x, "postrank_report_card", ...)
#' @export
print.postrank_baseline <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_baseline", ..., width = width, n_head = n_head)
#' @export
format.postrank_baseline <- function(x, ...) .pr_format_dispatch(x, "postrank_baseline", ...)
#' @export
print.postrank_comparison <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_comparison", ..., width = width, n_head = n_head)
#' @export
format.postrank_comparison <- function(x, ...) .pr_format_dispatch(x, "postrank_comparison", ...)
#' @export
print.postrank_frontier <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_frontier", ..., width = width, n_head = n_head)
#' @export
format.postrank_frontier <- function(x, ...) .pr_format_dispatch(x, "postrank_frontier", ...)
#' @export
print.postrank_commonality_cost <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_commonality_cost", ..., width = width, n_head = n_head)
#' @export
format.postrank_commonality_cost <- function(x, ...) .pr_format_dispatch(x, "postrank_commonality_cost", ...)
#' @export
print.postrank_sensitivity <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_sensitivity", ..., width = width, n_head = n_head)
#' @export
format.postrank_sensitivity <- function(x, ...) .pr_format_dispatch(x, "postrank_sensitivity", ...)
#' @export
print.postrank_crossfit <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_crossfit", ..., width = width, n_head = n_head)
#' @export
format.postrank_crossfit <- function(x, ...) .pr_format_dispatch(x, "postrank_crossfit", ...)
#' @export
print.postrank_mc_fragility <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_mc_fragility", ..., width = width, n_head = n_head)
#' @export
format.postrank_mc_fragility <- function(x, ...) .pr_format_dispatch(x, "postrank_mc_fragility", ...)
#' @export
print.postrank_diagnostics <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_diagnostics", ..., width = width, n_head = n_head)
#' @export
format.postrank_diagnostics <- function(x, ...) .pr_format_dispatch(x, "postrank_diagnostics", ...)
#' @export
print.postrank_report <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_report", ..., width = width, n_head = n_head)
#' @export
format.postrank_report <- function(x, ...) .pr_format_dispatch(x, "postrank_report", ...)
#' @export
print.postrank_iid_bounds <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_iid_bounds", ..., width = width, n_head = n_head)
#' @export
format.postrank_iid_bounds <- function(x, ...) .pr_format_dispatch(x, "postrank_iid_bounds", ...)
#' @export
print.postrank_protection_envelopes <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_protection_envelopes", ..., width = width, n_head = n_head)
#' @export
format.postrank_protection_envelopes <- function(x, ...) .pr_format_dispatch(x, "postrank_protection_envelopes", ...)
#' @export
print.postrank_protection_analysis <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_protection_analysis", ..., width = width, n_head = n_head)
#' @export
format.postrank_protection_analysis <- function(x, ...) .pr_format_dispatch(x, "postrank_protection_analysis", ...)
#' @export
print.postrank_regret_bound <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_regret_bound", ..., width = width, n_head = n_head)
#' @export
format.postrank_regret_bound <- function(x, ...) .pr_format_dispatch(x, "postrank_regret_bound", ...)
#' @export
print.postrank_backend_availability <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_backend_availability", ..., width = width, n_head = n_head)
#' @export
format.postrank_backend_availability <- function(x, ...) .pr_format_dispatch(x, "postrank_backend_availability", ...)
#' @export
print.postrank_summary <- function(x, ..., width = NULL, n_head = 10L) .pr_print_dispatch(x, "postrank_summary", ..., width = width, n_head = n_head)
#' @export
format.postrank_summary <- function(x, ...) .pr_format_dispatch(x, "postrank_summary", ...)

# ---- summary() methods: typed receipts (SPEC-13.5) -------------------------------------------
.pr_summary_lang <- function() {
  lang <- getOption("postrank.lang", "en")
  if (!identical(lang, "en")) .pr_abort(paste0("postrank.lang = \"", lang, "\" is not supported; official output is English (\"en\")"),
    "unsupported_language", "$.postrank.lang")
}
.pr_new_summary <- function(cls, x, headline = list(), settings = list(), declarations = list(), provenance = list(),
                            identities = list(), warnings = character(), interpretation = character(), details = FALSE) {
  .pr_summary_lang()
  .pr_cli_details(details)
  out <- structure(list(object_class = cls, schema_version = x$schema_version %||% NA_character_, headline = headline,
    provenance = provenance, declarations = declarations, settings = settings,
    identities = identities[!vapply(identities, is.null, TRUE)], warnings = unique(as.character(warnings)),
    interpretation = c(interpretation, "Smaller grade = higher priority; a shared grade withholds the comparison.",
      "Bounds are solver values; the gap is not regret.")),
    class = c(paste0(cls, "_summary"), "postrank_summary", "list"))
  attr(out, "console_view") <- .pr_summary_sections(cls, x)
  attr(out, "details") <- details
  out
}
.pr_fit_headline <- function(fit) {
  ev <- fit$evaluation; ok <- isTRUE(fit$incumbent_validated)
  list(n = length(fit$problem$pairwise$entity_ids), K = length(fit$problem$pairwise$criterion_ids),
    G = if (ok) ev$G else NA_integer_, sizes = if (ok) tabulate(fit$grade) else NULL, N = if (ok) ev$N else NA, M = fit$problem$M,
    disclosure_rate = if (ok) ev$disclosure_rate else NA, risk = if (ok) fit$objective$primary_action_risk else NA,
    status = fit$status$normalized, gap = fit$objective$risk_absolute_gap, bound_source = fit$objective$bound_source,
    E_over_N = if (ok) ev$E_over_N else NULL)
}
.pr_policy_view <- function(s) s[intersect(c("weights", "tau", "G_max", "q", "exact_G", "objective", "minimax_criteria", "minimax_refine"), names(s))]

#' @export
summary.postrank_fit <- function(object, ..., details = FALSE) {
  .pr_new_summary("postrank_fit", object, headline = .pr_fit_headline(object), settings = .pr_policy_view(object$problem$settings),
    declarations = list(status = if (is.null(object$problem$pairwise$context)) "undeclared (typed coefficient source)" else "declared, not independently verified"),
    provenance = list(backend = object$backend$name, wrapper_version = object$backend$wrapper_version %||% NA_character_,
      solver_version = object$backend$solver_version %||% NA_character_, resolution = object$backend$resolution %||% NA_character_,
      channel = object$backend$channel %||% NA_character_, strategy = object$engine$strategy, runtime = object$runtime),
    identities = list(input = object$input_identity, problem = object$problem_identity,
      solution = object$solution_identity$relation_identity),
    warnings = object$warnings, details = details)
}
#' @export
summary.postrank_analysis <- function(object, ..., details = FALSE) {
  s <- summary.postrank_fit(object$fit, details = details)
  s$object_class <- "postrank_analysis"; class(s)[1L] <- "postrank_analysis_summary"
  s$declarations <- object$metadata$declarations[intersect(c("status", "source", "kind", "note"), names(object$metadata$declarations))]
  s$provenance$timings <- object$timings
  s$provenance$package_version <- object$provenance$package_version
  s$headline$extras <- vapply(object$extras, function(r) if (r$available) "available" else r$reason, "")
  s$settings$label <- object$settings$label
  s$warnings <- object$warnings
  attr(s, "console_view") <- .pr_summary_sections("postrank_analysis", object)
  s
}
 .pr_simple_summary <- function(cls) function(object, ..., details = FALSE) {
  fields <- intersect(c("valid", "issues", "raw_residuals", "tolerances", "summary", "status", "guarantee_status",
    "guarantee_issued", "numerical_certification", "finite_sample_certificate", "numerically_verified",
    "computed_value", "regret_upper_bound", "unavailable_reason"), names(object))
  .pr_new_summary(cls, object, headline = c(list(class = cls), object[fields]),
    declarations = if (!is.null(object$assumptions)) list(assumptions = object$assumptions, design = object[["design"]]) else list(),
    provenance = object$provenance %||% list(),
    identities = list(input = object$input_identity %||% object$validation$input_identity, pairwise = object$pairwise_identity,
      problem = object$problem_identity), warnings = object$warnings, interpretation = object$interpretation, details = details)
}
#' @export
summary.postrank_draws <- function(object, ..., details = FALSE) {
  .pr_new_summary("postrank_draws", object,
    headline = list(n = length(object$entity_ids), K = length(object$criterion_ids), input_kind = object$input_kind,
      dependence_mode = object$dependence_mode, regime = object$joint_draws$sampling$regime),
    declarations = list(targets = vapply(object$targets, function(t) paste0(t$criterion_id, ": ", t$estimand), ""),
      identification = object$identification$note, tie_justification = object$tie_policy$justification,
      transforms = vapply(object$targets, function(t) t$source_transform %||% "identity", "")),
    provenance = object$provenance[intersect(c("producer", "artifact_id", "created_at"), names(object$provenance))],
    identities = list(input = object$validation$input_identity), details = details)
}
#' @export
summary.postrank_validation <- .pr_simple_summary("postrank_validation")
#' @export
summary.postrank_pairwise <- function(object, ..., details = FALSE) .pr_new_summary("postrank_pairwise", object,
  headline = list(dim = dim(object$e), sample_sizes = object$sample_sizes, method = object$method),
  identities = list(input = object$input_identity, pairwise = object$pairwise_identity), details = details)
#' @export
summary.postrank_coefficients <- function(object, ..., details = FALSE) .pr_new_summary("postrank_coefficients", object,
  headline = list(dim = dim(object$e), kind = object$input_kind),
  declarations = list(conditional_independence = object$source$conditional_independence),
  provenance = object$provenance, settings = object$capabilities,
  identities = list(coefficient = object$coefficient_identity), details = details)
#' @export
summary.postrank_coefficient_diagnostics <- .pr_simple_summary("postrank_coefficient_diagnostics")
#' @export
summary.postrank_settings <- function(object, ..., details = FALSE) .pr_new_summary("postrank_settings", object, headline = list(label = object$label),
  settings = c(.pr_policy_view(object), list(weight_sum_tolerance = object$weight_sum_tolerance)), provenance = object$provenance, details = details)
#' @export
summary.postrank_control <- function(object, ..., details = FALSE) .pr_new_summary("postrank_control", object,
  headline = list(time_limit = object$time_limit, threads = object$threads, strategy = object$strategy),
  settings = list(seed = object$seed, absolute_risk_gap = object$absolute_risk_gap, relative_gap = object$relative_gap,
    engine = unlist(object$engine), tolerances = unlist(object$tolerances)), provenance = object$provenance, details = details)
#' @export
summary.postrank_problem <- function(object, ..., details = FALSE) .pr_new_summary("postrank_problem", object,
  headline = list(n = length(object$pairwise$entity_ids), K = length(object$pairwise$criterion_ids), M = object$M,
    objective_units = object$objective_units$raw, builder_version = object$builder_version),
  settings = .pr_policy_view(object$settings), identities = list(input = object$input_identity, problem = object$problem_identity), details = details)
#' @export
summary.postrank_solution_validation <- .pr_simple_summary("postrank_solution_validation")
#' @export
summary.postrank_report_card <- function(object, ..., details = FALSE) .pr_new_summary("postrank_report_card", object,
  headline = list(n = nrow(object$data), level = object$level, interval_source = object$interval_source,
    secondary_order = object$secondary_order), settings = .pr_policy_view(object$settings),
  identities = list(input = object$input_identity, grade = object$grade_identity), warnings = object$warnings, details = details)
#' @export
summary.postrank_baseline <- function(object, ..., details = FALSE) .pr_new_summary("postrank_baseline", object,
  headline = list(method = object$method, cut_rule = object$cut_rule, risk = object$risk, objective = object$objective,
    cuts = object$cuts), settings = c(.pr_policy_view(object$settings), object$tie_policy),
  identities = list(input = object$input_identity), warnings = object$warnings, details = details)
#' @export
summary.postrank_comparison <- function(object, ..., details = FALSE) .pr_new_summary("postrank_comparison", object,
  headline = list(methods = object$table$method, reference = object$reference), settings = .pr_policy_view(object$settings),
  identities = list(input = object$input_identity), warnings = object$warnings, details = details)
#' @export
summary.postrank_frontier <- function(object, ..., details = FALSE) .pr_new_summary("postrank_frontier", object,
  headline = list(rows = nrow(object$table), backend = object$backend, strategy = object$strategy),
  settings = list(weights = object$weights, G_max = object$G_max, objective = object$objective),
  identities = list(input = object$input_identity), interpretation = object$interpretation, details = details)
#' @export
summary.postrank_commonality_cost <- function(object, ..., details = FALSE) .pr_new_summary("postrank_commonality_cost", object,
  headline = list(criteria = nrow(object$table), protection = object$protection, backend = object$backend),
  identities = list(input = object$input_identity, problem = object$problem_identity), interpretation = object$interpretation, details = details)
#' @export
summary.postrank_sensitivity <- function(object, ..., details = FALSE) .pr_new_summary("postrank_sensitivity", object,
  headline = list(rows = nrow(object$table), reference = object$reference_id), warnings = object$warnings, details = details)
#' @export
summary.postrank_crossfit <- .pr_simple_summary("postrank_crossfit")
#' @export
summary.postrank_mc_fragility <- .pr_simple_summary("postrank_mc_fragility")
#' @export
summary.postrank_diagnostics <- function(object, ..., details = FALSE) .pr_new_summary("postrank_diagnostics", object,
  headline = list(traces = names(object$summaries), regimes = object$regimes,
    convergence_verified = object$convergence_verified, finite_sample_certificate = object$finite_sample_certificate,
    numerical_certification = object$numerical_certification),
  identities = list(input = object$input_identity, problem = object$problem_identity), warnings = object$warnings,
  interpretation = object$interpretation, details = details)
#' @export
summary.postrank_report <- function(object, ..., details = FALSE) .pr_new_summary("postrank_report", object,
  headline = list(output_file = object$output_file %||% "not written", status = object$status$normalized),
  identities = list(input = object$input_identity, problem = object$problem_identity), warnings = object$warnings,
  interpretation = object$interpretation, details = details)
#' @export
summary.postrank_iid_bounds <- .pr_simple_summary("postrank_iid_bounds")
#' @export
summary.postrank_protection_envelopes <- .pr_simple_summary("postrank_protection_envelopes")
#' @export
summary.postrank_protection_analysis <- .pr_simple_summary("postrank_protection_analysis")
#' @export
summary.postrank_regret_bound <- .pr_simple_summary("postrank_regret_bound")
#' @export
summary.postrank_backend_availability <- function(object, ..., details = FALSE) .pr_new_summary("postrank_backend_availability", object,
  headline = list(backend = object$backend, installed = object$installed, available_for_attempt = object$available_for_attempt),
  provenance = list(package_path = object$package_path, runtime_check = object$runtime_check$status,
    license_check = object$license_check$status), interpretation = object$interpretation, details = details)

# Equality-neutral inputs have separate classes and a separate loss definition.
# These private views read their stored results without casting to legacy fits.
.pr_tie_sections <- function(x, cls) {
  scope <- "Decisions support weighted loss and an upper limit on grades; q limits, exact grade counts and minimax are unsupported in this path."
  loss <- "True equality incurs no error or withholding cost. Withheld unequal targets incur the declared cost. A shared grade does not assert true equality."
  if (cls == "postrank_tie_draws") {
    sampling <- if (identical(x$input_kind,"exact_finite_posterior")) paste0(length(x$finite_law$states)," states in a declared exact finite law.") else
      paste0(dim(x$joint_draws$tensor$values)[1L]," retained ",toupper(x$joint_draws$sampling$regime)," joint draws.")
    return(list(Result=c(paste0(length(x$entity_ids)," entities. ",.pr_criteria_words(x$criterion_ids)),sampling),
      `Equality and loss`=c(loss,"Equality declarations and scientific assumptions are recorded, not independently verified.",scope)))
  }
  if (cls == "postrank_tie_pairwise") return(list(Result=c(paste0(length(x$entity_ids)," entities. ",.pr_criteria_words(x$criterion_ids)),
    "Stored probabilities distinguish strict reversals (b), true equality (t) and unequal targets (d).",
    if(!is.null(x$exact)) "Exact finite-law probabilities are retained; no sample size is inferred." else
      paste0("Retained draws by criterion: ",paste(names(x$sample_sizes),.pr_fmt(x$sample_sizes,"count"),collapse="; "),".")),
    `Equality and loss`=c(loss,scope)))
  if (cls == "postrank_tie_problem") return(list(Result=c("Ready to solve; no grades calculated yet.",
    paste0(length(x$pairwise$entity_ids)," entities. ",.pr_criteria_words(x$pairwise$criterion_ids))),
    Settings=c(paste0("At most ",x$settings$G_max," grades; withholding cost ",.pr_fmt(x$settings$tau,"num")," on unequal targets."),
      paste0("All-withheld loss (R0): ",.pr_fmt(x$objective_units$offset,"risk"),". It depends on the probability of unequal targets and need not equal tau.")),
    `Equality and loss`=c(loss,scope)))
  if (cls == "postrank_tie_solution_validation") return(list(Result=c(if(isTRUE(x$valid)) "Returned grades passed the numerical checks." else "Returned grades did not pass the numerical checks.",
    paste0(length(x$issues)," recorded issues.")), Interpretation="These checks include the equality-profile constraints; they do not verify the scientific equality declarations or optimality."))
  fit <- cls == "postrank_tie_fit"
  ev <- if(fit)x$evaluation else x
  ok <- if(fit)isTRUE(x$incumbent_validated)&&!is.null(x$grade) else TRUE
  result <- if(ok)c(paste0(length(ev$grade)," entities in ",ev$G,if(ev$G==1L)" grade" else " grades"," (sizes ",.pr_grade_sizes(ev$grade),")."),
    paste0("Equality-neutral posterior loss: ",.pr_fmt(ev$weighted_risk,"risk"),"."),
    paste0("Disclosed ",.pr_fmt(ev$N,"count")," of ",.pr_fmt(ev$M,"count")," pairs (",.pr_fmt(ev$disclosure_rate,"pct"),"); withheld ",.pr_fmt(ev$M-ev$N,"count"),"."),
    paste0("All-withheld loss (R0): ",.pr_fmt(ev$R0,"risk"),"; R0 need not equal tau.")) else
      "No validated grades are available; action loss and disclosed comparisons are unavailable."
  if (ok && identical(ev$guard_satisfied, FALSE)) result <- c(result, "This grade violates the equality-profile constraints. Its loss can be scored, but it cannot be released as a feasible solution.")
  view <- list(Result=result)
  if(ok) view$`Criterion results` <- data.frame(Criterion=names(ev$criterion_risk), Loss=.pr_fmt(ev$criterion_risk,"risk"),
    `Error / disclosed`=.pr_fmt(ev$E_over_N,"ratio"), `Error / distinct`=.pr_fmt(ev$E_over_D,"ratio"),check.names=FALSE)
  view$`Reading the loss` <- c(loss,"Error / disclosed divides by the number of disclosed pairs. Error / distinct divides by their expected unequal-target mass. A zero denominator remains NA.",scope)
  if(fit) view$Computation <- .pr_gap_lines(x,full=TRUE)
  view
}
.pr_format_tie <- function(x, cls, ..., width=NULL, tier=NULL, n_head=10L) {
  .pr_cli_assert_class(x,cls,paste0("format.",cls))
  width <- .pr_cli_width(width); tier <- .pr_cli_tier(tier)
  view <- .pr_tie_sections(x,cls)
  lines <- .pr_cli_header(cls,view$Result[1L])
  if(length(view$Result)>1L) lines <- c(lines,.pr_cli_line(view$Result[-1L]))
  for(name in setdiff(names(view),"Result")) lines <- c(lines,paste0(name,":"),
    if(is.data.frame(view[[name]])) .pr_table_lines(view[[name]],n_head,width) else .pr_cli_line(view[[name]]))
  .pr_cli_finish(c(lines,.pr_cli_warning_line(x$warnings,width),
    .pr_cli_pointer("summary(x, details = TRUE) adds the stored technical record.")),width,tier)
}
.pr_print_tie <- function(x, cls, ..., width=NULL, n_head=10L) {
  cat(.pr_format_tie(x,cls,...,width=width,n_head=n_head),sep="\n")
  invisible(x)
}
.pr_summary_tie <- function(object, cls, details=FALSE) {
  fields <- intersect(c("loss","valid","issues","settings","status","objective","R0","E_over_N","E_over_D","criterion_risk"),names(object))
  source <- if (cls == "postrank_tie_fit") object[["problem"]][["pairwise"]] else if (cls == "postrank_tie_problem") object[["pairwise"]] else object
  .pr_new_summary(cls,object,headline=object[fields],settings=object$settings %||% list(),
    declarations=list(equality=source[["equality"]]),
    provenance=object$provenance %||% list(),identities=list(input=object$input_identity,problem=object$problem_identity,pairwise=object$pairwise_identity),
    warnings=object$warnings,interpretation="The equality-neutral loss uses R0, not necessarily tau, as the all-withheld baseline.",details=details)
}

#' @export
print.postrank_tie_draws <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_draws",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_draws <- function(x, ...) .pr_format_tie(x,"postrank_tie_draws",...)
#' @export
summary.postrank_tie_draws <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_draws",details)

#' @export
print.postrank_tie_pairwise <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_pairwise",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_pairwise <- function(x, ...) .pr_format_tie(x,"postrank_tie_pairwise",...)
#' @export
summary.postrank_tie_pairwise <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_pairwise",details)

#' @export
print.postrank_tie_problem <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_problem",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_problem <- function(x, ...) .pr_format_tie(x,"postrank_tie_problem",...)
#' @export
summary.postrank_tie_problem <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_problem",details)

#' @export
print.postrank_tie_fit <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_fit",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_fit <- function(x, ...) .pr_format_tie(x,"postrank_tie_fit",...)
#' @export
summary.postrank_tie_fit <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_fit",details)

#' @export
print.postrank_tie_evaluation <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_evaluation",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_evaluation <- function(x, ...) .pr_format_tie(x,"postrank_tie_evaluation",...)
#' @export
summary.postrank_tie_evaluation <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_evaluation",details)

#' @export
print.postrank_tie_solution_validation <- function(x, ..., width=NULL, n_head=10L) .pr_print_tie(x,"postrank_tie_solution_validation",...,width=width,n_head=n_head)
#' @export
format.postrank_tie_solution_validation <- function(x, ...) .pr_format_tie(x,"postrank_tie_solution_validation",...)
#' @export
summary.postrank_tie_solution_validation <- function(object, ..., details=FALSE) .pr_summary_tie(object,"postrank_tie_solution_validation",details)
