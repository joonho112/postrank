% Please edit documentation in R/control.R
\name{postrank_control}
\alias{postrank_control}
\title{Choose Computation Limits and Solver Output}
\usage{
postrank_control(
  time_limit = 60,
  threads = 1L,
  seed = 1304L,
  absolute_risk_gap = 1e-08,
  relative_gap = 0,
  strategy = c("staged", "label_mip"),
  engine = list(),
  verbose = NULL,
  output = FALSE,
  tolerances = list()
)
}
\arguments{
\item{time_limit}{Positive time budget in seconds.}

\item{threads}{Positive integer number of solver threads.}

\item{seed}{Nonnegative integer solver seed; \code{NULL} is not accepted.}

\item{absolute_risk_gap}{Nonnegative absolute stopping gap in normalized
risk units, converted to the solver objective scale where needed.}

\item{relative_gap}{Nonnegative relative stopping gap for the solver
objective. For weighted problems this centered objective differs from risk;
inspect the returned absolute risk gap when comparing computations.}

\item{strategy}{\code{"staged"} (default) or \code{"label_mip"}; see \code{\link[=postrank_solve]{postrank_solve()}}.}

\item{engine}{Named list of staged-search options, such as \code{mip} and
\code{mip_max_n}; see \code{\link[=postrank_solve]{postrank_solve()}} for their meanings and defaults.}

\item{verbose}{\code{NULL} (default) reads \code{getOption("postrank.verbose", FALSE)}
when solving, not when this control object is created. Explicit \code{TRUE} or
\code{FALSE} overrides that option. Controls progress messages from
\code{\link[=postrank_solve]{postrank_solve()}} and the main solve in \code{\link[=postrank]{postrank()}}; nested diagnostic
and grid solves produce no progress messages. It does not change numerical results.}

\item{output}{Logical; request the backend's own solver log, separately
from the package progress messages controlled by \code{verbose}.}

\item{tolerances}{Named list overriding the solution validator's
\code{feasibility}, \code{integrality} and \code{objective} tolerances; see
\code{\link[=validate_postrank_solution]{validate_postrank_solution()}}.}
}
\value{
A \code{postrank_control} named list containing the requested controls,
validated tolerance defaults, \code{schema_version}, \code{provenance} and \code{warnings}.
}
\description{
The computation controls specify the time budget, stopping gaps and search
strategy for \code{\link[=postrank_solve]{postrank_solve()}} and related optimization functions. The loss
and admissible grade reports are specified separately by
\code{\link[=postrank_settings]{postrank_settings()}}. Solving functions also accept the control values as a
named list.
}
\details{
Defaults are a 60-second budget, one thread, seed 1304, absolute risk gap
\code{1e-8}, relative gap zero and staged search. Construction, validation and
refinement can add overhead, so the budget is not a strict total wall-clock
limit. A small solver gap concerns the supplied numerical problem, not
posterior uncertainty or model calibration.

These controls do not choose display detail or alter the decision
weights. \code{engine} accepts \code{mip}, \code{mip_max_n}, \code{lp_time_share},
\code{local_search_passes}, \code{local_search_starts}, \code{max_cut_rounds} and
\code{cuts_per_round}. Unknown control names are rejected.
}
\examples{
ctrl <- postrank_control(time_limit = 10, absolute_risk_gap = 1e-6)
ctrl$time_limit
ctrl$verbose  # NULL inherits the option at solve time
quiet <- postrank_control(verbose = FALSE)
quiet$verbose
}
\seealso{
\code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_solve]{postrank_solve()}}
}
\concept{settings}
