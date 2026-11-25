% Please edit documentation in R/plots-relations.R
\name{postrank_plot_relations}
\alias{postrank_plot_relations}
\title{Plot Disclosed Pair Relations or Their Changes}
\usage{
postrank_plot_relations(
  x,
  y = NULL,
  labels = c("auto", "ids", "none"),
  ...,
  entity_labels = NULL
)
}
\arguments{
\item{x}{A \code{postrank_fit}, \code{postrank_analysis}, \code{postrank_baseline}, or a
named integer/numeric vector of grades (\code{1} = highest priority).}

\item{y}{Optional second \code{postrank_fit}, \code{postrank_analysis},
\code{postrank_baseline}, or named grade vector grading the exact same set of
entity IDs as \code{x}. Relation changes are classified from \code{x} to \code{y}.}

\item{labels}{Axis label mode: \code{"auto"} (the default) shows entity IDs (or
\code{entity_labels}) when there are at most 15 entities and every display label
has at most 20 characters, and otherwise shows integer positions in grade
order; \code{"ids"} always shows display labels (wrapped at 18 characters on
axes); \code{"none"} hides ticks and axis labels.}

\item{...}{Unused; unnamed extra arguments are ignored. Pass \code{entity_labels}
by name.}

\item{entity_labels}{Optional named character vector mapping raw entity IDs
to display names. Unmapped IDs keep their raw IDs. Labels affect tick text
only and never alter axis order or \verb{$data}.}
}
\value{
A \code{ggplot} object whose \verb{$data} table has one row per unordered pair
(\code{entity_i}, \code{entity_j}, \code{i_pos}, \code{j_pos}, \code{code}, \code{relation}, plus
\code{change} when \code{y} is supplied). If \code{x} or \code{y} is a fitted object without a
checked grading, returns an empty status \code{ggplot} stating which object has
no grades.
}
\description{
\code{postrank_plot_relations()} draws an upper-triangular matrix showing whether
each unordered entity pair is ordered (\code{above} or \code{below}) or left in the
same grade (\code{withheld}), or how those pair relations change from one grading
\code{x} to a second grading \code{y}. Tiles show chosen grading decisions rather than
posterior comparison probabilities; use \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}} to view
directional-error probabilities.
}
\details{
Both axes order entities by \code{x}'s grade (\code{1} first) and then raw entity ID
(\code{radix} order), with the horizontal axis along the top and the vertical axis
reversed so every unordered pair appears once in the upper triangle. In a
single-grading plot, gray tiles mark pairs left in the same grade
(\code{withheld}), which withholds ordering without asserting equal targets.

When \code{y} is supplied, each pair is classified as \code{"unchanged"},
\code{"newly disclosed"}, \code{"newly withheld"}, or \code{"reversed"}. \code{"unchanged"}
(light gray) covers both pairs ordered in the same direction by \code{x} and \code{y}
and pairs withheld by both; \code{"newly withheld"} is medium gray. The subtitle
reports category counts and overall agreement (\code{unchanged / M}, over all
\code{M = choose(n, 2)} unordered pairs). Relation changes describe how two
gradings differ on pairs, not which grading has lower risk; use
\code{\link[=postrank_compare]{postrank_compare()}} to evaluate rules under one shared loss.
}
\examples{
one <- postrank_example("tutorial_one")
postrank_plot_relations(one)

two <- postrank_example("tutorial_two")
postrank_plot_relations(
  one,
  two,
  labels = "ids",
  entity_labels = c(A = "Site A", F = "Site F")
)
}
\seealso{
\code{\link[=postrank_plot_compare]{postrank_plot_compare()}}, \code{\link[=get_relations]{get_relations()}},
\code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}}
}
\concept{visualization}
