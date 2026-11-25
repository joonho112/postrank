% Please edit documentation in R/accessors.R
\name{get_relations}
\alias{get_relations}
\title{Extract Which Pairwise Directions the Grades Disclose}
\usage{
get_relations(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} object.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
An \verb{n x n} integer matrix named and ordered by \code{entity_id}, with
\code{0L} on the diagonal, or \code{NULL} when no checked grading is available.
}
\description{
\code{get_relations()} converts the checked grades in \code{x} into an
entity-by-entity matrix of reported ordering decisions: \code{1L} when row entity
\code{i} has a higher-priority grade than column entity \code{j} (\code{grade[i] < grade[j]}),
\code{-1L} when \code{grade[i] > grade[j]}, and \code{0L} when the pair is left unordered
(\code{grade[i] == grade[j]}, including the diagonal).
}
\details{
Entries record the reported grading decisions, not posterior
comparison probabilities. A valid one-grade report leaving all pairs
unordered returns an all-\code{0L} matrix, whereas \code{NULL} means no checked
grading is available. \code{get_relations()} does not run a solver.
}
\examples{
one <- postrank_example("tutorial_one")
rel <- get_relations(one)
rel[c("A", "B", "C"), c("A", "B", "C")]
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}
}
\concept{reporting}
