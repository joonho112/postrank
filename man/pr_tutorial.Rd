% Please edit documentation in R/data-tutorial.R
\docType{data}
\name{pr_tutorial}
\alias{pr_tutorial}
\title{One or Two Criteria for Six Fictional Sites}
\format{
A named list with four elements:
\describe{
\item{one}{A \code{postrank_coefficients} object with one criterion (\code{score_A})
for sites \code{A} through \code{F}.}
\item{two}{A \code{postrank_coefficients} object for the same six sites on
\code{score_A} and \code{score_B}, keeping the exact same marginal distribution for
\code{score_A} as \code{one}.}
\item{units}{Data frame of site IDs and display labels in input order.}
\item{law}{List of the specified means, covariance matrices, conditioning
note, priority direction, units and construction metadata.}
}
}
\source{
Synthetic normal distribution specified in
\code{data-raw/pr-tutorial-law.json}; no external data.
}
\description{
\code{pr_tutorial} is a synthetic normal-posterior dataset for six fictional sites
(\code{A} through \code{F}) on one criterion (\code{score_A}) or two criteria (\code{score_A}
and \code{score_B}). All means and standard deviations are specified directly
rather than fitted to real data, providing the introductory examples used in
\code{vignette("a1-getting-started", package = "postrank")}.
}
\details{
Each site follows an independent bivariate normal distribution with marginal
standard deviations \code{0.2} and zero within-site correlation between \code{score_A}
and \code{score_B}. Larger values mean higher priority on both criteria, and
distinct sites have zero probability of exact equality.

Pairwise comparison probabilities and marginal summaries come analytically
from the normal distribution, so \code{pr_tutorial} contains no posterior draws
or Monte Carlo error. Stored grading results for \code{pr_tutorial$one} and
\code{pr_tutorial$two} are available through \code{postrank_example("tutorial_one")}
and \code{postrank_example("tutorial_two")}.
}
\examples{
names(pr_tutorial)
pr_tutorial$one
postrank_posterior_means(pr_tutorial$one)
postrank_posterior_means(pr_tutorial$two)
}
\seealso{
\code{\link[=postrank_example]{postrank_example()}}, \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=postrank]{postrank()}}, \code{vignette("a1-getting-started", package = "postrank")}
}
\concept{data}
\keyword{datasets}
