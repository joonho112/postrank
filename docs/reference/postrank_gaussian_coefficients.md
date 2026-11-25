# Compute Comparisons from a Conditional Gaussian Law

`postrank_gaussian_coefficients()` computes pairwise directional-error
probabilities analytically from entity posterior means and within-entity
covariance matrices under a normal (Gaussian) posterior, without
simulating draws. For distinct entities `i` and `j` on criterion `k`,
\\e\_{ij,k} = P(\theta\_{i,k} \le \theta\_{j,k})\\ is the probability
that reporting `i` above `j` is in the wrong order (diagonal entries are
`NA`).

## Usage

``` r
postrank_gaussian_coefficients(
  means,
  covariance,
  conditional_independence,
  provenance
)
```

## Arguments

- means:

  Finite plain numeric `n x K` matrix (`n >= 2`, `K >= 1`) with named
  `dimnames`: `list(entity = entity_ids, criterion = criterion_ids)`.
  Larger values must already mean higher priority toward grade 1.

- covariance:

  Finite symmetric positive-definite plain numeric `K x K x n` array
  with named `dimnames`:
  `list(criterion_i = criterion_ids, criterion_j = criterion_ids, entity = entity_ids)`.
  Each `K x K` slice gives within-entity covariance across criteria
  (positive variance when `K = 1`) and must satisfy exact symmetry
  `S == t(S)` with zero tolerance (symmetrize `(V + t(V)) / 2`
  beforehand if needed); cross-entity covariance cannot be encoded here,
  and singular or asymmetric matrices stop the call without repair.

- conditional_independence:

  Must be `"entities_given_shared_h"`, an explicit model declaration
  (not inferred from marginal moments) stating that entities are
  conditionally independent given the fixed conditioning state.

- provenance:

  Plain named list of non-empty character strings: `producer_id`,
  `producer_version`, `posterior_id`, `input_payload_sha256`,
  `source_sha256` and `config_sha256`, plus optional `model_sha256`.
  Every `*_sha256` entry must be a 64-character lowercase hexadecimal
  SHA-256 digest.

## Value

A `postrank_coefficients` object (`input_kind = "gaussian_conditional"`)
containing `entity_ids`, `criterion_ids`, `means`, the `n x n x K`
directional-error array `e`, `source`, `provenance`, `capabilities`,
`validation`, `coefficient_identity`, `input_identity`,
`pairwise_identity`, and `schema_version` (`"coefficient-0.1.0"`).

## Details

Each off-diagonal probability is computed directly in the lower tail of
the normal distribution from
`(means[j, k] - means[i, k]) / sqrt(v_i + v_j)` to preserve small tail
values; positive variances and conditional independence across entities
imply zero probability of exact equality. These are ordinary
floating-point analytic calculations, not exact rational arithmetic or
interval-verified bounds.

In
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
normal posterior coefficients support the weighted expected-loss
objective with `G_max` (minimax, `q` error budgets and `exact_G` are not
available there; see
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)).
If an empirical-Bayes prior is held fixed, these probabilities condition
on that estimate; to average over hyperparameter states, use
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
rather than moment-matching to a single normal distribution. `postrank`
does not fit the model or verify `provenance` hashes against external
files.

## See also

[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
[`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md),
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md),
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)

## Examples

``` r
law <- pr_tutorial$law
x <- postrank_gaussian_coefficients(
  means = law$means[, "score_A", drop = FALSE],
  covariance = law$covariance["score_A", "score_A", , drop = FALSE],
  conditional_independence = "entities_given_shared_h",
  provenance = pr_tutorial$one$provenance)
x$e[, , "score_A"]
#>         entity_j
#> entity_i         A         B            C            D            E
#>        A        NA 0.1883796 0.0003914691 0.0001026879 9.252871e-10
#>        B 0.8116204        NA 0.0066641644 0.0023388675 1.475701e-07
#>        C 0.9996085 0.9933358           NA 0.3618368049 4.004971e-03
#>        D 0.9998973 0.9976611 0.6381631951           NA 1.077813e-02
#>        E 1.0000000 0.9999999 0.9959950288 0.9892218666           NA
#>        F 1.0000000 1.0000000 0.9998973121 0.9996085309 8.555778e-01
#>         entity_j
#> entity_i            F
#>        A 7.687299e-13
#>        B 3.062416e-10
#>        C 1.026879e-04
#>        D 3.914691e-04
#>        E 1.444222e-01
#>        F           NA
```
