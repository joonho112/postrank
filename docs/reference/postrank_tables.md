# Convert Stored Results to Tables

The [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
methods return complete tables of stored results. For a fit, analysis or
baseline, the default table has exactly two columns, `entity_id` and
integer `grade`, in the original input order. Grade 1 has highest
priority. A shared grade withholds the comparison without asserting
equality of the latent targets.

## Usage

``` r
# S3 method for class 'postrank_fit'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'postrank_analysis'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  what = c("grades", "report_card")
)

# S3 method for class 'postrank_baseline'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'postrank_report_card'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A `postrank_fit`, `postrank_analysis`, `postrank_baseline` or
  `postrank_report_card`.

- row.names:

  Optional row names for the returned table; their length must match its
  number of rows. `NULL` uses default row names.

- optional:

  Logical; accepted by the
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  generic. Basic table names are already valid R names; report-card
  column names are retained.

- ...:

  Unused arguments for generic compatibility.

- what:

  For an analysis, either `"grades"` (default) or `"report_card"`.
  Supply this argument by name.

## Value

A data frame. The basic table has character `entity_id` and integer
`grade` columns. The report-card table has all columns of the prepared
card.

## Details

For an analysis, `what = "report_card"` selects the full prepared card,
ordered by grade and then its recorded secondary key. Calling
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on a
report card returns the same full table. The table retains raw entity
IDs, regardless of labels used in a figure. Select rows or columns from
the returned data frame using ordinary R indexing.

A fit or analysis without a validated grade returns zero rows with the
basic column types; it does not substitute an all-withheld grade. A
request for an unavailable card gives an explanatory error. Conversion
does not solve a problem, evaluate a grade or compute missing summaries.
Unlike a shortened console display or a plot with a row limit, table
conversion includes every available row and has no paging limit.

**Migration to 1.0:** an analysis previously returned its full report
card by default when available. The default now always returns the basic
grade table. Use `as.data.frame(analysis, what = "report_card")` for the
former report-card output. CSV preserves a table; RDS preserves the
complete object, including settings and solver qualifications, for later
views.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  grades <- as.data.frame(one)
  card <- as.data.frame(one, what = "report_card")
  grades
  card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
  csv <- tempfile(fileext = ".csv")
  rds <- tempfile(fileext = ".rds")
  write.csv(grades, csv, row.names = FALSE)
  saveRDS(one, rds)
  identical(read.csv(csv), grades)
  identical(as.data.frame(readRDS(rds)), grades)
  unlink(c(csv, rds))
}
```
