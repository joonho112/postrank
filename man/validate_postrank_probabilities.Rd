% Please edit documentation in R/probabilities.R
\name{validate_postrank_probabilities}
\alias{validate_postrank_probabilities}
\title{Check an Imported Probability Input}
\usage{
validate_postrank_probabilities(x)
}
\arguments{
\item{x}{An object from \code{\link[=postrank_probabilities]{postrank_probabilities()}}.}
}
\value{
Invisible \code{TRUE} on success. An invalid or altered object raises an
error; values and source records are not repaired or replaced.
}
\description{
Directional errors, corrections and summaries are reconstructed from the
stored source values and compared with the recorded probability input. These
checks detect invalid content or changes introduced after construction,
including changes in a loaded object.
}
\details{
The checks repeat the constructor's requirements, including named
axes, unused \code{NA} diagonals, probability range, reverse complements, and
consistency of the requested correction. They do not establish joint-law
coherence, the truth of the source description, or the accuracy of the
supplied probabilities. A correction record is not an error certificate.
To change probabilities, targets, or source descriptions, construct a new
input with \code{\link[=postrank_probabilities]{postrank_probabilities()}}.
}
\examples{
x <- postrank_probabilities(pr_tutorial$one$e,
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal-CDF comparisons for pr_tutorial score A",
    conditioning = "The specified independent-site Gaussian law is fixed"),
  targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
validate_postrank_probabilities(x)
}
\seealso{
\code{\link[=postrank_probabilities]{postrank_probabilities()}}
}
\concept{input}
