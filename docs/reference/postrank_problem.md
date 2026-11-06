# Build a Problem for Choosing Common Grades

The constructor defines the posterior loss and admissible grade reports
for
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).
Smaller grades indicate higher priority and shared grades withhold
comparisons. Construction of the optimization problem does not run a
solver or estimate the posterior.

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

  A validated `postrank_pairwise`, `postrank_coefficients`, or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object. Problem construction from Gaussian/ mixture coefficients or
  supplied probabilities currently supports weighted at-most-G problems
  only, without q, exact-G or minimax modes.

- weights:

  Nonnegative finite criterion-named weights summing to one. Include
  every criterion exactly once, including weight 1 for a single
  criterion, unless using `settings`. No automatic normalization is
  performed.

- tau:

  Cost of withholding a comparison, `0 < tau <= 0.5`.

- G_max:

  Positive integer upper bound on occupied grades, no larger than the
  number of entities. Fewer grades are permitted unless `exact_G` is
  set.

- objective:

  `"weighted"` or `"minimax"`: minimize the weighted average or largest
  selected criterion's expected risk.

- q:

  Optional uniquely criterion-named error budgets in `[0, 1]`. Each
  requires `E_k <= q_k * N`, including a protected criterion with zero
  objective weight. At N=0 this count constraint holds but `E_k/N` is
  undefined.

- exact_G:

  Optional exact number of nonempty grades, at most `G_max`.

- minimax_criteria:

  Optional nonempty set of criterion IDs for minimax; `NULL` includes
  all criteria. Only allowed for the minimax objective.

- minimax_refine:

  `"weighted"` (default) or `"none"`. For minimax, weighted refinement
  minimizes the original weighted risk within the primary cap. If any
  weight is zero, a further stage minimizes uniform criterion risk while
  also retaining a cap on that original weighted risk. Weights are never
  perturbed. See
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  for the qualifications of the recorded refinement conclusions. Ignored
  for weighted problems.

- settings:

  Optional
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  instead of separate policy arguments; explicitly supplying both is a
  `settings_conflict` error. Unlike the separate `G_max` argument, this
  route caps an oversized grade limit at the number of entities. An
  exact count is never relaxed.

## Value

A `postrank_problem` list containing `pairwise`, `settings`, the sparse
`model`, variable `index`, `pair_map`, total pair count `M`, and
`objective_units` for converting raw objectives to risk. Input/problem
identities and builder/schema versions support subsequent validation.
Minimax problems also contain `minimax_diagnostics$degenerate_criteria`:
selected criteria whose directional errors are all at least tau. Their
risk cannot be below tau, so the minimax value is at least tau and
equals tau when all withholding is allowed.

## Details

Expected risk is conditional on the supplied posterior and chosen
targets. Error budgets limit posterior expected wrong fractions when
N\>0; they do not ensure that every realized report has that error rate.
Minimax uses the maximum of expected criterion risks, not the
expectation of their statewise maximum. Use
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
to score a supplied action without solving; evaluation alone does not
check this action family.

## See also

[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)

## Examples

``` r
one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = .2, G_max = 3L)
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
protected <- postrank_problem(pw, weights = c(need_A = .6, need_B = .4),
  tau = .25, G_max = 3L, q = c(need_B = .3), exact_G = 2L)
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
