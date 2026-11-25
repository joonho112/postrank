# Build a Problem for Choosing Common Grades

`postrank_problem()` builds the optimization problem for
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
from pairwise comparison probabilities and loss settings, without
calling a solver or fitting a model. Grade 1 is the highest priority,
and entities in the same grade are left unordered.

## Usage

``` r
postrank_problem(
  pairwise,
  weights = NULL,
  tau = NULL,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
```

## Arguments

- pairwise:

  Pairwise directional-error probabilities: a `postrank_pairwise` object
  from
  [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md),
  a `postrank_coefficients` object
  ([`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)),
  or a
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object. Normal/mixture posteriors and supplied probabilities support
  only the weighted objective without `q`, `exact_G` or
  `minimax_criteria`.

- weights:

  Nonnegative finite weights summing to one within `1e-12`, uniquely
  named by criterion (covering every criterion once, including weight
  `1` for one criterion). Omit when passing `settings`; never rescaled
  automatically.

- tau:

  Cost of leaving a pair unordered (`0 < tau <= 0.5`). Omit when passing
  `settings`.

- G_max:

  Largest number of occupied grades, a positive integer at most the
  number of entities when passed directly. Fewer grades are allowed
  unless `exact_G` is given. Omit when passing `settings`.

- objective:

  `"weighted"` (the default) minimizes the weighted sum of criterion
  losses; `"minimax"` minimizes the largest loss among the selected
  criteria.

- q:

  Optional vector of per-criterion expected-error budgets in `[0, 1]`,
  uniquely named by known criteria. Each requires `E_k <= q_k * N` (even
  if criterion `k` has weight 0 in `weights`); at `N = 0` this holds
  (`0 <= 0`) while `E_k / N` is `NA`.

- exact_G:

  Optional positive integer requiring an exact number of occupied
  grades, at most `G_max` and never reduced automatically.

- minimax_criteria:

  Optional character vector of criterion IDs included in the minimax
  objective (`NULL` includes all criteria). Allowed only when
  `objective = "minimax"`.

- minimax_refine:

  How to refine a minimax solution when `objective = "minimax"`:
  `"weighted"` (the default) or `"none"`; see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).
  Ignored when `objective = "weighted"`.

- settings:

  Optional
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object used instead of `weights`, `tau`, `G_max`, `objective`, `q`,
  `exact_G`, `minimax_criteria` and `minimax_refine`. Supplying both
  stops with `settings_conflict`. Unlike a direct `G_max` argument,
  `settings` reduces an oversized `G_max` to the number of entities.

## Value

A `postrank_problem` object, a list containing `pairwise`, `settings`,
the sparse linear/integer `model`, variable `index`, `pair_map`,
unordered pair count `M`, `objective_units` (scale and offset converting
raw objective values to normalized loss), `input_identity`,
`problem_identity`, `schema_version` and `builder_version`. When
`objective = "minimax"`, `minimax_diagnostics$degenerate_criteria` lists
any selected criteria whose directional-error probabilities are all at
least `tau` (whose criterion loss cannot fall below `tau`).

## Details

Losses and `q` error budgets are posterior expectations conditional on
the supplied probabilities; `q` constrains expected wrong-order counts
rather than realized error rates. The minimax objective minimizes
`max_k E[loss_k]`, not `E[max_k loss_k]`. To compute the loss of an
existing grading without building an optimization model, use
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md).

## See also

[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)

## Examples

``` r
one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = 0.2, G_max = 3L)
one$objective_units
#> $raw
#> [1] "weighted_Z"
#> 
#> $scale
#> [1] 0.06666667
#> 
#> $offset
#> [1] 0.2
#> 

pw <- postrank_pairwise(postrank_toy)
protected <- postrank_problem(pw, weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25, G_max = 3L, q = c(need_B = 0.3), exact_G = 2L)
protected$settings[c("G_max", "exact_G", "q")]
#> $G_max
#> [1] 3
#> 
#> $exact_G
#> [1] 2
#> 
#> $q
#> need_B 
#>    0.3 
#> 
```
