# Choose the Loss and Allowed Grade Reports

The settings specify criterion weights, the withholding cost, the
maximum number of grades and optional error budgets or an exact grade
count for
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md).
They define the decision problem without fitting a posterior or
selecting grades. Computation limits are specified separately by
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

  Nonnegative finite criterion weights summing to one within `1e-12`; no
  automatic normalization is performed. Names identify criteria. Unnamed
  weights are matched in criterion order when used with an input. This
  constructor always requires weights, including weight 1 for one
  criterion.

- tau:

  Cost of a withheld comparison, `0 < tau <= 0.5`.

- G_max:

  Positive integer upper bound on occupied grades. Fewer grades are
  allowed unless `exact_G` is supplied.

- q:

  `NULL` or a uniquely criterion-named vector of budgets in `[0, 1]`.
  Each included criterion requires `E_k <= q_k * N`, including criteria
  with zero objective weight. At N=0 the count constraint holds, while
  `E_k/N` is undefined. These are expected-error budgets, not
  simultaneous guarantees.

- exact_G:

  `NULL` or the required number of nonempty grades, at most `G_max`.
  This requirement is never relaxed to fit the input.

- objective:

  `"weighted"` (default) minimizes the weighted average of criterion
  risks; `"minimax"` minimizes the largest selected criterion risk.

- minimax_criteria:

  `NULL` (all criteria) or criterion IDs included in the minimax
  objective. Only allowed with `objective = "minimax"`.

- minimax_refine:

  `"weighted"` (default) refines a minimax solution using the original
  weighted risk; `"none"` keeps the first-stage action. See
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  for additional zero-weight refinement and its numerical
  qualifications. Ignored for weighted problems.

- label:

  Optional short display label for grids and figures.

## Value

A `postrank_settings` named list with the policy arguments, `label`,
`weight_sum_tolerance`, `schema_version`, `provenance` and `warnings`.

## Details

When settings are used with an input, named weights must cover its
criteria and `q` must name known criteria. `G_max` is capped at the
number of entities, with the requested and resolved caps recorded in the
bound copy's provenance. `exact_G` cannot exceed the entity count.

Ordinary draw and exact finite-law pairwise inputs support validated
combinations of weighted/minimax objectives, error budgets and exact
grade counts. Problems built by
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
or
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
from Gaussian/mixture coefficients or supplied probabilities currently
support weighted at-most-G settings only. Constructing settings alone
does not establish that a particular input supports them. Display labels
and provenance do not alter the decision problem.

## See also

[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)

## Examples

``` r
one <- postrank_settings(weights = c(score_A = 1), tau = .2, G_max = 3L)
one$tau
#> [1] 0.2
protected <- postrank_settings(weights = c(need_A = .6, need_B = .4),
  tau = .25, G_max = 3L, q = c(need_B = .3))
protected$q
#> need_B 
#>    0.3 
```
