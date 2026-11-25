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
\item{pairwise}{Pairwise directional-error source accepted by
\code{\link[=postrank_problem]{postrank_problem()}}, or a \code{postrank_fit} / \code{postrank_analysis} whose
pairwise probabilities and base policy are reused (when reusing a fit or
analysis, supply only \code{tau} and/or \code{q_criterion} + \code{q_grid}).}

\item{weights, G_max, objective, q, exact_G, minimax_criteria, minimax_refine}{Policy arguments passed to \code{\link[=postrank_problem]{postrank_problem()}} when neither \code{settings} nor
a fit/analysis is supplied.}

\item{tau}{Numeric vector of unordered-pair costs in \verb{(0, 0.5]}. May be
omitted only when \code{q_criterion} and \code{q_grid} are supplied together with
\code{settings} or a fit/analysis (whose \code{tau} is then held fixed).}

\item{q_criterion, q_grid}{Optional criterion ID and numeric vector of
expected-error budgets in \verb{[0, 1]} (supply both together or omit both).
When both \code{tau} and \code{q_grid} have multiple values, all combinations are
solved.}

\item{backend, control, strategy}{Solver, controls and search strategy,
resolved as in \code{\link[=postrank_solve]{postrank_solve()}}.}

\item{settings}{Optional \code{\link[=postrank_settings]{postrank_settings()}} object supplying the base
policy (\code{tau} and/or \code{q_criterion} + \code{q_grid} may accompany it, whereas
separate policy arguments stop with \code{settings_conflict}).}
}
\value{
A \code{postrank_frontier} list whose \code{table} has one row per solved
setting with columns \code{tau}, \code{q_value}, \code{status}, \code{G}, \code{N},
\code{disclosure_rate} (\code{N / M}), \code{primary_risk}, \code{weighted_risk},
\code{risk_absolute_gap}, \code{relation_identity}, \verb{E_over_N_<k>} and \verb{risk_<k>},
alongside \code{weights}, \code{G_max}, \code{objective}, \code{q}, \code{exact_G}, \code{q_criterion},
\code{backend}, \code{strategy}, \code{interpretation}, \code{input_identity} and
\code{schema_version}.
}
\description{
\code{postrank_frontier()} solves a grading problem across a grid of unordered-pair
costs \code{tau} (and/or a grid of error budgets \code{q_grid} on one criterion
\code{q_criterion}), summarizing how the fraction of ordered pairs \code{N / M} and
expected wrong-order rates \code{E_k / N} vary across settings.
}
\details{
Solving requires an optimization solver: install the free \code{highs} package
(\code{install.packages("highs")}) and use \code{backend = "highs"} or
\code{options(postrank.backend = "highs")}, or provide a licensed Gurobi
installation (the default). \code{postrank} never switches solvers on its own.

Because changing \code{tau} changes the loss definition itself, compare frontier
rows by their ordered pair counts \code{N}, error rates \code{E_k / N} and grade
relations rather than ranking rows by \code{primary_risk}. Holding the input and
constraint family fixed, exact optima have nondecreasing \code{N} as \code{tau}
increases; if two rows at \code{tau_2 > tau_1} both have valid \code{risk_absolute_gap}
at most \eqn{\epsilon}, then \eqn{N_2 - N_1 \ge -2 \epsilon M / (\tau_2 - \tau_1)}.
Rows without a checked grading record \code{NA} action metrics.
}
\examples{
# Inspect a stored frontier without running a solver:
fr <- postrank_example("toy_frontier")
fr$table[, c("tau", "G", "N", "disclosure_rate", "primary_risk", "status")]
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Solve a three-point tau frontier with the optional highs package:
pw <- postrank_pairwise(postrank_toy)
postrank_frontier(pw, c(need_A = 0.6, need_B = 0.4), tau = c(0.1, 0.25, 0.4),
  G_max = 3L, backend = "highs", control = postrank_control(time_limit = 10))
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}, \code{\link[=postrank_sensitivity]{postrank_sensitivity()}},
\code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}
}
\concept{grids}
