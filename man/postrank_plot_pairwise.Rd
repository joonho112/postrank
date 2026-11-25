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
\item{x}{A \code{postrank_analysis}, \code{postrank_fit}, \code{postrank_pairwise}
(including objects from \code{\link[=postrank_probabilities]{postrank_probabilities()}}), or
\code{postrank_coefficients}. Raw \code{postrank_draws} (convert with
\code{\link[=postrank_pairwise]{postrank_pairwise()}} first) and tie-mode inputs (\verb{postrank_tie_*}) are not
accepted.}

\item{criteria}{Optional character vector of distinct criterion IDs from \code{x},
giving the subset and panel order. \code{NULL} (the default) shows all criteria
in stored order.}

\item{entities}{Optional character vector of at least two distinct entity IDs
from \code{x} to display. Axis order follows the stored result or input order,
not \code{entities}.}

\item{max_entities}{Integer cap of at least \code{2} on automatically displayed
entities (\code{20L} by default), or \code{NULL} to show all entities. Ignored when
\code{entities} is supplied.}

\item{entity_labels, criterion_labels}{Optional named character vectors
mapping raw IDs to display labels. Unmapped criterion IDs replace
underscores with spaces unless that creates duplicate labels. Final labels
must be distinct; \verb{$data} keeps raw IDs.}

\item{ncol}{Positive integer number of facet columns; \code{NULL} (the default)
uses \code{min(2, length(criteria_shown))}.}
}
\value{
A \code{ggplot} object whose \verb{$data} table contains \code{entity_i},
\code{entity_j}, \code{criterion}, and \code{error_probability} for the displayed entities
and criteria.
}
\description{
\code{postrank_plot_pairwise()} draws a square matrix of posterior
directional-error probabilities \verb{Pr(row target <= column target)} for each
criterion. Each off-diagonal cell gives the posterior expected wrong-direction
error from placing the row entity in a higher-priority grade than the column
entity; diagonal self-comparisons are \code{NA} and drawn in gray.
}
\details{
Larger target values mean higher priority, so a small value in row \code{i},
column \code{j} supports placing entity \code{i} above entity \code{j}. Because ordinary
\code{postrank} inputs have zero posterior probability of exact ties, opposite
off-diagonal cells \verb{(i, j)} and \verb{(j, i)} sum to \code{1}. Cells show posterior
comparison probabilities rather than chosen grades; see
\code{\link[=postrank_plot_relations]{postrank_plot_relations()}} for the pairs ordered or withheld by a grading.

The plot reads prepared probabilities without aggregating draws, solving, or
evaluating a grading, so a \code{postrank_fit} without a checked grading can still
display its input probabilities. Entity order uses the report card's stored
order when \code{x} is an analysis with a prepared card, grade-then-ID order for
other checked fits or analyses, and input entity order otherwise.

When \code{entities} is \code{NULL} and \code{x} has more than \code{max_entities} entities,
deterministic display selection spreads rows across stored grades (when
available) or across input order for visual layout only. Use
\code{postrank_plot_data(x, "pairwise")} for the complete \code{n * n * K} table.
}
\examples{
postrank_plot_pairwise(
  pr_tutorial$one,
  criterion_labels = c(score_A = "Score A")
)
postrank_plot_pairwise(
  pr_tutorial$two,
  entities = c("A", "C", "F"),
  ncol = 1,
  criterion_labels = c(score_A = "Score A", score_B = "Score B")
)
}
\seealso{
\code{\link[=postrank_plot_data]{postrank_plot_data()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_pairwise]{postrank_pairwise()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}}
}
\concept{visualization}
