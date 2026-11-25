# Stored Example Results

`postrank_example()` reads results stored with the package. Call it
without arguments to list the examples or give a name to load one.
Reading an example needs no solver.

## Usage

``` r
postrank_example(name = NULL)
```

## Arguments

- name:

  Name of a stored result, as listed by `postrank_example()`. If `NULL`
  (the default), the list is returned instead.

## Value

With `name = NULL`, a data frame with one row per stored result and the
columns

- `name` and `description`;

- `class`: the class of the stored object;

- `call`: an example call describing the calculation;

- `computed_with`: the postrank and solver versions that were used;

- `solves`: how many optimization problems were solved (0 for
  comparisons of stored results);

- `created`: when it was computed (UTC).

Otherwise the stored object, for example a `postrank_analysis`, with its
grades and numerical results. Local solver installation paths were
replaced with portable labels when saving.

## Details

The grading analyses used postrank 1.1.0 and HiGHS. The two comparison
examples summarize stored analyses. Some example calls are abbreviated
or refer to another stored result, such as `tutorial_two`. In the calls
for `toy_minimax` and `toy_frontier`, `w` stands for
`c(need_A = 0.6, need_B = 0.4)`.

Before a result is returned, postrank checks that the stored file is
unchanged (its size and SHA-256 checksum) and that this version of
postrank can read it. Reading a result never runs a solver and never
changes the stored files.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)

## Examples

``` r
ex <- postrank_example()
ex[, c("name", "description")]
#>                      name
#> 1           analysis_30x3
#> 2     analysis_30x3_tau35
#> 3          case_alabama67
#> 4             case_cde_12
#> 5       case_krw_signed97
#> 6        commonality_30x3
#> 7  commonality_30x3_tau35
#> 8         comparison_30x3
#> 9   comparison_30x3_tau35
#> 10          frontier_30x3
#> 11 gaussian_analysis_30x3
#> 12           toy_analysis
#> 13        toy_commonality
#> 14           toy_crossfit
#> 15           toy_frontier
#> 16            toy_minimax
#> 17   tutorial_commonality
#> 18      tutorial_frontier
#> 19           tutorial_one
#> 20   tutorial_sensitivity
#> 21           tutorial_two
#>                                                                   description
#> 1  30 example sites, three criteria, from posterior draws (pr_example_draws).
#> 2                                              analysis_30x3 with tau = 0.35.
#> 3                  Alabama county case study (pr_case_alabama), two criteria.
#> 4                  California school case study (pr_case_cde), one criterion.
#> 5                             97-firm case study (pr_case_krw), two criteria.
#> 6                               Cost of one common grading for analysis_30x3.
#> 7                         Cost of one common grading for analysis_30x3_tau35.
#> 8                                postrank_compare() result for analysis_30x3.
#> 9                          postrank_compare() result for analysis_30x3_tau35.
#> 10                             analysis_30x3 graded at tau from 0.10 to 0.45.
#> 11        The 30-site example from Gaussian posteriors (pr_example_gaussian).
#> 12                 Three-entity toy example with two criteria (postrank_toy).
#> 13                               Cost of one common grading for toy_analysis.
#> 14                                            Cross-fitting for toy_analysis.
#> 15                             The toy example graded at three values of tau.
#> 16        The toy example solved with the minimax objective (a postrank_fit).
#> 17             Cost of one common grading for the two scores of tutorial_two.
#> 18                                 tutorial_two graded at five values of tau.
#> 19                  Six tutorial sites graded on one score (pr_tutorial$one).
#> 20                       tutorial_two under a grid of tau, G_max and weights.
#> 21                 Six tutorial sites graded on two scores (pr_tutorial$two).

one <- postrank_example("tutorial_one")
get_grades(one)
#> A B C D E F 
#> 1 1 2 2 3 3 
```
