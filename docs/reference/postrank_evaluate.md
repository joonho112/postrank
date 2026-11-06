# Evaluate the Posterior Loss of Supplied Grades

Disclosed comparisons, expected directional errors and loss are
calculated for an existing grade vector without optimization. Smaller
grades indicate higher priority. Equal grades withhold a direction
without asserting equality of the latent targets. The resulting
quantities are conditional on the supplied posterior probabilities and
chosen loss.

## Usage

``` r
postrank_evaluate(
  grade,
  pairwise,
  weights = NULL,
  tau = NULL,
  objective = c("weighted", "minimax"),
  minimax_criteria = NULL,
  settings = NULL
)
```

## Arguments

- grade:

  Numeric vector of positive integer grades, named in exactly the
  input's entity order. Occupied labels are renumbered consecutively.

- pairwise:

  A `postrank_pairwise`, `postrank_coefficients`, or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object. Gaussian/mixture coefficients and supplied probabilities
  currently support weighted expected risk only.

- weights:

  Nonnegative finite criterion-named weights summing to one. Supply
  every criterion exactly once, including weight 1 for a single
  criterion, unless using `settings`. Weights are not normalized
  automatically.

- tau:

  Cost of a withheld comparison, with `0 < tau <= 0.5`.

- objective:

  `"weighted"` or `"minimax"`. The latter uses the largest expected
  criterion risk, not an expectation of statewise maximum loss.

- minimax_criteria:

  Optional nonempty criterion subset for minimax; `NULL` uses all
  criteria. Only allowed with `objective = "minimax"`.

- settings:

  Optional
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  supplying weights, tau, objective and minimax criteria instead of the
  separate arguments. Explicitly supplying both is a `settings_conflict`
  error.

## Value

An unclassed list with the canonical `grade`, occupied count `G`, total
unordered pairs `M`, disclosed pairs `N`, and directed disclosure matrix
`x`. `disclosure_rate = N/M` and `abstention_rate = (M-N)/M`.
Criterion-named `E`, `E_over_M`, `E_over_N` and `criterion_risk` give
expected error counts, their two normalizations and loss including
withholding. `weighted_risk`, `minimax_risk` and `primary_risk`
distinguish the weighted, largest selected-criterion and requested
objectives. `weighted_raw_objective = sum(weights * E) - tau * N` is in
centered raw units. `objective`, `minimax_criteria`, `settings`,
`schema_version` and input/pairwise identities record what was
evaluated.

## Details

For criterion k, risk is `(E_k + tau * (M - N)) / M`. When all
comparisons are withheld, N=0, conditional error ratios `E_over_N` are
`NA`, and risk is tau. This is a valid action, distinct from a solve
with no validated grade.

Evaluation does not check membership in a grade-cap, exact-grade or
error-budget family, even when those restrictions appear in `settings`.
Use
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
to specify that family;
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)
records membership separately when comparing actions.

## See also

[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)

## Examples

``` r
grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
ev <- postrank_evaluate(grade, pr_tutorial$one,
  weights = c(score_A = 1), tau = .2)
ev[c("N", "M", "E_over_N", "primary_risk")]
#> $N
#> [1] 12
#> 
#> $M
#> [1] 15
#> 
#> $E_over_N
#>    score_A 
#> 0.00206455 
#> 
#> $primary_risk
#> [1] 0.04165164
#> 
held <- postrank_evaluate(setNames(rep(1L, 6), names(grade)),
  pr_tutorial$one, weights = c(score_A = 1), tau = .2)
held[c("N", "E_over_N", "primary_risk")]
#> $N
#> [1] 0
#> 
#> $E_over_N
#> score_A 
#>      NA 
#> 
#> $primary_risk
#> [1] 0.2
#> 
```
