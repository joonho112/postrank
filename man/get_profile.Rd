% Please edit documentation in R/accessors.R
\name{get_profile}
\alias{get_profile}
\title{Extract Expected Errors and Loss for Each Criterion}
\usage{
get_profile(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis}.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
A data frame in input criterion order with columns:
\code{criterion}, \code{weight}, \code{E}, \code{E_over_M}, \code{E_over_N}, \code{risk}, \code{q},
\code{budget_slack} and \code{is_minimax_max}. Returns zero rows with these same
columns when no validated grade is available.
}
\description{
The stored grade report is summarized by criterion. A one-criterion analysis
has one row; for several criteria, the rows give the expected errors and
withholding loss associated with the common grading. The calculation uses
the stored evaluation without recalculating grades or posterior summaries.
}
\details{
\code{E} is the posterior expected number of wrong disclosed directions.
\code{E_over_M} divides by all unordered pairs; \code{E_over_N} divides by disclosed
pairs and is \code{NA} when N=0. Criterion \code{risk} adds the withholding cost:
\code{(E + tau * (M - N)) / M}. These describe the supplied posterior and loss,
not realized error rates or simultaneous guarantees.

\code{q} is the criterion's error budget and \code{budget_slack = q * N - E};
both are \code{NA} without a budget. A nonnegative slack satisfies that count
constraint before numerical tolerance is considered. \code{is_minimax_max}
identifies included criteria attaining the minimax maximum within the
comparison tolerance; it is false for weighted problems.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  two <- postrank(pr_tutorial$two, weights = c(score_A = .5, score_B = .5),
    tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_profile(two)
}
}
\seealso{
\code{\link[=get_risk]{get_risk()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}
}
\concept{reporting}
