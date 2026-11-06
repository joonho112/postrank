# Choose Colors for Grades and Pair Relations

The palettes define the colors used for grades, relations, relation
changes and probabilities. Grade colors progress from dark for the
highest-priority grade 1 to lighter colors for larger grade numbers.

## Usage

``` r
postrank_palette(n, which = c("grade", "relation", "change", "sequential"))
```

## Arguments

- n:

  Number of grades, from 1 to 64, for `which = "grade"`. Ignored for
  other palettes and may be omitted for them.

- which:

  `"grade"`, `"relation"`, `"change"` or `"sequential"`.

## Value

A character vector of R color specifications. Grade colors are named
`"1"` through `"n"`; relation and change colors are named by state. The
seven-stop sequential vector is unnamed. Some state colors use R gray
names rather than hexadecimal notation.

## Details

The grade palette interpolates sRGB channels from `#153653` to
`#4F879E`. Across its supported sizes, luminance increases with grade
number and colors retain at least 3:1 contrast against white. For a
single grade, the sole color is `#153653`.

The relation palette names `above`, `withheld` and `below`, with gray
for withholding. The change palette names `unchanged`,
`newly disclosed`, `newly withheld` and `reversed`; unchanged is light
gray, newly withheld is medium gray. Unchanged pairs may be ordered or
withheld. The colored states use selected Okabe-Ito colors.
`"sequential"` provides a light-to-dark Blues ramp used for
probabilities. A grade palette supports at most 64 grades; the
report-card view uses neutral ink and labels beyond that limit.

## See also

[`scale_colour_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md),
[`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md),
[`postrank_plot_relations()`](https://joonho112.github.io/postrank/reference/postrank_plot_relations.md)

## Examples

``` r
postrank_palette(1)
#>         1 
#> "#153653" 
postrank_palette(4)
#>         1         2         3         4 
#> "#153653" "#28516C" "#3C6C85" "#4F879E" 
postrank_palette(which = "relation")
#>     above  withheld     below 
#> "#0072B2"  "grey80" "#E69F00" 
postrank_palette(which = "change")
#>       unchanged newly disclosed  newly withheld        reversed 
#>        "grey92"       "#0072B2"       "#999999"       "#D55E00" 
```
