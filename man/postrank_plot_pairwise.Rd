% Please edit documentation in R/plots-pairwise.R
\name{postrank_plot_pairwise}
\alias{postrank_plot_pairwise}
\title{Plot Posterior Directional-Error Probabilities}
\usage{
postrank_plot_pairwise(
  x,
  criteria = NULL,
  entities = NULL,
  max_entities = 20L,
  entity_labels = NULL,
  criterion_labels = NULL,
  ncol = NULL
)
}
\arguments{
\item{x}{A \code{postrank_analysis}, \code{postrank_fit}, prepared
\code{postrank_pairwise}, \code{postrank_probabilities} or \code{postrank_coefficients}.
Raw posterior draws and tie-aware equality-neutral inputs are unsupported.}

\item{criteria}{Optional nonempty subset and display order of criterion IDs.}

\item{entities}{Optional distinct entity IDs; at least two are required.
Their display order follows the stored input or result, not this vector.}

\item{max_entities}{Automatic display limit, an integer at least two;
default 20. \code{NULL} shows all entities. Explicit \code{entities} override the limit.}

\item{entity_labels, criterion_labels}{Optional partial named maps from
original IDs to display labels. Final labels must be distinct. The data
retain their original IDs.}

\item{ncol}{Positive integer number of facet columns; default at most two.}
}
\value{
A \code{ggplot} object with original entity and criterion IDs and
\code{error_probability} in its plotted table. No stored input is changed.
}
\description{
For each possible reporting direction, the figure displays \verb{Pr(row target <= column target)}, the expected error from placing the row entity above the
column entity. A separate square matrix is shown for each criterion.
Self-comparisons are excluded, with \code{NA} diagonal entries displayed in gray.
}
\details{
A cell is not a selected grade, a probability of withholding or a claim of
equality. Larger target values mean higher priority, so a small cell value
supports placing its row entity above its column entity. In this ordinary
zero-equality domain, opposite off-diagonal directions sum to one.

The figure reads prepared probabilities; it does not aggregate raw draws,
fit a model, evaluate an action or solve. A fit without a validated
incumbent can still show its prepared input. Analyses with a card use its
stored entity order; other validated actions use grade then ID; bare inputs
and fits without an action retain input order. No posterior scores are
computed for ordering.

Automatic selection spreads entities across stored grades, or across input
order when no action is available. It is a display selection, not a
representative sample. Use a larger figure for a large explicit selection.
\code{\link[=postrank_plot_data]{postrank_plot_data()}} with \code{which = "pairwise"} returns the complete
unfiltered table, including every diagonal sentinel.
}
\examples{
# Prepared K = 1 and K = 2 Gaussian probabilities for six fictional sites.
# No analysis or solver is needed to inspect these inputs.
postrank_plot_pairwise(pr_tutorial$one,
  criterion_labels = c(score_A = "Score A"))
postrank_plot_pairwise(pr_tutorial$two, entities = c("A", "C", "F"), ncol = 1,
  criterion_labels = c(score_A = "Score A", score_B = "Score B"))
}
\seealso{
\code{\link[=postrank_plot_data]{postrank_plot_data()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_probabilities]{postrank_probabilities()}}
}
\concept{visualization}
