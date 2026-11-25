# Bound Weighted Risk Regret Under Fixed-Sample IID Draws

`postrank_regret_bound()` combines simultaneous IID probability radii
from
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
with a solver's whole-problem risk gap to compute an analytic upper
bound on posterior weighted-risk regret over a fixed grading family. The
bound applies to posterior expected loss rather than differences between
grade vectors.

## Usage

``` r
postrank_regret_bound(fit, bounds)
```

## Arguments

- fit:

  A `postrank_fit` (for example `analysis$fit`) solved on the exact same
  input as `bounds` with `objective = "weighted"` and no criterion error
  budgets (`q = NULL`). Both `at-most-G_max` and `exact_G` families are
  supported when fixed beforehand; `objective = "minimax"` and empirical
  `q` constraints stop with an error.

- bounds:

  A matching `postrank_iid_bounds` object from
  [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md).

## Value

A `postrank_regret_bound` list containing `weights`, `epsilon`, weighted
probability error `delta_w`, whole-problem solver gap `eta`,
`regret_upper_bound` (`2 * delta_w + eta` when established, otherwise
`NA_real_`), `eta_source`, `unavailable_reason`, `action_space`, and
status flags. When `eta` is usable, `guarantee_status` is
`"conditional_bound"` (`guarantee_issued` and `numerically_verified`
remain `FALSE`); when `eta` is missing or inconsistent,
`regret_upper_bound` is `NA_real_` with
`guarantee_status = "not_established"` and `unavailable_reason` stating
why. Invalid or mismatched inputs stop with an error.

## Details

Let \\\delta_w = \sum_k w_k \varepsilon_k\\. On the simultaneous \\1 -
\alpha\\ coefficient event of `bounds`, and given a valid absolute risk
gap \\\eta = U - L\\ for the complete empirical problem, the chosen
grading's true posterior weighted risk exceeds the minimum true
posterior weighted risk over the same fixed grading family by at most
\\2 \delta_w + \eta\\. Both the selected grading and the comparator must
belong to the same non-empty grading family fixed prior to sampling;
`postrank` records that assumption without verifying prior fixation.

`postrank_regret_bound()` re-runs
[`validate_postrank_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_solution.md)
on `fit$raw_solution` and checks that `fit` has a verified grading, no
numerical issues, and a whole-problem lower bound consistent with
`fit`'s risk units (including lower bounds clamped within one objective
tolerance when `bound_inversion_within_tolerance` is `TRUE`). An
unfinished solve (such as `"time_limit"`) is usable when it retains a
valid whole-problem lower bound; a raw objective gap, relative gap,
restricted candidate-set bound, or solver status label alone is never
substituted.

Empirical error budgets `q` depend on estimated probabilities and can
change which gradings are feasible, so use
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
and
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
when `q` is set. Because the formula is evaluated in ordinary
floating-point arithmetic from solver-reported bounds, it does not
provide a formal numerical certificate or imply a unique optimal
grading.

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
toy <- postrank_example("toy_analysis")
ref <- postrank_regret_bound(toy$fit, bounds)
ref[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
#> $delta_w
#> [1] 0.2926346
#> 
#> $eta
#> [1] 0
#> 
#> $regret_upper_bound
#> [1] 0.5852691
#> 
#> $guarantee_issued
#> [1] FALSE
#> 
```
