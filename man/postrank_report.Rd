% Please edit documentation in R/postrank-report.R
\name{postrank_report}
\alias{postrank_report}
\title{Create a Standalone Report from Stored Results}
\usage{
postrank_report(
  fit,
  diagnostics = NULL,
  output_file = NULL,
  lang = "en",
  figures = TRUE,
  analysis = NULL
)
}
\arguments{
\item{fit}{A \code{postrank_fit}, such as \code{analysis$fit}.}

\item{diagnostics}{Optional matching \code{postrank_diagnostics} or
\code{postrank_coefficient_diagnostics}. Omit to use matching diagnostics
already stored in \code{analysis}. Source, grade and settings are checked;
diagnostics are not recomputed.}

\item{output_file}{Optional path for a new HTML file. An existing file is
refused. \code{NULL} returns the report object without writing HTML.}

\item{lang}{Report language. Only \code{"en"} is supported; another language
raises \code{unsupported_language}.}

\item{figures}{Logical; embed eligible report-card and criterion-profile
figures as PNGs. \code{FALSE} records \code{figures_disabled}.}

\item{analysis}{Optional \code{postrank_analysis} with the same fit identities.
Supplies its prepared report card, declarations, extras and timings.}
}
\value{
A \code{postrank_report} list containing the stored grades, criterion
profile, disclosure, objective, status, numerical validation information
and source records, plus \code{figures}, \code{declarations}, \code{sections} and
\code{strings_version}. \code{output_file} records the written path, or \code{NULL}.
\code{diagnostics} retains the supplied object. Its \code{diagnostic_table} is
trace-oriented for draws; for coefficient inputs it has columns
\code{quantity}, \code{metric}, \code{value}, \code{available}, \code{NA_reason}, \code{method},
\code{raw_value}, \code{result_kind}, \code{warnings} and \code{error}. Unavailable metrics
retain their reasons rather than becoming zero.
}
\description{
The report combines stored grades, criterion losses, solver qualifications
and available posterior summaries or diagnostics. A self-contained English
HTML file can be written for offline use. Supplying \code{analysis} with its
\code{fit} includes the prepared report card and other stored components. Report
construction does not optimize or evaluate new grades, calculate pairwise
probabilities or prepare missing summaries.
}
\details{
Grade 1 has highest priority; shared grades withhold directions.
A valid all-withheld report has N=0 and undefined conditional error
ratios, not an error-free ranking. With no validated grade, the report
instead shows the solver status, available bounds and reasons for
unavailable grade-dependent content. An optimization gap concerns the
supplied numerical problem, separately from posterior or model uncertainty.

Marginal posterior intervals retain their source and level and describe
target uncertainty rather than Monte Carlo error. Stored diagnostics retain
their producer's methods, warnings and unavailable values. Required inputs,
including \code{chain_history} for eligible \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}
calculations, must be supplied when diagnostics are prepared; report
construction cannot recover missing draws or history. Numerical checks of an
empirical error budget alone do not establish a guarantee for the true
posterior.

The HTML has eleven sections: \code{header}, \code{frame}, \code{declarations}, \code{grades},
\code{decision}, \code{profiles}, \code{protection}, \code{posterior}, \code{mc}, \code{stability} and
\code{provenance}, followed by a footer. Tables include all stored rows; wide
tables scroll horizontally. Included figures use their default display
limits, so a report-card figure may show a stated subset while the table
remains complete. Use the plotting functions separately for custom
entity selection or labels; this function has no paging argument.

Figures are embedded in the HTML, with no separate image or network
dependency. Each attempt records \code{id}, \code{available}, \code{reason},
\code{png_base64}, \code{caption} and \code{alt} in \code{figures}. A missing PNG device or
failed figure leaves an explanatory record and a usable report.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  html <- tempfile(fileext = ".html")
  report <- postrank_report(one$fit, analysis = one, output_file = html)
  report
  vapply(report$figures, `[[`, logical(1), "available")
  unlink(html)
}
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_profile]{postrank_plot_profile()}},
\code{vignette("a6-reading-exporting-results", package = "postrank")}
}
\concept{reporting}
