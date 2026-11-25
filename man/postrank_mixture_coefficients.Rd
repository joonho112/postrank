% Please edit documentation in R/coefficient-mixture.R
\name{postrank_mixture_coefficients}
\alias{postrank_mixture_coefficients}
\title{Average Comparisons Across Shared Gaussian States}
\usage{
postrank_mixture_coefficients(
  components,
  weights,
  state_index,
  source_regime,
  conditional_independence,
  provenance
)
}
\arguments{
\item{components}{Non-empty plain named list of state records
(\code{names(components)} are unique state IDs). Every state must share the
exact same \code{entity_ids} (\code{n >= 2}) and \code{criterion_ids} (\code{K >= 1}) in
identical order, and no element may carry extra R attributes:
\itemize{
\item \code{mu}: finite numeric vector named by \code{criterion_ids} recording the shared
state \code{h}'s criterion-level hyperparameter mean (checked and stored for
provenance/identity);
\item \code{Sigma}: finite symmetric positive-definite \verb{K x K} matrix (\code{Sigma == t(Sigma)} with zero tolerance) with
\code{dimnames = list(criterion_i = criterion_ids, criterion_j = criterion_ids)}, recording the shared state \code{h}'s criterion-level
hyperparameter covariance;
\item \code{means}: finite \verb{n x K} precomputed entity conditional posterior mean
matrix given \code{h}, with
\code{dimnames = list(entity = entity_ids, criterion = criterion_ids)} (larger
values mean higher priority; used directly to compute mixture \code{means} and
\code{e});
\item \code{covariance}: finite symmetric positive-definite \verb{K x K x n} array of
within-entity conditional posterior covariances given \code{h} (every slice
must satisfy \code{S == t(S)} with zero tolerance; symmetrize \code{(V + t(V)) / 2}
beforehand if needed), with \code{dimnames} named \code{criterion_i},
\code{criterion_j}, and \code{entity} (\code{criterion_ids}, \code{criterion_ids},
\code{entity_ids}). \code{covariance} links criteria within an entity only;
cross-entity dependence enters through the shared state \code{h}.
}}

\item{weights}{Nonnegative finite plain numeric state probabilities named by
\code{names(components)} in component order, summing to one within \code{1e-12}
(never rescaled automatically, with no extra R attributes). When
\code{source_regime = "hyperparameter_mcmc"}, all weights must equal
\code{1 / length(components)}. These are mixture probabilities over states, not
criterion loss weights.}

\item{state_index}{Base \code{data.frame} (no tibble or extra attributes) in
component order, with \code{state_id} matching \code{names(components)}. When
\code{source_regime = "fixed_finite_mixture"}, \code{state_id} is the only column;
when \code{source_regime = "hyperparameter_mcmc"}, columns must be
\code{c("state_id", "chain_id", "iteration")} with positive integer chain and
original iteration numbers and unique \verb{(chain_id, iteration)} pairs.}

\item{source_regime}{\code{"fixed_finite_mixture"} for a specified finite mixture
or quadrature rule, or \code{"hyperparameter_mcmc"} for retained hyperparameter
MCMC states.}

\item{conditional_independence}{Must be \code{"entities_given_shared_h"}, an
explicit model declaration (not inferred from marginal moments) stating
that entities are conditionally independent given each shared state \code{h}.}

\item{provenance}{Plain named list of non-empty character strings (with no
extra R attributes): \code{producer_id}, \code{producer_version}, \code{posterior_id},
\code{input_payload_sha256}, \code{source_sha256}, and \code{config_sha256}, plus optional
\code{model_sha256}. Every \verb{*_sha256} entry must be a 64-character lowercase
hexadecimal SHA-256 digest.}
}
\value{
A \code{postrank_coefficients} object
(\code{input_kind = "shared_hyperstate_mixture"}) containing \code{entity_ids},
\code{criterion_ids}, mixture \code{means}, the \verb{n x n x K} directional-error array
\code{e}, \code{source}, \code{provenance}, \code{capabilities}, \code{validation},
\code{coefficient_identity}, \code{input_identity}, \code{pairwise_identity}, and
\code{schema_version} (\code{"coefficient-0.1.0"}). No entity-level target draws are
generated.
}
\description{
\code{postrank_mixture_coefficients()} computes posterior means and pairwise
directional-error probabilities by averaging conditional normal (Gaussian)
posteriors across shared parameter states \code{h} (such as hyperparameter MCMC
draws or discrete mixture components). Because every entity shares each state
\code{h}, averaging across states preserves cross-entity dependence induced by \code{h}
even when entities are independent conditional on \code{h}. For distinct entities
\code{i} and \code{j}, \eqn{e_{ij,k} = \sum_s w_s P(\theta_{i,k} \le \theta_{j,k} \mid h_s)}
is the expected error if \code{i} is graded above \code{j} (diagonals are \code{NA}).
\code{postrank} does not fit or sample the model.
}
\details{
Conditional probabilities and means are combined across states with
compensated summation (to reduce floating-point rounding error) rather than
replacing the mixture by a single moment-matched normal distribution. Unlike
a discrete finite law of target atoms (\code{exact_finite_posterior}), each
mixture state here is a continuous normal distribution with positive
variances, so distinct entities have zero probability of exact equality;
calculations use ordinary floating-point arithmetic rather than exact
rational arithmetic.

In \code{\link[=postrank]{postrank()}} and \code{\link[=postrank_problem]{postrank_problem()}}, mixture coefficients support the
weighted expected-loss objective with \code{G_max} (minimax, \code{q} error budgets,
and \code{exact_G} are unavailable there, while \code{\link[=postrank_cuts]{postrank_cuts()}} also supports
\code{exact_G} along a score order; see \code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}).
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} evaluates conditional expected loss across
the supplied states and, when \code{source_regime = "hyperparameter_mcmc"} and
\code{chain_history} is supplied (providing each chain's ordered retained
iterations so equal chain lengths and regular thinning spacing can be checked
before computing R-hat, ESS, and MCSE), computes MCMC integration
diagnostics. Any empirical-Bayes quantities held fixed outside \code{components}
remain conditioned on; neither this constructor nor
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} verifies that one coherent dataset produced
the moments, checks external files, or certifies numerical or model error.
}
\examples{
state <- function(d) {
  ks <- "score"; ids <- c("A", "B")
  list(mu = c(score = d),
    Sigma = matrix(1, 1, 1,
      dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = matrix(c(d, 0.4), 2, 1,
      dimnames = list(entity = ids, criterion = ks)),
    covariance = array(0.5, c(1, 1, 2),
      dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids)))
}
comps <- list(low = state(-1), high = state(0.5))
cfg <- list(weights = c(low = 0.5, high = 0.5),
  state_index = data.frame(state_id = c("low", "high")),
  source_regime = "fixed_finite_mixture",
  conditional_independence = "entities_given_shared_h")
prov <- list(producer_id = "postrank_mixture_coefficients help example",
  producer_version = "1", posterior_id = "two-state-normal-mixture",
  input_payload_sha256 = digest::digest(comps, algo = "sha256"),
  source_sha256 = digest::digest(body(state), algo = "sha256"),
  config_sha256 = digest::digest(cfg, algo = "sha256"))
x <- postrank_mixture_coefficients(comps, cfg$weights, cfg$state_index,
  cfg$source_regime, cfg$conditional_independence, prov)
x$e[, , "score"]
validate_postrank_coefficients(x, recompute = TRUE)
}
\seealso{
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=validate_postrank_coefficients]{validate_postrank_coefficients()}}, \code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}},
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}
}
\concept{coefficients}
