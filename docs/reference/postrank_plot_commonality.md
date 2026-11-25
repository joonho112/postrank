# Plot the Extra Criterion Risk of a Common Grading

`postrank_plot_commonality()` plots how much extra criterion risk each
criterion incurs under a shared common grading compared with a separate
grading solved for that criterion alone, using stored results from
[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md).
Segments show solver bounds from each criterion's separate optimization,
not posterior uncertainty intervals for targets or grades.

## Usage

``` r
postrank_plot_commonality(x, ...)
```

## Arguments

- x:

  A `postrank_commonality_cost` object.

- ...:

  Unused; unnamed extra arguments are ignored.

## Value

A `ggplot` object with one row per criterion (`$data` holds `x$table`).
Finite `cost_lower` values appear as hollow circles, and a horizontal
segment to `cost_upper` is drawn whenever both endpoints are finite;
missing bounds are noted in the subtitle rather than imputed.

## Details

For each criterion,
`cost_lower = max(0, common_grade_risk - own_best_risk)` compares the
common grading's risk on that criterion against the best checked grading
found in the criterion-specific solve (clipped at zero because the
common grading belongs to the comparison family when
`protection = "none"` or satisfies the active budget). `cost_upper`
subtracts the criterion-specific solve's `own_lower_bound` instead of
`own_best_risk`, so an unfinished separate solve leaves a range
`[cost_lower, cost_upper]` rather than assuming its best found grading
achieved the true minimum.

A vertical reference line marks zero extra risk, and y-axis labels
display each criterion ID, its separate solver status, and its absolute
solver gap (`own_best_risk - own_lower_bound`). The plot reads stored
results without running new solves.

## See also

[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md),
[`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md),
[`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md)

## Examples

``` r
commonality <- postrank_example("tutorial_commonality")
postrank_plot_commonality(commonality)
```
