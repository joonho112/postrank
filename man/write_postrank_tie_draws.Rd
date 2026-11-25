% Please edit documentation in R/tie-serialization.R
\name{write_postrank_tie_draws}
\alias{write_postrank_tie_draws}
\title{Write a Tie-Aware Posterior Input to JSON}
\usage{
write_postrank_tie_draws(x, path, overwrite = FALSE)
}
\arguments{
\item{x}{A plain \code{"tie-aware-input-0.1"} named list or an unmodified
\code{postrank_tie_draws} object.}

\item{path}{Destination JSON file path; \code{dirname(path)} must already exist.}

\item{overwrite}{Logical scalar (\code{FALSE} by default). When \code{FALSE}, stops
with an error if \code{path} already exists.}
}
\value{
\code{path}, invisibly.
}
\description{
\code{write_postrank_tie_draws()} validates and writes a tie-aware posterior input
(for posteriors with positive probability of exact equality under
equality-neutral loss) to a \code{"tie-aware-input-0.1"} JSON file readable by
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}.
}
\details{
Re-runs \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} before writing, formats numbers to 17
significant digits while retaining all entities, singleton dimensions,
sampling histories, and criterion equality partitions, validates the JSON
output against \code{inst/schema/tie-draws-schema.json}, and writes to a temporary
file in \code{dirname(path)} before renaming into place. Modified
\code{postrank_tie_draws} objects fail validation rather than being written. Use
\code{\link[=write_postrank_draws]{write_postrank_draws()}} for ordinary zero-equality inputs.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
input <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
path <- tempfile(fileext = ".json")
write_postrank_tie_draws(input, path)
restored <- read_postrank_tie_draws(path)
identical(restored$input_identity, input$input_identity)
identical(restored$equality, input$equality)
unlink(path)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}, \code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}},
\code{\link[=write_postrank_draws]{write_postrank_draws()}}
}
\concept{tie-aware}
