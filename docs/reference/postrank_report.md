# Create a Standalone Report from Stored Results

The report combines stored grades, criterion losses, solver
qualifications and available posterior summaries or diagnostics. A
self-contained English HTML file can be written for offline use.
Supplying `analysis` with its `fit` includes the prepared report card
and other stored components. Report construction does not optimize or
evaluate new grades, calculate pairwise probabilities or prepare missing
summaries.

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

  A `postrank_fit`, such as `analysis$fit`.

- diagnostics:

  Optional matching `postrank_diagnostics` or
  `postrank_coefficient_diagnostics`. Omit to use matching diagnostics
  already stored in `analysis`. Source, grade and settings are checked;
  diagnostics are not recomputed.

- output_file:

  Optional path for a new HTML file. An existing file is refused. `NULL`
  returns the report object without writing HTML.

- lang:

  Report language. Only `"en"` is supported; another language raises
  `unsupported_language`.

- figures:

  Logical; embed eligible report-card and criterion-profile figures as
  PNGs. `FALSE` records `figures_disabled`.

- analysis:

  Optional `postrank_analysis` with the same fit identities. Supplies
  its prepared report card, declarations, extras and timings.

## Value

A `postrank_report` list containing the stored grades, criterion
profile, disclosure, objective, status, numerical validation information
and source records, plus `figures`, `declarations`, `sections` and
`strings_version`. `output_file` records the written path, or `NULL`.
`diagnostics` retains the supplied object. Its `diagnostic_table` is
trace-oriented for draws; for coefficient inputs it has columns
`quantity`, `metric`, `value`, `available`, `NA_reason`, `method`,
`raw_value`, `result_kind`, `warnings` and `error`. Unavailable metrics
retain their reasons rather than becoming zero.

## Details

Grade 1 has highest priority; shared grades withhold directions. A valid
all-withheld report has N=0 and undefined conditional error ratios, not
an error-free ranking. With no validated grade, the report instead shows
the solver status, available bounds and reasons for unavailable
grade-dependent content. An optimization gap concerns the supplied
numerical problem, separately from posterior or model uncertainty.

Marginal posterior intervals retain their source and level and describe
target uncertainty rather than Monte Carlo error. Stored diagnostics
retain their producer's methods, warnings and unavailable values.
Required inputs, including `chain_history` for eligible
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
calculations, must be supplied when diagnostics are prepared; report
construction cannot recover missing draws or history. Numerical checks
of an empirical error budget alone do not establish a guarantee for the
true posterior.

The HTML has eleven sections: `header`, `frame`, `declarations`,
`grades`, `decision`, `profiles`, `protection`, `posterior`, `mc`,
`stability` and `provenance`, followed by a footer. Tables include all
stored rows; wide tables scroll horizontally. Included figures use their
default display limits, so a report-card figure may show a stated subset
while the table remains complete. Use the plotting functions separately
for custom entity selection or labels; this function has no paging
argument.

Figures are embedded in the HTML, with no separate image or network
dependency. Each attempt records `id`, `available`, `reason`,
`png_base64`, `caption` and `alt` in `figures`. A missing PNG device or
failed figure leaves an explanatory record and a usable report.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_plot_report_card()`](https://joonho112.github.io/postrank/reference/postrank_plot_report_card.md),
[`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md),
[`vignette("a6-reading-exporting-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a6-reading-exporting-results.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  html <- tempfile(fileext = ".html")
  report <- postrank_report(one$fit, analysis = one, output_file = html)
  report
  vapply(report$figures, `[[`, logical(1), "available")
  unlink(html)
}
```
