% Please edit documentation in R/draws-serialization.R
\name{write_postrank_draws}
\alias{write_postrank_draws}
\title{Save a Posterior Input as JSON}
\usage{
write_postrank_draws(x, path, overwrite = FALSE)
}
\arguments{
\item{x}{A \code{postrank_draws} or complete canonical \code{applied-0.1} payload.}

\item{path}{Destination JSON file. Its parent directory must exist.}

\item{overwrite}{Logical; allow replacement of an existing file.
Defaults to \code{FALSE}.}
}
\value{
The destination path, invisibly.
}
\description{
The writer saves posterior values and their scientific descriptions in the
format read by \code{\link[=read_postrank_draws]{read_postrank_draws()}}. The input is validated before
writing, and its declared entity, criterion and draw order is preserved.
}
\details{
Joint arrays, criterion-wise blocks and complete exact finite laws are
supported. Values are written with 17 significant digits, retaining
singleton dimensions and source sampling histories. The writer creates a
temporary file in the destination directory and renames it into place.

The file contains the canonical input, not a saved validation receipt or
external source-value audit. Reading it performs validation again; a
prior adapter's source-value comparison is not claimed merely because the
file round-trips. Required declaration checks apply without the high-level
array route's extra placeholder check. Use \code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}} for
an equality-neutral input.
}
\examples{
path <- tempfile(fileext = ".json")
write_postrank_draws(postrank_toy, path)
restored <- read_postrank_draws(path)
identical(restored$joint_draws$tensor$values,
  postrank_toy$joint_draws$tensor$values)
identical(restored$joint_draws$draw_index, postrank_toy$joint_draws$draw_index)
unlink(path)
}
\seealso{
\code{\link[=read_postrank_draws]{read_postrank_draws()}}, \code{\link[=validate_postrank_draws]{validate_postrank_draws()}},
\code{\link[=as_postrank_posterior]{as_postrank_posterior()}}
}
\concept{input}
