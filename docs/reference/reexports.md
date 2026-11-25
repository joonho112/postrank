# Draw a Stored postrank Result with autoplot

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
(re-exported from
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html))
dispatches stored `postrank` objects to the matching `postrank_plot_*()`
function and returns a `ggplot` object. Base R
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) uses the same
dispatch, prints the figure, and returns the `ggplot` invisibly. Neither
method solves or computes new posterior summaries.

## Usage

``` r
autoplot(object, ...)
```

## Arguments

- object:

  A `postrank_analysis`, `postrank_fit`, `postrank_report_card`,
  `postrank_baseline`, `postrank_frontier`, `postrank_commonality_cost`,
  or `postrank_comparison`.

- ...:

  Arguments passed on to the target plotting function. Analyses and fits
  accept `type` to select the figure; other arguments (such as `ncol` or
  `view`) follow the target `postrank_plot_*()` function.

## Value

For supported `postrank` classes, a `ggplot` object
([`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns it
invisibly after printing).

## Details

Dispatch by class:

- `postrank_analysis`: `type = "report_card"` (default), `"relations"`,
  `"profile"`, or `"pairwise"`.

- `postrank_fit`: `type = "relations"` (default), `"profile"`, or
  `"pairwise"`.

- `postrank_report_card`:
  [`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md).

- `postrank_baseline`:
  [`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md).

- `postrank_frontier`:
  [`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md).

- `postrank_commonality_cost`:
  [`postrank_plot_commonality()`](https://joonho112.github.io/postrank/reference/postrank_plot_commonality.md).

- `postrank_comparison`:
  [`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md).

Objects missing a report card or checked grading return the same status
`ggplot` as the underlying `postrank_plot_*()` function, while
`type = "pairwise"` remains available on fits without grades.

## See also

[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md),
[`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md),
[`postrank_plot_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_plot_pairwise.md),
[`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md),
[`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md),
[`postrank_plot_commonality()`](https://joonho112.github.io/postrank/reference/postrank_plot_commonality.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
autoplot(one)


two <- postrank_example("tutorial_two")
autoplot(two, type = "relations")
```
