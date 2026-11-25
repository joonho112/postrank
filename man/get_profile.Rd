% Please edit documentation in R/accessors.R
\name{get_profile}
\alias{get_profile}
\title{Extract Expected Errors and Loss for Each Criterion}
\usage{
get_profile(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} object.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
A data frame in input criterion order with columns \code{criterion},
\code{weight}, \code{E}, \code{E_over_M}, \code{E_over_N}, \code{risk}, \code{q}, \code{budget_slack} and
\code{is_minimax_max}. When no checked grading is available, a zero-row data
frame with these same columns and types is returned.
}
\description{
\code{get_profile()} returns a one-row-per-criterion table of posterior expected
wrong-order errors, losses and error-budget margins for the checked grading
stored in \code{x}, without running a solver or recomputing probabilities.
}
\details{
For each criterion, \code{E} is the posterior expected number of wrong-order
ordered (\code{disclosed}) pairs, \code{E_over_M} divides \code{E} by all \code{M} unordered
pairs, \code{E_over_N} divides \code{E} by the \code{N} ordered pairs (\code{NA} when \code{N = 0}),
and \code{risk} is the posterior expected loss \code{(E + tau * (M - N)) / M}.

\code{q} is the criterion's expected-error budget from \code{\link[=postrank_settings]{postrank_settings()}} and
\code{budget_slack} is \code{q * N - E} (both \code{NA} when no \code{q} budget was set for that
criterion). \code{is_minimax_max} is \code{TRUE} for included criteria within \code{1e-12}
of the maximum criterion loss when \code{objective == "minimax"}, and \code{FALSE} for
weighted problems.
}
\examples{
two <- postrank_example("tutorial_two")
get_profile(two)
}
\seealso{
\code{\link[=get_risk]{get_risk()}}, \code{\link[=get_grades]{get_grades()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}
}
\concept{reporting}
