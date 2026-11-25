# Build a One-at-a-Time or Full Settings Grid

`postrank_settings_grid()` builds a table of
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
rows around a reference setting `base` for
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md),
without running a solver. With `design = "one_at_a_time"` (the default),
each supplied axis is varied separately while holding the other axes at
`base`; with `design = "full"`, all combinations of `base` and the
supplied axis values are formed. Duplicate policies are removed, and the
`base` policy sits in row 1 (`setting_id = "S01"`,
`is_reference = TRUE`).

## Usage

``` r
postrank_settings_grid(
  base,
  tau = NULL,
  G_max = NULL,
  weights = NULL,
  q = NULL,
  design = c("one_at_a_time", "full")
)
```

## Arguments

- base:

  Reference
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object.

- tau:

  Optional numeric vector of `tau` values in `(0, 0.5]`.

- G_max:

  Optional positive integer vector of maximum grade counts (non-integers
  are rejected rather than truncated).

- weights:

  Optional named list of criterion weight vectors, with unique non-blank
  list names used as row labels.

- q:

  Optional list named by criteria in `base$weights`, where each element
  is a numeric vector of error budgets in `[0, 1]` (`NA` is not
  allowed).

- design:

  `"one_at_a_time"` (the default) or `"full"`.

## Value

A data frame with columns `setting_id`, `label`, `tau`, `G_max`,
`exact_G`, `objective`, `minimax_refine`, `w_<k>`, `q_<k>`,
`is_reference` and list-column `settings` (holding the full
`postrank_settings` objects).

## Details

Each row's optimization settings come from `settings[[i]]`; scalar
columns are display summaries checked for agreement by
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md).
Colliding display labels receive a `" [<setting_id>]"` suffix.

## See also

[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md),
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)

## Examples

``` r
base <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
g <- postrank_settings_grid(base, tau = c(0.1, 0.35), G_max = 2L)
g[, c("setting_id", "label", "tau", "G_max", "is_reference")]
#>   setting_id     label  tau G_max is_reference
#> 1        S01 reference 0.25     3         TRUE
#> 2        S02  tau=0.10 0.10     3        FALSE
#> 3        S03  tau=0.35 0.35     3        FALSE
#> 4        S04   G_max=2 0.25     2        FALSE
```
