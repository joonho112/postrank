# Format postrank Results for Reading in the Console

The `print(x)` method gives a concise display, `summary(x)` describes
the results and settings, and `format(x)` returns the display as text.
The methods use stored results without optimization or recalculation of
posterior probabilities. Grade 1 has highest priority and shared grades
withhold comparisons. Valid all-withheld grades are distinguished from
fits for which no validated grades are available.

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

  An object of the class named by the formatter. A wrong class raises
  `wrong_class`.

- ...:

  Additional display arguments.

- width:

  Line width; `NULL` follows `getOption("width")`. Widths are floored at
  40 characters.

- tier:

  Styling: `NULL` detects the context, `1` uses ANSI styling, `2` is
  plain text, and `3` is for knitted documents.

- n_head:

  Maximum number of rows displayed in table bodies. This affects
  applicable displays only; it does not select or remove stored
  entities.

- details:

  For the summary formatter, include technical source records and
  identities. `NULL` follows the summary object's stored preference.

## Value

Each formatter returns a character vector with one element per console
line. The matching [`format()`](https://rdrr.io/r/base/format.html)
method returns the same lines for the same arguments.
[`print()`](https://rdrr.io/r/base/print.html) writes those lines and
invisibly returns its input.
[`summary()`](https://rdrr.io/r/base/summary.html) returns a structured
summary with its own display.

## Details

Default summaries emphasize grades, disclosure, expected loss and solver
qualifications. Use `summary(x, details = TRUE)` to add technical
details; structured fields remain available with either display setting.
An optimization gap concerns the supplied numerical problem, separately
from posterior uncertainty and Monte Carlo error.

Large grade memberships and table bodies may be shortened for reading.
Accessors and
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)
return the complete stored results, so use those for calculations, row
selection or export. Console text is not a stable data format. Fix
`width` and `tier = 2` when saving plain text.

Styling tiers have the same content; stripping tier 1's ANSI styling
gives tier 2. Entity IDs and stored warning text are preserved. The
named formatter functions on this page remain available alongside
[`format()`](https://rdrr.io/r/base/format.html). The validation
formatter handles input and solution validations; the guarantee
formatter handles conditional risk, regret and protection records; the
summary formatter handles structured summaries.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)

## Examples

``` r
lines <- format(pr_tutorial$one, width = 72, tier = 2)
cat(lines, sep = "\n")
#> <postrank_coefficients>  6 entities under a declared conditional law
#>   One criterion: score_A.
#>   Gaussian comparison probabilities and marginal summaries are
#>     available.
#>   Supported decisions use weighted loss and an upper limit on grades.
#>     Target draws, q constraints, exact grade counts and minimax
#>     decisions are unsupported here.
#>   i summary(x, details = TRUE) retains the conditional-law
#>     declarations and source records.
identical(lines,
  format_postrank_coefficients_cli(pr_tutorial$one, width = 72, tier = 2))
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
technical <- summary(pr_tutorial$one, details = TRUE)
names(technical)
#> [1] "object_class"   "schema_version" "headline"       "provenance"    
#> [5] "declarations"   "settings"       "identities"     "warnings"      
#> [9] "interpretation"
```
