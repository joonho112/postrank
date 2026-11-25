# Re-Solve a Decision Problem Over a Settings Grid

`postrank_sensitivity()` solves one grading problem per setting in
`grid` on the same pairwise comparison probabilities, and summarizes how
grades, ordered pair counts and pairwise relations change relative to a
reference row.

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

  Pairwise comparison probabilities (`postrank_pairwise`,
  `postrank_coefficients` or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)),
  or a `postrank_analysis` whose `pairwise` component is reused.

- grid:

  A
  [`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md)
  data frame or a non-empty list of
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  objects.

- backend:

  Solver to use, `"gurobi"` or `"highs"`; `NULL` uses
  `getOption("postrank.backend")`, or `"gurobi"` if unset.

- control:

  Solver controls from
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  or a named list.

- reference:

  Optional `setting_id` of the reference row (defaults to the row with
  `is_reference = TRUE`, or row 1).

- keep_fits:

  Logical; whether to retain all `postrank_fit` objects in `fits`
  (defaults to `TRUE` when at most 25 rows remain after binding).

## Value

A `postrank_sensitivity` list containing `grid`, bound `settings`,
`fits` (`NULL` when `keep_fits = FALSE`), `grades` (`n x L` integer
matrix), `table` (loss, `N`, `disclosure_rate`, `G`, `status`, `reason`,
bounds, gap and `E_over_N_<k>`), `changes` (`n_same`, `n_new_disclosed`,
`n_new_withheld`, `n_reversed` and `change_fraction` relative to
`reference_id`), `reference_id`, `backend`, `control`, `schema_version`,
`provenance` and `warnings`.

## Details

Solving requires an optimization solver: install the free `highs`
package (`install.packages("highs")`) and use `backend = "highs"` or
`options(postrank.backend = "highs")`, or provide a licensed Gurobi
installation (the default). `postrank` never switches solvers on its
own.

Because changing `tau` or `weights` changes the loss definition itself,
compare rows by their grades, ordered pair counts and `changes` rather
than ranking settings by their `risk` numbers. If capping `G_max` at the
entity count makes two grid rows identical, duplicates are dropped with
a warning. Rows that finish without a checked grading record `NA` loss
and `changes` with `reason = "no_validated_incumbent"`.

## See also

[`postrank_settings_grid()`](https://joonho112.github.io/postrank/reference/postrank_settings_grid.md),
[`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md),
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)

## Examples

``` r
# Inspect a stored sensitivity grid without running a solver:
sens0 <- postrank_example("tutorial_sensitivity")
sens0$table[, c("setting_id", "risk", "N", "G", "status")]
#>   setting_id       risk  N G  status
#> 1        S01 0.09334319  9 3 optimal
#> 2        S02 0.04720411  8 2 optimal
#> 3        S03 0.12905020 11 3 optimal
#> 4        S04 0.09387078  8 2 optimal
#> 5        S05 0.09334319  9 3 optimal
#> 6        S06 0.07924975 12 3 optimal
#> 7        S07 0.09358215  8 2 optimal
sens0$changes
#>   setting_id n_same n_new_disclosed n_new_withheld n_reversed change_fraction
#> 1        S01     15               0              0          0      0.00000000
#> 2        S02     14               0              1          0      0.06666667
#> 3        S03     11               3              1          0      0.26666667
#> 4        S04     14               0              1          0      0.06666667
#> 5        S05     15               0              0          0      0.00000000
#> 6        S06     10               4              1          0      0.33333333
#> 7        S07     14               0              1          0      0.06666667
# Solve a two-row grid directly with the optional highs package:
pw <- postrank_pairwise(postrank_toy)
base <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
sens <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = 0.4),
  backend = "highs", control = postrank_control(time_limit = 10))
sens$table[, c("setting_id", "risk", "N", "G", "status")]
#>   setting_id   risk N G  status
#> 1        S01 0.2125 2 2 optimal
#> 2        S02 0.2625 2 2 optimal
```
