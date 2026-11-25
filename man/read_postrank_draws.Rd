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
Malformed JSON, schema mismatches or invalid input values stop the call
with a structured error.
}
\description{
\code{read_postrank_draws()} reads a saved posterior input from a JSON file in
\code{postrank}'s \code{applied-0.1} JSON schema, restoring its values, entity and
criterion order, target descriptions and sampling history. Files in this
format are written by \code{\link[=write_postrank_draws]{write_postrank_draws()}}.
}
\details{
Joint equal-weight draws (\code{joint_draws}), separate criterion-wise matrices
(\code{criterion_blocks}) and exact finite posterior laws (\code{finite_law}) are
supported. Singleton criterion dimensions (\code{K = 1}) are kept, and target
values are never negated, reordered or rounded on import. Before decoding,
the reader rejects duplicate JSON object keys, nonfinite or underflowing
numbers, and \code{finite_law} integer tokens outside the exact 53-bit integer
range (\verb{<= 9007199254740991}), then checks the JSON structure against the
installed \code{draws-schema.json} specification and runs
\code{\link[=as_postrank_draws]{as_postrank_draws()}}.

Required descriptions are checked for presence and non-empty text without
the placeholder-word list of \code{\link[=postrank_declarations]{postrank_declarations()}}. Reading a file does
not verify scientific identification, jointness or MCMC convergence. For
exact-tie inputs, use \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}.
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
