# Prepare an Entity Report Card with Posterior Intervals

`postrank_report_card()` combines a checked grading with marginal
posterior means, central intervals and expected ranks in an entity-level
table. Each row gives an entity's grade, how many other entities are
reported above it, below it or in the same grade, and per-criterion
posterior summaries. For a basic two-column grade table, use
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md).

## Usage

``` r
postrank_report_card(
  x,
  draws = NULL,
  level = 0.9,
  order = c("expected_rank", "mean", "label"),
  order_by = NULL
)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` object with a checked grading
  (`incumbent_validated = TRUE`; otherwise stops with
  `no_validated_incumbent`).

- draws:

  Optional posterior input matching `x`'s `input_identity`: a
  `postrank_draws`, `postrank_coefficients`, or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object with marginal interval summaries. Required when `x` is a
  `postrank_fit` built from a `postrank_pairwise` object that does not
  store the original draws.

- level:

  Central posterior interval level in `(0, 1)` (default `0.90`). For a
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  input with supplied intervals, `level` must equal the stored
  `summaries$level`.

- order:

  Secondary sort order within each grade: `"expected_rank"` (weighted
  expected rank, the default), `"mean"` (descending posterior mean on
  one criterion) or `"label"` (entity ID).

- order_by:

  Criterion ID used when `order = "mean"` (required when several
  criteria are present, optional with one; must be `NULL` for other
  `order` values).

## Value

A `postrank_report_card` object with the full data frame in `data`, plus
`level`, `interval_source`, `secondary_order`, `settings`,
`grade_identity`, `input_identity`, `schema_version`, `provenance`
(recording `ordering_criterion` when `order = "mean"`) and `warnings`.

## Details

Rows are sorted first by `grade` (grade 1 is highest priority; shared
grades leave pairs unordered), then by `order`, with `entity_id`
breaking remaining ties. In `data`, `n_above` counts entities graded
below this entity (`grade[i] < grade[j]`), `n_below` counts entities
graded above it, and `n_withheld` counts other entities sharing its
grade; for every row, `n_above + n_below + n_withheld == n - 1`.
Per-criterion columns are named `mean_<k>`, `lower_<k>`, `upper_<k>` and
`expected_rank_<k>`, where expected rank is \\1 + \sum\_{j \ne i}
e\_{ij,k}\\. When `order = "expected_rank"`, rows within a grade are
ordered by weighted expected rank rather than adding means across
criteria in different units.

Cached summaries on a `postrank_analysis` at the requested `level` are
reused; otherwise summaries are computed from the posterior source
without re-solving for grades. Intervals summarize marginal target
uncertainty (a posterior mean can lie outside an equal-tail interval),
not Monte Carlo error or the probability that a grade assignment is
right. `data` always retains all `n` entities; row caps in
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
affect only the plot.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md),
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
card <- postrank_report_card(one, level = 0.80, order = "mean")
as.data.frame(card)
#>   entity_id grade sort_rank n_above n_below n_withheld mean_score_A
#> 1         A     1         1       4       0          1         1.20
#> 2         B     1         2       4       0          1         0.95
#> 3         C     2         3       2       2          1         0.25
#> 4         D     2         4       2       2          1         0.15
#> 5         E     3         5       0       4          1        -0.50
#> 6         F     3         6       0       4          1        -0.80
#>   lower_score_A upper_score_A expected_rank_score_A
#> 1   0.943689687     1.4563103              1.188874
#> 2   0.693689687     1.2063103              1.820624
#> 3  -0.006310313     0.5063103              3.358889
#> 4  -0.106310313     0.4063103              3.646891
#> 5  -0.756310313    -0.2436897              5.129639
#> 6  -1.056310313    -0.5436897              5.855084
card$interval_source
#> [1] "gaussian_analytic"
```
