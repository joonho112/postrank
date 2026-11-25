# postrank: Posterior Ranking with Integer Grades

`postrank` assigns an integer grade to each entity (such as a school, an
employer or an area) using posterior information that you supply:
posterior draws, normal or mixture posteriors, or pairwise comparison
probabilities. For one or several criteria,
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
chooses a single common grading across entities; the multidomain
functions (`postrank_mdomain_*`) instead assign a separate grade in each
domain. The package does not fit a statistical model.

## How grades work

Grade 1 is the highest priority; larger values of each target mean
higher priority, as set when the input was built. Entities in different
grades are reported in that order. Entities in the same grade are left
unordered: the report withholds their comparison rather than claiming
they are equal. By default, grades minimize the posterior expected loss
averaged over all entity pairs, where reporting a pair in the wrong
order costs 1 and leaving a pair unordered costs `tau`. Leaving every
pair unordered (a single shared grade, with loss `tau`) is a valid
result.

## Getting started

Start with
[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md),
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
and
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md).
Stored example results from
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)
run without an optimization solver, and
[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md)
holds the six fictional sites used in the introductory guide.

Computing new grades with
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
requires a solver. Install the free `highs` package
(`install.packages("highs")`) and select it with `backend = "highs"` or
`options(postrank.backend = "highs")`, or provide a licensed Gurobi
installation (used by default when no solver is chosen). `postrank`
never switches solvers on its own.

## Package functions

|  |  |
|----|----|
| Input | [`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md), [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md), [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md), [`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md), [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md) |
| Coefficients | [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md), [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md), [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md), [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md) |
| Settings and control | [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md), [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md), [postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md) |
| Decision | [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md), [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md), [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md), [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md) |
| Baselines and comparison | [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md), [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md), [`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md), [`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md) |
| Side outputs and grids | [`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md), [`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md), [`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md) |
| Diagnostics | [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md), [`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md), [`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md) |
| Reporting and stored examples | [`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md), [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md), [`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md), [`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md) |
| Visualization | the seven `postrank_plot_*()` functions, [`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md), [`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md) |
| Reference bounds | [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md) and the conditional envelope functions |
| Multidomain | [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md), [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md), [`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md), [`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md) |

## Multidomain profiles

[`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
represents entity-by-domain posteriors when a separate grade is reported
in each domain rather than one common grade. Within each domain, a
shared grade leaves the pair unordered.
[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
defines additive domain losses and optional mean or joint-event
constraints.
[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
evaluates a given entity-by-domain grade matrix, while
[`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
and
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)
choose a matrix from a declared set of candidate profiles; optimality
holds only within that candidate set.
[`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md)
extracts checked grades,
[`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)
reports finite-law, conditional IID or descriptive MCMC summaries, and
[`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)
plots the results. Multidomain calculations need no mixed-integer solver
and use exact rational arithmetic when the optional `gmp` package is
installed; exact finite-law arithmetic does not verify the statistical
model or intended posterior. See
[`vignette("mdomain-quickstart", package = "postrank")`](https://joonho112.github.io/postrank/articles/mdomain-quickstart.md)
and
[`vignette("mdomain-decisions", package = "postrank")`](https://joonho112.github.io/postrank/articles/mdomain-decisions.md).

## Exact ties

Ordinary inputs assume that distinct entities have zero probability of
being equal. For posteriors in which exact equality has positive
probability, the `postrank_tie_*` functions (see
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md))
treat exact equality as having zero loss whether the pair is ordered or
left unordered, so the single-grade loss `R0` can be below `tau`.

## Case-study data

The three case-study datasets are adapted from public sources and keep
their source conditions, separate from the package code license:
[pr_case_cde](https://joonho112.github.io/postrank/reference/pr_case_cde.md)
preserves source attribution,
[pr_case_krw](https://joonho112.github.io/postrank/reference/pr_case_krw.md)
retains its source CC-BY-NC notice (license version unspecified in the
source), and
[pr_case_alabama](https://joonho112.github.io/postrank/reference/pr_case_alabama.md)
retains CC BY 4.0 attribution. See each dataset's help page and the
installed `DATA-NOTICE.md` file.

## Citation

`citation("postrank")` returns the package, its theory book and the
report-card method of Kline, Rose and Walters (2024), in that order. The
book is *Decisions from noisy multidimensional indicators: Theory,
evidence, and posterior grading* (Version 1.0.0),
[doi:10.5281/zenodo.23790260](https://doi.org/10.5281/zenodo.23790260) .
The method reference is *A discrimination report card*, American
Economic Review, 114(8), 2472-2525,
[doi:10.1257/aer.20230700](https://doi.org/10.1257/aer.20230700) .

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md),
[postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md),
[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md),
[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md)

## Author

**Maintainer**: JoonHo Lee <jlee296@ua.edu>
([ORCID](https://orcid.org/0009-0006-4019-8703)) \[copyright holder\]

Authors:

- JoonHo Lee <jlee296@ua.edu>
  ([ORCID](https://orcid.org/0009-0006-4019-8703)) \[copyright holder\]

## Examples

``` r
one <- postrank_example("tutorial_one")
get_grades(one)
#> A B C D E F 
#> 1 1 2 2 3 3 
get_risk(one)
#> $risk
#> [1] 0.04165164
#> 
#> $lower_bound
#> [1] 0.04165164
#> 
#> $gap
#> [1] 0
#> 
#> $status
#> [1] "optimal"
#> 
postrank_expected_rank(pr_tutorial$one)
#>        A        B        C        D        E        F 
#> 1.188874 1.820624 3.358889 3.646891 5.129639 5.855084 
#> attr(,"score_method")
#> [1] "expected_rank"
```
