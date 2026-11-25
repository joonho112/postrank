% Please edit documentation in R/report-card.R
\name{postrank_report_card}
\alias{postrank_report_card}
\title{Prepare an Entity Report Card with Posterior Intervals}
\usage{
postrank_report_card(
  x,
  draws = NULL,
  level = 0.9,
  order = c("expected_rank", "mean", "label"),
  order_by = NULL
)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} object with a checked
grading (\code{incumbent_validated = TRUE}; otherwise stops with
\code{no_validated_incumbent}).}

\item{draws}{Optional posterior input matching \code{x}'s \code{input_identity}: a
\code{postrank_draws}, \code{postrank_coefficients}, or \code{\link[=postrank_probabilities]{postrank_probabilities()}}
object with marginal interval summaries. Required when \code{x} is a
\code{postrank_fit} built from a \code{postrank_pairwise} object that does not store
the original draws.}

\item{level}{Central posterior interval level in \verb{(0, 1)} (default \code{0.90}).
For a \code{\link[=postrank_probabilities]{postrank_probabilities()}} input with supplied intervals, \code{level}
must equal the stored \code{summaries$level}.}

\item{order}{Secondary sort order within each grade: \code{"expected_rank"}
(weighted expected rank, the default), \code{"mean"} (descending posterior mean
on one criterion) or \code{"label"} (entity ID).}

\item{order_by}{Criterion ID used when \code{order = "mean"} (required when
several criteria are present, optional with one; must be \code{NULL} for other
\code{order} values).}
}
\value{
A \code{postrank_report_card} object with the full data frame in \code{data},
plus \code{level}, \code{interval_source}, \code{secondary_order}, \code{settings},
\code{grade_identity}, \code{input_identity}, \code{schema_version}, \code{provenance}
(recording \code{ordering_criterion} when \code{order = "mean"}) and \code{warnings}.
}
\description{
\code{postrank_report_card()} combines a checked grading with marginal posterior
means, central intervals and expected ranks in an entity-level table. Each
row gives an entity's grade, how many other entities are reported above it,
below it or in the same grade, and per-criterion posterior summaries. For a
basic two-column grade table, use \link{postrank_tables}.
}
\details{
Rows are sorted first by \code{grade} (grade 1 is highest priority; shared grades
leave pairs unordered), then by \code{order}, with \code{entity_id} breaking remaining
ties. In \code{data}, \code{n_above} counts entities graded below this entity
(\code{grade[i] < grade[j]}), \code{n_below} counts entities graded above it, and
\code{n_withheld} counts other entities sharing its grade; for every row,
\code{n_above + n_below + n_withheld == n - 1}. Per-criterion columns are named
\verb{mean_<k>}, \verb{lower_<k>}, \verb{upper_<k>} and \verb{expected_rank_<k>}, where expected
rank is \eqn{1 + \sum_{j \ne i} e_{ij,k}}. When \code{order = "expected_rank"},
rows within a grade are ordered by weighted expected rank rather than adding
means across criteria in different units.

Cached summaries on a \code{postrank_analysis} at the requested \code{level} are
reused; otherwise summaries are computed from the posterior source without
re-solving for grades. Intervals summarize marginal target uncertainty (a
posterior mean can lie outside an equal-tail interval), not Monte Carlo
error or the probability that a grade assignment is right. \code{data} always
retains all \code{n} entities; row caps in \code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}} affect
only the plot.
}
\examples{
one <- postrank_example("tutorial_one")
card <- postrank_report_card(one, level = 0.80, order = "mean")
as.data.frame(card)
card$interval_source
}
\seealso{
\code{\link[=postrank]{postrank()}}, \link{postrank_tables}, \code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}},
\code{\link[=postrank_posterior_means]{postrank_posterior_means()}}
}
\concept{reporting}
