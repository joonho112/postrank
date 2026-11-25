# Choose Colors for Grades and Pair Relations

`postrank_palette()` returns the color vectors used in `postrank`
figures for grades, pair relations, relation changes, and
directional-error probabilities. Grade colors run from dark blue
(`"#153653"`) for the highest-priority grade `1` to lighter blue-teal
(`"#4F879E"`) for larger grade numbers.

## Usage

``` r
postrank_palette(n, which = c("grade", "relation", "change", "sequential"))
```

## Arguments

- n:

  Integer number of grades from `1` to `64` when `which = "grade"`.
  Ignored (and may be omitted) for the other palettes.

- which:

  Palette to return: `"grade"` (the default), `"relation"`, `"change"`,
  or `"sequential"`.

## Value

A character vector of R color specifications (hexadecimal strings and,
for neutral states, R gray names):

- `"grade"`: named `"1"` through `as.character(n)`.

- `"relation"`: named `"above"`, `"withheld"`, and `"below"`.

- `"change"`: named `"unchanged"`, `"newly disclosed"`,
  `"newly withheld"`, and `"reversed"`.

- `"sequential"`: unnamed seven-stop light-to-dark blue ramp.

## Details

For `which = "grade"`, sRGB channels are linearly interpolated from
`"#153653"` to `"#4F879E"` (`"#153653"` when `n = 1`), giving strictly
increasing luminance with grade number and at least 3:1 contrast against
white across `1..64`. Values of `n` outside `1..64` stop with an error;
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
switches to neutral dark gray above 64 grades.

In `"relation"`, `"above"` (`"#0072B2"`) and `"below"` (`"#E69F00"`) use
Okabe-Ito colors and `"withheld"` uses `"grey80"`. In `"change"`,
`"unchanged"` (`"grey92"`, covering pairs ordered the same way or
withheld in both gradings) is light gray, `"newly withheld"`
(`"#999999"`) is medium gray, `"newly disclosed"` is `"#0072B2"`, and
`"reversed"` is `"#D55E00"`. `"sequential"` runs from `"#EFF3FF"` to
`"#084594"` for probability heat maps.

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
