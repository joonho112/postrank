# postrank: Posterior Ranking with Integer Grades

Posterior information on one or several criteria is used to assign an
integer grade to each entity under a declared loss. For several
criteria, the original P1 entry points assign one common grade.
Multidomain P2 entry points retain a separate grade for each domain. The
input is an existing posterior representation, supplied as draws,
supported analytic laws or previously calculated comparison
probabilities, together with scientific declarations and numerical
qualifications. The package does not fit a statistical model.

## Interpretation of grades

Grade 1 is the highest-priority block; larger targets mean higher
priority, and only the order and equality of grade labels matter. A
shared grade withholds the comparison of its members and asserts no
equality of the entities. The procedure seeks a grade minimizing the
declared weighted wrong-direction loss plus the withholding cost `tau`,
and reports the validated incumbent with the solver's bound and gap;
withholding every comparison, with risk `tau`, is a legitimate action.

## Package functions

|  |  |
|----|----|
| Input | [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md), [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md), [`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md) and the strict constructors |
| Coefficients | [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md), [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md), [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md), [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md) |
| Settings and control | [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md), [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md) |
| Decision | [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md), [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md), [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md), [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md) |
| Baselines and comparison | [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md), [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md), [`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md), [`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md) |
| Side outputs and grids | [`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md), [`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md), [`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md) |
| Diagnostics | [`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md), [`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md), [`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md) |
| Reporting | [`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md), [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md), [`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md) and the console formatters |
| Visualization | the seven `postrank_plot_*()` figures, [`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md), [`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md) |
| Reference calculations | [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md) and the conditional guarantee helpers |

## Getting started

[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md)
provides the same six fictional sites with one or two criteria in
[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md).
The Applied guides present empirical cases and the Methods guides
describe the loss, information requirements, optimization and numerical
uncertainty. Stored-result views need no optimizer. A fresh solve uses
an explicitly selected backend, the `postrank.backend` option, or Gurobi
in that order. HiGHS is an explicit alternative; there is no silent
backend fallback.

## Multidomain profiles

[`postrank_mdomain_input`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
retains identified unit-by-domain states and declared target laws. A
named grade matrix reports a separate order in each domain; a shared
domain grade withholds direction.
[`postrank_mdomain_decision`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
specifies additive losses and mean or direct joint-event guards.
[`postrank_mdomain_evaluate`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
evaluates a fixed matrix;
[`postrank_mdomain_family`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
and
[`postrank_mdomain_solve`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)
select within a complete declared candidate bank. This bank is the
stated scope of optimality.
[`postrank_mdomain_grades`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md)
extracts verified grades,
[`postrank_mdomain_assess`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)
distinguishes finite-law, conditional iid and descriptive MCMC routes,
and
[`postrank_plot_mdomain`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)
displays three stored-card views. Profile computation uses optional gmp
arithmetic and requires no MIP backend. Scientific sampling and
proper-law declarations are retained, not independently established. See
[`vignette("mdomain-quickstart", package = "postrank")`](https://joonho112.github.io/postrank/articles/mdomain-quickstart.md)
and
[`vignette("mdomain-decisions", package = "postrank")`](https://joonho112.github.io/postrank/articles/mdomain-decisions.md).

## Genuine target ties

The separate
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)
domain makes equality neutral in both wrong-direction and
withheld-comparison loss. It supports guarded weighted at-most-G
label-MIP problems through distinct `postrank_tie_*` entry points. Its
all-withhold risk is R0, which can be below tau. Ordinary constructors
retain their tie-free interpretation.

## Case-study data

The three case-study inputs are adapted from public sources and retain
source-specific conditions, separate from the package code license. The
CDE input preserves source attribution, KRW retains its source CC-BY-NC
notice with the license version unspecified, and Alabama retains CC BY
4.0 attribution. Details are given in the data help pages and the
installed DATA-NOTICE.

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
pr_tutorial$one
#> <postrank_coefficients>  6 entities under a declared conditional law
#>   One criterion: score_A.
#>   Gaussian comparison probabilities and marginal summaries are available.
#>   Supported decisions use weighted loss and an upper limit on grades. Target
#>     draws, q constraints, exact grade counts and minimax decisions are
#>     unsupported here.
#>   i summary(x, details = TRUE) retains the conditional-law declarations and
#>     source records.
postrank_expected_rank(pr_tutorial$one)
#>        A        B        C        D        E        F 
#> 1.188874 1.820624 3.358889 3.646891 5.129639 5.855084 
#> attr(,"score_method")
#> [1] "expected_rank"
pr_tutorial$two
#> <postrank_coefficients>  6 entities under a declared conditional law
#>   2 criteria: score_A, score_B.
#>   Gaussian comparison probabilities and marginal summaries are available.
#>   Supported decisions use weighted loss and an upper limit on grades. Target
#>     draws, q constraints, exact grade counts and minimax decisions are
#>     unsupported here.
#>   i summary(x, details = TRUE) retains the conditional-law declarations and
#>     source records.
```
