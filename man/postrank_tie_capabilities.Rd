% Please edit documentation in R/tie-solve.R
\name{postrank_tie_capabilities}
\alias{postrank_tie_capabilities}
\title{Check Which Tie-Aware Operations Are Available}
\usage{
postrank_tie_capabilities()
}
\value{
A named list of capability flags, supported backend names, loss
and input-domain identifiers, and accepted equality-evidence types.
A \code{TRUE} flag describes implemented support, not scientific validation
or a numerical certificate.
}
\description{
This fixed record describes the input types, decisions and numerical
operations supported by the separate \verb{postrank_tie_*} functions. It does not
inspect installed solvers, check a license or run an optimization.
}
\details{
Joint draws and complete exact finite laws support weighted
at-most-G label models with the full active-profile guard, using HiGHS
or Gurobi. One criterion is allowed, with its named weight equal to 1.
Criterionwise input blocks, typed coefficients, q budgets, minimax,
exact-G and staged solving are not supported by this route.

Core tie-aware objects have print, format and summary methods. Ordinary
baselines, accessors, reports and plots, and Monte Carlo diagnostics,
uniform IID bounds, regret bounds and protection envelopes do not apply
to these classes. The record reports these limits explicitly.

Equality evidence is either a structural declaration checked against
retained draws or equality across all positive-mass states of a complete
finite law. Coincidence in finitely many sampled values alone is not
proof of almost-sure equality. Using this route does not reinterpret
ordinary postrank objects or silently replace their weak-error loss.
}
\examples{
capabilities <- postrank_tie_capabilities()
capabilities[c("weighted_at_most_G", "q", "minimax", "exact_G")]
capabilities$backends
}
\seealso{
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{\link[=postrank_tie_solve]{postrank_tie_solve()}},
\code{\link[=postrank_backend_available]{postrank_backend_available()}},
\code{vignette("m4-ties-and-withholding", package = "postrank")}
}
\concept{tie-aware}
