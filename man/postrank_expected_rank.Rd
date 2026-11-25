% Please edit documentation in R/baselines.R
\name{postrank_expected_rank}
\alias{postrank_expected_rank}
\title{Weighted Expected-Rank Scores from Pairwise Errors}
\usage{
postrank_expected_rank(pairwise, weights = NULL)
}
\arguments{
\item{pairwise}{Pairwise directional-error probabilities: a
\code{postrank_pairwise}, \code{postrank_coefficients} or \code{\link[=postrank_probabilities]{postrank_probabilities()}}
object.}

\item{weights}{Nonnegative finite criterion weights summing to one within
\code{1e-12}, or \code{NULL} (the default) for equal weights \code{1 / K}. Unnamed weights
follow \code{pairwise$criterion_ids} order; named weights must name every
criterion once.}
}
\value{
A numeric vector named by \code{entity_ids}, carrying attribute
\code{score_method = "expected_rank"}.
}
\description{
\code{postrank_expected_rank()} computes each entity's posterior expected rank
averaged across criteria, where \code{1} is the highest priority (smallest score =
highest priority). Pass the resulting score vector to \code{\link[=postrank_cuts]{postrank_cuts()}} to
partition that score order into integer grades.
}
\details{
Entity \code{i}'s score is
\eqn{r_i = \sum_k b_k \{1 + \sum_{j \ne i} e_{ij,k}\}}
where \eqn{e_{ij,k} = P(\theta_{ik} \le \theta_{jk})} and \code{b} are \code{weights}.
Columns are summed in sorted \code{entity_id} order so permuting entity rows
preserves exact floating-point scores and tie blocks.
}
\examples{
postrank_expected_rank(pr_tutorial$one)

pw <- postrank_pairwise(postrank_toy)
postrank_expected_rank(pw, c(need_A = 0.6, need_B = 0.4))
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_composite]{postrank_composite()}}, \code{\link[=postrank_compare]{postrank_compare()}}
}
\concept{baselines}
