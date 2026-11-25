# One or Two Criteria for Six Fictional Sites

`pr_tutorial` is a synthetic normal-posterior dataset for six fictional
sites (`A` through `F`) on one criterion (`score_A`) or two criteria
(`score_A` and `score_B`). All means and standard deviations are
specified directly rather than fitted to real data, providing the
introductory examples used in
[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md).

## Format

A named list with four elements:

- one:

  A `postrank_coefficients` object with one criterion (`score_A`) for
  sites `A` through `F`.

- two:

  A `postrank_coefficients` object for the same six sites on `score_A`
  and `score_B`, keeping the exact same marginal distribution for
  `score_A` as `one`.

- units:

  Data frame of site IDs and display labels in input order.

- law:

  List of the specified means, covariance matrices, conditioning note,
  priority direction, units and construction metadata.

## Source

Synthetic normal distribution specified in
`data-raw/pr-tutorial-law.json`; no external data.

## Details

Each site follows an independent bivariate normal distribution with
marginal standard deviations `0.2` and zero within-site correlation
between `score_A` and `score_B`. Larger values mean higher priority on
both criteria, and distinct sites have zero probability of exact
equality.

Pairwise comparison probabilities and marginal summaries come
analytically from the normal distribution, so `pr_tutorial` contains no
posterior draws or Monte Carlo error. Stored grading results for
`pr_tutorial$one` and `pr_tutorial$two` are available through
`postrank_example("tutorial_one")` and
`postrank_example("tutorial_two")`.

## See also

[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md)

## Examples

``` r
names(pr_tutorial)
#> [1] "one"   "two"   "units" "law"  
pr_tutorial$one
#> <postrank_coefficients>  6 entities under a declared conditional law
#>   One criterion: score_A.
#>   Gaussian comparison probabilities and marginal summaries are available.
#>   Supported decisions use weighted loss and an upper limit on grades. Target
#>     draws, q constraints, exact grade counts and minimax decisions are
#>     unsupported here.
#>   i summary(x, details = TRUE) retains the conditional-law declarations and
#>     source records.
postrank_posterior_means(pr_tutorial$one)
#>       criterion
#> entity score_A
#>      A    1.20
#>      B    0.95
#>      C    0.25
#>      D    0.15
#>      E   -0.50
#>      F   -0.80
postrank_posterior_means(pr_tutorial$two)
#>       criterion
#> entity score_A score_B
#>      A    1.20     0.7
#>      B    0.95     0.4
#>      C    0.25     0.9
#>      D    0.15     0.6
#>      E   -0.50    -0.5
#>      F   -0.80    -0.7
```
