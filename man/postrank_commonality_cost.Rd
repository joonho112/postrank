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
\item{fit}{A \code{postrank_fit} or \code{postrank_analysis} object of a public
common-grade problem with a checked grading (\code{incumbent_validated = TRUE}).}

\item{backend, control, strategy}{Solver, controls and search strategy used
for each criterion solve, resolved as in \code{\link[=postrank_solve]{postrank_solve()}}.}

\item{protection}{How \code{q} error budgets from \code{fit} are treated in the
single-criterion problems: \code{"drop"} (the default, solving without \code{q} rows)
or \code{"keep"} (retaining all \code{q} rows). In either case, the common grading
is feasible for every criterion problem.}
}
\value{
A \code{postrank_commonality_cost} list containing \code{table} (one row per
criterion with \code{criterion_id}, \code{common_grade_risk}, \code{own_best_risk} \code{U},
\code{own_lower_bound} \code{L}, \code{cost_lower} \code{max(0, common - U)}, \code{cost_upper}
\code{common - L}, \code{own_status}, \code{own_G}, \code{own_disclosures} and
\code{relation_agreement}), plus \code{settings}, \code{protection}, \code{backend},
\code{strategy}, \code{interpretation}, \code{input_identity}, \code{problem_identity} and
\code{schema_version}.
}
\description{
\code{postrank_commonality_cost()} measures how much posterior expected loss a
single common grading adds on each criterion compared with grading that
criterion on its own under the same \code{tau} and grade-count rules. It solves
one single-criterion optimization problem per criterion, seeding each search
with the common grading.
}
\details{
Solving requires an optimization solver: install the free \code{highs} package
(\code{install.packages("highs")}) and use \code{backend = "highs"} or
\code{options(postrank.backend = "highs")}, or provide a licensed Gurobi
installation (the default). \code{postrank} never switches solvers on its own.

For criterion \code{k}, the cost of imposing the common grading lies in
\verb{[max(0, common_k - U_k), common_k - L_k]}, whose width is at most the
solver's absolute gap \code{U_k - L_k} on criterion \code{k}'s own problem. That
interval reflects optimization bounds on criterion \code{k}'s solve, not
posterior uncertainty about the cost.
}
\examples{
# Inspect a stored commonality-cost result without running a solver:
cc <- postrank_example("toy_commonality")
cc$table[, c("criterion_id", "common_grade_risk", "own_best_risk",
  "cost_lower", "cost_upper")]
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Solve directly with the optional highs package:
toy <- postrank_example("toy_analysis")
postrank_commonality_cost(toy, backend = "highs",
  control = postrank_control(time_limit = 10))
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_plot_commonality]{postrank_plot_commonality()}}, \code{\link[=postrank_compare]{postrank_compare()}},
\code{\link[=postrank_frontier]{postrank_frontier()}}
}
\concept{grids}
