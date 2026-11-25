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
\item{time_limit}{Positive time budget in seconds (default \code{60}).}

\item{threads}{Positive integer number of solver threads (default \code{1L}).}

\item{seed}{Nonnegative integer solver seed (default \code{1304L}); \code{NULL} is not
accepted.}

\item{absolute_risk_gap}{Nonnegative absolute stopping gap in normalized
loss (\code{risk}) units (default \code{1e-8}), converted internally to the solver's
objective scale where needed.}

\item{relative_gap}{Nonnegative relative stopping gap on the solver's
objective scale (default \code{0}). For weighted problems the solver uses a
centered objective that differs from normalized loss, so compare runs
using the returned absolute gap.}

\item{strategy}{Search method, \code{"staged"} (the default) or \code{"label_mip"};
see \code{\link[=postrank_solve]{postrank_solve()}}.}

\item{engine}{Named list of options for \code{"staged"} search: \code{mip} (\code{"auto"},
\code{"always"} or \code{"never"}), \code{mip_max_n}, \code{lp_time_share},
\code{local_search_passes}, \code{local_search_starts}, \code{max_cut_rounds} and
\code{cuts_per_round}. Ignored when \code{strategy = "label_mip"}; see
\code{\link[=postrank_solve]{postrank_solve()}} for defaults and meanings.}

\item{verbose}{Whether to print start and completion messages during
\code{\link[=postrank_solve]{postrank_solve()}} and the main solve in \code{\link[=postrank]{postrank()}}. If \code{NULL} (the
default), \code{getOption("postrank.verbose", FALSE)} is read at solve time.
\code{TRUE} or \code{FALSE} overrides that option. Nested diagnostic and grid solves
never print progress messages, and \code{verbose} does not change numerical
results.}

\item{output}{Logical scalar (default \code{FALSE}); whether to print the
solver's own console log, independent of \code{verbose}.}

\item{tolerances}{Named list overriding the solution checker's tolerances:
\code{feasibility} (default \code{1e-7}), \code{integrality} (default \code{1e-6}) and
\code{objective} (default \code{1e-7}); see \code{\link[=validate_postrank_solution]{validate_postrank_solution()}}.}
}
\value{
A \code{postrank_control} object, a named list containing:
\itemize{
\item \code{time_limit}, \code{threads}, \code{seed}, \code{absolute_risk_gap}, \code{relative_gap},
\code{strategy}, \code{engine}, \code{verbose} and \code{output}: the validated controls;
\item \code{tolerances}: named list with \code{feasibility}, \code{integrality} and
\code{objective};
\item \code{schema_version}: \code{"1"}, the version of this object's layout;
\item \code{provenance}: package and R versions, creation time, and function name;
\item \code{warnings}: character vector.
}
}
\description{
\code{postrank_control()} sets computation limits, stopping gaps, search strategy
and progress messages for \code{\link[=postrank]{postrank()}}, \code{\link[=postrank_solve]{postrank_solve()}} and related
optimization functions. Solving functions also accept these options as a
named list. The loss and allowed grade reports are set separately by
\code{\link[=postrank_settings]{postrank_settings()}}.
}
\details{
Defaults are a 60-second time budget, 1 thread, seed 1304, absolute loss gap
\code{1e-8}, relative gap \code{0}, and \code{"staged"} search. Problem construction,
solution checks and refinement stages can add overhead, so \code{time_limit} is
not a strict wall-clock cap on the whole R call. A small solver gap
describes the optimization for the supplied probabilities, not posterior
uncertainty or model adequacy.

Unknown names in a control list, \code{engine} or \code{tolerances} stop the
call with an error (\code{invalid_control} or \code{invalid_tolerances}). Controls
do not change the decision loss or criterion weights.
}
\examples{
ctrl <- postrank_control(time_limit = 10, absolute_risk_gap = 1e-6)
ctrl$time_limit
ctrl$verbose # NULL reads postrank.verbose when solving

quiet <- postrank_control(verbose = FALSE)
quiet$verbose
}
\seealso{
\code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \link{postrank_options}
}
\concept{settings}
