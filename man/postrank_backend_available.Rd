% Please edit documentation in R/backend-availability.R
\name{postrank_backend_available}
\alias{postrank_backend_available}
\title{Inspect Solver Package Availability}
\usage{
postrank_backend_available(backend = c("gurobi", "highs"))
}
\arguments{
\item{backend}{Solver package to inspect, \code{"gurobi"} (the default) or
\code{"highs"}.}
}
\value{
A \code{postrank_backend_availability} list containing \code{backend},
\code{installed}, \code{package_path}, \code{wrapper_version}, \code{available_for_attempt},
\code{runtime_check}, \code{license_check} and \code{interpretation}.
}
\description{
\code{postrank_backend_available()} checks whether the \code{gurobi} or \code{highs} R
package is installed and passes static runtime-linkage checks, without
loading the solver namespace, running an optimization or querying a license.
}
\details{
\code{available_for_attempt = TRUE} means the package directory was found and, on
macOS for Gurobi, no mismatch between Gurobi's linked R library and the
running R session was detected. Because no namespace is loaded and no
license or test solve is run, \code{available_for_attempt = TRUE} does not
confirm that a solve will succeed or that a Gurobi license is active.

Calling this function does not change library paths or select a solver. To
use HiGHS in \code{\link[=postrank]{postrank()}} or \code{\link[=postrank_solve]{postrank_solve()}}, pass \code{backend = "highs"} or
set \code{options(postrank.backend = "highs")}; \code{postrank} never switches solvers
automatically.
}
\examples{
avail <- postrank_backend_available("highs")
avail$available_for_attempt
avail$runtime_check$executed
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \link{postrank_options}
}
\concept{decision}
