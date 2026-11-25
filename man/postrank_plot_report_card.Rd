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
\item{x}{A \code{postrank_report_card} or a \code{postrank_analysis} with a prepared
report card.}

\item{criteria}{Optional character vector of distinct criterion IDs from the
card, giving the subset and left-to-right (or top-to-bottom) panel order.
\code{NULL} (the default) shows all criteria in stored weight order.}

\item{order}{Ordering of entities within each grade: \code{"grade"} (the default)
keeps the report card's stored \code{sort_rank} (\verb{1..n} row order);
\code{"expected_rank"} sorts by weighted expected rank across all criteria in
the card; \code{"mean"} sorts by descending posterior mean on one criterion;
\code{"label"} sorts by raw entity ID in locale-independent byte/ASCII
lexicographic (\code{"radix"}) order.}

\item{max_rows}{Positive integer cap on automatically displayed entities
(default \code{30L}), or \code{NULL} to show every entity. Ignored when \code{entities} is
supplied.}

\item{show_withheld}{Logical scalar (\code{TRUE} by default). When \code{TRUE} and the
full card has more than one grade, includes full-report grade sizes in the
subtitle.}

\item{...}{Unused; passing any argument in \code{...} stops with an error. Pass
arguments after \code{...} by name.}

\item{entities}{Optional character vector of distinct entity IDs from the
card to display. All named entities are shown even when \code{length(entities)}
exceeds \code{max_rows}; their vertical order follows \code{order}, not the order of
\code{entities}.}

\item{entity_labels}{Optional named character vector mapping known raw entity
IDs in the card to non-blank display names. Unmapped IDs keep their raw
IDs. Resulting display names must be distinct across the full card (include
an ID when two names would match); \code{"\\n"} may be used to break long labels.}

\item{criterion_labels}{Optional named character vector mapping known
criterion IDs in the card to non-blank panel strip labels. Unmapped IDs
replace underscores with spaces unless that would create duplicate labels.
Resulting strip labels must be distinct across all criteria in the card.}

\item{ncol}{Positive integer number of facet columns. \code{NULL} (the default)
uses \code{min(3, length(criteria_shown))}; values above the number of displayed
criteria are capped at that count. Use \code{ncol = 1} for narrow pages.}

\item{order_by}{Single criterion ID used when \code{order = "mean"}. Must be
\code{NULL} for other \code{order} choices. Required when \code{order = "mean"} and more
than one criterion is displayed; when \code{NULL} with a single displayed
criterion, that criterion is used. An explicit \code{order_by} may name any
criterion in the card, even one omitted from \code{criteria}.}
}
\value{
A \code{ggplot} object whose \verb{$data} table holds the same columns as
\code{postrank_plot_data(x, "report_card")} for the displayed entities and
criteria, ordered by \code{order} with \code{entity_id}, \code{criterion}, and \code{grade}
stored as factors (over raw IDs and \verb{1..G}) alongside \code{sort_rank} (\verb{1..n}
row order stored in the card), \code{n_withheld} (number of other entities in
the same grade), \code{mean}, \code{lower}, \code{upper}, and \code{expected_rank}. If \code{x} is a
\code{postrank_analysis} whose \code{report_card} slot is \code{NULL}, returns an empty
status \code{ggplot} stating why no report card is available.
}
\description{
\code{postrank_plot_report_card()} plots the stored posterior mean and central
interval for each displayed entity, with one panel per criterion and color
showing grade membership. Grade 1 is the highest priority, and larger target
values mean higher priority as declared when the input was built. Each
horizontal bar summarizes marginal uncertainty for one entity's target at a
time; entities in the same grade are left unordered (withheld), which does
not mean their targets are equal.
}
\details{
The plot reads stored means, interval endpoints, and grades without solving
or recomputing posterior summaries. Points mark posterior means and segments
mark central intervals (\code{lower} to \code{upper}) on \code{"Posterior target"}; means
are never clipped to interval endpoints because a skewed posterior can have
its mean outside its central interval. The caption records the stored
percentage level (\code{100 * card$level}, where \code{card} is \code{x} or \code{x$report_card})
and states whether the intervals came from supplied marginal summaries or
computed equal-tail posterior intervals (from draws, an exact finite law, or
normal/mixture posteriors). These intervals are marginal posterior summaries
for individual targets, not simultaneous intervals and not confidence
intervals for grade labels or solver bounds.

Grades always stay in contiguous vertical blocks (\code{1} at the top), with light
gray background bands on odd-numbered grades. When \code{order = "expected_rank"},
expected ranks are combined using the card's criterion weights across all
criteria, even if \code{criteria} displays a subset. When \code{order = "mean"}, means
on different criteria are never added together. Display labels affect axis
and strip text only.

When \code{entities} is \code{NULL} and the card has more than \code{max_rows} entities,
deterministic display selection gives at least one row to each grade when
\code{max_rows >= G}, allocates remaining rows in proportion to grade size, and
spaces rows across each grade; if \code{max_rows < G}, some grades are omitted
and the subtitle notes this. That subset is for visual layout only, not a
statistical sample or a re-grading. Colors use \code{\link[=scale_colour_grade]{scale_colour_grade()}} with
the full report's grade count \code{G} up to 64 grades (and neutral dark gray
without a legend when \code{G > 64}), so subsets keep their original grade colors.
}
\examples{
one <- postrank_example("tutorial_one")
postrank_plot_report_card(
  one,
  max_rows = NULL,
  criterion_labels = c(score_A = "Score A (standardized units)")
)

two <- postrank_example("tutorial_two")
postrank_plot_report_card(
  two,
  ncol = 1,
  entities = c("A", "C", "F"),
  entity_labels = c(A = "Site A", C = "Site C", F = "Site F"),
  criterion_labels = c(score_A = "Score A", score_B = "Score B")
)
}
\seealso{
\code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}},
\code{\link[=postrank_plot_relations]{postrank_plot_relations()}}, \code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}
}
\concept{visualization}
