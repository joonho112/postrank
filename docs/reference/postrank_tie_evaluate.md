# Evaluate a Fixed Grading Under Equality-Neutral Loss

`postrank_tie_evaluate()` computes posterior expected equality-neutral
loss, distinct-pair counts, and error ratios for a fixed grading without
running a solver. Under equality-neutral loss, ordering a pair incurs
loss only when the targets are strictly reversed (`theta_i < theta_j`),
and leaving a pair in the same grade costs `tau` only when the targets
are distinct (`theta_i != theta_j`), so exact equality
(`theta_i = theta_j`) has zero loss under either decision. Placing two
entities in the same grade still leaves them unordered rather than
claiming their targets are equal.

## Usage

``` r
postrank_tie_evaluate(grade, pairwise, weights, tau)
```

## Arguments

- grade:

  Positive integer/numeric vector named in the exact order of
  `pairwise$entity_ids` (`1` = highest priority; occupied labels are
  renumbered to `1..G` by
  [`canonical_postrank_grade()`](https://joonho112.github.io/postrank/reference/canonical_postrank_grade.md)
  without changing pairwise relations).

- pairwise:

  A validated `postrank_tie_pairwise` object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

- weights:

  Non-negative finite numeric vector named by every criterion in
  `pairwise` and summing to `1` (for a single criterion, supply a named
  weight of `1`; weights are not normalized automatically).

- tau:

  Cost of withholding a distinct comparison, a finite scalar with
  `0 < tau <= 0.5`.

## Value

A `postrank_tie_evaluation` list containing canonical `grade`, `G`,
`M = choose(n, 2)`, `N`, directed-disclosure matrix `x`,
`disclosure_rate = N / M`, `abstention_rate = (M - N) / M`, criterion
counts `E` (also `Eb`, expected strict wrong-direction errors), `D_k`
(expected disclosed-distinct pairs), `T_k` (expected total-distinct
pairs), and `H_k` (expected withheld-distinct pairs), weighted distinct
counts `D` and `T`, ratios `E_over_M`, `E_over_N`, `E_over_D`,
`D_k_over_T_k`, and `D_over_T` (also `distinct_disclosure_rate`; ratios
with zero denominator are `NA_real_`), `criterion_risk`,
`criterion_baseline`, `weighted_risk` and `primary_risk`,
`all_withhold_risk` and `R0`, `weighted_raw_objective` and `raw_Z`,
`guard_satisfied`, `guard_classes`, `guard`, and `settings`.

## Details

Criterion risk is `(E + tau * H_k) / M`, and the all-withheld risk is
`R0 = tau * T / M` (smaller than `tau` whenever positive equality
probability is present on an active criterion). Weighted risk equals
`R0 + raw_Z / M` with `raw_Z = sum(weights * E) - tau * D`, and is
summed directly from `pairwise$b` and `pairwise$d` independently of any
sparse MIP model. For an all-withheld single-grade grading (`G = 1`),
`N` and every `D_k` are `0`, `primary_risk` equals `R0`, and `E_over_N`
and `E_over_D` are `NA_real_`.

Reported ratios (`E_over_N`, `E_over_D`, `D_over_T`) are ratios of
posterior expected counts under the supplied posterior rather than
expectations of per-draw ratios. `guard_satisfied` records whether
`grade` keeps each active-profile equality class (`guard$groups`) in one
grade; unlike
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
`postrank_tie_evaluate()` also evaluates gradings that split an equality
class for comparison and does not check `G_max` feasibility (use
[`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md)
to check solver candidates). Ordinary
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
retains its zero-equality weak-error loss.

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md),
[`vignette("m4-ties-and-withholding", package = "postrank")`](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
weights <- c(S = 0.6, C = 0.4)
ev <- postrank_tie_evaluate(
  c(A = 3L, B = 3L, C = 2L, D = 1L),
  pw,
  weights,
  tau = 0.25
)
ev[c("primary_risk", "R0", "N", "D", "T", "guard_satisfied")]
#> $primary_risk
#> [1] 0.04
#> 
#> $R0
#> [1] 0.175
#> 
#> $N
#> [1] 5
#> 
#> $D
#> [1] 4.2
#> 
#> $T
#> [1] 4.2
#> 
#> $guard_satisfied
#> [1] TRUE
#> 

held <- postrank_tie_evaluate(
  c(A = 1L, B = 1L, C = 1L, D = 1L),
  pw,
  weights,
  tau = 0.25
)
held[c("primary_risk", "E_over_N", "E_over_D")]
#> $primary_risk
#> [1] 0.175
#> 
#> $E_over_N
#>  S  C 
#> NA NA 
#> 
#> $E_over_D
#>  S  C 
#> NA NA 
#> 
```
