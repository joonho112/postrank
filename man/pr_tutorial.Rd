% Please edit documentation in R/data-tutorial.R
\docType{data}
\name{pr_tutorial}
\alias{pr_tutorial}
\title{One or Two Criteria for Six Fictional Sites}
\format{
A named list with four elements:
\describe{
\item{one}{A \code{postrank_coefficients} input with one criterion,
\code{score_A}, for sites A through F.}
\item{two}{A \code{postrank_coefficients} input for the same six sites
with \code{score_A} and \code{score_B}. The law of \code{score_A}
is identical to that in \code{one}.}
\item{units}{Site IDs and display labels in input order.}
\item{law}{The fixed means, covariance matrices, conditioning statement,
direction, units and maintainer source information.}
}
}
\source{
Maintainer-created synthetic law in
\code{data-raw/pr-tutorial-law.json}; no external observations.
}
\description{
This Gaussian example illustrates the disclosure and withholding of pairwise
comparisons through integer grades. All means and variances are specified
directly, so the posterior laws are illustrative rather than fitted to
observations.
}
\details{
Each site has a bivariate normal law. Both marginal standard
deviations are 0.2. The two criteria are independent within each site,
and sites are independent. Higher values have higher priority on both
criteria. Scores are in illustrative standardized units with no empirical
calibration. Continuous normal laws have zero equality probability.

Analytic comparison probabilities and marginal summaries are calculated from
the same specified law. The example contains no draws, fitted-model
uncertainty or Monte Carlo diagnostics. Addition of the second criterion
changes the decision problem while retaining the first criterion's marginal
law.
}
\examples{
names(pr_tutorial)
pr_tutorial$one
pr_tutorial$two
postrank_posterior_means(pr_tutorial$one)
postrank_posterior_means(pr_tutorial$two)
}
\seealso{
\code{vignette("a1-getting-started", package = "postrank")},
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank]{postrank()}}
}
\concept{data}
\keyword{datasets}
