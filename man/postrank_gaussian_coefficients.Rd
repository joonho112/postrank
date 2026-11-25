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
\item{means}{Finite plain numeric \verb{n x K} matrix (\code{n >= 2}, \code{K >= 1}) with
named \code{dimnames}: \code{list(entity = entity_ids, criterion = criterion_ids)}.
Larger values must already mean higher priority toward grade 1.}

\item{covariance}{Finite symmetric positive-definite plain numeric \verb{K x K x n}
array with named \code{dimnames}:
\code{list(criterion_i = criterion_ids, criterion_j = criterion_ids, entity = entity_ids)}.
Each \verb{K x K} slice gives within-entity covariance across criteria (positive
variance when \code{K = 1}) and must satisfy exact symmetry \code{S == t(S)} with
zero tolerance (symmetrize \code{(V + t(V)) / 2} beforehand if needed);
cross-entity covariance cannot be encoded here, and singular or asymmetric
matrices stop the call without repair.}

\item{conditional_independence}{Must be \code{"entities_given_shared_h"}, an
explicit model declaration (not inferred from marginal moments) stating
that entities are conditionally independent given the fixed conditioning
state.}

\item{provenance}{Plain named list of non-empty character strings:
\code{producer_id}, \code{producer_version}, \code{posterior_id}, \code{input_payload_sha256},
\code{source_sha256} and \code{config_sha256}, plus optional \code{model_sha256}. Every
\verb{*_sha256} entry must be a 64-character lowercase hexadecimal SHA-256
digest.}
}
\value{
A \code{postrank_coefficients} object (\code{input_kind = "gaussian_conditional"})
containing \code{entity_ids}, \code{criterion_ids}, \code{means}, the \verb{n x n x K}
directional-error array \code{e}, \code{source}, \code{provenance}, \code{capabilities},
\code{validation}, \code{coefficient_identity}, \code{input_identity}, \code{pairwise_identity},
and \code{schema_version} (\code{"coefficient-0.1.0"}).
}
\description{
\code{postrank_gaussian_coefficients()} computes pairwise directional-error
probabilities analytically from entity posterior means and within-entity
covariance matrices under a normal (Gaussian) posterior, without simulating
draws. For distinct entities \code{i} and \code{j} on criterion \code{k},
\eqn{e_{ij,k} = P(\theta_{i,k} \le \theta_{j,k})} is the probability that
reporting \code{i} above \code{j} is in the wrong order (diagonal entries are \code{NA}).
}
\details{
Each off-diagonal probability is computed directly in the lower tail of the
normal distribution from \code{(means[j, k] - means[i, k]) / sqrt(v_i + v_j)} to
preserve small tail values; positive variances and conditional independence
across entities imply zero probability of exact equality. These are ordinary
floating-point analytic calculations, not exact rational arithmetic or
interval-verified bounds.

In \code{\link[=postrank]{postrank()}} and \code{\link[=postrank_problem]{postrank_problem()}}, normal posterior coefficients
support the weighted expected-loss objective with \code{G_max} (minimax, \code{q} error
budgets and \code{exact_G} are not available there; see
\code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}). If an empirical-Bayes prior is held
fixed, these probabilities condition on that estimate; to average over
hyperparameter states, use \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}} rather than
moment-matching to a single normal distribution. \code{postrank} does not fit the
model or verify \code{provenance} hashes against external files.
}
\examples{
law <- pr_tutorial$law
x <- postrank_gaussian_coefficients(
  means = law$means[, "score_A", drop = FALSE],
  covariance = law$covariance["score_A", "score_A", , drop = FALSE],
  conditional_independence = "entities_given_shared_h",
  provenance = pr_tutorial$one$provenance)
x$e[, , "score_A"]
}
\seealso{
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}},
\code{\link[=validate_postrank_coefficients]{validate_postrank_coefficients()}}, \code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}},
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}
}
\concept{coefficients}
