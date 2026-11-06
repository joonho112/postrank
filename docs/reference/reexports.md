# Draw a Stored postrank Result with autoplot

The re-exported
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
generic dispatches prepared postrank results to the corresponding
plotting method and returns a `ggplot`. Base R
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) uses the same
dispatch, prints the figure and returns it invisibly. Both methods use
prepared results without computing a new grading or diagnostic.

## Usage

``` r
autoplot(object, ...)
```

## Arguments

- object:

  A prepared postrank analysis, fit, report card, baseline, frontier,
  commonality result or method comparison.

- ...:

  Arguments for the selected plotting method. Analyses and fits accept
  `type` to choose the view; other arguments, such as `ncol` or `view`,
  follow the corresponding plotting function's help.

## Value

For the supported postrank classes, a `ggplot` object.

## Details

An analysis defaults to its prepared report card and also accepts
`type = "relations"`, `"profile"` or `"pairwise"`. A fit defaults to
relations and accepts `"relations"`, `"profile"` or `"pairwise"`. Report
cards, frontiers, commonality results, comparisons and baselines
dispatch to their corresponding plotting functions. Other named
arguments are passed to that figure, such as `ncol = 1` for a card or
`view = "relations"` for a comparison.

Missing prepared results are handled according to the corresponding
plotting function. Prepared pairwise probabilities remain available for
a fit without grades. The seven `postrank_plot_*()` functions provide
explicit selection of the figure type.

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
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
p <- autoplot(one) # prepared one-criterion report card
p

two <- load_or_compute("tutorial_two")
autoplot(two, type = "relations")
```
