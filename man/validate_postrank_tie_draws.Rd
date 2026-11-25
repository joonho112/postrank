% Please edit documentation in R/tie-input.R
\name{validate_postrank_tie_draws}
\alias{validate_postrank_tie_draws}
\title{Validate a Tie-Aware Posterior Input}
\usage{
validate_postrank_tie_draws(x)
}
\arguments{
\item{x}{A \code{postrank_tie_draws} object from \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} or
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}.}
}
\value{
\code{TRUE} invisibly when \code{x} passes all checks. Unlike
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}}, invalid or modified objects stop with a
structured error rather than returning a report with \code{valid = FALSE}.
}
\description{
\code{validate_postrank_tie_draws()} checks the numerical arrays or finite-law
states, declarations, criterion equality partitions, and content hash of a
\code{postrank_tie_draws} object used in tie-aware mode (the workflow for
posteriors with positive probability of exact equality under equality-neutral
loss).
}
\details{
Checks cover \code{"tie-aware-input-0.1"} fields, UTF-8 text, axis dimensions and
order, sampling history or exact rational masses (\code{gmp} required for
\code{"exact_finite_posterior"}), exact equality across every retained draw within
declared structural classes, and \code{x$input_identity}. Ordinary
\code{postrank_draws} objects are rejected. Passing validation confirms internal
consistency, not scientific equality, MCMC convergence, or a numerical
certificate.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
input <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
validate_postrank_tie_draws(input)
input$equality$criterion_classes
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}, \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}},
\code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}}
}
\concept{tie-aware}
