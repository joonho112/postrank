% Please edit documentation in R/guarantee-status.R
\name{postrank_guarantee_capabilities}
\alias{postrank_guarantee_capabilities}
\title{List Which Uncertainty Bounds postrank Computes}
\usage{
postrank_guarantee_capabilities()
}
\value{
A named list of logical capability flags, \code{schema_version}, and an
\code{interpretation} string:
\itemize{
\item \code{TRUE}: \code{fixed_S_IID_reference_calculation} (\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}),
\code{fixed_space_weighted_regret_reference} (\code{\link[=postrank_regret_bound]{postrank_regret_bound()}}), and
\code{protection_envelope_diagnostic} (\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}},
\code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}}).
\item \code{FALSE}: \code{formal_numerical_certifier},
\code{conditional_IID_safe_certificate},
\code{general_MCMC_finite_sample_certificate},
\code{optional_stopping_certificate}, \code{minimax_regret_bound}, and
\code{ESS_as_IID_sample_size}.
}
}
\description{
\code{postrank_guarantee_capabilities()} lists which conditional uncertainty
bounds \code{postrank} computes and which it does not. Each implemented bound
holds only under its stated sampling and problem assumptions, and all are
evaluated in ordinary floating-point arithmetic rather than verified with
interval arithmetic.
}
\details{
Implemented formulas require fixed-sample IID draw designs, fixed grading
families (or inner/outer protection envelopes), and usable solver lower
bounds; calling a bound function does not verify that those external
conditions hold for your posterior. Solver status labels and gaps describe
numerical optimization of the supplied comparison probabilities and do not
certify posterior probability accuracy, model fit, or performance across new
datasets.
}
\examples{
support <- postrank_guarantee_capabilities()
support[c(
  "fixed_S_IID_reference_calculation",
  "formal_numerical_certifier",
  "general_MCMC_finite_sample_certificate",
  "ESS_as_IID_sample_size"
)]
}
\seealso{
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}, \code{\link[=postrank_regret_bound]{postrank_regret_bound()}},
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}}, \code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}}
}
\concept{reference}
