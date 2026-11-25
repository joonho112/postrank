% Please edit documentation in R/accessors.R
\name{postrank_tables}
\alias{postrank_tables}
\alias{as.data.frame.postrank_fit}
\alias{as.data.frame.postrank_analysis}
\alias{as.data.frame.postrank_baseline}
\alias{as.data.frame.postrank_report_card}
\title{Convert Stored Results to Tables}
\usage{
\method{as.data.frame}{postrank_fit}(x, row.names = NULL, optional = FALSE, ...)

\method{as.data.frame}{postrank_analysis}(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  what = c("grades", "report_card")
)

\method{as.data.frame}{postrank_baseline}(x, row.names = NULL, optional = FALSE, ...)

\method{as.data.frame}{postrank_report_card}(x, row.names = NULL, optional = FALSE, ...)
}
\arguments{
\item{x}{A \code{postrank_fit}, \code{postrank_analysis}, \code{postrank_baseline} or
\code{postrank_report_card} object.}

\item{row.names}{Optional row names matching the number of returned rows, or
\code{NULL} for default row names.}

\item{optional}{Logical passed to \code{\link[base:as.data.frame]{base::as.data.frame()}}.}

\item{...}{Unused arguments for generic compatibility.}

\item{what}{For a \code{postrank_analysis}, \code{"grades"} (the default two-column
table) or \code{"report_card"} (the full stored report-card table). Pass by
name.}
}
\value{
A data frame: \code{data.frame(entity_id, grade)} (zero rows when \code{x}
has no checked grading), or the full report-card table when \code{x} is a
\code{postrank_report_card} or \code{what = "report_card"}.
}
\description{
\code{as.data.frame()} extracts complete data frames from stored \code{postrank}
results without row limits or solver calls. For a \code{postrank_fit},
\code{postrank_analysis} or \code{postrank_baseline}, the default table has two
columns, \code{entity_id} and integer \code{grade}, in input entity order. Grade 1 is
the highest priority; entities sharing a grade are left unordered without
claiming they are equal.
}
\details{
\code{as.data.frame(analysis, what = "report_card")} and
\code{as.data.frame(report_card)} return every entity row of the prepared report
card, ordered by \code{grade} and then the card's secondary sort key, keeping raw
\code{entity_id} values regardless of plot display labels. Requesting
\code{what = "report_card"} when \code{analysis$report_card} is \code{NULL} stops with
\code{report_card_unavailable}.

Unlike console printing or plot row limits, \code{as.data.frame()} always returns
all available rows. Note that before postrank 1.0, \code{as.data.frame(analysis)}
returned the report card when present; pass \code{what = "report_card"} to obtain
that table. Saving to CSV exports a table, whereas \code{saveRDS()} preserves the
full object with its settings, bounds and warnings.
}
\examples{
one <- postrank_example("tutorial_one")
grades <- as.data.frame(one)
grades

card <- as.data.frame(one, what = "report_card")
card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}},
\code{\link[=postrank_report_card]{postrank_report_card()}}
}
\concept{reporting}
