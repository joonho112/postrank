% Please edit documentation in R/pairwise-dispatch.R
\name{postrank_pairwise}
\alias{postrank_pairwise}
\title{Calculate Directional-Error Probabilities}
\usage{
postrank_pairwise(draws, method = c("blocks", "reference"), block_size = 128L)
}
\arguments{
\item{draws}{A \code{postrank_draws} object (or complete \code{"applied-0.1"} input
list), or an already computed \code{postrank_coefficients} or
\code{\link[=postrank_probabilities]{postrank_probabilities()}} object. When passing \code{postrank_coefficients} or
\code{postrank_probabilities}, omit \code{method} and \code{block_size}.}

\item{method}{Aggregation algorithm for Monte Carlo draws: \code{"blocks"} (the
default, summing bounded blocks of ordered pairs) or \code{"reference"} (one
pair at a time). Both compute identical equal-weight empirical
frequencies; exact finite posteriors ignore \code{method} and sum their exact
state probabilities.}

\item{block_size}{Positive integer maximum block size for \code{method = "blocks"}
(default \code{128L}). Controls working memory without changing \code{e}.}
}
\value{
For draw or exact finite-posterior inputs, a \code{postrank_pairwise}
object containing the \verb{n x n x K} array \code{e}, per-criterion \code{sample_sizes}
(\code{NA} for exact finite posteriors), \code{exact} rational coefficients when
applicable, and source identities. For \code{postrank_coefficients} or
\code{postrank_probabilities}, the validated input object unchanged.
}
\description{
\code{postrank_pairwise()} computes pairwise directional-error probabilities
\eqn{e_{ij,k} = P(\theta_{i,k} \le \theta_{j,k})} (the probability that
grading entity \code{i} above entity \code{j} is in the wrong order, with larger
target values meaning higher priority) from posterior draws or an exact
finite posterior. Diagonal entries are \code{NA}. Normal/mixture posterior
coefficients and precomputed comparison probabilities are validated and
returned unchanged.
}
\details{
\code{postrank_pairwise()} assumes zero probability of exact equality between
distinct entities within each criterion, so off-diagonal complements satisfy
\code{e[i, j, k] + e[j, i, k] = 1} (for posteriors with positive tie probability,
use \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}). In IID or MCMC draws, an empirical frequency
of \code{0} or \code{1} is a finite-sample summary rather than proof of posterior
certainty, whereas an exact finite posterior computes exact rational
probabilities using the optional \code{gmp} package.

Criterion-wise draw inputs (\code{criterion_blocks}) retain each criterion's own
draw count \code{S_k}; their probabilities support additive criterion losses
without defining a cross-criterion joint posterior.
}
\examples{
# Normal posterior coefficients are validated and returned unchanged:
one <- postrank_pairwise(pr_tutorial$one)
identical(one, pr_tutorial$one)

# Empirical wrong-order frequencies from IID posterior draws:
pw <- postrank_pairwise(postrank_toy)
pw$sample_sizes
pw$e[, , "need_A"]
}
\seealso{
\code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}},
\code{\link[=postrank_probabilities]{postrank_probabilities()}}, \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}
}
\concept{coefficients}
