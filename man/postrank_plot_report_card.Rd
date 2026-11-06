% Please edit documentation in R/plots-card.R
\name{postrank_plot_report_card}
\alias{postrank_plot_report_card}
\title{Plot Posterior Estimates and Grade Membership}
\usage{
postrank_plot_report_card(
  x,
  criteria = NULL,
  order = c("grade", "expected_rank", "mean", "label"),
  max_rows = 30L,
  show_withheld = TRUE,
  ...,
  entities = NULL,
  entity_labels = NULL,
  criterion_labels = NULL,
  ncol = NULL,
  order_by = NULL
)
}
\arguments{
\item{x}{A \code{postrank_report_card} or a \code{postrank_analysis} with a prepared card.}

\item{criteria}{Optional nonempty subset and display order of criterion IDs.}

\item{order}{Within-grade order: \code{"grade"} preserves the stored card order;
\code{"expected_rank"} uses weighted expected rank across all criteria;
\code{"mean"} uses one criterion's mean; \code{"label"} sorts raw entity IDs.}

\item{max_rows}{Positive integer display limit, default 30. \code{NULL} shows
every row. Explicit \code{entities} override this limit.}

\item{show_withheld}{Logical; include full grade sizes in the subtitle.}

\item{...}{Unused; nonempty arguments are rejected.}

\item{entities}{Optional distinct entity IDs to show. All selected entities
are shown, even if their number exceeds \code{max_rows}. Their display order
follows \code{order}, not the order of this vector.}

\item{entity_labels}{Optional named character vector mapping IDs to display
names. Partial maps retain the other IDs. Final display names must be
distinct; include an ID when names repeat. Newlines can break long labels.}

\item{criterion_labels}{Optional named criterion-to-label vector. Partial
maps use readable criterion names for the remainder. Final labels must be
distinct. Labels may include units or newlines without changing values.}

\item{ncol}{Positive integer number of facet columns; default at most three.
Use \code{ncol = 1} with a taller figure for a narrow page.}

\item{order_by}{Criterion used with \code{order = "mean"}. Required when several
criteria are displayed; otherwise the sole displayed criterion is used.
An explicit criterion may be any criterion of the card.}
}
\value{
A \code{ggplot} object whose data retain raw entity and criterion IDs.
If an analysis has no prepared card, a status panel explains the recorded
reason; a card and grades must already be available.
}
\description{
The figure displays the stored posterior mean and central interval for each
selected entity, with one panel per criterion and color indicating grade
membership. Grade 1 has highest priority. The intervals describe uncertainty
in the targets, whereas a shared grade denotes a withheld comparison without
asserting target equality.
}
\details{
The figure uses stored means, interval endpoints and grades without
recomputing summaries or solving. Means are never clipped to intervals:
a skewed distribution can have its mean outside its central interval.
The caption gives the stored interval level and distinguishes supplied
central summaries from computed equal-tail posterior intervals.
These are not confidence intervals for the grades or solver bounds.

All ordering keeps grades contiguous. \code{order = "expected_rank"} uses the
card's weights across all criteria, even when only some panels are shown.
\code{order = "mean"} uses the larger mean first within each grade; means in
different units are never added for ordering. Labels affect display only.

Automatic row selection spreads up to \code{max_rows} rows across grades.
Where possible, each grade receives a row; remaining rows are allocated
by grade size and spaced within each grade. If fewer rows than grades are
requested, some grades are omitted. This is a display selection, not a
representative sample or a new analysis. Grade colors and subtitle counts
refer to the full report. For about 30 rows, consider a 7 by 8 inch output;
smaller selections and \code{ncol = 1} suit narrow pages.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
p <- postrank_plot_report_card(one, max_rows = NULL,
  criterion_labels = c(score_A = "Score A (standardized units)"))
p

# The same six sites on two criteria, with one panel per row.
two <- load_or_compute("tutorial_two")
postrank_plot_report_card(two, ncol = 1, entities = c("A", "C", "F"),
  entity_labels = c(A = "Site A", C = "Site C", F = "Site F"),
  criterion_labels = c(score_A = "Score A", score_B = "Score B"))
}
\seealso{
\code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}},
\code{\link[=postrank_plot_relations]{postrank_plot_relations()}}, \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}
}
\concept{visualization}
