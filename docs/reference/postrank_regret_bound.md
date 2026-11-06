# Bound Weighted Risk with IID and Optimization Errors

A conditional regret reference is calculated for a weighted report
selected from the same fixed action family as its comparator.
Probability approximation error is combined with an absolute
optimization gap for the complete empirical problem. The resulting bound
concerns risk rather than differences between grade vectors.

## Usage

``` r
postrank_regret_bound(fit, bounds)
```

## Arguments

- fit:

  A normalized `postrank_fit` for the weighted problem on exactly the
  input used for `bounds`. At-most-G and exact-G families are supported
  when held fixed. Empirical `q` protections and minimax are unsupported
  here.

- bounds:

  A matching object from
  [`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md).

## Value

A `postrank_regret_bound` object containing `delta_w`, the usable
absolute risk gap `eta`, and `regret_upper_bound` when established.
Missing or unusable gap information produces `NA` with
`guarantee_status = "not_established"` and an explicit reason. Invalid
or mismatched inputs raise an error. A computed result remains an
uncertified conditional floating-point reference.

## Details

Write \\\delta_w=\sum_k w_k\varepsilon_k\\. On the simultaneous
coefficient event, true supplied-law regret is at most
\\2\delta_w+\eta\\, assuming a valid empirical whole-problem gap
\\\eta=U-L\\. Both the chosen action and the true-risk comparator must
belong to the same nonempty fixed family. The function records that
assumption; it cannot verify that the analyst fixed the family in
advance.

The fit's incumbent is independently revalidated. The gap must be the
normalized absolute gap in risk units from the same complete problem. A
raw objective gap, relative gap, restricted candidate-set lower bound,
or status label alone is insufficient. A numerically validated but
unfinished solve can be usable when it retains the required
whole-problem bound. Numerical issues or inconsistent bounds prevent the
calculation.

Empirical protection constraints can change the feasible family when
coefficients change, so the common-family argument does not apply to
them. Use
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
and
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
for that separate construction. The reference certifies neither
arithmetic nor backend bounds, posterior calibration, or a unique
selected grade.

## See also

[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md)

## Examples

``` r
bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025),
  design = list(sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"))
problem <- postrank_problem(postrank_pairwise(postrank_toy),
  weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
if (FALSE) { # \dontrun{
# Optional native solve; requires an installed HiGHS backend.
fit <- postrank_solve(problem, backend = "highs",
  control = postrank_control(time_limit = 10, threads = 1))
reference <- postrank_regret_bound(fit, bounds)
reference[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
} # }
```
