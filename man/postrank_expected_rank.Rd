% Please edit documentation in R/baselines.R
\name{postrank_expected_rank}
\alias{postrank_expected_rank}
\title{Weighted Expected-Rank Scores from Pairwise Errors}
\usage{
postrank_expected_rank(pairwise, weights = NULL)
}
\arguments{
\item{pairwise}{A \code{postrank_pairwise}, \code{postrank_coefficients}, or
\code{postrank_probabilities} object with tie-free directional errors.}

\item{weights}{\code{NULL} for equal weights, or nonnegative criterion weights
summing to one. An unnamed vector follows criterion order; names must
cover every criterion exactly once.}
}
\value{
A named numeric vector, one score per entity (attribute
\code{score_method = "expected_rank"}).
}
\description{
Each entity receives a score equal to its posterior expected rank averaged
over the chosen criteria. Smaller scores indicate higher reporting priority.
The resulting order can be partitioned into grades by \code{\link[=postrank_cuts]{postrank_cuts()}}.
}
\details{
The expected-rank score is
\eqn{r_i = \sum_k b_k \{1 + \sum_{j \ne i} e_{ij,k}\}}
with \eqn{e_{ij,k} = P(\theta_{ik} \le \theta_{jk} \mid Y)}: the posterior
expected rank of entity \code{i} (1 = highest priority), averaged over criteria
with weights \code{b}. Columns are summed in a stable entity-ID order.
Reordering input rows while retaining their IDs therefore preserves each
named score and its exact-score tie block.
}
\examples{
postrank_expected_rank(pr_tutorial$one)
pw <- postrank_pairwise(postrank_toy)
postrank_expected_rank(pw, c(need_A = .6, need_B = .4))
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_compare]{postrank_compare()}}
}
\concept{baselines}
