% Please edit documentation in R/tie-pairwise.R
\name{validate_postrank_tie_pairwise}
\alias{validate_postrank_tie_pairwise}
\title{Check Equality-Neutral Comparison Coefficients}
\usage{
validate_postrank_tie_pairwise(x)
}
\arguments{
\item{x}{An object from \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}
}
\value{
Invisible \code{TRUE} on success. Invalid probabilities, axes, source
records, or changed content raise an error. The function does not repair
or replace an object.
}
\description{
The strict-error, equality and distinctness arrays from
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}} are checked against their retained input and
equality records. Invalid or altered content is detected without modifying
the object.
}
\details{
Checks include matching entity and criterion axes, unused \code{NA}
diagonals, probability ranges, symmetric equality and distinctness, and
the identities \code{b[i,j,k] + b[j,i,k] = d[i,j,k]} and
\code{d[i,j,k] + t[i,j,k] = 1} off the diagonal, to tolerance \code{1e-12}.
It also checks consistency with the stored input, sample-size meaning,
equality declarations, and content identity.

Validation does not independently recalculate every probability from the
source states, verify a scientific structural-equality claim, or provide
a numerical accuracy certificate. To change the source, construct a new
tie-aware input and run \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}} again.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  validate_postrank_tie_pairwise(pw)
}
}
\seealso{
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}, \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}
}
\concept{tie-aware}
