# Prepare an Entity Report Card with Posterior Intervals

A validated grading is combined with marginal posterior summaries in an
entity-level report card. The table contains every entity, its grade,
counts of comparisons reported above or below it or withheld, and each
criterion's posterior mean, interval and expected rank. The table is
used for detailed reporting and plotting;
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)
supplies the basic two-column grade table.

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

  A `postrank_fit` or `postrank_analysis` with a validated grade.

- draws:

  Optional source input: `postrank_draws`, `postrank_coefficients`, or
  `postrank_probabilities` with supplied marginal intervals. It must
  have the same input identity as the fit.

- level:

  Central posterior interval level in `(0, 1)`; default `0.90`. For
  supplied marginal summaries, it must exactly match their stored level.

- order:

  Secondary sort key within each grade: `"expected_rank"` (weighted
  expected rank, default), `"mean"` (one criterion's posterior mean,
  larger first) or `"label"` (entity ID).

- order_by:

  Criterion used with `order = "mean"`. Required with several criteria,
  optional with one. Leave `NULL` for other ordering rules.

## Value

A `postrank_report_card` with the full table in `data`. Its other fields
record `level`, `interval_source`, `secondary_order`, `settings`,
`grade_identity`, `input_identity`, `schema_version`, `provenance` and
`warnings`. A selected mean-ordering criterion is recorded in
`provenance$ordering_criterion`.

## Details

The table is ordered first by grade, then the secondary key, with entity
ID breaking remaining ties. Grade 1 has highest priority. Shared grades
withhold comparisons and do not establish latent equality. `n_above`
counts other entities this entity is reported above; `n_below` counts
those it is reported below. Together with `n_withheld`, they sum to n-1
for each row. Columns `mean_`, `lower_`, `upper_` and `expected_rank_`
are suffixed with the criterion ID. Expected rank is \\1 + \sum\_{j \ne
i} e\_{ij,k}\\. Weighted ranks can set the row order; means in different
units are never added for this purpose.

The source comes from `draws`, then the analysis input, then a typed
coefficient or supplied-probability object stored in the fit. A bare
pairwise object contains no marginal posterior law, so supply its
original input through `draws`. Matching cached summaries are reused;
otherwise this function computes summaries from the source. It does not
solve for new grades. Figures and table conversion subsequently read the
prepared card without recomputing these summaries.

Intervals describe the supplied marginal posterior, not Monte Carlo
error or the probability that a grade is correct. A mean can lie outside
an equal-tail interval. Supplied probability matrices require genuine
same-target marginal intervals at their recorded level: a posterior law
or chain history is not inferred from the matrices. Without a validated
grade, the function stops with `no_validated_incumbent`.

The card always contains all entities. Row limits and display labels in
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
affect only the figure.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md),
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  card <- postrank_report_card(one, level = .8, order = "mean")
  as.data.frame(card)
  card$interval_source
}
#> [1] "gaussian_analytic"
```
