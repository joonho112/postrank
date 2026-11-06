# Compare Grading Rules on One Posterior and Loss

Alternative reports are evaluated under a common reference posterior and
loss, and changes in their pairwise relations are recorded. By default,
score-order baselines with optimal cuts are also calculated. With
`baselines = character()`, evaluation is restricted to the reference and
supplied actions, without optimization of cuts.

## Usage

``` r
postrank_compare(
  x,
  ...,
  baselines = c("expected_rank", "composite"),
  means = NULL
)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` with a validated grade.

- ...:

  Further `postrank_baseline` or `postrank_fit` objects, or named
  integer grade vectors (named arguments set the method label).

- baselines:

  Built-in baselines to add: any of `"expected_rank"` and `"composite"`;
  [`character()`](https://rdrr.io/r/base/character.html) for none.

- means:

  Optional `n x K` posterior mean matrix for the composite.

## Value

A `postrank_comparison` object. Its `table` includes method, risk,
disclosure, grade count, status, bounds, criterion error profiles,
`family_feasible` and `feasibility_reason`; `grades`, `relation_codes`
and `relations` use the same unique method IDs. `grades` is an
entity-by-method integer matrix and `relation_codes` an
entity-by-entity-by-method array; no-action columns are `NA`.
`relations` has one row per non-reference method, with `n_same`,
`n_new_disclosed`, `n_new_withheld`, `n_reversed` and `agreement` (the
unchanged fraction of all unordered pairs). `reference`, bound
`settings`, `input_identity`, `schema_version`, `provenance` and
`warnings` complete the object. Select table columns by name rather than
relying on their positions.

`reason` explains an unavailable action; `feasibility_reason` explains
an evaluated action outside the declared family. They are separate
fields. Duplicate method labels receive collision-free suffixes shared
by all result components. Use the returned IDs instead of predicting a
suffix. Older saved comparisons without feasibility metadata remain
displayable, with the absence of these records indicated. Checking
constraints requires recreating the comparison; displays do not
calculate missing metadata.

## Details

The common grade of `x` is labelled `"joint"`. Built-in baselines use
the same coefficients and policy: expected rank + optimal cuts and
posterior-mean composite + optimal cuts (`scales = 1`, `centers = 0`),
plus any baselines, fits or named grade vectors supplied through `...`.
Every action is evaluated under the reference settings, and relation
changes are read from the reference to the compared action.

Each row retains its status and scope: the joint row records solver
status, bounds and gap; an optimal-cuts baseline has
`status = "optimal"` with its restricted optimality scope; quantile and
supplied-action rows have status `"evaluated"`. Baseline rows have no
full-family bound (`NA`). A supplied fit without a validated grade stays
as a status row with `NA` action metrics and reason
`"no_validated_incumbent"`; an impossible requested baseline is
`"not_comparable"` with its error code as reason. A supplied fit or
baseline must match the reference policy and input identity. A named
grade vector carries no such policy record and is explicitly evaluated
under the reference loss, even if it was originally chosen for another
objective.

A supplied grade may be evaluated even when it is outside the reference
action family. `table$family_feasible` records grade-cap, exact-grade
and error-budget feasibility, with codes in `feasibility_reason`;
no-action rows have `NA`. All rows use the reference fit's recorded
feasibility tolerance for the raw budget residual `E_k - q_k * N`. This
tolerance is stored as `provenance$family_feasibility_tolerance` (the
usual validator default is used only if the reference receipt lacks it).
Grade counts are checked exactly. This is a numerical check, not a
certificate. Outside-family actions retain their risk and relations, and
are marked in print and figures; they do not support claims about minima
over the same feasible family.

Composite scores need posterior means: an explicit `means` matrix, the
input of a `postrank_analysis`, or the stored means of typed
coefficients. A fit built from empirical pairwise coefficients alone has
no means; requesting the composite baseline then raises
`missing_posterior_means`.

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25,
    G_max = 3L, backend = "highs", fragility = FALSE)
  cmp <- postrank_compare(fit)
  cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
}
#>          method   risk disclosure_rate G  status
#> 1         joint 0.2125       0.6666667 2 optimal
#> 2 expected_rank 0.2125       0.6666667 2 optimal
#> 3     composite 0.2125       0.6666667 2 optimal
```
