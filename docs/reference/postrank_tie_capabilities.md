# List Supported Features in Tie-Aware Mode

`postrank_tie_capabilities()` returns a static list showing which
inputs, problem settings, solvers, and downstream summaries are
supported in tie-aware mode (the `postrank_tie_*` workflow for
posteriors with positive equality probability under equality-neutral
loss). It does not probe whether `"gurobi"` or `"highs"` is installed or
licensed; use
[`postrank_backend_available()`](https://joonho112.github.io/postrank/reference/postrank_backend_available.md)
for solver checks.

## Usage

``` r
postrank_tie_capabilities()
```

## Value

A named list containing identifiers (`loss = "tie_aware_v1"`,
`input_domain = "tie-aware-input-0.1"`,
`backends = c("gurobi", "highs")`, and `equality_evidence`) and logical
support flags:

- `TRUE`: `joint_draws`, `exact_finite_laws`, `weighted_at_most_G`,
  `full_active_profile_guard`, and `label_mip`.

- `FALSE`: `staged`, `criterionwise_inputs`, `typed_coefficients`, `q`,
  `minimax`, `exact_G`, `legacy_baselines_reports_plots`,
  `mc_diagnostics`, `uniform_iid_bounds`, `regret`,
  `protection_envelopes`, and `numerical_certification`.

## Details

Tie-aware mode supports joint equal-weight draws and complete exact
finite laws on one or more criteria under weighted at-most-`G_max`
problems solved by `label_mip` with the active-profile equality
constraint. Criterion-wise draw blocks, Gaussian or mixture
coefficients, criterion error budgets `q`, `minimax` objectives,
`exact_G` grade counts, and `"staged"` solving are not implemented for
tie-aware inputs.

Tie-aware objects have [`print()`](https://rdrr.io/r/base/print.html),
[`format()`](https://rdrr.io/r/base/format.html), and
[`summary()`](https://rdrr.io/r/base/summary.html) methods, while
ordinary zero-equality baselines, table accessors, HTML reports, plots,
Monte Carlo diagnostics, and IID bounds reject `postrank_tie_*` classes
rather than reinterpreting their equality-neutral loss.

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`postrank_backend_available()`](https://joonho112.github.io/postrank/reference/postrank_backend_available.md),
[`vignette("m4-ties-and-withholding", package = "postrank")`](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)

## Examples

``` r
capabilities <- postrank_tie_capabilities()
capabilities[c("weighted_at_most_G", "q", "minimax", "exact_G")]
#> $weighted_at_most_G
#> [1] TRUE
#> 
#> $q
#> [1] FALSE
#> 
#> $minimax
#> [1] FALSE
#> 
#> $exact_G
#> [1] FALSE
#> 
capabilities$backends
#> [1] "gurobi" "highs" 
```
