% Please edit documentation in R/tie-pairwise.R
\name{validate_postrank_tie_pairwise}
\alias{validate_postrank_tie_pairwise}
\title{Validate Tie-Aware Pairwise Probabilities}
\usage{
validate_postrank_tie_pairwise(x)
}
\arguments{
\item{x}{A \code{postrank_tie_pairwise} object from \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}
}
\value{
\code{TRUE} invisibly when \code{x} passes all checks; invalid or modified
objects stop with a structured error.
}
\description{
\code{validate_postrank_tie_pairwise()} checks the strict directional-error (\code{b}),
equality (\code{t}), and distinctness (\code{d}) probability arrays of a
\code{postrank_tie_pairwise} object against its stored \code{postrank_tie_draws} source
and content hash.
}
\details{
Verifies \code{x$source} via \code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}, matching entity and
criterion axes, \code{NA} diagonals (rejecting \code{NaN}), \verb{[0, 1]} off-diagonal
bounds, symmetry of \code{t} and \code{d}, and the identities
\code{b[i, j, k] + b[j, i, k] = d[i, j, k]} and \code{d[i, j, k] + t[i, j, k] = 1}
off the diagonal within tolerance \code{1e-12}, along with \code{sample_sizes},
\code{sampling_regimes}, \code{method}, \code{exact}, and \code{pairwise_identity}. Validation
does not recompute probabilities from raw states, verify scientific equality,
or issue a numerical certificate.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
validate_postrank_tie_pairwise(pw)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}, \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}
}
\concept{tie-aware}
