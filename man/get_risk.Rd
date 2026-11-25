% Please edit documentation in R/accessors.R
\name{get_risk}
\alias{get_risk}
\title{Extract Posterior Loss with Its Solver Bound and Status}
\usage{
get_risk(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} object.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
A named list with four elements:
\itemize{
\item \code{risk}: posterior expected loss of the checked grading (weighted sum of
criterion losses when \code{objective == "weighted"}, or largest selected
criterion loss when \code{objective == "minimax"}), or \code{NA_real_} when no
checked grading is available;
\item \code{lower_bound}: a loss that no allowed grading for \code{x}'s problem can beat
(up to solver and floating-point tolerances), or \code{NA_real_} when no
usable lower bound is available;
\item \code{gap}: \code{risk - lower_bound}, or \code{NA_real_} when either is \code{NA};
\item \code{status}: normalized solver status string (\code{"optimal"},
\code{"feasible_not_certified"}, \code{"time_limit"}, \code{"infeasible"},
\code{"unbounded"}, \code{"numerical_error"} or \code{"unknown"}).
}
}
\description{
\code{get_risk()} returns the posterior expected loss (\code{risk}) of the checked
grading in \code{x} together with the solver's lower bound across all allowed
gradings, optimization gap and normalized termination status.
}
\details{
\code{lower_bound}, \code{gap} and \code{status} describe optimization over the supplied
pairwise probabilities only; they do not measure posterior uncertainty,
Monte Carlo error, or excess loss ("regret") under the true posterior when
probabilities are estimated from finite draws.

When a solver stops at its time limit without a checked grading, \code{risk} and
\code{gap} are \code{NA_real_} while \code{status} and any usable \code{lower_bound} are kept
(distinct from a valid one-grade report leaving all pairs unordered, which
has \code{risk = tau}). Even with a checked grading, \code{lower_bound} and \code{gap} are
\code{NA_real_} if no bound was computed or if the reported bound was excluded on
numerical checks; inspect \code{objective$bound_source} (on a \code{postrank_fit}, or
\code{x$fit$objective$bound_source} on a \code{postrank_analysis}) and \code{x$warnings}
for details.
}
\examples{
one <- postrank_example("tutorial_one")
get_risk(one)
}
\seealso{
\code{\link[=get_profile]{get_profile()}}, \code{\link[=get_grades]{get_grades()}}, \code{\link[=postrank_solve]{postrank_solve()}}
}
\concept{reporting}
