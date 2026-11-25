% Please edit documentation in R/probabilities.R
\name{validate_postrank_probabilities}
\alias{validate_postrank_probabilities}
\title{Check an Imported Probability Input}
\usage{
validate_postrank_probabilities(x)
}
\arguments{
\item{x}{A \code{postrank_probabilities} object created by
\code{\link[=postrank_probabilities]{postrank_probabilities()}}.}
}
\value{
\code{TRUE}, invisibly, when \code{x} is valid and unaltered; otherwise stops
with an error (\code{invalid_probabilities} or \code{stale_probability_identity}).
}
\description{
\code{validate_postrank_probabilities()} rebuilds a \code{postrank_probabilities}
object from its stored raw probabilities, source settings, correction rule
and marginal summaries, checking that nothing was altered after construction.
}
\details{
All checks from \code{\link[=postrank_probabilities]{postrank_probabilities()}} are re-run, including matching
entity and criterion names, \code{NA} diagonals, values in \verb{[0, 1]}, complement
tolerances and \code{summaries} consistency. Passing these checks confirms that
the stored object is intact; it does not verify joint-posterior coherence or
the accuracy of the external calculation. To change probabilities or
descriptions, call \code{\link[=postrank_probabilities]{postrank_probabilities()}} again.
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
