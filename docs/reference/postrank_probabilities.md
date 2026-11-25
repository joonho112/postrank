# Use Previously Calculated Comparison Probabilities

`postrank_probabilities()` builds a pairwise-probability input from
comparison probabilities computed outside `postrank` (for example by
analytic formulas, numerical integration or another posterior summary),
without requiring posterior draws. Pass a square matrix for one
criterion or a 3D array for several criteria.

## Usage

``` r
postrank_probabilities(
  probabilities,
  event,
  zero_ties,
  margin,
  source,
  targets,
  criterion = NULL,
  correction = "none",
  tolerance = NULL,
  summaries = NULL
)
```

## Arguments

- probabilities:

  A named `n x n` numeric matrix for one criterion, or a named
  `n x n x K` numeric array (`n >= 2`). Row and column entity names must
  match in the same order. Diagonal entries must be `NA` (unused
  self-comparisons, not `0` or `NaN`), and off-diagonal entries must be
  finite numbers in `[0, 1]`.

- event:

  Which pairwise event `probabilities[i, j, ]` represents (required):
  `"higher_priority"` for `P(theta[i, k] > theta[j, k])`, or
  `"directional_error"` for `P(theta[i, k] <= theta[j, k])`, where
  larger `theta` means higher priority. The returned `$e` array always
  stores `"directional_error"` (the expected error if entity `i` is
  graded above entity `j`).

- zero_ties:

  Must be `TRUE` (required): distinct entities have zero probability of
  exact equality on each criterion. For posteriors with positive or
  unknown tie probability, use
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

- margin:

  Must be `0` (required). Nonzero comparison margins are not supported.

- source:

  Plain named list with strings `kind`, `description` and `conditioning`
  (required). `kind` must be one of `"analytic_reference"`,
  `"numerical_integration"`, `"iid_summary"`, `"mcmc_summary"` or
  `"published_reference"`. State how the probabilities were computed and
  what was conditioned on (including any fixed empirical Bayes prior).

- targets:

  Character vector named by criterion (in the same order as
  `probabilities`) describing each higher-priority target and its units
  (required).

- criterion:

  Single criterion name when `probabilities` is a 2D matrix; leave
  `NULL` when `probabilities` is a 3D array (whose 3rd axis supplies the
  names).

- correction:

  How small discrepancies in `P(i, j) + P(j, i) = 1` are handled:
  `"none"` (the default) or `"symmetric"`.

- tolerance:

  Maximum allowed complement discrepancy `max |P(i, j) + P(j, i) - 1|`
  when `correction = "symmetric"`, a finite number in `[0, 1e-3]` (this
  cap is a safeguard, not a recommended integration tolerance). Must be
  `NULL` when `correction = "none"`, which requires complement sums to
  be within `1e-12` of `1`.

- summaries:

  Optional plain named list of marginal target summaries for the same
  oriented targets and units: `means` (`n x K` matrix with matching row
  and column names), `same_targets = TRUE`, and `description`. To enable
  report cards, also supply `lower`, `upper` (`n x K` matrices with
  `lower <= upper`) and `level` (`0 < level < 1`) together; intervals at
  any other `level` cannot be computed from these summaries.

## Value

A `postrank_probabilities` object (inheriting from `postrank_pairwise`)
containing directional error probabilities `e`, `raw_probabilities`,
`corrected_probabilities`, `correction` diagnostics, `source`,
`targets`, `summaries` and `capabilities`. Accepted by
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
and
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md).

## Details

**Supported settings and summaries.** Supplied probabilities support the
weighted expected-loss objective with `G_max`. Minimax objectives, `q`
error budgets and `exact_G` are not available in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md).
Because no posterior draws are present, Monte Carlo fragility,
cross-fitting, draw diagnostics and IID bounds are unavailable; a report
card is available in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)
only when `summaries` includes `lower`, `upper` and `level`, and only at
that `level`.

**Symmetric correction.** When `correction = "symmetric"`, each
upper-triangle entry is replaced by `(a[i, j] + 1 - a[j, i]) / 2` and
the lower-triangle entry is set to `1 - a[i, j]`. For any fixed grading
with `N` ordered pairs out of `M` total pairs, this changes the weighted
loss by at most `N / M` times the weighted sum of
`correction$maximum_absolute_change`. That bound measures only the
adjustment to the supplied array, not numerical integration, Monte Carlo
or model error.

**Scope of checks.** Checking range and complement sums does not verify
that the probabilities come from a coherent joint posterior or an
adequate model.

## See also

[`validate_postrank_probabilities()`](https://joonho112.github.io/postrank/reference/validate_postrank_probabilities.md),
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md),
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)

## Examples

``` r
x <- postrank_probabilities(pr_tutorial$one$e,
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal-CDF comparisons for pr_tutorial score A",
    conditioning = "The specified means, variances and independent-site law are fixed"),
  targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
postrank_evaluate(grade, x, c(score_A = 1), tau = 0.25)$weighted_risk
#> [1] 0.05165164
validate_postrank_probabilities(x)
```
