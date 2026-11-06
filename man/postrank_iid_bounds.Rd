% Please edit documentation in R/iid-coefficient-bounds.R
\name{postrank_iid_bounds}
\alias{postrank_iid_bounds}
\title{Calculate a Conditional Fixed-Sample IID Probability Bound}
\usage{
postrank_iid_bounds(draws, alpha, alpha_by_criterion, design)
}
\arguments{
\item{draws}{Ordinary posterior input from \code{\link[=postrank_draws]{postrank_draws()}} or
\code{\link[=as_postrank_draws]{as_postrank_draws()}}, with equal-weight IID whole-entity states within
every criterion. Joint-model and criterion-wise inputs are supported.
MCMC, exact finite laws, Gaussian/mixture coefficients, supplied probabilities,
and equality-neutral inputs are not fixed-sample IID target-draw inputs.}

\item{alpha}{Overall failure-probability budget, strictly between zero and one.
It must have been fixed before generating the draws.}

\item{alpha_by_criterion}{Positive criterion-named allocations covering every
criterion, summing to at most \code{alpha}. They must also have been fixed before
sampling; they are not normalized automatically.}

\item{design}{List with \code{sample_sizes_fixed_before_sampling = TRUE},
\code{alpha_fixed_before_sampling = TRUE}, \code{adaptive_stopping = FALSE},
criterion-named integer \code{planned_sample_sizes}, and a substantive
\code{declaration_note}. Planned sizes must equal the actual retained counts.
These are declarations about the real sampling design, not switches that
make an adaptive or dependent sample eligible.}
}
\value{
A \code{postrank_iid_bounds} object with criterion sample sizes \code{S}, pair
count \code{M}, allocations, unclipped \code{raw_radius}, and capped \code{epsilon}.
\code{guarantee_status} is \code{"conditional_bound"}, but \code{guarantee_issued},
\code{numerically_verified}, and \code{finite_sample_certificate} remain \code{FALSE}.
}
\description{
A simultaneous reference radius is calculated for directional-error
probabilities estimated from a fixed number of IID posterior draws. The
associated probability statement concerns repeated Monte Carlo generation
conditional on the same supplied posterior law. It does not give a posterior
probability that a grade is correct.
}
\details{
With \eqn{M=n(n-1)/2}, the criterion radius is
\eqn{\varepsilon_k=\min\{1,\sqrt{\log(2M/\alpha_k)/(2S_k)}\}}.
Under the assumptions, the simultaneous event bounds the absolute error
of every directed-pair coefficient on every criterion with probability at
least \eqn{1-\alpha}. Independence is required across whole-state draws
within each criterion, not across pairs or criteria.

The factor \verb{2M} uses the ordinary zero-equality condition: reverse
directional errors are complements. It must not be applied unchanged to
positive-equality probabilities. The relevant assumption is zero pairwise
equality, not continuous marginals. All draws must target the same fixed
proper posterior; fitted empirical Bayes quantities held fixed remain part
of that conditioning.

No adaptive stopping or replacement of \code{S} by MCMC ESS is supported.
Passing the structural checks does not verify IID sampling or prior fixation
of the design. The computed radii are floating-point references, not
verified outward enclosures. They do not assess model misspecification or
frequentist performance across new observed datasets.
}
\examples{
# These choices were fixed before generation in the bundled toy producer.
bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025),
  design = list(sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"))
bounds$epsilon
bounds[c("guarantee_status", "guarantee_issued", "numerically_verified")]
}
\seealso{
\code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}, \code{\link[=postrank_regret_bound]{postrank_regret_bound()}},
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}}
}
\concept{reference}
