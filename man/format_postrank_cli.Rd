% Please edit documentation in R/print-methods.R
\name{format_postrank_cli}
\alias{format_postrank_cli}
\alias{format_postrank_fit_cli}
\alias{format_postrank_analysis_cli}
\alias{format_postrank_draws_cli}
\alias{format_postrank_validation_cli}
\alias{format_postrank_pairwise_cli}
\alias{format_postrank_coefficients_cli}
\alias{format_postrank_coefficient_diagnostics_cli}
\alias{format_postrank_declarations_cli}
\alias{format_postrank_settings_cli}
\alias{format_postrank_control_cli}
\alias{format_postrank_problem_cli}
\alias{format_postrank_report_card_cli}
\alias{format_postrank_baseline_cli}
\alias{format_postrank_comparison_cli}
\alias{format_postrank_frontier_cli}
\alias{format_postrank_commonality_cost_cli}
\alias{format_postrank_sensitivity_cli}
\alias{format_postrank_crossfit_cli}
\alias{format_postrank_mc_fragility_cli}
\alias{format_postrank_diagnostics_cli}
\alias{format_postrank_report_cli}
\alias{format_postrank_guarantee_cli}
\alias{format_postrank_backend_availability_cli}
\alias{format_postrank_summary_cli}
\title{Format postrank Results for Reading in the Console}
\usage{
format_postrank_fit_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_analysis_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_draws_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_validation_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_pairwise_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_coefficients_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_coefficient_diagnostics_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_declarations_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_settings_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_control_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_problem_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_report_card_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_baseline_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_comparison_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_frontier_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_commonality_cost_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_sensitivity_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_crossfit_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_mc_fragility_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_diagnostics_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_report_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_guarantee_cli(x, ..., width = NULL, tier = NULL, n_head = 10L)

format_postrank_backend_availability_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L
)

format_postrank_summary_cli(
  x,
  ...,
  width = NULL,
  tier = NULL,
  n_head = 10L,
  details = NULL
)
}
\arguments{
\item{x}{An object of the class named by the formatter (wrong classes stop
with error code \code{wrong_class}). \code{format_postrank_validation_cli()} accepts
both \code{postrank_validation} and \code{postrank_solution_validation};
\code{format_postrank_guarantee_cli()} handles the conditional bound and
envelope records; \code{format_postrank_summary_cli()} formats objects returned
by \code{summary()}.}

\item{...}{Additional display arguments passed between methods.}

\item{width}{Target line width in characters (\code{NULL} reads
\code{getOption("width")}, floored at \code{40}).}

\item{tier}{Styling mode: \code{NULL} detects the session context, \code{1} adds ANSI
terminal styling, \code{2} produces plain text (identical to tier \code{1} with ANSI
codes stripped), and \code{3} formats for knitted documents.}

\item{n_head}{Maximum number of rows shown in printed table bodies (default
\code{10L}). Does not drop or alter rows stored inside \code{x}.}

\item{details}{Logical for \code{format_postrank_summary_cli()} and \code{summary()}:
whether to include technical source records and hashes. \code{NULL} uses the
setting stored on the summary object.}
}
\value{
Each \verb{format_postrank_*_cli()} function and \code{format()} method
returns a character vector with one element per line. \code{print()} writes
those lines and returns \code{x} invisibly. \code{summary()} returns a structured
\code{postrank_summary} object with its own \code{print()} and \code{format()} methods
(controlled by \code{postrank.lang}; see \link{postrank_options}).
}
\description{
In ordinary use, call \code{print(x)} for a concise console display, \code{summary(x)}
(or \code{summary(x, details = TRUE)}) for a fuller summary of settings and
bounds, and \code{format(x)} to get the console lines as a character vector. The
24 \verb{format_postrank_*_cli()} functions return the exact same lines as
\code{format(x)} when you want to set line width, styling tier or table row count
directly and verify \code{x}'s class. None of these methods run a solver or
recompute probabilities.
}
\details{
Console output uses \code{"disclosed"} for ordered pairs, \code{"withheld"} for
unordered pairs (shared grades), and \code{"risk"} for posterior expected loss.
Long grade member lists and tables are shortened for reading; use
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}} and \link{postrank_tables} to
extract complete results rather than parsing console text. When saving plain
text, fix \code{width} and \code{tier = 2}.
}
\examples{
one <- postrank_example("tutorial_one")
lines <- format(one, width = 72, tier = 2)
cat(lines, sep = "\n")
identical(lines, format_postrank_analysis_cli(one, width = 72, tier = 2))

summary(pr_tutorial$one)
tech <- summary(pr_tutorial$one, details = TRUE)
names(tech)
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}}, \link{postrank_tables},
\code{\link[=postrank_report]{postrank_report()}}, \link{postrank_options}
}
\concept{formatters}
