% Please edit documentation in R/coefficient-validation.R
\name{validate_postrank_coefficients}
\alias{validate_postrank_coefficients}
\title{Check Conditional Coefficients and Source Calculations}
\usage{
validate_postrank_coefficients(x, recompute = FALSE)
}
\arguments{
\item{x}{An object from \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}

\item{recompute}{Logical scalar, default \code{FALSE}. If \code{TRUE}, recompute the
projection from the stored conditional law as well as checking the object.}
}
\value{
Invisible \code{TRUE} on success; invalid structure, altered content, or
an inconsistent recomputed projection raises an error. The object is not repaired.
}
\description{
Gaussian or mixture coefficients are checked for consistency with their
stored input and source records. With \code{recompute = TRUE}, the means and
directional probabilities are recalculated from the supplied law.
}
\details{
The default checks named axes, finite values, covariance geometry,
provenance fields, supported-operation indicators, and content identity.
It does not repeatedly integrate every mixture component.

The optional recomputation requires identical axes and \code{NA} masks. It
compares probabilities to absolute tolerance \code{1e-12} and means to
\verb{1e-12 * max(1, abs(recomputed mean))} element by element. These tolerances
apply to floating-point recalculation; they do not permit changes to the
recorded object.

Passing validation establishes neither a connection to actual observations
nor the scientific truth of conditional independence, source provenance,
or MCMC convergence. It is not a probability-accuracy certificate. To
change a law or its source records, call its constructor again.
}
\examples{
validate_postrank_coefficients(pr_tutorial$one)
validate_postrank_coefficients(pr_tutorial$one, recompute = TRUE)
}
\seealso{
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}},
\code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}
}
\concept{coefficients}
