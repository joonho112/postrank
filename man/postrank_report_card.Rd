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
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} with a validated grade.}

\item{draws}{Optional source input: \code{postrank_draws},
\code{postrank_coefficients}, or \code{postrank_probabilities} with supplied marginal
intervals. It must have the same input identity as the fit.}

\item{level}{Central posterior interval level in \verb{(0, 1)}; default \code{0.90}.
For supplied marginal summaries, it must exactly match their stored level.}

\item{order}{Secondary sort key within each grade: \code{"expected_rank"}
(weighted expected rank, default), \code{"mean"} (one criterion's posterior
mean, larger first) or \code{"label"} (entity ID).}

\item{order_by}{Criterion used with \code{order = "mean"}. Required with several
criteria, optional with one. Leave \code{NULL} for other ordering rules.}
}
\value{
A \code{postrank_report_card} with the full table in \code{data}. Its other
fields record \code{level}, \code{interval_source}, \code{secondary_order}, \code{settings},
\code{grade_identity}, \code{input_identity}, \code{schema_version}, \code{provenance} and
\code{warnings}. A selected mean-ordering criterion is recorded in
\code{provenance$ordering_criterion}.
}
\description{
A validated grading is combined with marginal posterior summaries in an
entity-level report card. The table contains every entity, its grade, counts
of comparisons reported above or below it or withheld, and each criterion's
posterior mean, interval and expected rank. The table is used for detailed
reporting and plotting; \link{postrank_tables} supplies the basic two-column
grade table.
}
\details{
The table is ordered first by grade, then the secondary key, with
entity ID breaking remaining ties. Grade 1 has highest priority. Shared
grades withhold comparisons and do not establish latent equality.
\code{n_above} counts other entities this entity is reported above; \code{n_below}
counts those it is reported below. Together with \code{n_withheld}, they sum
to n-1 for each row. Columns \code{mean_}, \code{lower_}, \code{upper_} and
\code{expected_rank_} are suffixed with the criterion ID. Expected rank is
\eqn{1 + \sum_{j \ne i} e_{ij,k}}. Weighted ranks can set the row order;
means in different units are never added for this purpose.

The source comes from \code{draws}, then the analysis input, then a typed
coefficient or supplied-probability object stored in the fit. A bare
pairwise object contains no marginal posterior law, so supply its
original input through \code{draws}. Matching cached summaries are reused;
otherwise this function computes summaries from the source. It does not
solve for new grades. Figures and table conversion subsequently read the
prepared card without recomputing these summaries.

Intervals describe the supplied marginal posterior, not Monte Carlo
error or the probability that a grade is correct. A mean can lie outside
an equal-tail interval. Supplied probability matrices require genuine
same-target marginal intervals at their recorded level: a posterior law
or chain history is not inferred from the matrices. Without a validated
grade, the function stops with \code{no_validated_incumbent}.

The card always contains all entities. Row limits and display labels in
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}} affect only the figure.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  card <- postrank_report_card(one, level = .8, order = "mean")
  as.data.frame(card)
  card$interval_source
}
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_posterior_means]{postrank_posterior_means()}}, \link{postrank_tables}
}
\concept{reporting}
