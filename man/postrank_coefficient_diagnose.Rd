% Please edit documentation in R/coefficient-diagnostics.R
\name{postrank_coefficient_diagnose}
\alias{postrank_coefficient_diagnose}
\title{Diagnose Integration of a Conditional Expected Risk}
\usage{
postrank_coefficient_diagnose(
  x,
  fit = NULL,
  grade = NULL,
  settings = NULL,
  chain_history = NULL,
  max_trace_bytes = 8 * 1024^2
)
}
\arguments{
\item{x}{An object from \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}

\item{fit}{Optional fit computed from the same input. Its problem, settings,
and released grade are checked; an incumbent is independently revalidated.}

\item{grade}{Optional named fixed grade vector, with smaller grades indicating
higher priority. It must agree with \code{fit} when both are supplied.}

\item{settings}{Weighted-loss settings for a fixed \code{grade} without \code{fit},
including criterion-named \code{weights}, \code{tau}, and \code{G_max}.}

\item{chain_history}{Original retained-history records, each with \code{chain_id}
and ordered \code{retained_iterations}. Required for eligible hyperparameter-MCMC
metrics; not used for a single Gaussian or fixed finite mixture.}

\item{max_trace_bytes}{Nonnegative integer bound on the numeric conditional-risk
output buffers, in bytes. This is not a bound on total process memory.}
}
\value{
A \code{postrank_coefficient_diagnostics} object with the fixed-action
\code{evaluation} when available, a mixture \code{conditional_risk_trace} where
defined, and \code{diagnostics} records that distinguish available metrics from
explicit unavailable reasons. It does not certify convergence or a selected
report's frequentist or posterior accuracy.
}
\description{
The conditional expected risk of a fixed grading is evaluated from Gaussian
or shared-state mixture coefficients. For a mixture, conditional expected
risks are also obtained for the individual shared states. Where the
hyperparameter states were obtained using MCMC and the required original chain
histories are available, these values support diagnostics of the
integration.
}
\details{
The diagnostic traces concern conditional expected risk. They do not
represent realized target losses or their quantiles. A single Gaussian law
has no Monte Carlo trace, and its MCSE is unavailable rather than zero. A
fixed finite mixture is evaluated using its specified weights and has no
Monte Carlo sampling history.

MCMC metrics require history matching all original retained source
coordinates, at least two chains with four iterations each, equal chain
lengths, and regular common spacing. Chains are not truncated, padded, or
interpolated. Matching the records checks history structure, not its truth
or sampler convergence. Missing history, unavailable optional libraries,
inadequate chain layouts, and nonfinite raw metrics retain their reasons.

\code{\link[=postrank_diagnose]{postrank_diagnose()}} dispatches these coefficient inputs here with the
default missing-history behavior. Use this function to supply history.
Target pair-indicator traces, stability solves, cross-fit diagnostics,
target Monte Carlo fragility, and IID target-coefficient bounds are not
supplied by this route. An all-withheld report has structurally constant
risk and cannot diagnose exploration of the target posterior.
}
\examples{
x <- pr_tutorial$one
# A specified report, evaluated without optimization.
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
d <- postrank_coefficient_diagnose(x, grade = grade,
  settings = list(weights = c(score_A = 1), tau = .25, G_max = 3L))
d$evaluation$weighted_risk
d$diagnostics$mcse_mean$unavailable_reason
}
\seealso{
\code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}, \code{\link[=postrank_diagnose]{postrank_diagnose()}},
\code{\link[=postrank_report]{postrank_report()}} for displaying already prepared diagnostics.
}
\concept{coefficients}
