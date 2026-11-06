% Please edit documentation in R/canonical-grade.R
\name{canonical_postrank_grade}
\alias{canonical_postrank_grade}
\title{Renumber Grades While Preserving Comparisons}
\usage{
canonical_postrank_grade(grade, entity_ids)
}
\arguments{
\item{grade}{Numeric vector of positive integers, with names in exactly
the order of \code{entity_ids}. Gaps between occupied labels are allowed.}

\item{entity_ids}{Character vector of distinct entity IDs, in input order.}
}
\value{
A named integer vector in the same entity order, using grades
\verb{1, ..., G}, where G is the number of distinct supplied labels.
}
\description{
Occupied grade labels are replaced by consecutive integers starting at 1.
Smaller grades indicate higher priority and equal grades withhold a
comparison. The relabelling preserves all disclosed directions and withheld
comparisons.
}
\details{
This function does not sort entities, evaluate posterior risk or
optimize grades. A shared grade does not assert equality of latent targets.
}
\examples{
canonical_postrank_grade(c(A = 10, B = 10, C = 30), c("A", "B", "C"))
}
\seealso{
\code{\link[=postrank_evaluate]{postrank_evaluate()}}, \code{\link[=get_grades]{get_grades()}}
}
\concept{decision}
