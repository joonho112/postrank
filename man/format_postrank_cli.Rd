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
\item{x}{An object of the class named by the formatter. A wrong class
raises \code{wrong_class}.}

\item{...}{Additional display arguments.}

\item{width}{Line width; \code{NULL} follows \code{getOption("width")}. Widths are
floored at 40 characters.}

\item{tier}{Styling: \code{NULL} detects the context, \code{1} uses ANSI styling,
\code{2} is plain text, and \code{3} is for knitted documents.}

\item{n_head}{Maximum number of rows displayed in table bodies. This affects
applicable displays only; it does not select or remove stored entities.}

\item{details}{For the summary formatter, include technical source records
and identities. \code{NULL} follows the summary object's stored preference.}
}
\value{
Each formatter returns a character vector with one element per
console line. The matching \code{format()} method returns the same lines for
the same arguments. \code{print()} writes those lines and invisibly returns
its input. \code{summary()} returns a structured summary with its own display.
}
\description{
The \code{print(x)} method gives a concise display, \code{summary(x)} describes the
results and settings, and \code{format(x)} returns the display as text. The
methods use stored results without optimization or recalculation of
posterior probabilities. Grade 1 has highest priority and shared grades
withhold comparisons. Valid all-withheld grades are distinguished from fits
for which no validated grades are available.
}
\details{
Default summaries emphasize grades, disclosure, expected loss and
solver qualifications. Use \code{summary(x, details = TRUE)} to add technical
details; structured fields remain available with either display setting.
An optimization gap concerns the supplied numerical problem, separately
from posterior uncertainty and Monte Carlo error.

Large grade memberships and table bodies may be shortened for reading.
Accessors and \link{postrank_tables} return the complete stored results, so use
those for calculations, row selection or export. Console text is not a
stable data format. Fix \code{width} and \code{tier = 2} when saving plain text.

Styling tiers have the same content; stripping tier 1's ANSI styling gives
tier 2. Entity IDs and stored warning text are preserved. The named
formatter functions on this page remain available alongside \code{format()}.
The validation formatter handles input and solution validations; the
guarantee formatter handles conditional risk, regret and protection
records; the summary formatter handles structured summaries.
}
\examples{
lines <- format(pr_tutorial$one, width = 72, tier = 2)
cat(lines, sep = "\n")
identical(lines,
  format_postrank_coefficients_cli(pr_tutorial$one, width = 72, tier = 2))
summary(pr_tutorial$one)
technical <- summary(pr_tutorial$one, details = TRUE)
names(technical)
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_profile]{get_profile()}}, \code{\link[=get_risk]{get_risk()}}, \code{\link[=postrank_report]{postrank_report()}}
}
\concept{reporting}
