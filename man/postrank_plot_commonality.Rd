% Please edit documentation in R/plots-frontier.R
\name{postrank_plot_commonality}
\alias{postrank_plot_commonality}
\title{Plot the Extra Criterion Risk of a Common Grading}
\usage{
postrank_plot_commonality(x, ...)
}
\arguments{
\item{x}{A \code{postrank_commonality_cost} object.}

\item{...}{Unused; unnamed extra arguments are ignored.}
}
\value{
A \code{ggplot} object with one row per criterion (\verb{$data} holds
\code{x$table}). Finite \code{cost_lower} values appear as hollow circles, and a
horizontal segment to \code{cost_upper} is drawn whenever both endpoints are
finite; missing bounds are noted in the subtitle rather than imputed.
}
\description{
\code{postrank_plot_commonality()} plots how much extra criterion risk each
criterion incurs under a shared common grading compared with a separate
grading solved for that criterion alone, using stored results from
\code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}. Segments show solver bounds from each
criterion's separate optimization, not posterior uncertainty intervals for
targets or grades.
}
\details{
For each criterion, \code{cost_lower = max(0, common_grade_risk - own_best_risk)}
compares the common grading's risk on that criterion against the best checked
grading found in the criterion-specific solve (clipped at zero because the
common grading belongs to the comparison family when \code{protection = "none"} or
satisfies the active budget). \code{cost_upper} subtracts the criterion-specific
solve's \code{own_lower_bound} instead of \code{own_best_risk}, so an unfinished
separate solve leaves a range \verb{[cost_lower, cost_upper]} rather than assuming
its best found grading achieved the true minimum.

A vertical reference line marks zero extra risk, and y-axis labels display
each criterion ID, its separate solver status, and its absolute solver gap
(\code{own_best_risk - own_lower_bound}). The plot reads stored results without
running new solves.
}
\examples{
commonality <- postrank_example("tutorial_commonality")
postrank_plot_commonality(commonality)
}
\seealso{
\code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}},
\code{\link[=postrank_plot_compare]{postrank_plot_compare()}}
}
\concept{visualization}
