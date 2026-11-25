% Please edit documentation in R/coefficient-validation.R
\name{validate_postrank_coefficients}
\alias{validate_postrank_coefficients}
\title{Check Conditional Coefficients and Source Calculations}
\usage{
validate_postrank_coefficients(x, recompute = FALSE)
}
\arguments{
\item{x}{A \code{postrank_coefficients} object from
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}

\item{recompute}{Plain logical scalar (default \code{FALSE}). When \code{TRUE}, also
recomputes \code{means} and \code{e} from \code{x$source} and checks agreement.}
}
\value{
\code{TRUE}, invisibly, when all checks pass; otherwise stops with an
error (\code{invalid_coefficients}, \code{stale_coefficient_identity} or
\code{coefficient_projection_mismatch}).
}
\description{
\code{validate_postrank_coefficients()} checks that a \code{postrank_coefficients}
object has intact axes, positive-definite covariances, valid \code{provenance}
SHA-256 digests and unchanged identity hashes, and optionally recalculates
\code{means} and \code{e} from the stored normal or mixture parameters.
}
\details{
With \code{recompute = FALSE}, structure, positive definiteness and SHA-256
object identities are verified without re-evaluating every mixture state.
With \code{recompute = TRUE}, recomputed probabilities must match stored \code{e}
within \code{1e-12} and recomputed means must match within
\code{1e-12 * max(1, abs(recomputed_mean))}.

Passing validation confirms internal consistency of \code{x}; it does not verify
conditional independence in the underlying data, MCMC convergence or
external files. To modify parameters or provenance, call the constructor
again.
}
\examples{
validate_postrank_coefficients(pr_tutorial$one)
validate_postrank_coefficients(pr_tutorial$one, recompute = TRUE)
}
\seealso{
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}, \code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}
}
\concept{coefficients}
