% Please edit documentation in R/tie-pairwise.R
\name{postrank_tie_pairwise}
\alias{postrank_tie_pairwise}
\title{Compute Strict Error and Equality Probabilities}
\usage{
postrank_tie_pairwise(
  draws,
  method = c("blocks", "reference"),
  block_size = 128L
)
}
\arguments{
\item{draws}{A \code{postrank_tie_draws} object from \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} or
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}, or a plain \code{"tie-aware-input-0.1"} list.}

\item{method}{Aggregation algorithm for \code{"equal_weight_draws"} inputs:
\code{"blocks"} (the default, processing up to \code{block_size} ordered pairs at a
time to limit indicator-matrix memory) or \code{"reference"} (one ordered pair
at a time). Ignored for \code{"exact_finite_posterior"} inputs, which sum exact
state masses (\code{method = "exact_finite_law"}).}

\item{block_size}{Positive integer maximum ordered-pair block size (\code{128L} by
default) for \code{method = "blocks"}; does not change numerical values.}
}
\value{
A \code{postrank_tie_pairwise} list containing \verb{n x n x K} arrays \code{b}
(strict directional-error probability), \code{t} (equality probability), and \code{d}
(distinctness probability) with \code{NA} diagonals, together with \code{entity_ids},
\code{criterion_ids}, \code{sample_sizes} (\code{S} for Monte Carlo draws, \code{NA} for exact
finite laws), \code{sampling_regimes}, \code{equality}, \code{source}, \code{exact} (rational
strings and double-projection differences for exact finite laws; \code{NULL} for
Monte Carlo draws), \code{coefficient_type}, and \code{pairwise_identity}.
}
\description{
\code{postrank_tie_pairwise()} computes pairwise strict directional-error (\code{b}),
equality (\code{t}), and distinctness (\code{d}) probabilities for tie-aware mode (the
workflow for posteriors in which distinct entities can be equal with positive
probability under equality-neutral loss, where true target equality has zero
loss). Placing two entities in the same grade still leaves them unordered
rather than claiming their targets are equal.
}
\details{
For distinct entities \code{i != j} on criterion \code{k}:
\itemize{
\item \verb{b[i, j, k] = Pr(theta_\{i,k\} < theta_\{j,k\})} is the strict
directional-error probability from placing \code{i} in a higher-priority grade
than \code{j}.
\item \verb{t[i, j, k] = Pr(theta_\{i,k\} = theta_\{j,k\})} is the equality
probability.
\item \verb{d[i, j, k] = Pr(theta_\{i,k\} != theta_\{j,k\})} is the distinctness
probability.
}
Off the diagonal, \code{t} and \code{d} are symmetric, opposite strict-direction errors
sum to distinctness (\code{b[i, j, k] + b[j, i, k] = d[i, j, k]}), and
\code{d[i, j, k] + t[i, j, k] = 1} (so \code{b[i, j, k] + b[j, i, k] = 1} only when
\code{t[i, j, k] = 0}). Under equality-neutral loss, leaving \verb{(i, j)} in the same
grade costs \code{tau * d[i, j, k]} rather than \code{tau}.

Exact finite laws aggregate over all positive-mass states using optional
package \code{gmp} and record both exact rational strings and their \code{double}
projections in \code{b}, \code{t}, and \code{d}. Monte Carlo inputs compute empirical draw
frequencies at full supplied precision without rounding or jitter; coincident
Monte Carlo ties are never used to merge structural equality classes.
Criterion equality partitions are intersected across positive-weight criteria
later in \code{\link[=postrank_tie_problem]{postrank_tie_problem()}}. Use \code{\link[=postrank_pairwise]{postrank_pairwise()}} instead when
every distinct pair has zero equality probability.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
input <- read_postrank_tie_draws(path)
pw <- postrank_tie_pairwise(input)
c(
  strict_error = pw$b["A", "B", "S"],
  equality = pw$t["A", "B", "S"],
  distinctness = pw$d["A", "B", "S"]
)
pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=validate_postrank_tie_pairwise]{validate_postrank_tie_pairwise()}}, \code{\link[=postrank_tie_problem]{postrank_tie_problem()}},
\code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}}, \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}
}
\concept{tie-aware}
