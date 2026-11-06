% Please edit documentation in R/tie-pairwise.R
\name{postrank_tie_pairwise}
\alias{postrank_tie_pairwise}
\title{Calculate Strict Error and Equality Probabilities}
\usage{
postrank_tie_pairwise(
  draws,
  method = c("blocks", "reference"),
  block_size = 128L
)
}
\arguments{
\item{draws}{A validated \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} input or its canonical
payload, containing complete joint states for one or more criteria and
explicit equality declarations. Values are compared at their supplied
precision, without rounding, jitter, or independently rearranging entities.}

\item{method}{\code{"blocks"} (default) or \code{"reference"} for equal-weight Monte
Carlo aggregation. The block method limits working indicator storage;
the reference method handles one ordered pair at a time. Exact finite
laws instead use their declared masses.}

\item{block_size}{Positive integer maximum ordered-pair block size for the
block algorithm. It does not change which values count as equal.}
}
\value{
A \code{postrank_tie_pairwise} object with entity-by-entity-by-criterion
arrays \code{b} (strict directional error), \code{t} (equality), and \code{d} (distinctness),
plus the source and equality declarations. All diagonals are \code{NA} because
self-comparisons are unused. Sample sizes describe Monte Carlo input only;
exact finite laws retain rational coefficients and their double projection.
}
\description{
Comparison probabilities are calculated for an equality-neutral loss under a
target law that permits exact equality. Under this loss, equality
contributes neither a strict-direction error nor a withholding cost. A
shared reported grade continues to denote a withheld direction without
asserting equality of the underlying targets.
}
\details{
For distinct entities, the error for reporting i above j is
\eqn{b_{ij,k}=P(\theta_{i,k}<\theta_{j,k})}.
Equality is \eqn{t_{ij,k}=P(\theta_{i,k}=\theta_{j,k})}, and
distinctness is \eqn{d_{ij,k}=P(\theta_{i,k}\ne\theta_{j,k})}.
Equality and distinctness are symmetric, while the two strict-direction
errors sum to distinctness: \eqn{b_{ij,k}+b_{ji,k}=d_{ij,k}}.
Reverse strict errors sum to one only when equality probability is zero.
The withholding contribution is \code{tau * d}, not always \code{tau}.

For a complete finite law, aggregation uses every positive-mass state and
optional \code{gmp} arithmetic. For Monte Carlo input, equality frequencies are
empirical; repeated coincidences do not establish structural equality.
Per-criterion structural classes come from supplied declarations for Monte
Carlo input and from the full positive-mass support for finite laws.
The problem builder later intersects those classes across active criteria;
the coefficient calculation has no criterion-loss weights.

This function neither converts positive equality into ordinary weak-error
probabilities nor verifies the scientific equality model. Use
\code{\link[=postrank_pairwise]{postrank_pairwise()}} when every distinct pair has zero equality probability
and the ordinary loss is intended. A finite target law need not have
continuous marginals to satisfy that zero-equality condition.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  # Bundled complete two-state teaching law, not retained Monte Carlo draws.
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  input <- read_postrank_tie_draws(path)
  pw <- postrank_tie_pairwise(input)
  # A and B are structurally equal on criterion S in this specified law.
  c(strict_error = pw$b["A", "B", "S"], equality = pw$t["A", "B", "S"],
    distinctness = pw$d["A", "B", "S"])
  # The reverse strict errors for C and D sum to their distinctness.
  pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
}
}
\seealso{
\code{\link[=validate_postrank_tie_pairwise]{validate_postrank_tie_pairwise()}}, \code{\link[=postrank_tie_problem]{postrank_tie_problem()}},
\code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}}, \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}
}
\concept{tie-aware}
