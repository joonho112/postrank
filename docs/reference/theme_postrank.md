# Use the postrank Figure Theme

`theme_postrank()` returns the `ggplot2` theme used across `postrank`
figures, extending
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
with white backgrounds, a light horizontal grid, axis lines and ticks,
left-aligned bold titles, and a bottom legend.

## Usage

``` r
theme_postrank(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size in points (`11` by default).

- base_family:

  Font family passed to `ggplot2` (`""` by default, using the graphics
  device's default family).

## Value

A `ggplot2` `theme` object that can be added to a plot with `+`.

## Details

White plot and panel backgrounds (`"#FFFFFF"`) keep at least 3:1
contrast with the grade color ramp from
[`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md).
The theme changes visual styling only and leaves grades, entity order,
and plotted data untouched; add further
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
calls afterward to customize individual elements.

## See also

[`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md),
[`scale_colour_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)

## Examples

``` r
p <- postrank_plot_pairwise(pr_tutorial$one)
p + theme_postrank(base_size = 12)
```
