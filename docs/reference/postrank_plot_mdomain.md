# Plot a Multidomain Profile Report Card

Display the validated grades, occupied profile cells, or a specified
pair's domain directions. Plots read the stored result and never select
a new card.

## Usage

``` r
postrank_plot_mdomain(
  x,
  view = c("grades", "cells", "pair"),
  units = NULL,
  domains = NULL,
  ...
)
```

## Arguments

- x:

  A `postrank_mdomain_evaluation` or `postrank_mdomain_fit`. For an
  assessment, use its stored `evaluation`.

- view:

  One of `"grades"`, `"cells"`, or `"pair"`.

- units:

  Optional ordered unit IDs to display. The pair view requires exactly
  two distinct IDs.

- domains:

  Optional ordered domain IDs. Cell views use one or two explicitly
  selected domains when the full card has more than two.

- ...:

  Named display options `title`, `unit_labels`, `domain_labels` and
  `base_size`. Label maps are named character vectors keyed by original
  IDs. The plot records the selected IDs independently of their labels.

## Value

A `ggplot` with inspectable plotting data and a `postrank_mdomain`
attribute describing the view and original card scope. Its `caption`
field retains the full context accompanying the shorter figure caption.

## Details

A tied grade withholds a direction. Cell labels locate grade
combinations. Counts sum over any unshown domains. Risk and protection
in the caption refer to the original card even when only a subset is
shown. Smaller grade numbers mean higher reported priority within that
domain.

## See also

[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md)
