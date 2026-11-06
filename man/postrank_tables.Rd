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
\code{postrank_report_card}.}

\item{row.names}{Optional row names for the returned table; their length
must match its number of rows. \code{NULL} uses default row names.}

\item{optional}{Logical; accepted by the \code{as.data.frame()} generic. Basic
table names are already valid R names; report-card column names are retained.}

\item{...}{Unused arguments for generic compatibility.}

\item{what}{For an analysis, either \code{"grades"} (default) or
\code{"report_card"}. Supply this argument by name.}
}
\value{
A data frame. The basic table has character \code{entity_id} and integer
\code{grade} columns. The report-card table has all columns of the prepared card.
}
\description{
The \code{as.data.frame()} methods return complete tables of stored results. For
a fit, analysis or baseline, the default table has exactly two columns,
\code{entity_id} and integer \code{grade}, in the original input order. Grade 1 has
highest priority. A shared grade withholds the comparison without asserting
equality of the latent targets.
}
\details{
For an analysis, \code{what = "report_card"} selects the full prepared
card, ordered by grade and then its recorded secondary key. Calling
\code{as.data.frame()} on a report card returns the same full table. The table
retains raw entity IDs, regardless of labels used in a figure. Select
rows or columns from the returned data frame using ordinary R indexing.

A fit or analysis without a validated grade returns zero rows with the
basic column types; it does not substitute an all-withheld grade. A
request for an unavailable card gives an explanatory error. Conversion
does not solve a problem, evaluate a grade or compute missing summaries.
Unlike a shortened console display or a plot with a row limit, table
conversion includes every available row and has no paging limit.

\strong{Migration to 1.0:} an analysis previously returned its full report
card by default when available. The default now always returns the basic
grade table. Use \code{as.data.frame(analysis, what = "report_card")} for the
former report-card output. CSV preserves a table; RDS preserves the complete
object, including settings and solver qualifications, for later views.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  grades <- as.data.frame(one)
  card <- as.data.frame(one, what = "report_card")
  grades
  card[, c("entity_id", "grade", "mean_score_A", "lower_score_A", "upper_score_A")]
  csv <- tempfile(fileext = ".csv")
  rds <- tempfile(fileext = ".rds")
  write.csv(grades, csv, row.names = FALSE)
  saveRDS(one, rds)
  identical(read.csv(csv), grades)
  identical(as.data.frame(readRDS(rds)), grades)
  unlink(c(csv, rds))
}
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}}, \code{\link[=postrank_report_card]{postrank_report_card()}}
}
\concept{reporting}
