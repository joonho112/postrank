# Keep Grade Colors Consistent Across Views

`scale_colour_grade()`, `scale_color_grade()`, and `scale_fill_grade()`
construct discrete `ggplot2` color and fill scales for grade membership
using
[`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md).
Passing the full report's grade count `n_grades` keeps grade colors and
legend entries identical when plotting a subset of entities that omits
one or more grades.

## Usage

``` r
scale_colour_grade(n_grades = NULL, ...)

scale_color_grade(n_grades = NULL, ...)

scale_fill_grade(n_grades = NULL, ...)
```

## Arguments

- n_grades:

  Integer number of grades in the full grading (`1` to `64`), or `NULL`
  (the default) to size the palette from the discrete levels present in
  the plotted data.

- ...:

  Additional arguments passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).
  Do not pass `aesthetics`, `palette`, `drop`, `name`, or (when
  `n_grades` is supplied) `limits`, which are set by the scale helper.

## Value

A `ggplot2` discrete color or fill scale.

## Details

Map grades as discrete values such as `factor(grade)`. When `n_grades`
is supplied, the scale fixes `limits = as.character(seq_len(n_grades))`
and `drop = FALSE` so missing grades retain their slot on the color
ramp. Grade `1` has highest priority; shared color indicates shared
grade membership (withheld ordering, not equal targets).

## See also

[`postrank_palette()`](https://joonho112.github.io/postrank/reference/postrank_palette.md),
[`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md)

## Examples

``` r
d <- data.frame(entity = c("A", "C"), value = c(2, 1), grade = factor(c(1, 3)))
ggplot2::ggplot(d, ggplot2::aes(value, entity, colour = grade)) +
  ggplot2::geom_point(size = 3) +
  scale_colour_grade(n_grades = 3) +
  theme_postrank()
```
