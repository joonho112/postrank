% Please edit documentation in R/tie-serialization.R
\name{read_postrank_tie_draws}
\alias{read_postrank_tie_draws}
\title{Read an Equality-Neutral Posterior Input from JSON}
\usage{
read_postrank_tie_draws(path)
}
\arguments{
\item{path}{Path to an existing \code{tie-aware-input-0.1} JSON file.}
}
\value{
A validated \code{postrank_tie_draws} from \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.
}
\description{
The reader imports posterior values, declarations of genuine equality and
original source histories for a tie-aware analysis. Files produced by
\code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}} preserve the numerical targets and IDs.
}
\details{
The reader supports joint equal-weight IID/MCMC draws and complete exact
finite laws. It preserves the \code{K = 1} criterion axis and performs no target
transformation. It does not convert ordinary inputs or reinterpret rounded
continuous values as a scientific equality model.

Duplicate decoded keys, malformed supported array shapes and unsafe
finite-law integer tokens are rejected before floating conversion. Shape
checks cover the supported JSON binding; the R validator checks the
corresponding metadata, values and equality partition. These checks do not
verify scientific equality, jointness or convergence. Complete finite laws
require the optional \code{gmp} package.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  input <- read_postrank_tie_draws(path)
  input$criterion_ids
  input$equality$criterion_classes
  validate_postrank_tie_draws(input)
}
}
\seealso{
\code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}}, \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}},
\code{\link[=read_postrank_draws]{read_postrank_draws()}}
}
\concept{tie-aware}
