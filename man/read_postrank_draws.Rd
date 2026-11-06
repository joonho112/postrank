% Please edit documentation in R/draws-serialization.R
\name{read_postrank_draws}
\alias{read_postrank_draws}
\title{Read Posterior Draws or an Exact Finite Law from JSON}
\usage{
read_postrank_draws(path)
}
\arguments{
\item{path}{Path to an existing \code{applied-0.1} JSON file.}
}
\value{
A validated \code{postrank_draws} object from \code{\link[=as_postrank_draws]{as_postrank_draws()}}.
Invalid JSON or unsupported input raises a structured error.
}
\description{
The reader imports a saved posterior input, including its target
definitions, ordered IDs and original sampling history. Files in this format
are produced by \code{\link[=write_postrank_draws]{write_postrank_draws()}}.
}
\details{
The reader supports joint equal-weight draws, criterion-wise blocks and
complete exact finite laws. It preserves the singleton criterion dimension
for \code{K = 1} and does not orient, reorder or round supplied targets.
Duplicate decoded JSON keys, invalid JSON numbers and malformed supported
array shapes are rejected. Exact-law integer tokens are checked before
conversion so that unsafe values cannot pass by floating-point rounding.

Supported JSON shape checks and R semantic checks are performed; this is
not a general JSON Schema validation. Required declarations are preserved
without the high-level array route's additional placeholder-text check.
Reading a file does not verify its scientific provenance, jointness or
convergence. Use \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}} for equality-neutral inputs;
this reader does not convert between the two input domains.
}
\examples{
path <- system.file("examples", "synthetic-iid.json", package = "postrank")
draws <- read_postrank_draws(path)
draws$entity_ids
draws$criterion_ids
validate_postrank_draws(draws)$valid
}
\seealso{
\code{\link[=write_postrank_draws]{write_postrank_draws()}}, \code{\link[=as_postrank_draws]{as_postrank_draws()}},
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}}
}
\concept{input}
