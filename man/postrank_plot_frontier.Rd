% Please edit documentation in R/plots-frontier.R
\name{postrank_plot_frontier}
\alias{postrank_plot_frontier}
\title{Plot Disclosure, Error and Risk Across Settings}
\usage{
postrank_plot_frontier(
  x,
  panels = c("disclosure", "error", "risk"),
  highlight = NULL,
  mark_uncertified = TRUE,
  ...
)
}
\arguments{
\item{x}{A \code{postrank_frontier} with stored grid results.}

\item{panels}{Nonempty subset of \code{"disclosure"}, \code{"error"} and \code{"risk"}.
Selected panels retain this standard display order.}

\item{highlight}{Optional value on the displayed horizontal axis (\code{tau} or
the varied error budget), marked by a dashed line.}

\item{mark_uncertified}{Logical; draw rows whose recorded status is not
\code{"optimal"} hollow. \code{FALSE} gives every available row its ordinary point
style. This legacy argument name does not imply numerical certification.}

\item{...}{Unused.}
}
\value{
A \code{ggplot} object. When no selected panel has an available value,
a status panel explains the missing incumbent or undefined error rate.
}
\description{
A prepared frontier is displayed over a grid of withholding costs or error
budgets. The available panels give disclosure \code{N/M}, criterion error \code{E_k/N}
and risk at each setting. The figure uses stored results without repeating
the grid calculations.
}
\details{
\code{M} is the number of all unordered pairs and \code{N} the number disclosed.
Point shape distinguishes grade counts; criterion color and line style
identify error series. Rows without an incumbent retain their status in
the subtitle and receive no point. Lines stop at unavailable rows and at
undefined \code{E_k/N} when \code{N = 0}; a single available point has no connecting
line. Axes start at zero and adapt to the available values.

Changing \code{tau} changes the loss. Risks at different \code{tau} values therefore
do not rank policies under one shared loss. Changing an error budget changes
the feasible action family. If a budget grid contains several \code{tau} values,
they receive separate panel columns rather than a common connecting line.

Disclosure is nondecreasing in \code{tau} for exact optima when all other
settings are fixed, but the set of disclosed pairs need not be nested.
Recorded optimal statuses and numerical gaps do not establish exact
monotonicity of the displayed actions or posterior validity. Available
statuses and gaps remain visible even when points are styled alike.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
frontier <- load_or_compute("tutorial_frontier")
postrank_plot_frontier(frontier, highlight = .2)
}
\seealso{
\code{\link[=postrank_frontier]{postrank_frontier()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}}, \code{\link[=postrank_plot_profile]{postrank_plot_profile()}}
}
\concept{visualization}
