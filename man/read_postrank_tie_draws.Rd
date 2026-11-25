% Please edit documentation in R/tie-serialization.R
\name{read_postrank_tie_draws}
\alias{read_postrank_tie_draws}
\title{Read a Tie-Aware Posterior Input from JSON}
\usage{
read_postrank_tie_draws(path)
}
\arguments{
\item{path}{Path to an existing \code{"tie-aware-input-0.1"} JSON file.}
}
\value{
A validated \code{postrank_tie_draws} object from
\code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.
}
\description{
\code{read_postrank_tie_draws()} reads a \code{"tie-aware-input-0.1"} JSON file into a
validated \code{postrank_tie_draws} object for tie-aware mode (the workflow for
posteriors in which distinct entities can be equal with positive probability
under equality-neutral loss, where true equality has zero loss). Files
written by \code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}} round-trip with identical numerical
values, IDs, equality partitions, and \code{input_identity}.
}
\details{
Supports both \code{input_kind = "equal_weight_draws"} (joint IID or MCMC draws,
preserving singleton criterion axes when \code{K = 1}) and
\code{"exact_finite_posterior"} (which requires optional package \code{gmp}). Before
floating-point conversion, \code{read_postrank_tie_draws()} scans the raw JSON
structure against \code{inst/schema/tie-draws-schema.json}, rejecting duplicate
object keys, malformed array shapes, and integer tokens outside safe-integer
range (\code{2^53 - 1}), and then runs \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.

Use \code{\link[=read_postrank_draws]{read_postrank_draws()}} for ordinary zero-equality inputs; this reader
does not convert ordinary inputs or treat rounded continuous draws as a valid
equality model. Schema and R validation do not verify scientific equality or
MCMC convergence.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
input <- read_postrank_tie_draws(path)
input$criterion_ids
input$equality$criterion_classes
validate_postrank_tie_draws(input)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=write_postrank_tie_draws]{write_postrank_tie_draws()}}, \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}},
\code{\link[=read_postrank_draws]{read_postrank_draws()}}
}
\concept{tie-aware}
