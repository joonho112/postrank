% Please edit documentation in R/accessors.R
\name{get_grades}
\alias{get_grades}
\title{Extract the Grade Assigned to Each Entity}
\usage{
get_grades(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit}, \code{postrank_analysis} or \code{postrank_baseline}.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
An integer vector named by entity ID, or \code{NULL} when a fit has no
validated candidate. Fit/analysis grades retain the input's entity order.
}
\description{
The stored grades are returned as a named vector for subsequent analysis or
export. Grade 1 has highest priority. Entities assigned the same grade have
their comparison withheld; a common grade does not imply equality of their
latent targets.
}
\details{
This accessor does not solve or choose a new grade report. A valid
all-withheld report returns grade 1 for every entity; \code{NULL} instead means
that no validated grades are available. Console truncation does not limit
this vector. Use \link{postrank_tables} for a two-column data frame.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  grades <- get_grades(one)
  grades
}
}
\seealso{
\code{\link[=get_relations]{get_relations()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}}
}
\concept{reporting}
