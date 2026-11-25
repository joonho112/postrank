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
\item{fit}{A \code{postrank_fit} object, such as \code{analysis$fit}.}

\item{diagnostics}{Optional matching \code{postrank_diagnostics} or
\code{postrank_coefficient_diagnostics} object. If \code{NULL} and \code{analysis} is
supplied, \code{analysis$diagnostics} is used when present. Input, grade and
settings identities are checked against \code{fit}.}

\item{output_file}{Optional path for a new HTML file. Existing files are
refused (\code{report_exists}). If \code{NULL} (the default), the report object is
returned without writing a file.}

\item{lang}{Report language. Only \code{"en"} (English) is supported; any other
value stops with \code{unsupported_language} (see \link{postrank_options}).}

\item{figures}{Logical scalar (default \code{TRUE}); whether to embed the
report-card and criterion-profile plots as base64 PNG images. \code{FALSE}
records \code{reason = "figures_disabled"}.}

\item{analysis}{Optional \code{postrank_analysis} object whose \code{fit} matches
\code{fit}, supplying its prepared report card, declaration summary, extras
status and timings.}
}
\value{
A \code{postrank_report} list containing the stored grades,
\code{criterion_profile}, \code{disclosure}, \code{objective}, \code{status}, \code{report_card},
\code{diagnostics} and \code{diagnostic_table}, \code{figures}, \code{declarations},
\code{sections}, \code{strings_version}, and \code{output_file} (the normalized path when
written, or \code{NULL}).
}
\description{
\code{postrank_report()} assembles stored grades, per-criterion losses, solver
bounds and available posterior intervals or diagnostics into a
\code{postrank_report} object, and optionally writes a self-contained English HTML
file. It reads stored results without running a solver or recomputing
probabilities or diagnostics.
}
\details{
The HTML document is self-contained (inline CSS and base64-encoded PNG
figures, no external network links) with eleven sections: \code{header}, \code{frame},
\code{declarations}, \code{grades}, \code{decision}, \code{profiles}, \code{protection}, \code{posterior},
\code{mc}, \code{stability} and \code{provenance}, plus a footer. Tables include every
stored row with horizontal scrolling; embedded figures use the default
display limits of \code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}} and
\code{\link[=postrank_plot_profile]{postrank_plot_profile()}}. If PNG rendering fails, the report remains valid
and \code{figures} records the reason.

Grade 1 is the highest priority, and shared grades leave pairs unordered. A
valid one-grade report leaving all pairs unordered shows \code{N = 0} and
\code{E_k / N = NA} (loss \code{tau}); when \code{fit} has no checked grading, the report
shows the solver status, any lower bound and why grade tables are
unavailable. Solver bounds and gaps describe the optimization problem only,
and marginal posterior intervals describe target uncertainty rather than
Monte Carlo error.
}
\examples{
one <- postrank_example("tutorial_one")
html <- tempfile(fileext = ".html")
report <- postrank_report(one$fit, analysis = one, output_file = html)
report$sections
file.exists(html)
unlink(html)
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_report_card]{postrank_report_card()}},
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}}, \code{\link[=postrank_plot_profile]{postrank_plot_profile()}},
\code{vignette("a6-reading-exporting-results", package = "postrank")}
}
\concept{reporting}
