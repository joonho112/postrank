% Please edit documentation in R/accessors.R
\name{get_relations}
\alias{get_relations}
\title{Extract Which Pairwise Directions the Grades Disclose}
\usage{
get_relations(x, ...)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis}.}

\item{...}{Unused arguments for generic compatibility.}
}
\value{
An integer matrix with one row and column per entity, named and
ordered as the input. Its diagonal is zero. Returns \code{NULL} when no
validated grade is available.
}
\description{
The stored grading is represented as a matrix of disclosed directions. Entry
\verb{(i, j)} is 1 when row entity i has higher priority than column entity j, -1
for the opposite direction, and 0 when the comparison is withheld. The
entries represent reporting decisions rather than posterior comparison
probabilities.
}
\details{
Smaller grades mean higher priority. Shared grades give zero in
both directions without asserting latent equality. A valid all-withheld
report has an all-zero relation matrix, distinct from \code{NULL} after a solve
without validated grades. This accessor does not run a solver.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  relations <- get_relations(one)
  relations[c("A", "B", "C"), c("A", "B", "C")]
}
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}
}
\concept{reporting}
