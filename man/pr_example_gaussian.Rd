% Please edit documentation in R/data.R
\docType{data}
\name{pr_example_gaussian}
\alias{pr_example_gaussian}
\title{The Three-Criterion Example's Gaussian Law}
\format{
A \code{postrank_coefficients} object (\code{source$kind = "gaussian_conditional"}):
\code{means} 30 x 3, \code{e} 30 x 30 x 3, \code{source$covariance} 3 x 3 x 30
(criterion_i, criterion_j, entity), plus provenance, capabilities and
identities.
}
\source{
\code{data-raw/make-pr-example-gaussian.R}.
}
\usage{
pr_example_gaussian
}
\description{
The frozen law behind \link{pr_example_draws} as a \code{postrank_coefficients}
object built by \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, with the explicit
declaration \code{"entities_given_shared_h"} and the six strict provenance
fields (\code{input_payload_sha256} hashes the frozen law file, \code{source_sha256}
the law generator source and \code{config_sha256} the generation configuration).
Analytic directional errors and marginal summaries describe this same law.
The finite sample in \link{pr_example_draws} approximates it and need not give
exactly the same coefficients or grades. See \link{pr_tutorial} for a smaller
one-criterion example and \code{\link[=postrank_problem]{postrank_problem()}} for native mode restrictions.
}
\examples{
dim(pr_example_gaussian$e)
postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
}
\concept{data}
\keyword{datasets}
