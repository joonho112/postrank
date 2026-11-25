% Please edit documentation in R/accessors.R
\name{get_grades}
\alias{get_grades}
\title{Extract the Grade Assigned to Each Entity}
\usage{
get_grades(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit}, \code{postrank_analysis} or \code{postrank_baseline}
object.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
An integer vector named by \code{entity_id} in input entity order, or
\code{NULL} when \code{x} has no checked grading (\code{incumbent_validated = FALSE}).
}
\description{
\code{get_grades()} extracts the checked integer grade vector from a fit,
analysis or baseline result. Grade 1 is the highest priority; entities given
the same grade are left unordered without claiming they are equal.
}
\details{
\code{get_grades()} reads stored grades without running a solver. A
valid grading that leaves all pairs unordered returns \code{1L} for every
entity, whereas \code{NULL} means no checked grading is available. Unlike
printed console output, the returned vector is never truncated; use
\link{postrank_tables} (\code{as.data.frame(x)}) for a two-column data frame.
}
\examples{
one <- postrank_example("tutorial_one")
get_grades(one)
}
\seealso{
\code{\link[=get_risk]{get_risk()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_relations]{get_relations()}},
\link{postrank_tables}
}
\concept{reporting}
