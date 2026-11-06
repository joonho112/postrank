% Please edit documentation in R/coefficient-gaussian.R
\name{postrank_gaussian_coefficients}
\alias{postrank_gaussian_coefficients}
\title{Compute Comparisons from a Conditional Gaussian Law}
\usage{
postrank_gaussian_coefficients(
  means,
  covariance,
  conditional_independence,
  provenance
)
}
\arguments{
\item{means}{Finite numeric matrix with dimension names
\code{list(entity = entity_ids, criterion = criterion_ids)}. Supply at least
two unique entity IDs and one criterion. Targets must already be oriented
so that larger values mean higher reporting priority, in the declared units.}

\item{covariance}{Finite, symmetric, positive definite conditional covariance
array with dimensions criterion-by-criterion-by-entity and dimension names
\code{list(criterion_i = criterion_ids, criterion_j = criterion_ids, entity = entity_ids)}. Each matrix describes dependence among criteria
within one entity; it cannot encode covariance between entities. For one
criterion, each matrix is its positive conditional variance. No jitter or
covariance repair is applied.}

\item{conditional_independence}{Explicitly \code{"entities_given_shared_h"}.
This is a model assumption, not something inferred from marginal moments.}

\item{provenance}{Named list with \code{producer_id}, \code{producer_version},
\code{posterior_id}, \code{input_payload_sha256}, \code{source_sha256}, and
\code{config_sha256}; \code{model_sha256} is optional. Hashes must be lowercase
SHA-256 strings describing the actual source and calculation. They record
provenance but do not authenticate the fit or its scientific assumptions.}
}
\value{
A \code{postrank_coefficients} object containing posterior \code{means}, an
entity-by-entity-by-criterion directional-error array \code{e}, the supplied
conditional law and provenance, and supported-operation indicators.
No target draws or Monte Carlo sample sizes are created.
}
\description{
Directional-error probabilities are calculated from conditional means and
covariance matrices without simulation of the target values. The input may
contain one or several criteria, with dependence among criteria within an
entity. Entities are assumed independent conditional on the supplied shared
state.
}
\details{
For distinct entities, \eqn{e_{ij,k}=P(\theta_{i,k}\leq\theta_{j,k})}
is the error probability for reporting entity i above entity j. Positive
conditional variances and between-entity independence make equality have
probability zero. Diagonals are \code{NA}: self-comparisons are not used.

The normal difference uses the sum of the two conditional marginal
variances. Both directions use the normal CDF directly to retain small
tails. These are floating-point analytic calculations, not exact rational
arithmetic or certified numerical error bounds.

The native joint search through \code{\link[=postrank_problem]{postrank_problem()}} supports weighted
expected loss with an upper grade-count limit for this input. It does not
support minimax, criterion protections \code{q}, or an exact grade count there.
\code{\link[=postrank_evaluate]{postrank_evaluate()}} can score a fixed report; scoring does not check its
membership in a constrained action family. Other operations have their
own documented support; see \code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}.

The package does not fit the model or verify that the supplied law follows
from observed data. If an empirical Bayes prior estimate is held fixed,
these probabilities condition on that estimate. Use
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}} to average conditional probabilities over
explicitly supplied shared states; matching only their moments changes
the law in general.
}
\examples{
# Reconstruct the documented one-criterion tutorial law with its own provenance.
law <- pr_tutorial$law
x <- postrank_gaussian_coefficients(
  means = law$means[, "score_A", drop = FALSE],
  covariance = law$covariance["score_A", "score_A", , drop = FALSE],
  conditional_independence = "entities_given_shared_h",
  provenance = pr_tutorial$one$provenance)
x$e[, , "score_A"]
}
\seealso{
\code{\link[=validate_postrank_coefficients]{validate_postrank_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}},
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}
}
\concept{coefficients}
