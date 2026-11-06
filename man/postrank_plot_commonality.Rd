% Please edit documentation in R/plots-frontier.R
\name{postrank_plot_commonality}
\alias{postrank_plot_commonality}
\title{Plot the Extra Criterion Risk of a Common Grading}
\usage{
postrank_plot_commonality(x, ...)
}
\arguments{
\item{x}{A \code{postrank_commonality_cost} with stored common-action evaluations
and criterion-specific optimization results.}

\item{...}{Unused.}
}
\value{
A \code{ggplot} object with one labeled row per criterion. A finite
\code{cost_lower} is shown as a hollow point; the segment to \code{cost_upper} appears
only when both endpoints are available. Missing bounds remain unavailable.
}
\description{
The criterion-specific increase in risk under the stored common action is
compared with a criterion-specific optimization. Bounds for the increase are
obtained from each criterion's own optimization. The intervals represent
numerical optimization uncertainty rather than posterior uncertainty about
targets or grades.
}
\details{
The lower endpoint is \code{max(0, common_grade_risk - own_best_risk)}: it
subtracts the criterion's own incumbent risk and is clipped at zero because
the common action is available in that comparison family. The upper endpoint
subtracts the own solve's lower bound. Thus the own incumbent is not assumed to equal
the unknown minimum. A zero line provides a reference, and labels retain
the own solve's status and available absolute risk gap. The comparison
inherits the stored action families, protection setting and numerical
limitations; the plot does not perform another criterion-specific solve.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
commonality <- load_or_compute("tutorial_commonality")
postrank_plot_commonality(commonality)
}
\seealso{
\code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}},
\code{\link[=postrank_plot_compare]{postrank_plot_compare()}}
}
\concept{visualization}
