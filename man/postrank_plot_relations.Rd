% Please edit documentation in R/plots-relations.R
\name{postrank_plot_relations}
\alias{postrank_plot_relations}
\title{Plot Disclosed Comparisons or Their Changes}
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
complete named integer grade vector. Grade 1 has highest priority.}

\item{y}{Optional second fit, analysis, baseline or named grade vector on
exactly the same entities. Changes run from \code{x} to \code{y}.}

\item{labels}{\code{"auto"} shows IDs or display names for at most 15 entities
when every label has at most 20 characters; otherwise it shows positions
in grade order. \code{"ids"} always shows the labels. \code{"none"} hides ticks and
axis labels. Increase the canvas size when explicitly showing many IDs.}

\item{...}{Unused.}

\item{entity_labels}{Optional partial named character vector mapping raw
entity IDs to display names. Unmapped IDs keep their text. Names are
wrapped on explicit ID axes and never alter data or ordering. Supply
this argument by name.}
}
\value{
A \code{ggplot} object. If either fitted object lacks a validated grade,
a status panel explains which result is unavailable.
}
\description{
The matrix displays the pairwise directions disclosed or withheld by a
grading. When a second report is supplied, each relation is classified as
unchanged, newly disclosed, newly withheld or reversed. The tiles represent
selected actions. Posterior comparison probabilities are displayed
separately by \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}.
}
\details{
Both axes follow the first object's grade, then raw entity ID. Only the
upper triangle is drawn, so every unordered pair appears once. In a
single-report view, gray means that the comparison is withheld. A shared
grade does not assert latent equality.

In a change map, light gray means unchanged and medium gray means newly
withheld. Unchanged includes pairs that were disclosed in the same direction
and pairs withheld by both reports. Agreement uses all \code{M = choose(n, 2)}
pairs. A relation change is not itself a loss improvement: reports from
different policies need evaluation under a common loss for a risk comparison.
The function reads grades and does not solve or calculate new posterior scores.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
postrank_plot_relations(one)
two <- load_or_compute("tutorial_two")
postrank_plot_relations(one, two, labels = "ids",
  entity_labels = c(A = "Site A", F = "Site F"))
}
\seealso{
\code{\link[=postrank_plot_compare]{postrank_plot_compare()}}, \code{\link[=get_relations]{get_relations()}}, \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}
}
\concept{visualization}
