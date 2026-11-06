% Please edit documentation in R/tie-input.R
\name{validate_postrank_tie_draws}
\alias{validate_postrank_tie_draws}
\title{Check an Equality-Neutral Posterior Input}
\usage{
validate_postrank_tie_draws(x)
}
\arguments{
\item{x}{A \code{postrank_tie_draws} from \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.}
}
\value{
Invisible \code{TRUE} on success. Invalid or changed input raises a
structured error; unlike \code{\link[=validate_postrank_draws]{validate_postrank_draws()}}, this function does
not return a record with \code{valid = FALSE}.
}
\description{
The validator checks numerical values, declared equality classes and
sampling history for a tie-aware analysis. It also detects changes
introduced after the object was constructed by \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.
}
\details{
Checks cover ordered axes, required source descriptions, sampling history,
exact within-class equality and the object's content identity. Scientific
equality classes for Monte Carlo draws remain declarations about the model;
their agreement with finitely many draws is not proof of almost-sure
equality. Complete finite laws determine equality from all positive-mass
states. Validation does not establish scientific provenance, jointness,
stationarity or convergence. Ordinary \code{postrank_draws} inputs are not
accepted, and reusing the constructor does not silently accept mutations.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
    package = "postrank"))
  valid <- validate_postrank_tie_draws(input)
  valid
  input$equality$criterion_classes
}
}
\seealso{
\code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}, \code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}}
}
\concept{tie-aware}
