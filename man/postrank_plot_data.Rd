% Please edit documentation in R/plots-data.R
\name{postrank_plot_data}
\alias{postrank_plot_data}
\title{Extract Stored Data for a Figure}
\usage{
postrank_plot_data(x, which = NULL)
}
\arguments{
\item{x}{A \code{postrank_analysis}, \code{postrank_fit}, \code{postrank_report_card},
\code{postrank_baseline}, \code{postrank_frontier}, \code{postrank_commonality_cost},
\code{postrank_comparison}, or prepared pairwise/coefficient input.}

\item{which}{Optional component name. Analysis components are
\code{"report_card"}, \code{"relations"} and \code{"profile"}; \code{"pairwise"} explicitly
requests prepared probabilities. See Details for other classes.}
}
\value{
A data frame, a named list for an analysis with \code{which = NULL},
or \code{NULL} for an unavailable card or relation component. A profile without
a validated incumbent is an empty typed data frame. The analysis list has
an \code{availability} attribute with an available flag and reason per component.
}
\description{
The complete data underlying the seven postrank figure types are returned
for inspection or alternative displays. Stored results are read and reshaped
without optimization, action evaluation or calculation of posterior
summaries. Plot row limits and display labels do not affect the returned
tables.
}
\details{
For an analysis, \code{which = NULL} returns \code{report_card}, \code{relations} and
\code{profile}. Pairwise probabilities are deliberately separate because the
complete table has \code{n * n * K} rows. A fit defaults to \code{"relations"} and
also accepts \code{"profile"} or \code{"pairwise"}. A report card returns its long
table; a baseline returns its relations. Frontier and commonality objects
return their stored tables. A comparison returns its summary table by
default and its change-count table for \code{which = "relations"}.

The report-card table has \code{entity_id}, \code{grade}, \code{sort_rank}, \code{n_withheld},
\code{criterion}, \code{mean}, \code{lower}, \code{upper} and \code{expected_rank}. Rows are grouped
by criterion and follow stored card order within each criterion; interval
level and source remain on the card object. Relations contain one row per
unordered pair with \code{entity_i}, \code{entity_j}, \code{i_pos}, \code{j_pos}, \code{code} and
\code{relation}, in grade-then-ID order. Code 1 means the first entity is above
the second, 0 means withheld and -1 means below. Profile columns are
listed in \code{\link[=get_profile]{get_profile()}}.

\code{which = "pairwise"} returns \code{entity_i}, \code{entity_j}, \code{criterion} and
\code{error_probability}, including the \code{NA} diagonal. It preserves input ID
order, with \code{entity_i} varying fastest. This component remains available
for fits without a validated grade. Prepared pairwise/probability/coefficient
objects return it by default, but raw draws must first be aggregated with
\code{\link[=postrank_pairwise]{postrank_pairwise()}}. The table is not a relation-change map; use
\code{\link[=postrank_plot_relations]{postrank_plot_relations()}} with two actions for that view.

The designs \code{"sensitivity"}, \code{"fragility"}, \code{"crossfit"}, \code{"trace"} and
\code{"dispersion"} are reserved and raise \code{unshipped_figure}. This does not
imply that all similarly named numerical diagnostic functions are unavailable.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
card_data <- postrank_plot_data(one, "report_card")
head(card_data)

# Complete two-criterion probability table, including its gray diagonal cells.
pair_data <- postrank_plot_data(pr_tutorial$two, "pairwise")
nrow(pair_data)
head(pair_data)
attr(postrank_plot_data(one), "availability")
}
\seealso{
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}, \code{\link[=get_profile]{get_profile()}}
}
\concept{visualization}
