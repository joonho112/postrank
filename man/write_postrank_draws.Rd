% Please edit documentation in R/draws-serialization.R
\name{write_postrank_draws}
\alias{write_postrank_draws}
\title{Save a Posterior Input as JSON}
\usage{
write_postrank_draws(x, path, overwrite = FALSE)
}
\arguments{
\item{x}{A \code{postrank_draws} object or a complete \code{applied-0.1} input list.}

\item{path}{Destination JSON file path. Its parent directory must exist.}

\item{overwrite}{Logical scalar (default \code{FALSE}); whether to replace an
existing file at \code{path}.}
}
\value{
\code{path}, invisibly.
}
\description{
\code{write_postrank_draws()} validates a \code{postrank_draws} object (or complete
\code{applied-0.1} list) and writes its values, target descriptions and sampling
history to a JSON file that \code{\link[=read_postrank_draws]{read_postrank_draws()}} can restore.
}
\details{
Joint arrays, criterion-wise blocks and exact finite laws are supported.
Numbers are formatted with 17 significant digits, preserving entity,
criterion and draw order, singleton dimensions (\code{K = 1}), and MCMC chain
histories. The JSON text is checked against the installed
\code{draws-schema.json} specification, written to a temporary file in
\code{dirname(path)} and renamed into place.

The file stores the input fields (\code{schema_version = "applied-0.1"}), not the
in-memory \code{validation} record. Reading the file runs
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}} afresh, so a prior \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}
\code{source_audit} is not carried through JSON. For exact-tie inputs, use
\code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}}.
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
