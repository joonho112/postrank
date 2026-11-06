# Construct Inner and Outer Problems for Criterion Protections

Two empirical problems are constructed from a weighted problem with
criterion-specific error budgets. Simultaneous coefficient-error radii
are used to tighten the budgets for the inner problem and relax them for
the outer problem. The construction itself requires no optimization.

## Usage

``` r
postrank_protection_envelopes(problem, bounds)
```

## Arguments

- problem:

  A public weighted
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
  with nonempty `q` budgets. Begin with the original public problem, not
  a previously created envelope. Minimax is unsupported.

- bounds:

  A
  [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
  object from exactly the same posterior input, retaining every declared
  criterion, including zero-weight criteria.

## Value

A `postrank_protection_envelopes` object containing the original
`public_problem`, `bounds`, `public_q`, internal `inner_problem` and
`outer_problem`, and their signed `thresholds`. The original problem and
public budgets are preserved. No statistical or numerical certificate is
issued.

## Details

The empirical rows are \\\widehat E_k\leq(q_k-\varepsilon_k)N\\ for the
inner problem and \\\widehat E_k\leq(q_k+\varepsilon_k)N\\ for the outer
problem. Here `N` counts disclosed pairs, not all possible pairs; `E` is
the sum of directional-error probabilities on that criterion. Thresholds
are deliberately not clipped to the public `q` range.

On the simultaneous coefficient event, the inner feasible family lies
inside the true protected family, which lies inside the outer family,
subject also to valid numerical feasibility checks. A negative inner
threshold excludes positive disclosure on that protected criterion. An
all-withheld action has `N = 0` and satisfies these rows when the action
family permits it; exact-G with more than one nonempty grade excludes
it. Thus an infeasible inner problem does not establish infeasibility of
the original protected problem. A zero criterion-loss weight does not
remove an explicit protection or its need for a coefficient radius.

The models retain the original objective and grade-count family. Their
signed thresholds are internal linear inequalities, not new accepted
values for the public `q` argument.
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
can solve the two problems and combine an inner action with a
whole-outer lower bound. Construction alone does not establish that an
action satisfies the error budgets under the supplied posterior law.

## See also

[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)

## Examples

``` r
bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025),
  design = list(sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"))
problem <- postrank_problem(postrank_pairwise(postrank_toy),
  weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L,
  q = c(need_A = .2))
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
