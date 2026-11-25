# Build a Grading Problem Under Equality-Neutral Loss

`postrank_tie_problem()` builds a weighted mixed-integer grading problem
for tie-aware mode under equality-neutral loss (where true target
equality has zero loss whether the pair is ordered or placed in the same
grade). It chooses one common grading across criteria with at most
`G_max` occupied grades while constraining entities in the same
active-profile equality class to receive the same grade. Pass the
returned problem to
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md).

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

  A validated `postrank_tie_pairwise` object from
  [`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).

- weights:

  Non-negative finite numeric vector named by every criterion in
  `pairwise` and summing to `1` (for a single criterion, supply a named
  weight of `1`; weights are not normalized automatically).

- tau:

  Cost of withholding a distinct comparison, a finite scalar with
  `0 < tau <= 0.5`.

- G_max:

  Positive integer cap on the number of occupied grades
  (`1 <= G_max <= n`).

- objective:

  Must be `"weighted"` (`"minimax"` is not supported in tie-aware mode).

- q:

  Must be `NULL` (criterion error budgets are not supported in tie-aware
  mode).

- exact_G:

  Must be `NULL` (requiring an exact grade count is not supported in
  tie-aware mode).

## Value

A `postrank_tie_problem` list (separate from `postrank_problem`)
containing `pairwise`, `settings`, `guard` (the active-profile equality
constraint), sparse label-MIP `model`, `index`, `pair_map`,
`M = choose(n, 2)`, `objective_units`, and `problem_identity`. Its raw
objective `Z` equals weighted expected strict errors minus `tau` times
weighted expected disclosed-distinct pairs, so weighted risk is
`R0 + Z / M`, where `objective_units$offset` is the all-withheld risk
`R0 = tau * T / M` (smaller than `tau` whenever positive equality
probability is present on an active criterion).

## Details

Grade `1` is the highest priority, and placing two entities in the same
grade leaves them unordered without claiming equal targets. On criterion
`k`, ordering `i` above `j` has expected loss
`b[i, j, k] = Pr(theta_{i,k} < theta_{j,k})`, leaving them in the same
grade has expected loss
`tau * d[i, j, k] = tau * Pr(theta_{i,k} != theta_{j,k})`, and exact
equality (`theta_{i,k} = theta_{j,k}`) contributes zero loss under
either decision. With `T` denoting the criterion-weighted sum of
expected distinct pairs, placing all entities in one shared grade has
risk `R0 = tau * T / M`, where `M = choose(n, 2)` counts all original
unordered entity pairs.

`postrank_tie_problem()` intersects the criterion equality partitions
across positive-weight (`weights > 0`) criteria to form *active-profile
equality classes* (`guard$classes` and `guard$groups`, labeled
`"profile_1"`, ...) and adds linear equality rows forcing every member
of a class to receive the same grade while keeping all `n` entities and
original pair multiplicities. For weighted at-most-`G_max` problems
without extra constraints, there always exists a global risk minimizer
obeying this constraint (moving all members of a class to the
lowest-cost grade among their currently occupied grades cannot increase
risk or add occupied grades), although unconstrained problems can also
admit other minimizers that split a class.

## See also

[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
problem <- postrank_tie_problem(
  pw,
  weights = c(S = 0.6, C = 0.4),
  tau = 0.25,
  G_max = 3L
)
problem$guard$groups
#> $profile_1
#> [1] "A" "B"
#> 
#> $profile_2
#> [1] "C"
#> 
#> $profile_3
#> [1] "D"
#> 
problem$objective_units
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
