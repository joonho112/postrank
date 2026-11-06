#' postrank: Posterior Ranking with Integer Grades
#'
#' Posterior information on one or several criteria is used to assign an
#' integer grade to each entity under a declared loss. For several criteria,
#' one common grade is assigned. The input is an existing posterior
#' representation, supplied as draws, supported analytic laws or previously
#' calculated comparison probabilities, together with scientific declarations
#' and numerical qualifications. The package does not fit a statistical model.
#'
#' @section Interpretation of grades:
#' Grade 1 is the highest-priority block; larger targets mean higher priority,
#' and only the order and equality of grade labels matter. A shared grade
#' withholds the comparison of its members and asserts no equality of the
#' entities. The procedure seeks a grade minimizing the declared weighted
#' wrong-direction loss plus the withholding cost `tau`, and reports the
#' validated incumbent with the solver's bound and gap; withholding every
#' comparison, with risk `tau`, is a legitimate action.
#'
#' @section Package functions:
#' \tabular{ll}{
#'   Input \tab [postrank_draws()], [postrank_declarations()], [read_postrank_draws()] and the strict constructors \cr
#'   Coefficients \tab [postrank_pairwise()], [postrank_gaussian_coefficients()], [postrank_mixture_coefficients()], [postrank_probabilities()] \cr
#'   Settings and control \tab [postrank_settings()], [postrank_control()] \cr
#'   Decision \tab [postrank()], [postrank_problem()], [postrank_solve()], [postrank_evaluate()] \cr
#'   Baselines and comparison \tab [postrank_expected_rank()], [postrank_composite()], [postrank_cuts()], [postrank_compare()] \cr
#'   Side outputs and grids \tab [postrank_commonality_cost()], [postrank_frontier()], [postrank_sensitivity()] \cr
#'   Diagnostics \tab [postrank_crossfit()], [postrank_mc_fragility()], [postrank_diagnose()] \cr
#'   Reporting \tab [postrank_report_card()], [postrank_report()], [get_grades()] and the console formatters \cr
#'   Visualization \tab the seven `postrank_plot_*()` figures, [theme_postrank()], [postrank_palette()] \cr
#'   Reference calculations \tab [postrank_iid_bounds()] and the conditional guarantee helpers
#' }
#'
#' @section Getting started:
#' [pr_tutorial] provides the same six fictional sites with one or two
#' criteria in `vignette("a1-getting-started", package = "postrank")`.
#' The Applied guides present empirical cases and the Methods guides describe the
#' loss, information requirements, optimization and numerical uncertainty.
#' Stored-result views need no optimizer. A fresh solve uses an explicitly
#' selected backend, the `postrank.backend` option, or Gurobi in that order.
#' HiGHS is an explicit alternative; there is no silent backend fallback.
#'
#' @section Genuine target ties:
#' The separate [postrank_tie_capabilities()] domain makes equality neutral
#' in both wrong-direction and withheld-comparison loss. It supports guarded
#' weighted at-most-G label-MIP problems through distinct `postrank_tie_*`
#' entry points. Its all-withhold risk is R0, which can be below tau.
#' Ordinary constructors retain their tie-free interpretation.
#'
#' @section Case-study data:
#' The three case-study inputs are adapted from public sources and retain
#' source-specific conditions, separate from the package code license. The CDE
#' input preserves source attribution, KRW retains its source CC-BY-NC notice
#' with the license version unspecified, and Alabama retains CC BY 4.0
#' attribution. Details are given in the data help pages and the installed
#' DATA-NOTICE.
#'
#' @section Citation:
#' `citation("postrank")` returns the package, its theory book and the
#' report-card method of Kline, Rose and Walters (2024), in that order.
#' The book is *Decisions from noisy multidimensional indicators: Theory,
#' evidence, and posterior grading* (Version 1.0.0),
#' \doi{10.5281/zenodo.23790260}. The method reference is *A discrimination
#' report card*, American Economic Review, 114(8), 2472-2525,
#' \doi{10.1257/aer.20230700}.
#'
#' @seealso [postrank_options], [pr_tutorial],
#'   `vignette("a1-getting-started", package = "postrank")`
#' @examples
#' pr_tutorial$one
#' postrank_expected_rank(pr_tutorial$one)
#' pr_tutorial$two
#' @keywords internal
"_PACKAGE"
