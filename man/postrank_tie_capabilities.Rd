% Please edit documentation in R/tie-solve.R
\name{postrank_tie_capabilities}
\alias{postrank_tie_capabilities}
\title{List Supported Features in Tie-Aware Mode}
\usage{
postrank_tie_capabilities()
}
\value{
A named list containing identifiers (\code{loss = "tie_aware_v1"},
\code{input_domain = "tie-aware-input-0.1"}, \code{backends = c("gurobi", "highs")},
and \code{equality_evidence}) and logical support flags:
\itemize{
\item \code{TRUE}: \code{joint_draws}, \code{exact_finite_laws}, \code{weighted_at_most_G},
\code{full_active_profile_guard}, and \code{label_mip}.
\item \code{FALSE}: \code{staged}, \code{criterionwise_inputs}, \code{typed_coefficients}, \code{q},
\code{minimax}, \code{exact_G}, \code{legacy_baselines_reports_plots}, \code{mc_diagnostics},
\code{uniform_iid_bounds}, \code{regret}, \code{protection_envelopes}, and
\code{numerical_certification}.
}
}
\description{
\code{postrank_tie_capabilities()} returns a static list showing which inputs,
problem settings, solvers, and downstream summaries are supported in
tie-aware mode (the \verb{postrank_tie_*} workflow for posteriors with positive
equality probability under equality-neutral loss). It does not probe whether
\code{"gurobi"} or \code{"highs"} is installed or licensed; use
\code{\link[=postrank_backend_available]{postrank_backend_available()}} for solver checks.
}
\details{
Tie-aware mode supports joint equal-weight draws and complete exact finite
laws on one or more criteria under weighted at-most-\code{G_max} problems solved
by \code{label_mip} with the active-profile equality constraint. Criterion-wise
draw blocks, Gaussian or mixture coefficients, criterion error budgets \code{q},
\code{minimax} objectives, \code{exact_G} grade counts, and \code{"staged"} solving are not
implemented for tie-aware inputs.

Tie-aware objects have \code{print()}, \code{format()}, and \code{summary()} methods, while
ordinary zero-equality baselines, table accessors, HTML reports, plots, Monte
Carlo diagnostics, and IID bounds reject \verb{postrank_tie_*} classes rather than
reinterpreting their equality-neutral loss.
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
