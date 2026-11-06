# Optimal or Quantile Cuts of a Declared Score Order

A declared score order is partitioned into ordered grades, with exactly
tied scores retained in the same grade. Optimal cuts minimize weighted
loss over partitions of that order, whereas quantile cuts use fixed
positions. The search therefore remains conditional on the declared
order.

## Usage

``` r
postrank_cuts(
  scores,
  pairwise,
  settings,
  direction = c("ascending", "descending"),
  rule = c("optimal", "quantile"),
  G_b = NULL,
  method = NULL
)
```

## Arguments

- scores:

  A named score vector (one per entity), for example from
  [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
  or
  [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md).

- pairwise:

  The `postrank_pairwise`, `postrank_coefficients`, or
  `postrank_probabilities` object whose directional errors define the
  loss.

- settings:

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object (weights, tau, grade rule).

- direction:

  `"ascending"` (smaller score = higher priority, as for expected rank)
  or `"descending"` (larger = higher, as for composites).

- rule:

  `"optimal"` or `"quantile"`.

- G_b:

  For `rule = "quantile"`, the requested number of grades (default: the
  settings' `exact_G`, else `G_max`, capped at `n`).

- method:

  Optional label; defaults to the score's `score_method` attribute, else
  `"user_scores"`.

## Value

A `postrank_baseline` list. `scores`, `direction`, `order` and
`score_blocks` record the declared order and its indivisible exact-score
blocks. `cut_rule`, `cuts` (block positions) and the entity-named
`grade` record the action. `evaluation` contains the fixed-action
metrics; `risk` is the weighted loss and `objective` its raw
optimization value. `optimality_scope` distinguishes optimal partitions
of this score order from quantile cuts; neither provides a full-family
solver bound. `method`, `tie_policy`, bound `settings`,
`input_identity`, `schema_version`, `provenance` and `warnings` retain
the construction record. When the requested grade count is impossible,
the function raises an error rather than returning an all-withheld
report.

## Details

`rule = "optimal"` uses a contiguous-partition dynamic program (subject
to ordinary floating-point arithmetic) under the settings' grade cap
`G_max`, or the exact grade count `exact_G`; its optimality is
restricted to contiguous partitions of this score order.
`rule = "quantile"` uses the fixed positional labels \\1 + \lfloor
(p - 1) G_b / n \rfloor\\ and performs no optimization. Exactly equal
stored scores are never split; a quantile boundary inside an exact-score
block merges the grades it straddles, so the realized number of grades
can be below `G_b`. The realized grade count must still satisfy `G_max`
and `exact_G`; violations raise `baseline_grade_limit_violation` or
`baseline_exact_grade_violation`.

The dynamic program optimizes the weighted objective only: settings with
error budgets `q` or the minimax objective are refused
(`unsupported_baseline_settings`); an `exact_G` larger than the number
of exact-score blocks is refused (`exact_G_exceeds_blocks`). Typed
Gaussian and mixture coefficients permit exact-count cuts within this
fixed order, although their native joint problem constructor does not
support exact-G. Direct
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
inputs are restricted to weighted at-most-G cuts, as well as weighted
at-most-G native problems.

## See also

[`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md),
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)

## Examples

``` r
pw <- postrank_pairwise(postrank_toy)
s <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s, direction = "ascending")
get_grades(er)
#>    001 site-B site C 
#>      1      1      2 
```
