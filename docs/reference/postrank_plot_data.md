# Extract Stored Data for a Figure

`postrank_plot_data()` returns the complete data frame (or named list of
data frames) underlying the seven `postrank` plot types without solving,
evaluating gradings, or recomputing posterior summaries. Plot display
caps (`max_rows`, `max_entities`) and label maps do not filter or rename
the returned tables.

## Usage

``` r
postrank_plot_data(x, which = NULL)
```

## Arguments

- x:

  A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
  `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`,
  `postrank_comparison`, `postrank_pairwise` (including
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)),
  or `postrank_coefficients`.

- which:

  Optional single string naming the component to extract. For a
  `postrank_analysis`, `NULL` returns a named list of `"report_card"`,
  `"relations"`, and `"profile"`, or pass one of `"report_card"`,
  `"relations"`, `"profile"`, or `"pairwise"`. See Details for other
  classes.

## Value

A data frame, a named list of three components (with an `"availability"`
attribute) when `x` is a `postrank_analysis` and `which = NULL`, or
`NULL` when a requested `"report_card"` or `"relations"` table has no
underlying report card or checked grading. When `profile` is requested
without a checked grading, returns the zero-row data frame from
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md).

## Details

Accepted `which` values by input class:

- `postrank_analysis`: `NULL` returns
  `list(report_card = ..., relations = ..., profile = ...)` whose
  `"availability"` attribute gives `list(available, reason)` for each
  slot; `"pairwise"` must be requested by name because its table has
  `n * n * K` rows.

- `postrank_fit`: defaults to `"relations"` and also accepts `"profile"`
  or `"pairwise"`.

- `postrank_report_card`: returns the long report-card table.

- `postrank_baseline`: returns the pair-relations table.

- `postrank_frontier` and `postrank_commonality_cost`: return `x$table`.

- `postrank_comparison`: returns `x$table` by default, or `x$relations`
  when `which = "relations"`.

- `postrank_pairwise` and `postrank_coefficients`: accept `NULL` or
  `"pairwise"` and return the pairwise probability table (aggregate raw
  `postrank_draws` with
  [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
  first).

Returned columns for reshaped views:

- `report_card`: `entity_id`, `grade`, `sort_rank`, `n_withheld`,
  `criterion`, `mean`, `lower`, `upper`, and `expected_rank`, stacked by
  criterion in stored card order (interval `level` and `interval_source`
  stay on the `postrank_report_card` object).

- `relations`: one row per unordered pair (`i_pos < j_pos`) in
  grade-then-ID order with `entity_i`, `entity_j`, `i_pos`, `j_pos`,
  integer `code` (`1L` = `"above"`, `0L` = `"withheld"`, `-1L` =
  `"below"`), and factor `relation`.

- `profile`: same columns as
  [`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md).

- `pairwise`: `entity_i`, `entity_j`, `criterion`, and
  `error_probability` (`n * n * K` rows in input order with `entity_i`
  varying fastest, including `NA` diagonal entries; available even when
  a fit has no checked grading).

Passing `which` equal to `"sensitivity"`, `"fragility"`, `"crossfit"`,
`"trace"`, or `"dispersion"` stops with condition code
`"unshipped_figure"`; those figure names are not implemented as plot
views, although the numerical functions
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md),
[`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md),
and
[`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md)
are available.

## See also

[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md),
[`postrank_plot_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_plot_pairwise.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
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
```
