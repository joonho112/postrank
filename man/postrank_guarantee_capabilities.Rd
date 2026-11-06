% Please edit documentation in R/guarantee-status.R
\name{postrank_guarantee_capabilities}
\alias{postrank_guarantee_capabilities}
\title{Check Which Uncertainty Bounds Are Implemented}
\usage{
postrank_guarantee_capabilities()
}
\value{
A named list of capability indicators and an interpretation string.
Implemented reference calculations include fixed-sample IID coefficient
bounds, weighted regret over a fixed action family, and protection
envelopes. Formal numerical certification, general MCMC finite-sample
certification, optional-stopping certification, and minimax regret bounds
are not implemented. ESS cannot be substituted for an IID sample size.
}
\description{
This record describes the implemented conditional uncertainty calculations.
Evaluation of a reference formula in floating-point arithmetic does not, by
itself, provide a numerically certified guarantee.
}
\details{
The supported reference formulas require their stated sampling,
action-family, and numerical assumptions. Support does not establish that
those assumptions hold for an input. In particular, a solver's numerical
gap concerns optimization of the supplied coefficients; it does not certify
posterior probability accuracy, model adequacy, or repeated-data calibration.
See \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}, \code{\link[=postrank_regret_bound]{postrank_regret_bound()}}, and
\code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}} for their distinct scopes.
}
\examples{
support <- postrank_guarantee_capabilities()
support[c("fixed_S_IID_reference_calculation", "formal_numerical_certifier",
  "general_MCMC_finite_sample_certificate", "ESS_as_IID_sample_size")]
}
\concept{reference}
