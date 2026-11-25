# Specify Loss and Error Controls for Multidomain Grading

`postrank_mdomain_decision()` builds a decision specification setting
domain weights, withholding costs `tau`, pair scopes, expected-error
budgets `q`, and joint false-discovery-proportion (FDP) exceedance
thresholds `t` and `alpha` for multidomain profile grading. Domain IDs,
unit IDs, and scope dimensions are checked again when the specification
is matched to a
[`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
object. Grade `1` is the highest priority within each domain, and equal
grades leave a pair unordered. Requires optional package `gmp`.

## Usage

``` r
postrank_mdomain_decision(
  weights = NULL,
  tau = "1/10",
  scope = "all_pairs",
  q = NULL,
  t = "0",
  alpha = "1/20",
  expected = NULL,
  joint = NULL
)
```

## Arguments

- weights:

  Domain weights (non-negative with positive total), or `NULL` (the
  default) for exact equal weights `1 / D` on every domain. Named
  vectors must match the input's domain order. Rational strings (such as
  `c("3/5", "2/5")` or `c("0.6", "0.4")`) must sum to `1` exactly;
  numeric weights within `1e-12` of `1` are normalized in exact
  stored-binary rational arithmetic when bound to an input. Zero weights
  are allowed and keep protection rows on that domain active.

- tau:

  Withholding cost in `(0, 1/2]`, as a scalar or domain-ordered vector
  (default `"1/10"`).

- scope:

  `"all_pairs"` (the default), or a named list of symmetric `n x n`
  binary (`0`/`1` or logical) matrices with zero diagonals (when named,
  row and column names must match input unit order).

- q:

  Optional expected wrong-direction error cap (`E / N <= q`) in
  `[0, 1]`, as a scalar or domain-ordered vector. `NULL` (the default)
  omits expected-error constraints unless `expected` is supplied.

- t:

  Threshold in `[0, 1]` for strict scoped FDP exceedance events
  `F / N > t`, as a scalar or domain-ordered vector (default `"0"`, so
  any wrong-direction error `F >= 1` counts as an exceedance). Set
  `t = NULL` to disable convenience joint constraints.

- alpha:

  Upper bound in `[0, 1]` on the probability of the union of all active
  `F / N > t` events across domains and scopes (default `"1/20"`).

- expected:

  Optional data frame with columns `domain_id`, `scope_id`, and `q`,
  overriding `q`. Pass a zero-row data frame to disable expected-error
  constraints when using a custom `scope` catalog.

- joint:

  Optional data frame with columns `domain_id`, `scope_id`, and `t`,
  overriding `t`. Pass a zero-row data frame to disable joint FDP
  constraints when using a custom `scope` catalog.

## Value

A `postrank_mdomain_decision` list storing the validated policy
parameters and exact-rational `receipts`.

## Details

Policy numbers (`weights`, `tau`, `q`, `t`, `alpha`) accept fraction or
decimal strings (`"1/10"`, `"0.05"`),
[`gmp::bigq`](https://rdrr.io/pkg/gmp/man/bigrational.html) rationals,
or finite R `numeric` values. String fractions and decimals keep their
exact rational value, whereas R `numeric` values keep their exact
IEEE-754 binary floating value (for instance, numeric `0.1` is not
`1/10`), so strings are recommended whenever exact decimal or fractional
thresholds are intended.

Convenience arguments `q` and `t` expand to one row per domain on the
full-pair scope (`"full"`). If `scope` is a custom list of masks that
omits a full-pair mask, supply `expected` and `joint` explicitly (or
zero-row data frames to disable them).

## See also

[`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md),
[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`postrank_mdomain_assess()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)

## Examples

``` r
dec <- postrank_mdomain_decision(tau = "1/4", t = "1/10", alpha = "1/20")
dec
#> Multidomain decision recipe
#>   Withholding cost tau: 1/4
#>   Mean guards: disabled
#>   Joint guards: full-scope convenience rows
#>   Joint cap alpha: 1/20; exact rational policy fields
summary(dec)
#> Multidomain decision summary (unbound recipe)
#>  parameter domain_id exact_value
#>    weights      <NA>        <NA>
#>        tau      <NA>         1/4
#>          q      <NA>        <NA>
#>          t      <NA>        1/10
#>      alpha      <NA>        1/20
#>   Scope catalog and explicit protection rows are retained in this summary.
```
