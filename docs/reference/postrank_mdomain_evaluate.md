# Evaluate a Fixed Multidomain Grade Profile

`postrank_mdomain_evaluate()` computes domain-weighted expected loss
and, when `mode = "joint"`, the probability of the union of strict
scoped false-discovery-proportion (FDP) exceedances for a fixed
multidomain grade matrix without searching candidates. Requires optional
package `gmp`.

## Usage

``` r
postrank_mdomain_evaluate(
  input,
  grades,
  decision = NULL,
  mode = c("joint", "expected"),
  keep_traces = TRUE
)
```

## Arguments

- input:

  A validated
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  object.

- grades:

  Finite numeric `n x D` matrix with row and column names in `input`'s
  exact unit and domain order (`1` = highest priority within each
  domain). Occupied grade labels on each domain are renumbered to
  `1..K_d` without changing pairwise orderings or ties; equal grades
  leave a pair unordered without claiming equal targets, and splitting a
  structural equality class stops with an error.

- decision:

  A
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  specification, or `NULL` (the default) to use the default
  specification from
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md).

- mode:

  `"joint"` (the default, evaluating both expected quantities and the
  joint union exceedance probability `J`) or `"expected"` (evaluating
  expected quantities only, leaving `J`, `joint_feasible`, and
  `feasible_for_represented_measure` as `NA`, even when joint
  constraints are disabled).

- keep_traces:

  Logical scalar (`TRUE` by default). When `TRUE`, retains per-state
  error counts and joint event indicators in `evaluation`.

## Value

A `postrank_mdomain_evaluation` list containing `input`, `action`,
`decision` (matched to `input`), renumbered (`1..K_d`) `n x D` integer
`grades`, `mode`, `M = n * (n - 1) / 2`, `risk` and `risk_exact`, `J`
and `J_exact`, `domain_table`, `scope_table`, `expected_constraints`,
`event_table` (`NULL` in `"expected"` mode), `mean_feasible`,
`joint_feasible`, `feasible_for_represented_measure`, `status`,
`assurance`, and `receipts` (validation and hash records, including
`validation_spec_hashes` for
[`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)).

## Details

Expected loss uses the full unordered pair count `M = n * (n - 1) / 2`
as its denominator, whereas scoped FDP `F / N` uses the number `N` of
pairs ordered inside that scope on that domain. Each strict exceedance
event `F / N > t` is evaluated via the exact `gmp` integer cutoff
`F >= floor(t * N) + 1`; when `N = 0`, no pairs are ordered in that
scope so the event is analytically false.

Separate domain matrix inputs (`layout = "criterionwise_arrays"`) can
run `mode = "joint"` only when at most one domain has an active joint
event (or the union event is analytically zero); matching row names
across separate matrices are never paired as coupled joint states. Exact
rational (`gmp`) arithmetic over finite draws evaluates their empirical
distribution without rounding error rather than certifying feasibility
under an intended continuous posterior.

## See also

[`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md),
[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md),
[`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)

## Examples

``` r
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
G <- matrix(
  c(1L, 1L, 2L, 3L, 1L, 2L),
  nrow = 3L,
  ncol = 2L,
  dimnames = list(inp$unit_ids, inp$domain_ids)
)
ev <- postrank_mdomain_evaluate(inp, G)
ev
#> Fixed multidomain report evaluation
#>   3 units; 2 domains; mode: joint
#>   Risk: 19/240; joint probability: 11/32
#>   Joint guards: evaluated; infeasible_for_represented_measure
#>   Basis: supplied_empirical_measure; exact_represented_measure_arithmetic
#>   Intended posterior feasibility certificate: none
ev$domain_table
#>   domain_id N     EF withheld       loss weighted_loss      eFDP eFDP_zero
#> 1    need_A 2 0.0625        1 0.05416667    0.02708333 0.0312500 0.0312500
#> 2    need_B 3 0.3125        0 0.10416667    0.05208333 0.1041667 0.1041667
#>   EF_exact loss_exact weighted_loss_exact eFDP_exact eFDP_zero_exact
#> 1     1/16     13/240              13/480       1/32            1/32
#> 2     5/16       5/48                5/96       5/48            5/48
#>                               arithmetic
#> 1 exact_empirical_iid_equal_weight_draws
#> 2 exact_empirical_iid_equal_weight_draws
```
