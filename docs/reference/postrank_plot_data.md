# Extract Stored Data for a Figure

The complete data underlying the seven postrank figure types are
returned for inspection or alternative displays. Stored results are read
and reshaped without optimization, action evaluation or calculation of
posterior summaries. Plot row limits and display labels do not affect
the returned tables.

## Usage

``` r
postrank_plot_data(x, which = NULL)
```

## Arguments

- x:

  A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
  `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`,
  `postrank_comparison`, or prepared pairwise/coefficient input.

- which:

  Optional component name. Analysis components are `"report_card"`,
  `"relations"` and `"profile"`; `"pairwise"` explicitly requests
  prepared probabilities. See Details for other classes.

## Value

A data frame, a named list for an analysis with `which = NULL`, or
`NULL` for an unavailable card or relation component. A profile without
a validated incumbent is an empty typed data frame. The analysis list
has an `availability` attribute with an available flag and reason per
component.

## Details

For an analysis, `which = NULL` returns `report_card`, `relations` and
`profile`. Pairwise probabilities are deliberately separate because the
complete table has `n * n * K` rows. A fit defaults to `"relations"` and
also accepts `"profile"` or `"pairwise"`. A report card returns its long
table; a baseline returns its relations. Frontier and commonality
objects return their stored tables. A comparison returns its summary
table by default and its change-count table for `which = "relations"`.

The report-card table has `entity_id`, `grade`, `sort_rank`,
`n_withheld`, `criterion`, `mean`, `lower`, `upper` and `expected_rank`.
Rows are grouped by criterion and follow stored card order within each
criterion; interval level and source remain on the card object.
Relations contain one row per unordered pair with `entity_i`,
`entity_j`, `i_pos`, `j_pos`, `code` and `relation`, in grade-then-ID
order. Code 1 means the first entity is above the second, 0 means
withheld and -1 means below. Profile columns are listed in
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md).

`which = "pairwise"` returns `entity_i`, `entity_j`, `criterion` and
`error_probability`, including the `NA` diagonal. It preserves input ID
order, with `entity_i` varying fastest. This component remains available
for fits without a validated grade. Prepared
pairwise/probability/coefficient objects return it by default, but raw
draws must first be aggregated with
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md).
The table is not a relation-change map; use
[`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md)
with two actions for that view.

The designs `"sensitivity"`, `"fragility"`, `"crossfit"`, `"trace"` and
`"dispersion"` are reserved and raise `unshipped_figure`. This does not
imply that all similarly named numerical diagnostic functions are
unavailable.

## See also

[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md),
[`postrank_plot_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_plot_pairwise.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)

## Examples

``` r
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
card_data <- postrank_plot_data(one, "report_card")
head(card_data)
#>   entity_id grade sort_rank n_withheld criterion  mean       lower      upper
#> 1         A     1         1          1   score_A  1.20  0.87102927  1.5289707
#> 2         B     1         2          1   score_A  0.95  0.62102927  1.2789707
#> 3         C     2         3          1   score_A  0.25 -0.07897073  0.5789707
#> 4         D     2         4          1   score_A  0.15 -0.17897073  0.4789707
#> 5         E     3         5          1   score_A -0.50 -0.82897073 -0.1710293
#> 6         F     3         6          1   score_A -0.80 -1.12897073 -0.4710293
#>   expected_rank
#> 1      1.188874
#> 2      1.820624
#> 3      3.358889
#> 4      3.646891
#> 5      5.129639
#> 6      5.855084

# Complete two-criterion probability table, including its gray diagonal cells.
pair_data <- postrank_plot_data(pr_tutorial$two, "pairwise")
nrow(pair_data)
#> [1] 72
head(pair_data)
#>   entity_i entity_j criterion error_probability
#> 1        A        A   score_A                NA
#> 2        B        A   score_A         0.8116204
#> 3        C        A   score_A         0.9996085
#> 4        D        A   score_A         0.9998973
#> 5        E        A   score_A         1.0000000
#> 6        F        A   score_A         1.0000000
attr(postrank_plot_data(one), "availability")
#> $report_card
#> $report_card$available
#> [1] TRUE
#> 
#> $report_card$reason
#> NULL
#> 
#> 
#> $relations
#> $relations$available
#> [1] TRUE
#> 
#> $relations$reason
#> NULL
#> 
#> 
#> $profile
#> $profile$available
#> [1] TRUE
#> 
#> $profile$reason
#> NULL
#> 
#> 
```
