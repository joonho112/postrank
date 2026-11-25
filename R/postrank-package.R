#' postrank: Posterior Ranking with Integer Grades
#'
#' `postrank` assigns an integer grade to each entity (such as a school, an
#' employer or an area) using posterior information that you supply: posterior
#' draws, normal or mixture posteriors, or pairwise comparison probabilities.
#' For one or several criteria, [postrank()] chooses a single common grading
#' across entities; the multidomain functions (`postrank_mdomain_*`) instead
#' assign a separate grade in each domain. The package does not fit a
#' statistical model.
#'
#' @section How grades work:
#' Grade 1 is the highest priority; larger values of each target mean higher
#' priority, as set when the input was built. Entities in different grades are
#' reported in that order. Entities in the same grade are left unordered: the
#' report withholds their comparison rather than claiming they are equal. By
#' default, grades minimize the posterior expected loss averaged over all entity
#' pairs, where reporting a pair in the wrong order costs 1 and leaving a pair
#' unordered costs `tau`. Leaving every pair unordered (a single shared grade,
#' with loss `tau`) is a valid result.
#'
#' @section Getting started:
#' Start with `vignette("a1-getting-started", package = "postrank")`,
#' [postrank()], [postrank_describe()] and [postrank_example()]. Stored example
#' results from [postrank_example()] run without an optimization solver, and
#' [pr_tutorial] holds the six fictional sites used in the introductory guide.
#'
#' Computing new grades with [postrank()] or [postrank_solve()] requires a
#' solver. Install the free `highs` package (`install.packages("highs")`) and
#' select it with `backend = "highs"` or `options(postrank.backend = "highs")`,
#' or provide a licensed Gurobi installation (used by default when no solver is
#' chosen). `postrank` never switches solvers on its own.
#'
#' @section Package functions:
#' \tabular{ll}{
#'   Input \tab [postrank_describe()], [postrank_draws()], [postrank_declarations()], [read_postrank_draws()], [as_postrank_draws()] \cr
#'   Coefficients \tab [postrank_pairwise()], [postrank_gaussian_coefficients()], [postrank_mixture_coefficients()], [postrank_probabilities()] \cr
#'   Settings and control \tab [postrank_settings()], [postrank_control()], [postrank_options] \cr
#'   Decision \tab [postrank()], [postrank_problem()], [postrank_solve()], [postrank_evaluate()] \cr
#'   Baselines and comparison \tab [postrank_expected_rank()], [postrank_composite()], [postrank_cuts()], [postrank_compare()] \cr
#'   Side outputs and grids \tab [postrank_commonality_cost()], [postrank_frontier()], [postrank_sensitivity()] \cr
#'   Diagnostics \tab [postrank_crossfit()], [postrank_mc_fragility()], [postrank_diagnose()] \cr
#'   Reporting and stored examples \tab [postrank_report_card()], [postrank_report()], [get_grades()], [postrank_example()] \cr
#'   Visualization \tab the seven `postrank_plot_*()` functions, [theme_postrank()], [postrank_palette()] \cr
#'   Reference bounds \tab [postrank_iid_bounds()] and the conditional envelope functions \cr
#'   Multidomain \tab [postrank_mdomain_input()], [postrank_mdomain_decision()], [postrank_mdomain_solve()], [postrank_plot_mdomain()]
#' }
#'
#' @section Multidomain profiles:
#' [postrank_mdomain_input()] represents entity-by-domain posteriors when a
#' separate grade is reported in each domain rather than one common grade. Within
#' each domain, a shared grade leaves the pair unordered.
#' [postrank_mdomain_decision()] defines additive domain losses and optional
#' mean or joint-event constraints. [postrank_mdomain_evaluate()] evaluates a
#' given entity-by-domain grade matrix, while [postrank_mdomain_family()] and
#' [postrank_mdomain_solve()] choose a matrix from a declared set of candidate
#' profiles; optimality holds only within that candidate set.
#' [postrank_mdomain_grades()] extracts checked grades,
#' [postrank_mdomain_assess()] reports finite-law, conditional IID or
#' descriptive MCMC summaries, and [postrank_plot_mdomain()] plots the results.
#' Multidomain calculations need no mixed-integer solver and use exact rational
#' arithmetic when the optional `gmp` package is installed; exact finite-law
#' arithmetic does not verify the statistical model or intended posterior. See
#' `vignette("mdomain-quickstart", package = "postrank")` and
#' `vignette("mdomain-decisions", package = "postrank")`.
#'
#' @section Exact ties:
#' Ordinary inputs assume that distinct entities have zero probability of being
#' equal. For posteriors in which exact equality has positive probability, the
#' `postrank_tie_*` functions (see [postrank_tie_capabilities()]) treat exact
#' equality as having zero loss whether the pair is ordered or left unordered,
#' so the single-grade loss `R0` can be below `tau`.
#'
#' @section Case-study data:
#' The three case-study datasets are adapted from public sources and keep their
#' source conditions, separate from the package code license: [pr_case_cde]
#' preserves source attribution, [pr_case_krw] retains its source CC-BY-NC
#' notice (license version unspecified in the source), and [pr_case_alabama]
#' retains CC BY 4.0 attribution. See each dataset's help page and the installed
#' `DATA-NOTICE.md` file.
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
#' @seealso [postrank()], [postrank_example()], [postrank_describe()],
#'   [postrank_options], [pr_tutorial],
#'   `vignette("a1-getting-started", package = "postrank")`
#' @examples
#' one <- postrank_example("tutorial_one")
#' get_grades(one)
#' get_risk(one)
#' postrank_expected_rank(pr_tutorial$one)
#' @keywords internal
"_PACKAGE"
