% Please edit documentation in R/options.R
\name{postrank_options}
\alias{postrank_options}
\title{Session Options for Solving and Reporting}
\description{
\code{postrank} reads three session options at call time. Loading the package
does not set any option. Save the return value of \code{\link[=options]{options()}} to restore
the previous state after a temporary change.
}
\details{
\describe{
\item{\code{postrank.backend}}{Solver used when an optimization function is
called with \code{backend = NULL}. Unset (\code{NULL}) by default. A non-\code{NULL}
\code{backend} argument overrides this option; if both are \code{NULL}, \code{"gurobi"}
is used. Must be \code{"gurobi"} or \code{"highs"}; any other value stops with
error code \code{invalid_backend}. If the chosen solver is not installed or
cannot be loaded, the call stops with an error explaining how to install
HiGHS or configure Gurobi; \code{postrank} never switches solvers on its own.}
\item{\code{postrank.lang}}{Language for \code{summary()} methods and
\code{\link[=postrank_report]{postrank_report()}}. Default \code{"en"}. English (\code{"en"}) is the only
supported value; any other value stops with \code{unsupported_language}.
Passing \code{lang = "en"} to \code{\link[=postrank_report]{postrank_report()}} overrides this option,
whereas \code{summary()} methods always read it. \code{print()} and \code{format()} do
not read \code{postrank.lang}.}
\item{\code{postrank.verbose}}{Whether \code{\link[=postrank_solve]{postrank_solve()}} and the main solve in
\code{\link[=postrank]{postrank()}} print start and completion messages. Default \code{FALSE}. Must
be \code{TRUE} or \code{FALSE}. Setting \code{verbose = TRUE} or \code{verbose = FALSE} in
\code{\link[=postrank_control]{postrank_control()}} overrides this option, while \code{verbose = NULL} reads
it at solve time. Nested diagnostic and grid solves never print progress
messages. This option does not affect numerical results or the solver's
own log controlled by \code{output} in \code{\link[=postrank_control]{postrank_control()}}.}
}

The environment variable \code{POSTRANK_TEST_GUROBI} is read only by the
package's own test suite (\code{"true"} enables tests that call a licensed Gurobi
installation). Package functions do not read it.
}
\examples{
getOption("postrank.backend")              # unset: solver defaults to "gurobi"
old <- options(postrank.backend = "highs") # choose HiGHS for this session
getOption("postrank.backend")
options(old)
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_control]{postrank_control()}}, \code{\link[=postrank_solve]{postrank_solve()}},
\code{\link[=postrank_report]{postrank_report()}}
}
