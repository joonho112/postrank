# Format postrank Results for Reading in the Console

In ordinary use, call `print(x)` for a concise console display,
`summary(x)` (or `summary(x, details = TRUE)`) for a fuller summary of
settings and bounds, and `format(x)` to get the console lines as a
character vector. The 24 `format_postrank_*_cli()` functions return the
exact same lines as `format(x)` when you want to set line width, styling
tier or table row count directly and verify `x`'s class. None of these
methods run a solver or recompute probabilities.

## Usage

``` r
format_postrank_fit_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_analysis_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_draws_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_validation_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_pairwise_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_coefficients_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_coefficient_diagnostics_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_declarations_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_settings_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_control_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_problem_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_report_card_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_baseline_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_comparison_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_frontier_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_commonality_cost_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_sensitivity_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_crossfit_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_mc_fragility_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_diagnostics_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_report_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_guarantee_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_backend_availability_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_summary_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L,
  details = NULL
)
```

## Arguments

- x:

  An object of the class named by the formatter (wrong classes stop with
  error code `wrong_class`). `format_postrank_validation_cli()` accepts
  both `postrank_validation` and `postrank_solution_validation`;
  `format_postrank_guarantee_cli()` handles the conditional bound and
  envelope records; `format_postrank_summary_cli()` formats objects
  returned by [`summary()`](https://rdrr.io/r/base/summary.html).

- ...:

  Additional display arguments passed between methods.

- width:

  Target line width in characters (`NULL` reads `getOption("width")`,
  floored at `40`).

- tier:

  Styling mode: `NULL` detects the session context, `1` adds ANSI
  terminal styling, `2` produces plain text (identical to tier `1` with
  ANSI codes stripped), and `3` formats for knitted documents.

- n_head:

  Maximum number of rows shown in printed table bodies (default `10L`).
  Does not drop or alter rows stored inside `x`.

- details:

  Logical for `format_postrank_summary_cli()` and
  [`summary()`](https://rdrr.io/r/base/summary.html): whether to include
  technical source records and hashes. `NULL` uses the setting stored on
  the summary object.

## Value

Each `format_postrank_*_cli()` function and
[`format()`](https://rdrr.io/r/base/format.html) method returns a
character vector with one element per line.
[`print()`](https://rdrr.io/r/base/print.html) writes those lines and
returns `x` invisibly.
[`summary()`](https://rdrr.io/r/base/summary.html) returns a structured
`postrank_summary` object with its own
[`print()`](https://rdrr.io/r/base/print.html) and
[`format()`](https://rdrr.io/r/base/format.html) methods (controlled by
`postrank.lang`; see
[postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md)).

## Details

Console output uses `"disclosed"` for ordered pairs, `"withheld"` for
unordered pairs (shared grades), and `"risk"` for posterior expected
loss. Long grade member lists and tables are shortened for reading; use
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
and
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)
to extract complete results rather than parsing console text. When
saving plain text, fix `width` and `tier = 2`.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md),
[postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
lines <- format(one, width = 72, tier = 2)
cat(lines, sep = "\n")
#> <postrank_analysis>  6 entities in 3 grades (sizes 2 / 2 / 2)
#>   One criterion: score_A.
#>   Posterior loss: 0.0417.
#>   Disclosed 12 of 15 pairs (80.0%); withheld 3.
#>   Expected error among disclosed pairs: score_A 0.002.
#>   Solver: Optimal within solver tolerances.
#>   Optimization gap: 0; requested absolute gap 1e-08.
#>   Prepared: report card.
#>   Grade 1 has highest priority; a shared grade withholds the comparison.
#>   grade 1 (2): A, B
#>   grade 2 (2): C, D
#>   grade 3 (2): E, F
#>   !  1 warning recorded: Reported lower bound exceeded the validated ...
#>   i summary(x) explains the loss, settings and bounds; get_grades(x)
#>     returns all grades.
identical(lines, format_postrank_analysis_cli(one, width = 72, tier = 2))
#> [1] TRUE

summary(pr_tutorial$one)
#> <postrank_coefficients_summary>
#> Result:
#>   6 entities under a declared conditional law
#>   One criterion: score_A.
#>   Gaussian comparison probabilities and marginal summaries are available.
#>   Supported decisions use weighted loss and an upper limit on grades. Target
#>     draws, q constraints, exact grade counts and minimax decisions are
#>     unsupported here.
#>   i summary(x, details = TRUE) adds source records and identities; structured
#>     fields remain available.
tech <- summary(pr_tutorial$one, details = TRUE)
names(tech)
#> [1] "object_class"   "schema_version" "headline"       "provenance"    
#> [5] "declarations"   "settings"       "identities"     "warnings"      
#> [9] "interpretation"
```
