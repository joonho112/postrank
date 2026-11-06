# Score Fixed Grades When True Equality Has Zero Loss

A proposed grading is evaluated under the equality-neutral loss. A
disclosed direction incurs an error only when the targets are strictly
reversed, and withholding costs `tau` only when the targets are
distinct. True equality therefore has zero loss under either action.
Shared grades remain decisions to withhold comparisons and do not
establish target equality. The supplied grades are evaluated without
selection or optimization.

## Usage

``` r
postrank_tie_evaluate(grade, pairwise, weights, tau)
```

## Arguments

- grade:

  Positive integer numeric vector named in declared entity order. Labels
  are canonicalized without changing pairwise relations.

- pairwise:

  A validated object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

- weights:

  Nonnegative finite weights, named for every criterion exactly once and
  summing to one. They are not automatically normalized. For one
  criterion, supply its named weight of 1.

- tau:

  Cost of withholding a distinct comparison, in `(0, 0.5]`.

## Value

A `postrank_tie_evaluation` list with the grade, counts, losses,
settings, input identities and `guard_satisfied`/`guard_classes`.
Criterion-specific `E` (also `Eb`), `D_k`, `T_k` and `H_k` are expected
wrong, disclosed-distinct, total-distinct and withheld-distinct counts.
`D` and `T` are the weighted distinct counts. `N` is the raw number of
disclosed unordered pairs; `M` counts all unordered pairs.

`disclosure_rate = N/M` and `D_over_T` (also `distinct_disclosure_rate`)
use raw pairs and distinct opportunities, respectively. `D_k_over_T_k`,
`E_over_D` and `E_over_N` keep the criterion-specific distinct and raw
denominators separate. Ratios with zero denominators are `NA`.

`criterion_risk` and `criterion_baseline` contain criterion losses and
all-withheld baselines. `weighted_risk` and `primary_risk` are the
weighted loss. `all_withhold_risk` (also `R0`) is its all-withheld
baseline. `weighted_raw_objective` (also `raw_Z`) is
`sum(weights * E) - tau * D`.

## Details

Criterion risk is `(E + tau * H_k) / M`. The all-withheld baseline is
`R0 = tau * T / M`, which is generally smaller than `tau` when some
equality mass is present. Risk also equals `R0 + raw_Z / M`, but the
evaluator directly sums the action's losses independently of the solver
objective. For an all-withheld action, N and every D_k are zero, risk is
R0, and E/N and E/D_k are undefined. Zero expected strict errors do not
establish a strictly superior direction when equality is possible.

Ratios are ratios of posterior expected counts, not expectations of
realized draw-specific ratios. They describe the supplied law and loss,
not external prediction accuracy or policy benefit. Ordinary
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
retains its separate weak-error loss and does not silently change when
this function is used.

Entities equal with probability one on every positive-weight criterion
form an active-profile class. Tie-aware optimization keeps each such
class in one grade. This evaluator reports whether a fixed grade obeys
that rule, but also scores violations for comparison. It does not check
a `G_max` family or establish feasibility or optimality. Use
[`validate_postrank_tie_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_solution.md)
to check a problem's numerical solution.

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md),
[`vignette("m4-ties-and-withholding", package = "postrank")`](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  # A complete two-state law, not two Monte Carlo draws.
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  weights <- c(S = .6, C = .4)
  ev <- postrank_tie_evaluate(c(A = 3L, B = 3L, C = 2L, D = 1L),
    pw, weights, tau = .25)
  ev[c("primary_risk", "R0", "N", "D", "T", "guard_satisfied")]
  held <- postrank_tie_evaluate(c(A = 1L, B = 1L, C = 1L, D = 1L),
    pw, weights, tau = .25)
  held[c("primary_risk", "E_over_N", "E_over_D")]
}
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
