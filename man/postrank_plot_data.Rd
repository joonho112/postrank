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
\code{postrank_comparison}, \code{postrank_pairwise} (including
\code{\link[=postrank_probabilities]{postrank_probabilities()}}), or \code{postrank_coefficients}.}

\item{which}{Optional single string naming the component to extract. For a
\code{postrank_analysis}, \code{NULL} returns a named list of \code{"report_card"},
\code{"relations"}, and \code{"profile"}, or pass one of \code{"report_card"},
\code{"relations"}, \code{"profile"}, or \code{"pairwise"}. See Details for other classes.}
}
\value{
A data frame, a named list of three components (with an
\code{"availability"} attribute) when \code{x} is a \code{postrank_analysis} and
\code{which = NULL}, or \code{NULL} when a requested \code{"report_card"} or \code{"relations"}
table has no underlying report card or checked grading. When \code{profile} is
requested without a checked grading, returns the zero-row data frame from
\code{\link[=get_profile]{get_profile()}}.
}
\description{
\code{postrank_plot_data()} returns the complete data frame (or named list of data
frames) underlying the seven \code{postrank} plot types without solving,
evaluating gradings, or recomputing posterior summaries. Plot display caps
(\code{max_rows}, \code{max_entities}) and label maps do not filter or rename the
returned tables.
}
\details{
Accepted \code{which} values by input class:
\itemize{
\item \code{postrank_analysis}: \code{NULL} returns \code{list(report_card = ..., relations = ..., profile = ...)} whose \code{"availability"} attribute gives
\code{list(available, reason)} for each slot; \code{"pairwise"} must be requested
by name because its table has \code{n * n * K} rows.
\item \code{postrank_fit}: defaults to \code{"relations"} and also accepts
\code{"profile"} or \code{"pairwise"}.
\item \code{postrank_report_card}: returns the long report-card table.
\item \code{postrank_baseline}: returns the pair-relations table.
\item \code{postrank_frontier} and \code{postrank_commonality_cost}: return
\code{x$table}.
\item \code{postrank_comparison}: returns \code{x$table} by default, or
\code{x$relations} when \code{which = "relations"}.
\item \code{postrank_pairwise} and \code{postrank_coefficients}: accept \code{NULL} or
\code{"pairwise"} and return the pairwise probability table (aggregate raw
\code{postrank_draws} with \code{\link[=postrank_pairwise]{postrank_pairwise()}} first).
}

Returned columns for reshaped views:
\itemize{
\item \code{report_card}: \code{entity_id}, \code{grade}, \code{sort_rank}, \code{n_withheld},
\code{criterion}, \code{mean}, \code{lower}, \code{upper}, and \code{expected_rank}, stacked by
criterion in stored card order (interval \code{level} and \code{interval_source}
stay on the \code{postrank_report_card} object).
\item \code{relations}: one row per unordered pair (\code{i_pos < j_pos}) in
grade-then-ID order with \code{entity_i}, \code{entity_j}, \code{i_pos}, \code{j_pos},
integer \code{code} (\code{1L} = \code{"above"}, \code{0L} = \code{"withheld"}, \code{-1L} = \code{"below"}),
and factor \code{relation}.
\item \code{profile}: same columns as \code{\link[=get_profile]{get_profile()}}.
\item \code{pairwise}: \code{entity_i}, \code{entity_j}, \code{criterion}, and
\code{error_probability} (\code{n * n * K} rows in input order with \code{entity_i}
varying fastest, including \code{NA} diagonal entries; available even when a
fit has no checked grading).
}

Passing \code{which} equal to \code{"sensitivity"}, \code{"fragility"}, \code{"crossfit"},
\code{"trace"}, or \code{"dispersion"} stops with condition code \code{"unshipped_figure"};
those figure names are not implemented as plot views, although the numerical
functions \code{\link[=postrank_sensitivity]{postrank_sensitivity()}}, \code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}}, and
\code{\link[=postrank_crossfit]{postrank_crossfit()}} are available.
}
\examples{
one <- postrank_example("tutorial_one")
card_data <- postrank_plot_data(one, "report_card")
head(card_data)
attr(postrank_plot_data(one), "availability")

pair_data <- postrank_plot_data(pr_tutorial$two, "pairwise")
nrow(pair_data)
head(pair_data)
}
\seealso{
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_plot_pairwise]{postrank_plot_pairwise()}}, \code{\link[=get_profile]{get_profile()}}
}
\concept{visualization}
