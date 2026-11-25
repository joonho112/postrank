% Please edit documentation in R/plots-frontier.R
\name{postrank_plot_frontier}
\alias{postrank_plot_frontier}
\title{Plot Disclosure, Error, and Risk Across Settings}
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
\item{x}{A \code{postrank_frontier} object.}

\item{panels}{Non-empty character vector chosen from
\code{c("disclosure", "error", "risk")} (all three by default). Selected panels
always appear in that top-to-bottom order.}

\item{highlight}{Optional numeric value on the horizontal axis (\code{tau} or the
varied error budget \code{q_value}) marked with a vertical dashed line.}

\item{mark_uncertified}{Logical scalar (\code{TRUE} by default). When \code{TRUE}, grid
points whose solver \code{status} is not \code{"optimal"} are drawn as hollow
circles; when \code{FALSE}, all available points use the standard shape scale.
Here \code{"optimal"} records the solver's numerical termination status, which
is not a mathematical certificate.}

\item{...}{Unused; unnamed extra arguments are ignored.}
}
\value{
A \code{ggplot} object. When no grid point has a finite value for the
requested panels (for example, no checked grading or \code{N = 0} when only
\code{"error"} is shown), returns an empty status \code{ggplot} stating why.
}
\description{
\code{postrank_plot_frontier()} plots stored disclosure rates (\code{N / M}),
criterion wrong-direction error rates (\code{E_k / N}), and primary risk across a
grid of withholding costs \code{tau} or error budgets \code{q_k} from
\code{\link[=postrank_frontier]{postrank_frontier()}}, without re-solving the grid.
}
\details{
\code{M = choose(n, 2)} is the number of unordered entity pairs and \code{N} is the
number of disclosed (ordered) pairs. Point shapes indicate the number of
distinct grades \code{G} (up to 18 distinct \code{G} values; above 18, solid circles
are used and noted in the subtitle). Color and line type distinguish criteria
in the \code{"error"} panel. Grid rows without a checked grading are listed in the
subtitle and omitted from the plot; connecting lines stop at missing rows and
at \code{N = 0} where \code{E_k / N} is undefined, so non-adjacent available points are
never joined across a gap. Vertical axes start at zero.

Changing \code{tau} changes the loss function itself, so risk values at different
\code{tau} settings do not compare rules under one shared loss. Changing an error
budget \code{q_k} changes the feasible set of gradings; when an error-budget grid
spans multiple \code{tau} values, each \code{tau} receives its own facet column rather
than a single connecting line.

Under exact optimization with all other settings fixed, disclosure \code{N / M} is
nondecreasing in \code{tau}, although the disclosed pair sets need not be nested.
Numerical solver statuses and gaps do not guarantee exact monotonicity of the
returned gradings.
}
\examples{
frontier <- postrank_example("tutorial_frontier")
postrank_plot_frontier(frontier, highlight = 0.2)
}
\seealso{
\code{\link[=postrank_frontier]{postrank_frontier()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}},
\code{\link[=postrank_plot_profile]{postrank_plot_profile()}}
}
\concept{visualization}
