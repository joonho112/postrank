# Create a Standalone Report from Stored Results

`postrank_report()` assembles stored grades, per-criterion losses,
solver bounds and available posterior intervals or diagnostics into a
`postrank_report` object, and optionally writes a self-contained English
HTML file. It reads stored results without running a solver or
recomputing probabilities or diagnostics.

## Usage

``` r
postrank_report(
  fit,
  diagnostics = NULL,
  output_file = NULL,
  lang = "en",
  figures = TRUE,
  analysis = NULL
)
```

## Arguments

- fit:

  A `postrank_fit` object, such as `analysis$fit`.

- diagnostics:

  Optional matching `postrank_diagnostics` or
  `postrank_coefficient_diagnostics` object. If `NULL` and `analysis` is
  supplied, `analysis$diagnostics` is used when present. Input, grade
  and settings identities are checked against `fit`.

- output_file:

  Optional path for a new HTML file. Existing files are refused
  (`report_exists`). If `NULL` (the default), the report object is
  returned without writing a file.

- lang:

  Report language. Only `"en"` (English) is supported; any other value
  stops with `unsupported_language` (see
  [postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md)).

- figures:

  Logical scalar (default `TRUE`); whether to embed the report-card and
  criterion-profile plots as base64 PNG images. `FALSE` records
  `reason = "figures_disabled"`.

- analysis:

  Optional `postrank_analysis` object whose `fit` matches `fit`,
  supplying its prepared report card, declaration summary, extras status
  and timings.

## Value

A `postrank_report` list containing the stored grades,
`criterion_profile`, `disclosure`, `objective`, `status`, `report_card`,
`diagnostics` and `diagnostic_table`, `figures`, `declarations`,
`sections`, `strings_version`, and `output_file` (the normalized path
when written, or `NULL`).

## Details

The HTML document is self-contained (inline CSS and base64-encoded PNG
figures, no external network links) with eleven sections: `header`,
`frame`, `declarations`, `grades`, `decision`, `profiles`, `protection`,
`posterior`, `mc`, `stability` and `provenance`, plus a footer. Tables
include every stored row with horizontal scrolling; embedded figures use
the default display limits of
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md)
and
[`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md).
If PNG rendering fails, the report remains valid and `figures` records
the reason.

Grade 1 is the highest priority, and shared grades leave pairs
unordered. A valid one-grade report leaving all pairs unordered shows
`N = 0` and `E_k / N = NA` (loss `tau`); when `fit` has no checked
grading, the report shows the solver status, any lower bound and why
grade tables are unavailable. Solver bounds and gaps describe the
optimization problem only, and marginal posterior intervals describe
target uncertainty rather than Monte Carlo error.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md),
[`vignette("a6-reading-exporting-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a6-reading-exporting-results.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
html <- tempfile(fileext = ".html")
report <- postrank_report(one$fit, analysis = one, output_file = html)
report$sections
#>  [1] "header"       "frame"        "declarations" "grades"       "decision"    
#>  [6] "profiles"     "protection"   "posterior"    "mc"           "stability"   
#> [11] "provenance"  
file.exists(html)
#> [1] TRUE
unlink(html)
```
