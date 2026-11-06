% Please edit documentation in R/tie-serialization.R
\name{write_postrank_tie_draws}
\alias{write_postrank_tie_draws}
\title{Save an Equality-Neutral Posterior Input as JSON}
\usage{
write_postrank_tie_draws(x, path, overwrite = FALSE)
}
\arguments{
\item{x}{A complete canonical \code{tie-aware-input-0.1} payload or an unchanged
\code{postrank_tie_draws} object.}

\item{path}{Destination JSON file; its parent directory must exist.}

\item{overwrite}{Logical; allow replacement of an existing file.
Defaults to \code{FALSE}.}
}
\value{
The destination path, invisibly.
}
\description{
The writer stores a tie-aware input with its numerical values, target
definitions and equality classes. The file can be read by
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}} with all entities and their original order
retained.
}
\details{
Validation is repeated before writing. Values use 17 significant digits;
all entities, singleton dimensions, sampling histories and named criterion
equality partitions are retained. A temporary file in the destination
directory is renamed into place after the supported JSON checks pass.

The file stores the canonical input, not a claim of scientific verification.
Reading it repeats validation and recreates its content identity. Changed
objects fail validation rather than being silently accepted. Use
\code{\link[=write_postrank_draws]{write_postrank_draws()}} for the ordinary zero-equality input domain.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
    package = "postrank"))
  path <- tempfile(fileext = ".json")
  write_postrank_tie_draws(input, path)
  restored <- read_postrank_tie_draws(path)
  identical(restored$input_identity, input$input_identity)
  identical(restored$equality, input$equality)
  unlink(path)
}
}
\seealso{
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}, \code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}
}
\concept{tie-aware}
