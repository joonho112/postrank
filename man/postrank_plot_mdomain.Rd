% Please edit documentation in R/mdomain-plot.R
\name{postrank_plot_mdomain}
\alias{postrank_plot_mdomain}
\title{Plot a Multidomain Profile Report Card}
\usage{
postrank_plot_mdomain(
  x,
  view = c("grades", "cells", "pair"),
  units = NULL,
  domains = NULL,
  ...
)
}
\arguments{
\item{x}{A \code{postrank_mdomain_evaluation} or \code{postrank_mdomain_fit}.
For an assessment, use its stored \code{evaluation}.}

\item{view}{One of \code{"grades"}, \code{"cells"}, or \code{"pair"}.}

\item{units}{Optional ordered unit IDs to display. The pair view requires
exactly two distinct IDs.}

\item{domains}{Optional ordered domain IDs. Cell views use one or two
explicitly selected domains when the full card has more than two.}

\item{...}{Named display options \code{title}, \code{unit_labels}, \code{domain_labels}
and \code{base_size}. Label maps are named character vectors keyed by original
IDs. The plot records the selected IDs independently of their labels.}
}
\value{
A \code{ggplot} with inspectable plotting data and a
\code{postrank_mdomain} attribute describing the view and original card scope.
Its \code{caption} field retains the full context accompanying the shorter figure caption.
}
\description{
Display the validated grades, occupied profile cells, or a specified pair's
domain directions. Plots read the stored result and never select a new card.
}
\details{
A tied grade withholds a direction. Cell labels locate grade
combinations. Counts sum over any unshown domains. Risk and protection
in the caption refer to the original card even when only a subset is shown.
Smaller grade numbers mean higher reported priority within that domain.
}
\seealso{
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}},
\code{\link[=theme_postrank]{theme_postrank()}}
}
\concept{multidomain}
