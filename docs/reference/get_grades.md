# Extract the Grade Assigned to Each Entity

The stored grades are returned as a named vector for subsequent analysis
or export. Grade 1 has highest priority. Entities assigned the same
grade have their comparison withheld; a common grade does not imply
equality of their latent targets.

## Usage

``` r
get_grades(x, ...)
```

## Arguments

- x:

  A `postrank_fit`, `postrank_analysis` or `postrank_baseline`.

- ...:

  Unused arguments for generic compatibility.

## Value

An integer vector named by entity ID, or `NULL` when a fit has no
validated candidate. Fit/analysis grades retain the input's entity
order.

## Details

This accessor does not solve or choose a new grade report. A valid
all-withheld report returns grade 1 for every entity; `NULL` instead
means that no validated grades are available. Console truncation does
not limit this vector. Use
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)
for a two-column data frame.

## See also

[`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  grades <- get_grades(one)
  grades
}
#> A B C D E F 
#> 1 1 2 2 3 3 
```
