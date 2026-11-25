# Optimal or Quantile Cuts of a Declared Score Order

`postrank_cuts()` partitions an entity score order into contiguous
integer grades (grade 1 = highest priority), keeping entities with equal
scores in the same grade. No external optimization solver is required.

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

  Finite numeric vector named by `pairwise$entity_ids`, for example from
  [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
  or
  [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md).

- pairwise:

  A `postrank_pairwise`, `postrank_coefficients` or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object supplying directional-error probabilities.

- settings:

  A
  [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  object specifying weighted `weights`, `tau`, `G_max` and optional
  `exact_G`.

- direction:

  Score direction: `"ascending"` (smaller score = higher priority, the
  default, matching
  [`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md))
  or `"descending"` (larger score = higher priority, matching
  [`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)).

- rule:

  Cut rule: `"optimal"` (the default, dynamic programming over
  contiguous cuts) or `"quantile"` (fixed positional cuts).

- G_b:

  Positive integer requested grade count when `rule = "quantile"`
  (defaults to `settings$exact_G`, or `settings$G_max`, capped at `n`;
  must be `NULL` when `rule = "optimal"`).

- method:

  Optional non-empty label for this baseline; defaults to
  `attr(scores, "score_method")`, or `"user_scores"` if unset.

## Value

A `postrank_baseline` list containing `method`, `scores`, `direction`,
`order`, `score_blocks`, `cut_rule`, `cuts`, `grade`, `evaluation`,
`objective`, `risk`, `optimality_scope`, `tie_policy`, bound `settings`,
`input_identity`, `schema_version`, `provenance` and `warnings`.

## Details

`rule = "optimal"` uses dynamic programming (in ordinary floating-point
arithmetic) to minimize weighted expected loss over contiguous
partitions of the given score order under `G_max` or `exact_G` (breaking
exact objective ties toward fewer occupied grades and then earlier block
cuts). Optimality holds only within contiguous partitions of this score
order, not across all allowed gradings. `rule = "quantile"` assigns raw
positional grades \\1 + \lfloor (p - 1) G_b / n \rfloor\\ without
optimization, merging any grades straddled by equal scores (which can
leave fewer than `G_b` occupied grades, recorded in `warnings`).

Settings with `q` error budgets or `objective = "minimax"` stop with
`unsupported_baseline_settings`, and `exact_G` exceeding the number of
distinct score blocks stops with `exact_G_exceeds_blocks` (or
`baseline_exact_grade_violation` when quantile merging leaves fewer
grades).
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
inputs support at-most-`G_max` cuts without `exact_G`, whereas
`postrank_pairwise` and `postrank_coefficients` also allow `exact_G`.

## See also

[`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md),
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)

## Examples

``` r
pw <- postrank_pairwise(postrank_toy)
s <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s,
  direction = "ascending")
get_grades(er)
#>    001 site-B site C 
#>      1      1      2 
```
