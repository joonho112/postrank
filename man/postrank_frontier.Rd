% Please edit documentation in R/decision-frontier.R
\name{postrank_frontier}
\alias{postrank_frontier}
\title{Disclosure and Error Frontier Over Tau or One Budget}
\usage{
postrank_frontier(
  pairwise,
  weights = NULL,
  tau,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  q_criterion = NULL,
  q_grid = NULL,
  backend = NULL,
  control = list(),
  strategy = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
}
\arguments{
\item{pairwise}{A directional-error source accepted by
\code{\link[=postrank_problem]{postrank_problem()}}, or a \code{postrank_fit} /
\code{postrank_analysis} whose pairwise object and policy are reused (then
only \code{tau} or \code{q_criterion}/\code{q_grid} may be supplied).}

\item{weights, G_max, objective, q, exact_G, minimax_criteria}{As in
\code{\link{postrank_problem}}.}

\item{tau}{A vector of abstention costs.}

\item{q_criterion, q_grid}{Optional criterion ID and vector of q values; each
grid value replaces that criterion's q.}

\item{backend, control, strategy}{Resolved as in \code{\link{postrank_solve}}
(\code{backend = NULL}: option, then Gurobi; no fallback).}

\item{minimax_refine}{Passed to \code{\link{postrank_problem}} for minimax.}

\item{settings}{Optional \code{\link{postrank_settings}} supplying the policy;
\code{tau} (the grid axis) may accompany it, other loose policy arguments
may not (\code{settings_conflict}). For a q-grid with \code{tau} omitted,
the base tau comes from \code{settings} or the reused fit.}
}
\value{
A \code{postrank_frontier} list whose \code{table} has one row per
setting: tau, q value, status, grade count, disclosures N, disclosure rate
N/M, criterion error ratios E_k/N, criterion risks, primary and weighted
risk, the absolute gap and the grade's relation identity.
}
\description{
A grading problem is solved at each withholding-cost or error-budget
setting. The resulting disclosure, criterion error ratios, risks and grade
relations are compared. A working optimizer backend is required. Since a
change in tau changes the loss function, raw risks at different tau values
cannot be used to rank decisions under a common loss.
}
\details{
Holding the input and feasible family fixed, exact optima have
nondecreasing disclosure counts as tau increases. If both actions have
valid absolute risk gaps at most \eqn{\epsilon}, then for
\eqn{\tau_2 > \tau_1} the weaker bound is
\eqn{N_2-N_1\ge-2\epsilon M/(\tau_2-\tau_1)}. Assessment requires both the stored
\code{risk_absolute_gap} and status; a status label alone does not
establish that bound. Changing q or the grade family at the same time
removes the fixed-family comparison. Missing action metrics remain \code{NA}.
The input-specific restrictions of \code{\link[=postrank_problem]{postrank_problem()}} apply to each
new problem; this function does not extend those capabilities.
}
\examples{
draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
  package = "postrank", mustWork = TRUE))
pairwise <- postrank_pairwise(draws)
weights <- c(need_A = .6, need_B = .4)
if (requireNamespace("highs", quietly = TRUE)) {
  postrank_frontier(pairwise, weights, tau = c(.1, .25, .4), G_max = 3L,
    backend = "highs", control = list(time_limit = 10))
}
}
\concept{grids}
