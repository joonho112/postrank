# Plot the Extra Criterion Risk of a Common Grading

The criterion-specific increase in risk under the stored common action
is compared with a criterion-specific optimization. Bounds for the
increase are obtained from each criterion's own optimization. The
intervals represent numerical optimization uncertainty rather than
posterior uncertainty about targets or grades.

## Usage

``` r
postrank_plot_commonality(x, ...)
```

## Arguments

- x:

  A `postrank_commonality_cost` with stored common-action evaluations
  and criterion-specific optimization results.

- ...:

  Unused.

## Value

A `ggplot` object with one labeled row per criterion. A finite
`cost_lower` is shown as a hollow point; the segment to `cost_upper`
appears only when both endpoints are available. Missing bounds remain
unavailable.

## Details

The lower endpoint is `max(0, common_grade_risk - own_best_risk)`: it
subtracts the criterion's own incumbent risk and is clipped at zero
because the common action is available in that comparison family. The
upper endpoint subtracts the own solve's lower bound. Thus the own
incumbent is not assumed to equal the unknown minimum. A zero line
provides a reference, and labels retain the own solve's status and
available absolute risk gap. The comparison inherits the stored action
families, protection setting and numerical limitations; the plot does
not perform another criterion-specific solve.

## See also

[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md),
[`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md),
[`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md)

## Examples

``` r
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
commonality <- load_or_compute("tutorial_commonality")
postrank_plot_commonality(commonality)
```
