# Compute a Conditional Fixed-Sample IID Probability Bound

`postrank_iid_bounds()` computes an analytic simultaneous error radius
for pairwise directional-error probabilities estimated from a fixed
number of independent posterior draws. The `1 - alpha` probability
statement applies to repeated Monte Carlo draw generation from the same
fixed posterior distribution; it is not a posterior probability that a
grading is right and does not assess model specification or performance
on new datasets.

## Usage

``` r
postrank_iid_bounds(draws, alpha, alpha_by_criterion, design)
```

## Arguments

- draws:

  Independent equal-weight posterior draws prepared as an `S x n x K`
  array via `postrank_draws(..., regime = "iid")` or as separate
  per-criterion IID entity-draw matrices via
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  (`equal_weight = TRUE`, with `dependence_mode = "joint_model"` or
  `"criterionwise_expected_only"`). MCMC draws (effective sample size
  ESS cannot replace an IID draw count), exact finite laws, Gaussian or
  mixture coefficients, pre-computed
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
  and tie-mode inputs are rejected.

- alpha:

  Overall failure-probability budget, a finite scalar strictly between
  `0` and `1` fixed before generating the draws.

- alpha_by_criterion:

  Finite positive numeric vector named by every criterion in `draws`,
  summing to at most `alpha` and fixed before generating the draws.
  Values are ordered to `draws$criterion_ids` and are never rescaled
  automatically.

- design:

  Named list with exactly five elements (extra fields stop with an
  error): `sample_sizes_fixed_before_sampling = TRUE`,
  `alpha_fixed_before_sampling = TRUE`, `adaptive_stopping = FALSE`,
  criterion-named positive integer `planned_sample_sizes` equal to the
  actual retained draw counts `S` on every criterion, and a non-empty
  character scalar `declaration_note`. These fields record how the
  simulation was designed prior to sampling; `postrank` checks internal
  consistency but cannot verify external sampling history, and setting
  these flags on an adaptive or dependent sample does not make the bound
  valid.

## Value

A `postrank_iid_bounds` list containing `schema_version`,
`input_identity`, `bound_identity`, `entity_ids`, `criterion_ids`,
`dependence_mode`, criterion sample sizes `S`, unordered pair count
`M = choose(n, 2)`, `alpha`, `alpha_by_criterion`, unclipped
`raw_radius`, capped `epsilon = pmin(raw_radius, 1)`,
`radius_interpretation = "theoretical_floating_reference"`, `design`,
`assumptions`, `guarantee_reason`, `numerical_verification_reason`, and
status flags (`guarantee_status = "conditional_bound"`,
`bound_computed = TRUE`, while `guarantee_issued`,
`numerically_verified`, `numerical_certification`, and
`finite_sample_certificate` are `FALSE`).

## Details

With \\M = n(n - 1) / 2\\ unordered pairs, the radius on criterion \\k\\
is \$\$\varepsilon_k = \min\left\\1, \sqrt{\frac{\log(2M / \alpha_k)}{2
S_k}}\right\\.\$\$ Under the stated assumptions, with Monte Carlo
probability at least \\1 - \alpha\\ simultaneously across all directed
entity pairs and all declared criteria, every empirical
directional-error probability lies within \\\varepsilon_k\\ of its true
value under the supplied posterior. Independence is required across
whole-state draws \\s = 1, \dots, S_k\\ within each criterion, not
across entity pairs or across criteria.

The factor \\2M\\ uses the zero-equality complement identity \\e\_{ji,k}
= 1 - e\_{ij,k}\\, so bounding one direction per unordered pair bounds
the reverse direction by the same absolute error. That identity requires
zero posterior probability of exact pairwise equality (not necessarily
continuous marginal densities) and does not apply unchanged when exact
ties have positive probability. All draws must target one fixed proper
posterior; empirical Bayes hyperparameters held fixed during draw
generation are part of that conditioning.

Adaptive stopping and substituting MCMC ESS for \\S_k\\ are not
supported. Radii are evaluated in ordinary floating-point arithmetic
without outward interval-arithmetic enclosures, so this function does
not issue a formal numerical certificate.

## See also

[`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)

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
bounds$epsilon
#>    need_A    need_B 
#> 0.2926346 0.2926346 
bounds[c("guarantee_status", "guarantee_issued", "numerically_verified")]
#> $guarantee_status
#> [1] "conditional_bound"
#> 
#> $guarantee_issued
#> [1] FALSE
#> 
#> $numerically_verified
#> [1] FALSE
#> 
```
