% Please edit documentation in R/decision-frontier.R
\name{postrank_commonality_cost}
\alias{postrank_commonality_cost}
\title{Criterion-Wise Cost of a Common Grade}
\usage{
postrank_commonality_cost(
  fit,
  backend = NULL,
  control = list(),
  strategy = NULL,
  protection = c("drop", "keep")
)
}
\arguments{
\item{fit}{A \code{postrank_fit} or \code{postrank_analysis} of the common weighted
or minimax problem, with a validated grade.}

\item{backend, control, strategy}{Resolved as in \code{\link{postrank_solve}} (\code{backend = NULL}:
option, then Gurobi; \code{strategy = NULL}: \code{control$strategy}) and used for
the criterion problems.}

\item{protection}{\code{"drop"} (default) solves each criterion problem
without the common problem's q rows; \code{"keep"} keeps them. Either way
the common grade is feasible for the criterion problem. These choices
define different own-criterion comparison families; record which was used.}
}
\value{
A \code{postrank_commonality_cost} list whose \code{table} has, per
criterion: the common grade's criterion risk, the criterion's own best
risk (upper bound U) and lower bound L, the cost interval
\code{[common - U, common - L]} (its width is at most the criterion
problem's risk gap, less when the lower end is clipped at zero; a
certified problem's gap is within the absolute or relative gap control),
the own grade's status, grade count and disclosures, and
the relation agreement between the own and common grades. The interval
reflects optimization bounds, not posterior uncertainty about the cost.
}
\description{
The criterion-wise posterior-risk cost of a common grading is assessed by
solving a separate problem for each criterion. Each optimization assigns all
weight to that criterion while retaining the common problem's tau and
grade-count settings. A working optimizer backend is required.
}
\details{
The cost is the increase in criterion risk associated with imposing
a common grade. This is a descriptive comparison under the same posterior
and has no welfare interpretation. The lower endpoint is clipped at zero
because the common action belongs to each comparison family. An unfinished
solve may yield an interval rather than a single cost. With one criterion
there is no conflict between criteria, although an unfinished common solve
can still be suboptimal.
}
\examples{
draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
  package = "postrank", mustWork = TRUE))
pairwise <- postrank_pairwise(draws)
weights <- c(need_A = .6, need_B = .4)
if (requireNamespace("highs", quietly = TRUE)) {
  problem <- postrank_problem(pairwise, weights, tau = .25, G_max = 3L)
  fit <- postrank_solve(problem, backend = "highs", control = list(time_limit = 10))
  postrank_commonality_cost(fit, backend = "highs", control = list(time_limit = 10))
}
}
\concept{grids}
