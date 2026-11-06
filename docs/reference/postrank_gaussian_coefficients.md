# Compute Comparisons from a Conditional Gaussian Law

Directional-error probabilities are calculated from conditional means
and covariance matrices without simulation of the target values. The
input may contain one or several criteria, with dependence among
criteria within an entity. Entities are assumed independent conditional
on the supplied shared state.

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

  Finite numeric matrix with dimension names
  `list(entity = entity_ids, criterion = criterion_ids)`. Supply at
  least two unique entity IDs and one criterion. Targets must already be
  oriented so that larger values mean higher reporting priority, in the
  declared units.

- covariance:

  Finite, symmetric, positive definite conditional covariance array with
  dimensions criterion-by-criterion-by-entity and dimension names
  `list(criterion_i = criterion_ids, criterion_j = criterion_ids, entity = entity_ids)`.
  Each matrix describes dependence among criteria within one entity; it
  cannot encode covariance between entities. For one criterion, each
  matrix is its positive conditional variance. No jitter or covariance
  repair is applied.

- conditional_independence:

  Explicitly `"entities_given_shared_h"`. This is a model assumption,
  not something inferred from marginal moments.

- provenance:

  Named list with `producer_id`, `producer_version`, `posterior_id`,
  `input_payload_sha256`, `source_sha256`, and `config_sha256`;
  `model_sha256` is optional. Hashes must be lowercase SHA-256 strings
  describing the actual source and calculation. They record provenance
  but do not authenticate the fit or its scientific assumptions.

## Value

A `postrank_coefficients` object containing posterior `means`, an
entity-by-entity-by-criterion directional-error array `e`, the supplied
conditional law and provenance, and supported-operation indicators. No
target draws or Monte Carlo sample sizes are created.

## Details

For distinct entities, \\e\_{ij,k}=P(\theta\_{i,k}\leq\theta\_{j,k})\\
is the error probability for reporting entity i above entity j. Positive
conditional variances and between-entity independence make equality have
probability zero. Diagonals are `NA`: self-comparisons are not used.

The normal difference uses the sum of the two conditional marginal
variances. Both directions use the normal CDF directly to retain small
tails. These are floating-point analytic calculations, not exact
rational arithmetic or certified numerical error bounds.

The native joint search through
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
supports weighted expected loss with an upper grade-count limit for this
input. It does not support minimax, criterion protections `q`, or an
exact grade count there.
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
can score a fixed report; scoring does not check its membership in a
constrained action family. Other operations have their own documented
support; see
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md).

The package does not fit the model or verify that the supplied law
follows from observed data. If an empirical Bayes prior estimate is held
fixed, these probabilities condition on that estimate. Use
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
to average conditional probabilities over explicitly supplied shared
states; matching only their moments changes the law in general.

## See also

[`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md),
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)

## Examples

``` r
# Reconstruct the documented one-criterion tutorial law with its own provenance.
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
