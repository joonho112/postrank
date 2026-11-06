# Build a Grading Problem with Equality-Neutral Loss

A weighted problem is constructed for targets that may be exactly equal.
One common grading is selected for all criteria, subject to at most
`G_max` occupied grades and a constraint retaining verified identical
active profiles in the same grade. The resulting problem is passed to
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md)
for optimization. This explicitly selected loss leaves ordinary postrank
problems unchanged.

## Usage

``` r
postrank_tie_problem(
  pairwise,
  weights,
  tau,
  G_max,
  objective = "weighted",
  q = NULL,
  exact_G = NULL
)
```

## Arguments

- pairwise:

  A validated object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md),
  with strict-error, equality and distinctness probabilities and
  verified criterion equality partitions.

- weights:

  Nonnegative finite weights named for every criterion exactly once and
  summing to one. No automatic normalization is used. A single criterion
  requires its named weight of 1.

- tau:

  Cost of withholding a distinct comparison, with `0 < tau <= 0.5`.

- G_max:

  Positive integer upper bound on occupied grades, no larger than the
  original entity count. This is a cap, not a required grade count.

- objective:

  Only `"weighted"` is supported in this mode.

- q:

  Must be `NULL`; tie-aware error-budget protection is unsupported.

- exact_G:

  Must be `NULL`; requiring an exact grade count is unsupported.

## Value

A `postrank_tie_problem` with a sparse label mixed-integer model,
`guard`, `M`, `objective_units`, settings and input/loss identities. Its
raw objective Z is weighted expected strict errors minus `tau` times
weighted disclosed-distinct opportunities. Risk is `R0 + Z/M`; the
offset `objective_units$offset` is the all-withheld risk R0, not
generally `tau`.

## Details

Grade 1 has highest priority; a shared grade withholds a direction.
Disclosing i above j has criterion loss `P(theta_i < theta_j)`;
withholding has loss `tau * P(theta_i != theta_j)`. Genuine equality
costs zero under either action. With T the weighted expected number of
distinct pairs, `R0 = tau * T/M`. M still counts the original unordered
entity pairs, including pairs with equality mass.

The mandatory guard intersects verified equality partitions over the
positive-weight criteria. Entities in the same resulting active-profile
class receive the same grade. The sparse model enforces label equality
within each class; it retains all entities and original pair
multiplicities. Equal sample values or posterior means alone cannot
establish an almost-sure equality class.

For weighted at-most-G decisions without extra constraints, there exists
a global minimizer obeying the guard: moving an equality class to its
least costly currently occupied class grade cannot increase risk or the
number of occupied grades. This is an existence result, not a claim that
every unconstrained optimum obeys the guard. It does not extend here to
quotas, q budgets, minimax or exact-G decisions, or guarantee that a
funding schedule is preserved when the grade count changes.

## See also

[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, weights = c(S = .6, C = .4),
    tau = .25, G_max = 3L)
  problem$guard$groups
  problem$objective_units
}
#> $raw
#> [1] "tie_weighted_Z"
#> 
#> $scale
#> [1] 0.1666667
#> 
#> $offset
#> [1] 0.175
#> 
```
