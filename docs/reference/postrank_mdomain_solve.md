# Select a Multidomain Grade Profile from a Candidate Family

`postrank_mdomain_solve()` evaluates every grade profile in the
Cartesian product of a
[`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
and selects the feasible profile(s) minimizing domain-weighted expected
loss subject to expected-error budgets and direct joint
false-discovery-proportion (FDP) exceedance limits. Every tied minimizer
in the candidate set is retained. Requires optional package `gmp` and
runs no external MIP solver.

## Usage

``` r
postrank_mdomain_solve(input, family, decision = NULL, max_actions = 100000L)
```

## Arguments

- input:

  The validated
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  object used to build `family`.

- family:

  A
  [`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md)
  object built on `input`.

- decision:

  A
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  specification, or `NULL` (the default) to use the default
  specification from
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md).

- max_actions:

  Positive integer cap (`100000L` by default) on the exact Cartesian
  product size. If `family` has more than `max_actions` profiles,
  `postrank_mdomain_solve()` stops with an error before enumeration
  rather than truncating the search.

## Value

A `postrank_mdomain_fit` list containing `grades` (selected `n x D`
integer grade matrix), `evaluation`
([`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
output for `selected_id`), `candidate_table` (one row per examined
profile), `optimizer_ids`, `optimizer_count`, `selected_id`, `solution`,
`input`, `family`, `decision` (matched to `input`), `status`,
`search_scope`, `assurance`, and `receipts` (validation and hash
records).

## Details

When multiple feasible candidates tie for the minimum loss,
`optimizer_ids` lists all of them (`status$optimum = "tied"`) and
`selected_id` picks the first in lexicographic order of the renumbered
(`1..K_d`) grade columns without adding a secondary tie-breaking
objective.

Optimality holds only within the declared candidate family
(`status$optimality = "candidate_restricted"`); examining the entire
Cartesian product of `family` does not establish optimality over all
possible multidomain grade matrices or unrestricted ordered partitions.
Exact rational (`gmp`) arithmetic over finite draws evaluates their
empirical distribution without rounding error rather than certifying
feasibility or optimality under an intended continuous posterior. If an
active joint constraint requires cross-domain coupling that `input` does
not supply, the call stops with a capability error rather than pairing
separate domain rows.

## See also

[`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md),
[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md),
[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md)

## Examples

``` r
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
dec <- postrank_mdomain_decision(tau = "1/4", t = "1/2", alpha = "1/5")
fam <- postrank_mdomain_family(
  inp,
  order = "posterior_mean",
  cuts = list(need_A = 1:2, need_B = 1:2),
  max_grades = 3L
)
fit <- postrank_mdomain_solve(inp, fam, decision = dec)
fit
#> Multidomain candidate-family fit
#>   16 declared actions examined; 2 optimizers (tied)
#>   Risk: 5/48; joint probability: 0
#>   Scope: complete declared candidate product; unrestricted optimality not established
#>   Search: candidate_restricted_exact_optimum_for_represented_measure
#>   Intended posterior feasibility certificate: none
postrank_mdomain_grades(fit)
#>        need_A need_B
#> 001         1      3
#> site-B      1      1
#> site C      2      2
```
