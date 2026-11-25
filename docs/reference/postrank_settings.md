# Choose the Loss and Allowed Grade Reports

`postrank_settings()` defines the loss function and allowed grade
reports for
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md):
criterion weights, the cost `tau` of leaving a pair unordered, the
maximum number of grades `G_max`, and optional per-criterion error
budgets `q` or an exact grade count `exact_G`. Computation limits are
set separately by
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md).

## Usage

``` r
postrank_settings(
  weights,
  tau = 0.25,
  G_max = 4L,
  q = NULL,
  exact_G = NULL,
  objective = c("weighted", "minimax"),
  minimax_criteria = NULL,
  minimax_refine = c("weighted", "none"),
  label = NULL
)
```

## Arguments

- weights:

  Criterion weights: nonnegative finite numbers summing to one within
  `1e-12`. They are never rescaled automatically. Always required by
  `postrank_settings()`, including weight `1` for a single criterion.
  Names identify criteria; unnamed weights are matched in criterion
  order when combined with an input.

- tau:

  Cost of leaving a pair unordered, relative to a cost of 1 for a
  wrong-order pair. Must satisfy `0 < tau <= 0.5`.

- G_max:

  Largest number of occupied grades, a positive integer. Fewer grades
  are allowed unless `exact_G` is given.

- q:

  `NULL` (the default) or a vector of per-criterion expected-error
  budgets in `[0, 1]`, uniquely named by criterion. Each named criterion
  `k` requires `E_k <= q_k * N`, where `E_k` is the expected number of
  wrong-order ordered pairs on criterion `k` and `N` is the number of
  ordered pairs (including criteria with weight 0 in `weights`). When
  `N = 0`, the count constraint `0 <= 0` holds while `E_k / N` is `NA`.
  These constrain posterior expected error counts, not simultaneous
  error rates.

- exact_G:

  `NULL` (the default) or a positive integer giving the exact number of
  occupied grades required, at most `G_max`. Unlike `G_max`, this value
  is never reduced automatically to fit the number of entities.

- objective:

  `"weighted"` (the default) minimizes the weighted sum of criterion
  losses; `"minimax"` minimizes the largest loss among the selected
  criteria.

- minimax_criteria:

  `NULL` (the default, all criteria) or a character vector of criterion
  IDs included in the minimax objective. Allowed only when
  `objective = "minimax"`.

- minimax_refine:

  How a minimax solution is refined when `objective = "minimax"`:
  `"weighted"` (the default) minimizes the weighted loss while keeping
  the first-stage minimax value, and `"none"` keeps the first-stage
  grading. Ignored when `objective = "weighted"`. See
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  for additional refinement on zero-weight criteria.

- label:

  Optional non-empty string used to label this setting in grids and
  figures. Defaults to `"tau=<tau>, G_max=<G_max>"`. Does not change the
  decision problem.

## Value

A `postrank_settings` object, a named list containing:

- `weights`, `tau`, `G_max`, `q`, `exact_G`, `objective`,
  `minimax_criteria`, `minimax_refine` and `label`: the validated
  settings;

- `weight_sum_tolerance`: `1e-12`;

- `schema_version`: `"1"`, the version of this object's layout;

- `provenance`: package and R versions, creation time, and function
  name;

- `warnings`: character vector of notes added when the settings are
  bound to an input.

## Details

When settings are combined with an input in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
named weights must cover all criteria, `q` must name known criteria, and
`exact_G` cannot exceed the number of entities. If `G_max` exceeds the
number of entities, the bound copy reduces `G_max` to that number,
records `requested_G_max` and `resolved_G_max` in `provenance`, and
appends a note to `warnings`.

Posterior draws and exact finite-law inputs support weighted and minimax
objectives, `q` and `exact_G`. Normal or mixture posteriors
([`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md))
and supplied probabilities
([`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md))
support only the weighted objective without `q`, `exact_G` or
`minimax_criteria`. Creating a `postrank_settings` object checks the
arguments on their own; whether an input supports them is checked when
building or solving the problem.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)

## Examples

``` r
one <- postrank_settings(weights = c(score_A = 1), tau = 0.2, G_max = 3L)
one$tau
#> [1] 0.2

protected <- postrank_settings(weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25, G_max = 3L, q = c(need_B = 0.3))
protected$q
#> need_B 
#>    0.3 
```
