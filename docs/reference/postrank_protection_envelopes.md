# Build Inner and Outer Problems for Error Budgets

`postrank_protection_envelopes()` builds two empirical grading problems
from a weighted problem that carries criterion error budgets `q_k`. Here
a *protection envelope* is the pair of tightened (`inner`, using
`q_k - epsilon_k`) and relaxed (`outer`, using `q_k + epsilon_k`)
problems formed with simultaneous IID probability radii `epsilon_k` from
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
so that, on the simultaneous `1 - alpha` event, their feasible sets
bracket the unknown true budget-constrained set. Building the envelopes
runs no solver.

## Usage

``` r
postrank_protection_envelopes(problem, bounds)
```

## Arguments

- problem:

  Original public weighted `postrank_problem` from
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
  with non-empty `q` budgets (`objective = "weighted"` and no existing
  `protection_envelope`). `objective = "minimax"` is not supported.

- bounds:

  A `postrank_iid_bounds` object from
  [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
  built on the exact same posterior input, retaining every declared
  criterion in `problem` (including zero-weight criteria) in the same
  order.

## Value

A `postrank_protection_envelopes` list containing `public_problem`,
`public_q`, `bounds`, `inner_problem`, `outer_problem`, signed
`thresholds = list(inner = ..., outer = ...)`, `envelope_identity`, and
status fields (`status = "diagnostic_only"`, `bound_computed = FALSE`,
and `guarantee_issued = FALSE`). This object does not issue a
statistical or numerical certificate.

## Details

For each protected criterion `k`, the empirical linear inequality is
\\\widehat E_k \le (q_k - \varepsilon_k) N\\ in `inner_problem` and
\\\widehat E_k \le (q_k + \varepsilon_k) N\\ in `outer_problem`, where
`N` is the number of disclosed (ordered) pairs and \\\widehat E_k\\ is
the empirical sum of wrong-direction probabilities on criterion `k`. The
signed thresholds `q_k - epsilon_k` and `q_k + epsilon_k` are internal
linear constraint coefficients and are not clipped to `(0, 1)` (nor
accepted by the public `q` argument of
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)).

On the simultaneous `1 - alpha` coefficient event (and subject to valid
numerical feasibility checks), every grading feasible for
`inner_problem` satisfies the true posterior `q` budgets, and every
grading satisfying the true posterior `q` budgets is feasible for
`outer_problem`. When `q_k - epsilon_k < 0`, no grading with `N > 0` can
satisfy that inner row, whereas the single-grade all-withheld grading
has `N = 0` and remains feasible whenever `G = 1` is allowed
(`exact_G >= 2` excludes `G = 1`). Therefore an infeasible
`inner_problem` does not prove that the true budget-constrained problem
is infeasible. Setting a criterion's objective `weight` to `0` keeps any
explicit `q_k` budget and its `epsilon_k` radius active.

Pass the returned object to
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
to solve both problems and compare an inner grading against an outer
whole-problem lower bound.

## See also

[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md),
[`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md)

## Examples

``` r
bounds <- postrank_iid_bounds(
  postrank_toy,
  alpha = 0.05,
  alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
  design = list(
    sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE,
    adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"
  )
)
problem <- postrank_problem(
  postrank_pairwise(postrank_toy),
  weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25,
  G_max = 3L,
  q = c(need_A = 0.2)
)
envelopes <- postrank_protection_envelopes(problem, bounds)
envelopes$thresholds
#> $inner
#>      need_A 
#> -0.09263456 
#> 
#> $outer
#>    need_A 
#> 0.4926346 
#> 
identical(envelopes$public_problem, problem)
#> [1] TRUE
```
