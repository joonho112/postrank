# Average Comparisons Across Shared Gaussian States

Means and directional-error probabilities are obtained by averaging
conditional Gaussian laws over supplied shared states. Each state is
common to all entities. Consequently, averaging over the states can
retain dependence between entities that are independent conditional on a
state. The model and shared states are supplied externally; the package
neither fits nor samples the model.

## Usage

``` r
postrank_mixture_coefficients(
  components,
  weights,
  state_index,
  source_regime,
  conditional_independence,
  provenance
)
```

## Arguments

- components:

  Nonempty named list of state records, each with exactly `mu`, `Sigma`,
  `means`, and `covariance`. `mu` is a criterion-named vector; `Sigma`
  is a symmetric positive definite matrix with dimension names
  `criterion_i` and `criterion_j`. Conditional `means` and `covariance`
  use the entity and criterion axes described in
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md).
  Within-entity covariance may connect criteria; between-entity
  dependence enters through the shared state.

- weights:

  Nonnegative state-named probability weights in component order,
  summing to one within `1e-12`. They are not normalized automatically.
  These mixture masses describe the law, not criterion-loss weights.

- state_index:

  Plain data.frame in component order. A fixed finite mixture has only
  `state_id`; hyperparameter MCMC has `state_id`, `chain_id`, and
  original `iteration`, with unique positive integer chain/iteration
  coordinates. Chain coordinates are inapplicable to a fixed mixture.

- source_regime:

  `"fixed_finite_mixture"` for an explicitly supplied finite mixture, or
  `"hyperparameter_mcmc"` for retained shared-state MCMC output. The
  MCMC regime requires uniform weights over retained states.

- conditional_independence:

  Explicitly `"entities_given_shared_h"`. Independence is conditional on
  the same state for all entities; it is not inferred from marginal
  moments.

- provenance:

  Named list with `producer_id`, `producer_version`, `posterior_id`,
  `input_payload_sha256`, `source_sha256`, and `config_sha256`;
  `model_sha256` is optional. Supply actual source descriptions and
  lowercase SHA-256 digests. These records do not authenticate the
  scientific source.

## Value

A `postrank_coefficients` object with mixture `means`, directional
probabilities `e`, the supplied states and provenance, and
supported-operation indicators. No target draws or target sample sizes
are generated.

## Details

Each conditional probability is the error for reporting entity i above
entity j: \\P(\theta\_{i,k}\leq\theta\_{j,k}\mid h)\\. Positive
variances and conditional independence make pairwise equality have
probability zero. The output has `NA` diagonals because self-comparisons
are unused.

The constructor averages conditional probabilities and means using
compensated summation. It does not replace the mixture with a
moment-matched Gaussian. A finite mixture of continuous Gaussian target
laws is also different from a finite law of target atoms; these
coefficients use floating-point arithmetic, not exact rational
finite-law masses.

`mu`, `Sigma`, and the conditional moments are supplied declarations.
Their structural checks do not establish that one dataset or a converged
sampler produced them. Empirical Bayes quantities held fixed remain
conditioned on; only uncertainty represented by the supplied states is
averaged over.

The native
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
route supports weighted expected loss with an upper grade-count limit,
not minimax, `q` protections, or exact-G there.
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
can describe conditional expected-risk variation across states; MCMC
metrics additionally require original history. Neither those metrics nor
this calculation certify numerical or model error.

## See also

[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
[`validate_postrank_coefficients()`](https://joonho112.github.io/postrank/reference/validate_postrank_coefficients.md),
[`postrank_coefficient_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_capabilities.md)

## Examples

``` r
# A specified one-criterion law, not the output of a fitted model or sampler.
state <- function(d) {
  ks <- "score"; ids <- c("A", "B")
  list(mu = c(score = d),
    Sigma = matrix(1, 1, 1,
      dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = matrix(c(d, .4), 2, 1,
      dimnames = list(entity = ids, criterion = ks)),
    covariance = array(.5, c(1, 1, 2),
      dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids)))
}
components <- list(low = state(-1), high = state(.5))
config <- list(weights = c(low = .5, high = .5),
  state_index = data.frame(state_id = c("low", "high")),
  source_regime = "fixed_finite_mixture",
  conditional_independence = "entities_given_shared_h")
provenance <- list(producer_id = "postrank_mixture_coefficients help example",
  producer_version = "1", posterior_id = "specified-two-state-normal-law",
  input_payload_sha256 = digest::digest(components, algo = "sha256"),
  source_sha256 = digest::digest(body(state), algo = "sha256"),
  config_sha256 = digest::digest(config, algo = "sha256"))
x <- postrank_mixture_coefficients(components, config$weights,
  config$state_index, config$source_regime, config$conditional_independence,
  provenance)
x$e[, , "score"]
#>         entity_j
#> entity_i         A         B
#>        A        NA 0.6897078
#>        B 0.3102922        NA
validate_postrank_coefficients(x, recompute = TRUE)
```
