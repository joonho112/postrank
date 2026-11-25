% Please edit documentation in R/data.R
\docType{data}
\name{pr_example_gaussian}
\alias{pr_example_gaussian}
\title{The Three-Criterion Example's Gaussian Law}
\format{
A \code{postrank_coefficients} object (\code{source$kind = "gaussian_conditional"}):
\code{means} 30 x 3, \code{e} 30 x 30 x 3, \code{source$covariance} 3 x 3 x 30
(criterion_i x criterion_j x entity), plus \code{provenance}, \code{capabilities} and
identity hashes.
}
\source{
Built by \code{data-raw/make-pr-example-gaussian.R} from the same
synthetic normal posterior as \link{pr_example_draws}.
}
\usage{
pr_example_gaussian
}
\description{
\code{pr_example_gaussian} is the synthetic analytic normal posterior underlying
\link{pr_example_draws}, stored as a \code{postrank_coefficients} object built by
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} with \code{conditional_independence = "entities_given_shared_h"}.
Its pairwise directional-error probabilities and marginal intervals follow
analytically from the normal posterior (\code{provenance} records SHA-256 hashes
of the parameter file, generator script and configuration). The 4,000 IID
draws in \link{pr_example_draws} approximate this distribution and need not give
identical probabilities or grades.
}
\examples{
dim(pr_example_gaussian$e)
postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
}
\seealso{
\link{pr_example_draws}, \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=postrank_example]{postrank_example()}}
}
\concept{data}
\keyword{datasets}
