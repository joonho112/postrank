% Please edit documentation in R/options.R
\name{postrank_options}
\alias{postrank_options}
\title{Session Options for Solving and Reporting}
\description{
Session options specify the default backend, progress messages and report
language. They are read at call time and are not set when the package is
loaded. A temporary change can be reversed by \code{options(old)}, as illustrated
below.
}
\details{
\describe{
\item{\code{postrank.backend}}{Unset by default. The backend used when an
optimization function is called with \code{backend = NULL}: the explicit \code{backend}
argument takes precedence, followed by this option, then \code{"gurobi"}. The value must be
\code{"gurobi"} or \code{"highs"}; anything else raises \code{invalid_backend}. If the
resolved backend is not installed or not usable the call stops with both
remedies; postrank never switches to another backend.}
\item{\code{postrank.lang}}{Default \code{"en"}. Official report and summary text is
English only. Language-sensitive views (\code{\link[=postrank_report]{postrank_report()}} and the
\code{summary()} methods) reject any other value with \code{unsupported_language}.
\code{\link[=postrank_report]{postrank_report()}} has a \code{lang} argument, and an explicit \code{lang = "en"}
there overrides the option; the \code{summary()} methods have no such argument
and always read the option. \code{print()} and the formatters do not read it.}
\item{\code{postrank.verbose}}{Default \code{FALSE}. A logical scalar controlling
start and completion messages from \code{\link[=postrank_solve]{postrank_solve()}} and the main solve
in \code{\link[=postrank]{postrank()}}. It is read when solving. An explicit \code{verbose = TRUE}
or \code{verbose = FALSE} in the control overrides it; \code{verbose = NULL}
inherits it. Nested diagnostic and grid solves produce no progress messages.
This option does not change numerical settings, results, or the separate solver
\code{output} control.}
}

The environment variable \code{POSTRANK_TEST_GUROBI} is for the package's own
test suite only: set to \code{"true"}, it enables the tests that run the licensed
Gurobi backend. Ordinary use never reads it.
}
\examples{
getOption("postrank.backend")             # when unset, solving verbs default to "gurobi"
old <- options(postrank.backend = "highs") # select HiGHS for this session
getOption("postrank.backend")
options(old)
}
\seealso{
\code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank]{postrank()}}, \code{\link[=postrank_report]{postrank_report()}}
}
