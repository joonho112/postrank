% Please edit documentation in R/plots-compare.R
\name{reexports}
\alias{reexports}
\alias{autoplot}
\title{Draw a Stored postrank Result with autoplot}
\usage{
autoplot(object, ...)
}
\arguments{
\item{object}{A prepared postrank analysis, fit, report card, baseline,
frontier, commonality result or method comparison.}

\item{...}{Arguments for the selected plotting method. Analyses and fits
accept \code{type} to choose the view; other arguments, such as \code{ncol} or
\code{view}, follow the corresponding plotting function's help.}
}
\value{
For the supported postrank classes, a \code{ggplot} object.
}
\description{
The re-exported \code{\link[ggplot2:autoplot]{ggplot2::autoplot()}} generic dispatches prepared postrank
results to the corresponding plotting method and returns a \code{ggplot}. Base R
\code{plot()} uses the same dispatch, prints the figure and returns it invisibly.
Both methods use prepared results without computing a new grading or
diagnostic.
}
\details{
An analysis defaults to its prepared report card and also accepts
\code{type = "relations"}, \code{"profile"} or \code{"pairwise"}. A fit defaults to
relations and accepts \code{"relations"}, \code{"profile"} or \code{"pairwise"}.
Report cards, frontiers, commonality results, comparisons and baselines
dispatch to their corresponding plotting functions. Other named arguments
are passed to that figure, such as \code{ncol = 1} for a card or
\code{view = "relations"} for a comparison.

Missing prepared results are handled according to the corresponding plotting
function. Prepared pairwise probabilities remain available for a fit without
grades. The seven \verb{postrank_plot_*()} functions provide explicit selection
of the figure type.
}
\examples{
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
p <- autoplot(one) # prepared one-criterion report card
p
two <- load_or_compute("tutorial_two")
autoplot(two, type = "relations")
}
\seealso{
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_plot_profile]{postrank_plot_profile()}}, \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}},
\code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}, \code{\link[=postrank_plot_compare]{postrank_plot_compare()}},
\code{\link[=postrank_plot_commonality]{postrank_plot_commonality()}}
}
\concept{visualization}
