% Please edit documentation in R/coefficient-identity.R
\name{postrank_coefficient_capabilities}
\alias{postrank_coefficient_capabilities}
\title{Check Which Operations a Conditional-Law Input Supports}
\usage{
postrank_coefficient_capabilities(x)
}
\arguments{
\item{x}{A \code{postrank_coefficients} object from
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}
}
\value{
A named list of 12 logical flags:
\itemize{
\item \code{weighted_expected_risk}, \code{posterior_means} and
\code{weighted_at_most_G_problem}: \code{TRUE};
\item \code{minimax_problem}, \code{protection_problem} (\code{q}) and \code{exact_G_problem} (in
\code{\link[=postrank_problem]{postrank_problem()}}): \code{FALSE};
\item \code{target_state_trace}, \code{target_quantiles} (empirical draw quantiles),
\code{exact_rational} and \code{formal_numerical_certification}: \code{FALSE};
\item \code{rb_conditional_risk_trace}: \code{TRUE} for mixtures, \code{FALSE} for a single
normal posterior;
\item \code{hyperparameter_mcse_eligible}: \code{TRUE} only for mixtures with
\code{source_regime == "hyperparameter_mcmc"}.
}
}
\description{
\code{postrank_coefficient_capabilities()} validates a normal or shared-state
mixture posterior input and returns logical flags telling which \code{postrank}
functions and settings accept it.
}
\details{
\code{exact_G_problem = FALSE} applies to unrestricted optimization in
\code{\link[=postrank]{postrank()}} and \code{\link[=postrank_problem]{postrank_problem()}}; fixed-order cuts in \code{\link[=postrank_cuts]{postrank_cuts()}}
do allow \code{exact_G} on \code{postrank_coefficients}. \code{hyperparameter_mcse_eligible = TRUE}
indicates that \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} can compute MCMC metrics if
valid \code{chain_history} records are supplied, not that sampling converged.
}
\examples{
caps <- postrank_coefficient_capabilities(pr_tutorial$one)
caps[c("weighted_expected_risk", "weighted_at_most_G_problem",
  "minimax_problem", "rb_conditional_risk_trace")]
}
\seealso{
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}, \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}},
\code{\link[=validate_postrank_coefficients]{validate_postrank_coefficients()}}
}
\concept{coefficients}
