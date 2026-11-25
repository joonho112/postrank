% Please edit documentation in R/iid-coefficient-bounds.R
\name{postrank_iid_bounds}
\alias{postrank_iid_bounds}
\title{Compute a Conditional Fixed-Sample IID Probability Bound}
\usage{
postrank_iid_bounds(draws, alpha, alpha_by_criterion, design)
}
\arguments{
\item{draws}{Independent equal-weight posterior draws prepared as an
\verb{S x n x K} array via \code{postrank_draws(..., regime = "iid")} or as separate
per-criterion IID entity-draw matrices via \code{\link[=as_postrank_draws]{as_postrank_draws()}}
(\code{equal_weight = TRUE}, with \code{dependence_mode = "joint_model"} or
\code{"criterionwise_expected_only"}). MCMC draws (effective sample size ESS
cannot replace an IID draw count), exact finite laws, Gaussian or mixture
coefficients, pre-computed \code{\link[=postrank_probabilities]{postrank_probabilities()}}, and tie-mode inputs
are rejected.}

\item{alpha}{Overall failure-probability budget, a finite scalar strictly
between \code{0} and \code{1} fixed before generating the draws.}

\item{alpha_by_criterion}{Finite positive numeric vector named by every
criterion in \code{draws}, summing to at most \code{alpha} and fixed before
generating the draws. Values are ordered to \code{draws$criterion_ids} and are
never rescaled automatically.}

\item{design}{Named list with exactly five elements (extra fields stop with
an error): \code{sample_sizes_fixed_before_sampling = TRUE},
\code{alpha_fixed_before_sampling = TRUE}, \code{adaptive_stopping = FALSE},
criterion-named positive integer \code{planned_sample_sizes} equal to the actual
retained draw counts \code{S} on every criterion, and a non-empty character
scalar \code{declaration_note}. These fields record how the simulation was
designed prior to sampling; \code{postrank} checks internal consistency but
cannot verify external sampling history, and setting these flags on an
adaptive or dependent sample does not make the bound valid.}
}
\value{
A \code{postrank_iid_bounds} list containing \code{schema_version},
\code{input_identity}, \code{bound_identity}, \code{entity_ids}, \code{criterion_ids},
\code{dependence_mode}, criterion sample sizes \code{S}, unordered pair count
\code{M = choose(n, 2)}, \code{alpha}, \code{alpha_by_criterion}, unclipped \code{raw_radius},
capped \code{epsilon = pmin(raw_radius, 1)},
\code{radius_interpretation = "theoretical_floating_reference"}, \code{design},
\code{assumptions}, \code{guarantee_reason}, \code{numerical_verification_reason}, and
status flags (\code{guarantee_status = "conditional_bound"},
\code{bound_computed = TRUE}, while \code{guarantee_issued}, \code{numerically_verified},
\code{numerical_certification}, and \code{finite_sample_certificate} are \code{FALSE}).
}
\description{
\code{postrank_iid_bounds()} computes an analytic simultaneous error radius for
pairwise directional-error probabilities estimated from a fixed number of
independent posterior draws. The \code{1 - alpha} probability statement applies to
repeated Monte Carlo draw generation from the same fixed posterior
distribution; it is not a posterior probability that a grading is right and
does not assess model specification or performance on new datasets.
}
\details{
With \eqn{M = n(n - 1) / 2} unordered pairs, the radius on criterion \eqn{k}
is
\deqn{\varepsilon_k = \min\left\{1, \sqrt{\frac{\log(2M / \alpha_k)}{2 S_k}}\right\}.}
Under the stated assumptions, with Monte Carlo probability at least
\eqn{1 - \alpha} simultaneously across all directed entity pairs and all
declared criteria, every empirical directional-error probability lies within
\eqn{\varepsilon_k} of its true value under the supplied posterior.
Independence is required across whole-state draws \eqn{s = 1, \dots, S_k}
within each criterion, not across entity pairs or across criteria.

The factor \eqn{2M} uses the zero-equality complement identity
\eqn{e_{ji,k} = 1 - e_{ij,k}}, so bounding one direction per unordered pair
bounds the reverse direction by the same absolute error. That identity
requires zero posterior probability of exact pairwise equality (not
necessarily continuous marginal densities) and does not apply unchanged when
exact ties have positive probability. All draws must target one fixed proper
posterior; empirical Bayes hyperparameters held fixed during draw generation
are part of that conditioning.

Adaptive stopping and substituting MCMC ESS for \eqn{S_k} are not supported.
Radii are evaluated in ordinary floating-point arithmetic without outward
interval-arithmetic enclosures, so this function does not issue a formal
numerical certificate.
}
\examples{
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
bounds[c("guarantee_status", "guarantee_issued", "numerically_verified")]
}
\seealso{
\code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}, \code{\link[=postrank_regret_bound]{postrank_regret_bound()}},
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}}
}
\concept{reference}
