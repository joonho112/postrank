# Use the postrank Figure Theme

The theme specifies the typography and white background used in postrank
figures. It extends
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
with a light horizontal grid, axis lines, a left-aligned bold title and
a bottom legend.

## Usage

``` r
theme_postrank(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size in points; default 11.

- base_family:

  Font family passed to ggplot2; the default `""` uses the graphics
  device's default family.

## Value

A ggplot2 `theme` that can be added to a plot.

## Details

White plot and panel backgrounds preserve the contrast of the grade
palette. The theme affects presentation only: grades, entity order and
plotted values are retained. Additional ggplot2 theme settings can be
applied subsequently to modify individual figures.

## See also

[`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md),
[`scale_colour_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)

## Examples

``` r
# A prepared one-criterion probability matrix, with larger text.
p <- postrank_plot_pairwise(pr_tutorial$one)
p + theme_postrank(base_size = 12)
```
