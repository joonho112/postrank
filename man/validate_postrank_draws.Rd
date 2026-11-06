% Please edit documentation in R/draws-class.R
\name{validate_postrank_draws}
\alias{validate_postrank_draws}
\title{Check a Posterior Input and Inspect Its Validation Results}
\usage{
validate_postrank_draws(x, source = NULL)
}
\arguments{
\item{x}{A canonical \code{applied-0.1} named-list payload or a \code{postrank_draws}.}

\item{source}{Reserved; leave \code{NULL}. To compare mapped values with a
\code{posterior} source object, use \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}
}
\value{
A \code{postrank_validation} list with logical \code{valid}, an \code{issues} list
of error codes, paths and messages, and separate check flags. Invalid
payloads are reported in this record rather than constructed as inputs.
}
\description{
The validator checks the target definitions, numerical values, axes and
sampling history required by the ordinary input routes. Its \code{valid} and
\code{issues} fields report whether the input meets those requirements.
}
\details{
The checks cover the supported structures, ordered IDs, target and source
declarations, numeric values, zero-tie policy and sampling history. They
do not change the values or perform a fit. The function does not run a
general JSON Schema validator, so \code{schema_checked} is \code{FALSE} even for a
valid R input. The additional placeholder-text checks of
\code{\link[=postrank_declarations]{postrank_declarations()}} are not applied here.

\code{source_values_checked}, \code{jointness_verified} and \code{convergence_verified}
are separate from \code{valid}. Source-value comparison is retained only when
an existing object's successful \code{\link[=as_postrank_posterior]{as_postrank_posterior()}} audit matches
its current input identity. Structural validity does not establish the
scientific truth of the declarations, model adequacy or convergence.
The tie-aware validator has a different return convention; see
\code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}.
}
\examples{
check <- validate_postrank_draws(postrank_toy)
check$valid
check[c("source_values_checked", "jointness_verified", "convergence_verified")]

# Deliberately omit required context to inspect the reported problem.
bad <- postrank_toy
bad$context <- NULL
validate_postrank_draws(bad)$issues
}
\seealso{
\code{\link[=as_postrank_draws]{as_postrank_draws()}}, \code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}
}
\concept{input}
