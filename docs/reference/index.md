# Package index

## Grading and stored examples

Run a common-grade analysis in one call, load precomputed example
results without a solver, or build, solve, and evaluate a grading
problem step by step.

- [`canonical_postrank_grade()`](https://joonho112.github.io/postrank/reference/canonical_postrank_grade.md)
  : Renumber Grades While Preserving Comparisons
- [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
  : Assign Grades to Entities Under Posterior Uncertainty
- [`postrank_backend_available()`](https://joonho112.github.io/postrank/reference/postrank_backend_available.md)
  : Inspect Solver Package Availability
- [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
  : Evaluate the Posterior Loss of Supplied Grades
- [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
  : Build a Problem for Choosing Common Grades
- [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  : Find Grades and Report Their Optimization Bounds
- [`validate_postrank_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_solution.md)
  : Check a Solver Candidate for the Grading Problem
- [`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)
  : Stored Example Results

## Posterior draw inputs

Describe posterior draws in plain arguments or structured blocks, build
and validate draw objects, and read or write draw files.

- [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  : Prepare a Fully Described Posterior Input
- [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)
  : Import Mapped Posterior Draws
- [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
  : Describe the Targets and Source of Posterior Draws
- [`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
  : Describe Posterior Draws in Plain Arguments
- [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  : Prepare Posterior Draws for One or Several Criteria
- [`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md)
  : Build a Posterior Input from a Joint Array
- [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  : Use Previously Calculated Comparison Probabilities
- [`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)
  : Read Posterior Draws or an Exact Finite Law from JSON
- [`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md)
  : Check a Posterior Input and Inspect Its Validation Results
- [`validate_postrank_probabilities()`](https://joonho112.github.io/postrank/reference/validate_postrank_probabilities.md)
  : Check an Imported Probability Input
- [`write_postrank_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_draws.md)
  : Save a Posterior Input as JSON

## Analytic posteriors and comparison probabilities

Compute pairwise directional-error probabilities from draws or normal
and mixture posteriors, or supply precomputed comparison probabilities.

- [`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)
  : Check Which Operations a Conditional-Law Input Supports
- [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
  : Diagnose Integration of a Conditional Expected Risk
- [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
  : Compute Comparisons from a Conditional Gaussian Law
- [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
  : Average Comparisons Across Shared Gaussian States
- [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
  : Calculate Directional-Error Probabilities
- [`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md)
  : Check Conditional Coefficients and Source Calculations

## Settings and solver control

Specify reporting loss settings (`weights`, `tau`, `G_max`, error
budgets, minimax) and solver time limits, tolerances, and backend
availability.

- [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  : Choose Computation Limits and Solver Output
- [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  : Choose the Loss and Allowed Grade Reports

## Tables, accessors, and HTML reports

Extract assigned grades, pair relations, criterion error profiles,
report-card tables, and standalone HTML reports from stored results.

- [`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)
  : Extract the Grade Assigned to Each Entity
- [`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)
  : Extract Expected Errors and Loss for Each Criterion
- [`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md)
  : Extract Which Pairwise Directions the Grades Disclose
- [`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
  : Extract Posterior Loss with Its Solver Bound and Status
- [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
  : Create a Standalone Report from Stored Results
- [`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)
  : Prepare an Entity Report Card with Posterior Intervals
- [`as.data.frame(`*`<postrank_fit>`*`)`](https://joonho112.github.io/postrank/reference/postrank_tables.md)
  [`as.data.frame(`*`<postrank_analysis>`*`)`](https://joonho112.github.io/postrank/reference/postrank_tables.md)
  [`as.data.frame(`*`<postrank_baseline>`*`)`](https://joonho112.github.io/postrank/reference/postrank_tables.md)
  [`as.data.frame(`*`<postrank_report_card>`*`)`](https://joonho112.github.io/postrank/reference/postrank_tables.md)
  : Convert Stored Results to Tables

## Figures and plot helpers

Draw the seven common-grade ggplot2 figures, extract their underlying
data tables, and apply package themes and grade palettes.

- [`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md)
  : Choose Colors for Grades and Pair Relations
- [`postrank_plot_commonality()`](https://joonho112.github.io/postrank/reference/postrank_plot_commonality.md)
  : Plot the Extra Criterion Risk of a Common Grading
- [`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md)
  : Plot Grading Rules Evaluated Under the Same Loss
- [`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md)
  : Extract Stored Data for a Figure
- [`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md)
  : Plot Disclosure, Error, and Risk Across Settings
- [`postrank_plot_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_plot_pairwise.md)
  : Plot Posterior Directional-Error Probabilities
- [`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md)
  : Plot Criterion-Wise Error Rates or Risk
- [`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md)
  : Plot Disclosed Pair Relations or Their Changes
- [`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
  : Plot Posterior Estimates and Grade Membership
- [`autoplot()`](https://joonho112.github.io/postrank/reference/reexports.md)
  : Draw a Stored postrank Result with autoplot
- [`scale_colour_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)
  [`scale_color_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)
  [`scale_fill_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)
  : Keep Grade Colors Consistent Across Views
- [`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md)
  : Use the postrank Figure Theme

## Baseline rules and method comparison

Score entities by posterior means, expected ranks, or linear composites,
cut fixed orders into grades, and compare rules under one common loss.

- [`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)
  : Compare Grading Rules on One Posterior and Loss
- [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
  : Posterior-Mean Composite Scores with Declared Scales
- [`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
  : Optimal or Quantile Cuts of a Declared Score Order
- [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
  : Weighted Expected-Rank Scores from Pairwise Errors
- [`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md)
  : Posterior Means and Intervals per Entity and Criterion

## Sensitivity grids and frontiers

Trace grades across tau or error-budget frontiers, run grids of
reporting settings, and measure the per-criterion cost of sharing one
common grade.

- [`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)
  : Criterion-Wise Cost of a Common Grade
- [`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md)
  : Disclosure and Error Frontier Over Tau or One Budget
- [`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)
  : Re-Solve a Decision Problem Over a Settings Grid
- [`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md)
  : Build a One-at-a-Time or Full Settings Grid

## Monte Carlo diagnostics

Summarize Monte Carlo standard errors, resampling fragility, and
out-of-fold loss differences without claiming calibration guarantees.

- [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md)
  : Select and Evaluate Gradings on Two Draw Folds
- [`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
  : Inspect Monte Carlo Precision for Reports or Pairs
- [`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md)
  : Find Pairwise Decisions Near the Monte Carlo Noise Scale

## Conditional IID bounds and envelopes

Compute conditional error radii, regret bounds, and protection envelopes
that hold only under independent draws with a sample size fixed in
advance.

- [`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md)
  : List Which Uncertainty Bounds postrank Computes
- [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
  : Compute a Conditional Fixed-Sample IID Probability Bound
- [`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
  : Solve Protection Envelopes and Bound Regret
- [`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
  : Build Inner and Outer Problems for Error Budgets
- [`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md)
  : Bound Weighted Risk Regret Under Fixed-Sample IID Draws

## Multidomain profile report cards

Assign each entity a separate grade per domain, evaluate additive losses
and joint cross-domain error caps over a declared candidate set, and
plot profile cards.

- [`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)
  : Assess a Fixed Multidomain Grade Profile
- [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  : Specify Loss and Error Controls for Multidomain Grading
- [`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
  : Evaluate a Fixed Multidomain Grade Profile
- [`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
  : Build a Candidate Family of Multidomain Grade Profiles
- [`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md)
  : Extract Verified Multidomain Grades
- [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  : Prepare Posterior States for Multidomain Grading
- [`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)
  : Select a Multidomain Grade Profile from a Candidate Family
- [`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)
  : Plot a Multidomain Grade Profile

## Posteriors with exact ties

Grade entities under posteriors where exact equality between distinct
entities has positive probability; see postrank_tie_capabilities() for
supported modes.

- [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
  : Prepare Posterior Inputs with Positive Equality Probability
- [`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)
  : List Supported Features in Tie-Aware Mode
- [`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
  : Evaluate a Fixed Grading Under Equality-Neutral Loss
- [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
  : Compute Strict Error and Equality Probabilities
- [`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md)
  : Build a Grading Problem Under Equality-Neutral Loss
- [`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md)
  : Solve a Grading Problem Under Equality-Neutral Loss
- [`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)
  : Read a Tie-Aware Posterior Input from JSON
- [`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md)
  : Validate a Tie-Aware Posterior Input
- [`validate_postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_pairwise.md)
  : Validate Tie-Aware Pairwise Probabilities
- [`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md)
  : Validate a Candidate Solution to a Tie-Aware Problem
- [`write_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/write_postrank_tie_draws.md)
  : Write a Tie-Aware Posterior Input to JSON

## Bundled datasets

Synthetic teaching posteriors and the California school, employer
callback, and Alabama county case-study datasets.

- [`postrank_toy`](https://joonho112.github.io/postrank/reference/postrank_toy.md)
  : A Small Sample of 32 IID Posterior Draws
- [`pr_case_alabama`](https://joonho112.github.io/postrank/reference/pr_case_alabama.md)
  : Historical Economic Opportunity in 67 Alabama Counties
- [`pr_case_cde`](https://joonho112.github.io/postrank/reference/pr_case_cde.md)
  : Chronic Absence in a Small California School Example
- [`pr_case_krw`](https://joonho112.github.io/postrank/reference/pr_case_krw.md)
  : Race and Gender Contact Gaps at 97 Employers
- [`pr_example_draws`](https://joonho112.github.io/postrank/reference/pr_example_draws.md)
  : An Additional Three-Criterion Example with 4000 IID Draws
- [`pr_example_gaussian`](https://joonho112.github.io/postrank/reference/pr_example_gaussian.md)
  : The Three-Criterion Example's Gaussian Law
- [`pr_toy_mcmc`](https://joonho112.github.io/postrank/reference/pr_toy_mcmc.md)
  : A Slowly Mixing Two-State Markov-Chain Example
- [`pr_tutorial`](https://joonho112.github.io/postrank/reference/pr_tutorial.md)
  : One or Two Criteria for Six Fictional Sites

## Package overview and global options

Package-level overview and session options (postrank.backend,
postrank.verbose, and postrank.lang).

- [`postrank-package`](https://joonho112.github.io/postrank/reference/postrank-package.md)
  : postrank: Posterior Ranking with Integer Grades
- [`postrank_options`](https://joonho112.github.io/postrank/reference/postrank_options.md)
  : Session Options for Solving and Reporting

## Console text formatters

Class-checked wrappers that return the same console output lines as
format(x) with width and styling controls.

- [`format_postrank_fit_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_analysis_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_draws_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_validation_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_pairwise_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_coefficients_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_coefficient_diagnostics_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_declarations_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_settings_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_control_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_problem_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_report_card_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_baseline_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_comparison_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_frontier_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_commonality_cost_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_sensitivity_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_crossfit_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_mc_fragility_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_diagnostics_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_report_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_guarantee_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_backend_availability_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  [`format_postrank_summary_cli()`](https://joonho112.github.io/postrank/reference/format_postrank_cli.md)
  : Format postrank Results for Reading in the Console
