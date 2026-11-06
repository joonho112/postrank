% Please edit documentation in R/coefficient-identity.R
\name{postrank_coefficient_capabilities}
\alias{postrank_coefficient_capabilities}
\title{Check Which Operations a Conditional-Law Input Supports}
\usage{
postrank_coefficient_capabilities(x)
}
\arguments{
\item{x}{An object from \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}
}
\value{
A named list of logical indicators, after validating \code{x}. These cover
weighted expected risk, means, native problem types, target-draw quantities,
conditional-risk traces, and eligibility for hyperparameter-MCMC metrics.
}
\description{
These indicators describe the calculations supported for Gaussian or
shared-state mixture coefficients. They concern the implemented operations
and provide no assessment of the model assumptions or probability accuracy.
}
\details{
The native \code{\link[=postrank_problem]{postrank_problem()}} route supports weighted loss with an
upper grade-count limit for these inputs. Its \code{minimax_problem},
\code{protection_problem}, and \code{exact_G_problem} indicators are \code{FALSE}.
These are problem-construction limits; a fixed-action evaluator or
fixed-order baseline has its own documented scope.

A mixture can supply a trace of conditional expected risk across shared
states. Eligibility for hyperparameter-MCMC diagnostics does not mean that
sufficient original chain history was supplied or that sampling converged.
Neither Gaussian nor mixture coefficients supply realized target-loss
draws, target quantiles, exact rational coefficients, or a statistical or
numerical certificate.
}
\examples{
capabilities <- postrank_coefficient_capabilities(pr_tutorial$one)
capabilities[c("weighted_expected_risk", "weighted_at_most_G_problem",
  "target_state_trace", "formal_numerical_certification")]
}
\seealso{
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}, \code{\link[=validate_postrank_coefficients]{validate_postrank_coefficients()}}
}
\concept{coefficients}
