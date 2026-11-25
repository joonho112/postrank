% Please edit documentation in R/plots-compare.R
\name{reexports}
\alias{reexports}
\alias{autoplot}
\title{Draw a Stored postrank Result with autoplot}
\usage{
autoplot(object, ...)
}
\arguments{
\item{object}{A \code{postrank_analysis}, \code{postrank_fit}, \code{postrank_report_card},
\code{postrank_baseline}, \code{postrank_frontier}, \code{postrank_commonality_cost}, or
\code{postrank_comparison}.}

\item{...}{Arguments passed on to the target plotting function. Analyses and
fits accept \code{type} to select the figure; other arguments (such as \code{ncol} or
\code{view}) follow the target \verb{postrank_plot_*()} function.}
}
\value{
For supported \code{postrank} classes, a \code{ggplot} object (\code{plot()} returns
it invisibly after printing).
}
\description{
\code{autoplot()} (re-exported from \code{\link[ggplot2:autoplot]{ggplot2::autoplot()}}) dispatches stored
\code{postrank} objects to the matching \verb{postrank_plot_*()} function and returns a
\code{ggplot} object. Base R \code{plot()} uses the same dispatch, prints the figure,
and returns the \code{ggplot} invisibly. Neither method solves or computes new
posterior summaries.
}
\details{
Dispatch by class:
\itemize{
\item \code{postrank_analysis}: \code{type = "report_card"} (default), \code{"relations"},
\code{"profile"}, or \code{"pairwise"}.
\item \code{postrank_fit}: \code{type = "relations"} (default), \code{"profile"}, or
\code{"pairwise"}.
\item \code{postrank_report_card}: \code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}.
\item \code{postrank_baseline}: \code{\link[=postrank_plot_relations]{postrank_plot_relations()}}.
\item \code{postrank_frontier}: \code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}.
\item \code{postrank_commonality_cost}: \code{\link[=postrank_plot_commonality]{postrank_plot_commonality()}}.
\item \code{postrank_comparison}: \code{\link[=postrank_plot_compare]{postrank_plot_compare()}}.
}

Objects missing a report card or checked grading return the same status
\code{ggplot} as the underlying \verb{postrank_plot_*()} function, while
\code{type = "pairwise"} remains available on fits without grades.
}
\examples{
one <- postrank_example("tutorial_one")
autoplot(one)

two <- postrank_example("tutorial_two")
autoplot(two, type = "relations")
}
\seealso{
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_plot_profile]{postrank_plot_profile()}}, \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}},
\code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}, \code{\link[=postrank_plot_compare]{postrank_plot_compare()}},
\code{\link[=postrank_plot_commonality]{postrank_plot_commonality()}}
}
\concept{visualization}
