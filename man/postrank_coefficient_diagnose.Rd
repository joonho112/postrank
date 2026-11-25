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
\item{x}{A \code{postrank_coefficients} object from
\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}} or \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}.}

\item{fit}{Optional \code{postrank_fit} computed from \code{x}. Its problem, settings
and checked grading are verified against \code{x}.}

\item{grade}{Optional positive integer grade vector named by \code{x$entity_ids}
(grade 1 = highest priority). Must match \code{fit$grade} when \code{fit} is also
given.}

\item{settings}{Weighted-loss settings (\code{postrank_settings()} or a named
list with \code{weights}, \code{tau} and \code{G_max}), required when \code{grade} is given
without \code{fit}.}

\item{chain_history}{Optional plain list of original MCMC chain records, each
with scalar positive integer \code{chain_id} and strictly increasing integer
vector \code{retained_iterations}. Used only when \code{x} has
\code{source_regime == "hyperparameter_mcmc"}.}

\item{max_trace_bytes}{Nonnegative integer memory cap in bytes for the
\verb{S x (K + 1)} conditional-loss trace arrays (default \code{8 * 1024^2}).}
}
\value{
A \code{postrank_coefficient_diagnostics} list containing \code{evaluation}
(\code{NULL} when no grade is supplied or validated), \code{conditional_risk_trace}
(for mixtures with a grade), the five metric records in \code{diagnostics},
\code{layout}, \code{unavailable_reason}, \code{conditional_risk_mcse_available}, and
\code{interpretation}.
}
\description{
\code{postrank_coefficient_diagnose()} evaluates the expected loss of a fixed
grading under normal or shared-state mixture posterior coefficients, records
state-by-state conditional expected losses for mixtures, and computes MCMC
integration diagnostics (\code{rhat}, \code{ess_bulk}, \code{ess_tail}, \code{ess_mean},
\code{mcse_mean}) when the mixture states came from hyperparameter MCMC and
\code{chain_history} is supplied.
}
\details{
For a mixture posterior, \code{conditional_risk_trace$values} holds the analytic
conditional expected loss given each shared state \code{h_s}, rather than realized
entity-level loss draws or target-loss quantiles. A single normal posterior
has no state trace (\code{unavailable_reason = "analytic_Gaussian_no_hyperstate_MC_trace"}),
and a \code{"fixed_finite_mixture"} uses fixed weights without MCMC sampling
(\code{"fixed_finite_mixture_MC_not_used"}).

Hyperparameter-MCMC metrics require \code{chain_history} covering every chain in
\code{x$source$state_index}, at least 2 chains of equal length (\verb{>= 4} retained
iterations each) and common regular spacing; otherwise \code{diagnostics} records
\code{available = FALSE} with a specific \code{unavailable_reason}. \code{\link[=postrank_diagnose]{postrank_diagnose()}}
calls this function with \code{chain_history = NULL}, so call
\code{postrank_coefficient_diagnose()} directly when supplying \code{chain_history}.
Diagnostics are descriptive summaries, not guarantees of MCMC convergence or
post-selection accuracy.
}
\examples{
x <- pr_tutorial$one
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
d <- postrank_coefficient_diagnose(x, grade = grade,
  settings = list(weights = c(score_A = 1), tau = 0.25, G_max = 3L))
d$evaluation$weighted_risk
d$diagnostics$mcse_mean$unavailable_reason
}
\seealso{
\code{\link[=postrank_coefficient_capabilities]{postrank_coefficient_capabilities()}}, \code{\link[=postrank_diagnose]{postrank_diagnose()}},
\code{\link[=postrank_report]{postrank_report()}}
}
\concept{coefficients}
