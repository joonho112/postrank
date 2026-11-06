# One or Two Criteria for Six Fictional Sites

This Gaussian example illustrates the disclosure and withholding of
pairwise comparisons through integer grades. All means and variances are
specified directly, so the posterior laws are illustrative rather than
fitted to observations.

## Format

A named list with four elements:

- one:

  A `postrank_coefficients` input with one criterion, `score_A`, for
  sites A through F.

- two:

  A `postrank_coefficients` input for the same six sites with `score_A`
  and `score_B`. The law of `score_A` is identical to that in `one`.

- units:

  Site IDs and display labels in input order.

- law:

  The fixed means, covariance matrices, conditioning statement,
  direction, units and maintainer source information.

## Source

Maintainer-created synthetic law in `data-raw/pr-tutorial-law.json`; no
external observations.

## Details

Each site has a bivariate normal law. Both marginal standard deviations
are 0.2. The two criteria are independent within each site, and sites
are independent. Higher values have higher priority on both criteria.
Scores are in illustrative standardized units with no empirical
calibration. Continuous normal laws have zero equality probability.

Analytic comparison probabilities and marginal summaries are calculated
from the same specified law. The example contains no draws, fitted-model
uncertainty or Monte Carlo diagnostics. Addition of the second criterion
changes the decision problem while retaining the first criterion's
marginal law.

## See also

[`vignette("a1-getting-started", package = "postrank")`](https://joonho112.github.io/postrank/articles/a1-getting-started.md),
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)

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
pr_tutorial$two
#> <postrank_coefficients>  6 entities under a declared conditional law
#>   2 criteria: score_A, score_B.
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
