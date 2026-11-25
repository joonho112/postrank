% Please edit documentation in R/canonical-grade.R
\name{canonical_postrank_grade}
\alias{canonical_postrank_grade}
\title{Renumber Grades While Preserving Comparisons}
\usage{
canonical_postrank_grade(grade, entity_ids)
}
\arguments{
\item{grade}{Positive integer vector named in the exact order of
\code{entity_ids}. Gaps between occupied grade numbers are allowed.}

\item{entity_ids}{Character vector of at least two distinct entity IDs, in
input order.}
}
\value{
An integer vector named in the order of \code{entity_ids}, taking values
\verb{1, ..., G} where \code{G} is the number of distinct labels in \code{grade}.
}
\description{
\code{canonical_postrank_grade()} renumbers occupied grades to \verb{1, 2, ..., G}
without changing which entity pairs are ordered or left unordered. Grade 1
is the highest priority, and entities sharing a grade are left unordered
without claiming they are equal.
}
\details{
This function only relabels existing grade numbers; it does not
reorder entities, compute posterior loss or choose grades.
}
\examples{
canonical_postrank_grade(c(A = 10, B = 10, C = 30), c("A", "B", "C"))
}
\seealso{
\code{\link[=postrank_evaluate]{postrank_evaluate()}}, \code{\link[=get_grades]{get_grades()}}
}
\concept{decision}
