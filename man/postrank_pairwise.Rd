% Please edit documentation in R/pairwise-dispatch.R
\name{postrank_pairwise}
\alias{postrank_pairwise}
\title{Calculate Directional-Error Probabilities}
\usage{
postrank_pairwise(draws, method = c("blocks", "reference"), block_size = 128L)
}
\arguments{
\item{draws}{An object from \code{\link[=postrank_draws]{postrank_draws()}} or \code{\link[=as_postrank_draws]{as_postrank_draws()}}, a
supported canonical input payload, or already calculated coefficients from
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}, or
\code{\link[=postrank_probabilities]{postrank_probabilities()}}. For already calculated inputs, omit \code{method}
and \code{block_size}.}

\item{method}{For Monte Carlo draws, \code{"blocks"} (default) aggregates bounded
blocks of ordered pairs; \code{"reference"} aggregates one pair at a time.
Both use equal-weight empirical frequencies and preserve the input draws.
Exact finite laws instead use their declared masses.}

\item{block_size}{Positive integer maximum ordered-pair block size for the
block algorithm. It changes working storage, not the probability event.}
}
\value{
For draw or finite-law input, a \code{postrank_pairwise} object containing
the directional-error array \code{e}, criterion-specific \code{sample_sizes}, and
source records. Exact finite laws also retain rational coefficients and
a floating-point projection, with sample sizes marked unavailable.
Already calculated coefficient or probability inputs are validated and
returned unchanged, with their original class and source information.
}
\description{
Posterior draws or a specified finite law are aggregated into comparison
probabilities for one or several criteria. For distinct entities,
\eqn{e_{ij,k}=P(\theta_{i,k}\leq\theta_{j,k})} is the error for reporting
entity i above entity j, with larger target values having higher priority.
Diagonal entries are \code{NA} because self-comparisons are unused.
}
\details{
The ordinary route requires zero equality probability for each pair
of distinct entities. Continuity of every marginal is neither necessary
nor sufficient: a finite law with no pairwise equality is admissible,
whereas identical continuous targets have equality probability one.
Use \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}} for the separate equality-neutral loss when
genuine equality is present. With zero equality, reverse off-diagonal
probabilities sum to one.

For IID or MCMC output, a frequency of zero or one does not establish that
the underlying posterior event is impossible or certain. A declared exact
finite law instead defines the probabilities through its complete states
and masses; it requires the optional \code{gmp} package for exact arithmetic.

Criterion-wise inputs retain each criterion's own draw count and history.
Within a criterion, all entity values must refer to the same state. The
resulting coefficients suffice for additive expected risk, but separate
criterion blocks do not establish a cross-criterion joint trace for
composite-score or simultaneous-event calculations.
}
\examples{
# A one-criterion analytic input is already calculated.
one <- postrank_pairwise(pr_tutorial$one)
one$e[, , "score_A"]
identical(one, pr_tutorial$one)

# Empirical frequencies from the bundled joint posterior-draw example.
pw <- postrank_pairwise(postrank_toy)
pw$sample_sizes
}
\seealso{
\code{\link[=postrank_evaluate]{postrank_evaluate()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}},
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}
}
\concept{coefficients}
