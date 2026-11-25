# Convert Stored Results to Tables

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) extracts
complete data frames from stored `postrank` results without row limits
or solver calls. For a `postrank_fit`, `postrank_analysis` or
`postrank_baseline`, the default table has two columns, `entity_id` and
integer `grade`, in input entity order. Grade 1 is the highest priority;
entities sharing a grade are left unordered without claiming they are
equal.

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
  `postrank_report_card` object.

- row.names:

  Optional row names matching the number of returned rows, or `NULL` for
  default row names.

- optional:

  Logical passed to
  [`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

- ...:

  Unused arguments for generic compatibility.

- what:

  For a `postrank_analysis`, `"grades"` (the default two-column table)
  or `"report_card"` (the full stored report-card table). Pass by name.

## Value

A data frame: `data.frame(entity_id, grade)` (zero rows when `x` has no
checked grading), or the full report-card table when `x` is a
`postrank_report_card` or `what = "report_card"`.

## Details

`as.data.frame(analysis, what = "report_card")` and
`as.data.frame(report_card)` return every entity row of the prepared
report card, ordered by `grade` and then the card's secondary sort key,
keeping raw `entity_id` values regardless of plot display labels.
Requesting `what = "report_card"` when `analysis$report_card` is `NULL`
stops with `report_card_unavailable`.

Unlike console printing or plot row limits,
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) always
returns all available rows. Note that before postrank 1.0,
`as.data.frame(analysis)` returned the report card when present; pass
`what = "report_card"` to obtain that table. Saving to CSV exports a
table, whereas [`saveRDS()`](https://rdrr.io/r/base/readRDS.html)
preserves the full object with its settings, bounds and warnings.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
grades <- as.data.frame(one)
grades
#>   entity_id grade
#> 1         A     1
#> 2         B     1
#> 3         C     2
#> 4         D     2
#> 5         E     3
#> 6         F     3

card <- as.data.frame(one, what = "report_card")
card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
#>   entity_id grade mean_score_A lower_score_A upper_score_A
#> 1         A     1         1.20    0.87102927     1.5289707
#> 2         B     1         0.95    0.62102927     1.2789707
#> 3         C     2         0.25   -0.07897073     0.5789707
#> 4         D     2         0.15   -0.17897073     0.4789707
#> 5         E     3        -0.50   -0.82897073    -0.1710293
#> 6         F     3        -0.80   -1.12897073    -0.4710293
```
