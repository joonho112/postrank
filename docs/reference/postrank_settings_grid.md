# Build a One-at-a-Time or Full Settings Grid

Settings are constructed for
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)
without optimization. The default `design = "one_at_a_time"` varies each
supplied axis separately around `base`, flags the base row with
`is_reference = TRUE`, and removes rows equal to the base or to each
other. With `design = "full"`, the Cartesian grid is constructed and the
row equal to `base` is flagged as the reference. The complete
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
object in the `settings` list-column defines each row; the scalar
columns provide its displayed summary.

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

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object.

- tau:

  Optional numeric vector of tau values.

- G_max:

  Optional integer vector of grade caps.

- weights:

  Optional named list of weight profiles (named numeric vectors); the
  unique nonblank list names label the rows.

- q:

  Optional uniquely criterion-named list of numeric error-budget
  vectors.

- design:

  `"one_at_a_time"` (default) or `"full"`.

## Value

A data frame with `setting_id`, `label`, `tau`, `G_max`, `exact_G`,
`objective`, `minimax_refine`, `w_<k>`, `q_<k>`, `is_reference` and the
`settings` list-column.

## Details

Profile names such as `base` are ordinary display labels, not reserved
keys. Different policies receive distinct labels; a colliding user label
is suffixed with its setting ID. Invalid fractional grade caps are
refused.

## See also

[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)

## Examples

``` r
base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
g <- postrank_settings_grid(base, tau = c(.1, .35), G_max = 2L)
g[, c("setting_id", "label", "tau", "G_max", "is_reference")]
#>   setting_id     label  tau G_max is_reference
#> 1        S01 reference 0.25     3         TRUE
#> 2        S02  tau=0.10 0.10     3        FALSE
#> 3        S03  tau=0.35 0.35     3        FALSE
#> 4        S04   G_max=2 0.25     2        FALSE
```
