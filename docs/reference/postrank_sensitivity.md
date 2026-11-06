# Re-Solve a Decision Problem Over a Settings Grid

A separate optimization is performed for each distinct policy using the
same posterior coefficients. A working optimizer backend is required.

## Usage

``` r
postrank_sensitivity(
  x,
  grid,
  backend = NULL,
  control = postrank_control(),
  reference = NULL,
  keep_fits = NULL
)
```

## Arguments

- x:

  A `postrank_pairwise`, `postrank_coefficients`, or
  `postrank_probabilities` object accepted by
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
  or a `postrank_analysis` whose coefficients are reused.

- grid:

  A
  [`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md)
  data frame or a list of
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md).

- backend:

  `NULL` (option, then Gurobi) or `"gurobi"`/`"highs"`.

- control:

  A
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  object or bare control list.

- reference:

  Optional `setting_id` of the reference row (default: the row flagged
  `is_reference`).

- keep_fits:

  Keep every fit (`TRUE` by default for at most 25 rows).

## Value

A `postrank_sensitivity` list. `table` contains action metrics and
solver bounds, `changes` counts pair relations newly disclosed, newly
withheld or reversed against the reference, and `grades` stores entity
grades by setting. Changes compare relations, not numeric label
differences. `grid` and `settings` retain the bound policies; `fits`
holds the full fits when requested. `reference_id`, `backend`,
`control`, `schema_version`, `provenance` and `warnings` record the
calculation.

## Details

One problem is solved per grid row using the same coefficients. The
backend is resolved once and recorded. Each row reports risk,
disclosure, grade count, status, bounds and relation changes relative to
the reference row. Rows without a validated grade retain their status,
reason and bounds, with `NA` action metrics and changes; they are not
replaced by all-withheld actions. Grade caps exceeding the entity count
are reduced when bound to the input. Rows that coincide only after this
reduction are removed with a warning. Since raw risks are comparable
only under a common loss, the table reports settings separately without
ranking them.

## See also

[`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md),
[`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  pw <- postrank_pairwise(postrank_toy)
  base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
  sens <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = .4), backend = "highs",
    control = postrank_control(time_limit = 10))
  sens$table[, c("risk", "N", "G", "status")]
}
#>     risk N G  status
#> 1 0.2125 2 2 optimal
#> 2 0.2625 2 2 optimal
```
