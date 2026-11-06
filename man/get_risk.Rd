% Please edit documentation in R/accessors.R
\name{get_risk}
\alias{get_risk}
\title{Extract Posterior Loss with Its Solver Bound and Status}
\usage{
get_risk(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis}.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
A named list with numeric \code{risk}, \code{lower_bound} and \code{gap}, and
character \code{status}. Unavailable numeric values are \code{NA}.
}
\description{
The primary risk of the validated grading is returned with the whole-problem
lower bound, absolute risk gap and normalized solver status. These
quantities describe both the available decision and the extent to which
numerical optimality has been established.
}
\details{
\code{risk} is weighted expected loss for a weighted problem, or the
largest selected criterion risk for minimax. With one criterion and
weight 1, it is that criterion's risk. The gap is an optimization quantity
for the supplied probabilities, not posterior uncertainty or a bound on
true-posterior regret by itself.

A time limit may leave validated grades or none. Without validated grades,
risk and gap are \code{NA}, while status and any usable lower bound remain.
Missing or rejected bounds can also make the gap unavailable despite a
retained grade. Consult the fit's \code{objective$bound_source}, warnings and
validation details for the numerical qualifications.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_risk(one)
}
}
\seealso{
\code{\link[=get_profile]{get_profile()}}, \code{\link[=postrank_solve]{postrank_solve()}}
}
\concept{reporting}
