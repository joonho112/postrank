# Solve Protection Envelopes and Compare Their Risk Bounds

The inner and outer problems from
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
are solved to obtain a conditional regret reference for the inner report
under the true criterion protections. The two optimizations are
performed sequentially. Both attempt records are retained even when the
first optimization fails or is infeasible.

## Usage

``` r
postrank_protection_analysis(envelopes, backend = NULL, control = list())
```

## Arguments

- envelopes:

  An object from
  [`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md).

- backend:

  Explicit `"highs"` or `"gurobi"`, or `NULL` to use the
  `postrank.backend` option and then Gurobi. There is no backend
  fallback. An unavailable selected backend raises an error before the
  attempts.

- control:

  A
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  object or named control list passed to each of the two solves. A time
  limit applies separately to each solve.

## Value

A `postrank_protection_analysis` object with `inner_fit`, `outer_fit`,
two `attempts`, thresholds, and any unavailable `reasons`. When usable,
it contains `inner_risk_upper`, `outer_whole_problem_risk_lower`,
`delta_w`, and `computed_value`; otherwise that value is `NA` and the
status is `"not_established"`. Computed values have `"diagnostic_only"`
status, not numerical or finite-sample certification.

## Details

Let \\U\_{\rm inner}\\ be the risk of a validated inner candidate,
\\L\_{\rm outer}\\ a lower bound for the whole outer problem, and
\\\delta_w=\sum_k w_k\varepsilon_k\\. The returned reference is
\\U\_{\rm inner}-L\_{\rm outer}+2\delta_w\\. Under the simultaneous
coefficient event and valid numerical feasibility and bounds, this
bounds the inner report's supplied-law regret relative to the true
protected family.

The calculation needs a validated inner candidate and a usable
whole-outer lower bound without numerical issues. Neither the inner
lower bound nor an outer incumbent may replace that lower bound. Missing
incumbents, unusable bounds, solve errors, and an inverted cross-problem
gap retain explicit reasons. A status label such as `"optimal"` is not
sufficient. An infeasible inner envelope alone does not prove that the
original protected family is empty.

The IID assumptions and signed-threshold construction are described in
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
and
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md).
The package supplies no verified outward coefficient/arithmetic
enclosure or rigorous backend-bound certifier. This result is not a
posterior probability of feasibility or evidence of calibration on new
data.

## See also

[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
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
  weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L,
  q = c(need_A = .2))
envelopes <- postrank_protection_envelopes(problem, bounds)
if (FALSE) { # \dontrun{
# Optional: two small native solves, each with its own 10-second limit.
analysis <- postrank_protection_analysis(envelopes, backend = "highs",
  control = postrank_control(time_limit = 10, threads = 1))
analysis[c("status", "computed_value", "reasons", "guarantee_issued")]
} # }
```
