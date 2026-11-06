% Please edit documentation in R/backend-availability.R
\name{postrank_backend_available}
\alias{postrank_backend_available}
\title{Inspect Solver Package Availability}
\usage{
postrank_backend_available(backend = c("gurobi", "highs"))
}
\arguments{
\item{backend}{\code{"gurobi"} (default) or \code{"highs"}.}
}
\value{
A \code{postrank_backend_availability} list with \code{installed},
\code{package_path}, \code{wrapper_version}, \code{available_for_attempt}, \code{runtime_check}
and \code{license_check}. \code{available_for_attempt = TRUE} means no known obstacle
was found by this inspection, not that a solve or license check succeeded.
}
\description{
The installed Gurobi or HiGHS package is inspected through its package and
linkage information. The inspection does not load the solver namespace,
execute an optimization or check a license.
}
\details{
The inspection can identify a known macOS mismatch between Gurobi's
linked R runtime and the running R. Other runtime failures may only become
apparent when solving. It does not change library paths or select another
backend. Choose HiGHS explicitly in \code{\link[=postrank]{postrank()}} or \code{\link[=postrank_solve]{postrank_solve()}};
neither function silently replaces an unavailable backend.
}
\examples{
availability <- postrank_backend_available("highs")
availability$available_for_attempt
availability$runtime_check$executed
}
\seealso{
\code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_control]{postrank_control()}}
}
\concept{decision}
