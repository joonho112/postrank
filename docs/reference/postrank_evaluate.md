# Evaluate the Posterior Loss of Supplied Grades

`postrank_evaluate()` computes the ordered pair count, posterior
expected wrong-order errors and posterior expected loss for a supplied
integer grade vector, without running an optimization solver. Grade 1 is
the highest priority; entities given the same grade are left unordered
without claiming they are equal.

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

  Positive integer vector named in the exact `entity_ids` order of
  `pairwise`. Occupied grade numbers are renumbered to `1, ..., G` by
  [`canonical_postrank_grade()`](https://joonho112.github.io/postrank/reference/canonical_postrank_grade.md).

- pairwise:

  Pairwise directional-error probabilities: a `postrank_pairwise`,
  `postrank_coefficients` or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object. Normal/mixture posteriors and supplied probabilities support
  only `objective = "weighted"` without `minimax_criteria`.

- weights:

  Nonnegative finite weights summing to one within `1e-12`, uniquely
  named by criterion (covering every criterion once, including weight
  `1` for one criterion). Omit when passing `settings`; never rescaled
  automatically.

- tau:

  Cost of leaving a pair unordered (`0 < tau <= 0.5`). Omit when passing
  `settings`.

- objective:

  `"weighted"` (the default) or `"minimax"`. Minimax uses the largest
  posterior expected criterion loss among the selected criteria, not the
  expected statewise maximum.

- minimax_criteria:

  Optional character vector of criterion IDs included when
  `objective = "minimax"` (`NULL` uses all criteria). Must be `NULL`
  when `objective = "weighted"`.

- settings:

  Optional
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object supplying `weights`, `tau`, `objective` and `minimax_criteria`
  instead of separate arguments; supplying both stops with
  `settings_conflict`.

## Value

An unclassed named list containing:

- `grade` and `G`: the renumbered integer grades (`1, ..., G`) and
  number of occupied grades;

- `M`, `N`, `x`, `disclosure_rate` (`N / M`) and `abstention_rate`
  (`(M - N) / M`): total unordered pairs, ordered (`disclosed`) pairs,
  the `n x n` logical ordering matrix (`x[i, j]` is `TRUE` when
  `grade[i] < grade[j]`), and pair fractions;

- `E`, `E_over_M`, `E_over_N` and `criterion_risk`: criterion-named
  expected wrong-order pair counts, counts divided by `M` and by `N`
  (`NA` when `N = 0`), and per-criterion loss
  `(E_k + tau * (M - N)) / M`;

- `weighted_risk`, `minimax_risk`, `primary_risk` and
  `weighted_raw_objective` (`sum(weights * E) - tau * N`);

- `objective`, `minimax_criteria`, `settings`, `schema_version`,
  `input_identity` and `pairwise_identity`.

## Details

When every entity is given the same grade (`G = 1`), `N = 0`, `E_over_N`
is `NA`, and every criterion's loss equals `tau`. `postrank_evaluate()`
scores any valid grade vector; it does not check whether `grade`
satisfies `G_max`, `exact_G` or `q` constraints in `settings` (see
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
and
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)).

## See also

[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`canonical_postrank_grade()`](https://joonho112.github.io/postrank/reference/canonical_postrank_grade.md)

## Examples

``` r
grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
ev <- postrank_evaluate(grade, pr_tutorial$one,
  weights = c(score_A = 1), tau = 0.2)
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
  pr_tutorial$one, weights = c(score_A = 1), tau = 0.2)
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
