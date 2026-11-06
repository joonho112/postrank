% Please edit documentation in R/validate-solution.R
\name{validate_postrank_solution}
\alias{validate_postrank_solution}
\title{Check a Solver Candidate for the Grading Problem}
\usage{
validate_postrank_solution(problem, solution, tolerances = list())
}
\arguments{
\item{problem}{A validated \code{postrank_problem}.}

\item{solution}{Numeric primal vector in the problem's model-column order,
such as \code{fit$raw_solution}, or \code{NULL} when no candidate was returned.
A named grade vector alone is not a primal vector; use \code{\link[=postrank_evaluate]{postrank_evaluate()}}
to score grades without validating the optimization variables.}

\item{tolerances}{Named list of nonnegative finite \code{feasibility},
\code{integrality} and \code{objective} tolerances. Defaults are \code{1e-7}, \code{1e-6}
and \code{1e-7}, respectively.}
}
\value{
A \code{postrank_solution_validation} list with \code{valid}, \code{issues},
\code{warnings}, raw/rounded residuals, \code{integrality_residual}, \code{rounded_solution},
raw labels/pair variables, and \code{tolerances}. For a valid candidate,
\code{grade}, \code{evaluation} and \code{recomputed_raw_objective} describe the checked
action. \code{epigraph_shortfall} and \code{epigraph_repaired} record any permitted
minimax adjustment. \code{validity_basis} is \code{"rounded_integer_solution"}.
Invalid or absent candidates have \code{grade} and \code{evaluation} set to \code{NULL};
malformed problems or tolerance settings raise input errors.
}
\description{
A numerical solver candidate is checked for feasible grades under the
specified problem, and its pairwise relations and posterior risk are
recomputed. The check is performed within \code{\link[=postrank_solve]{postrank_solve()}} and can also be
applied directly to a returned raw solution. Feasibility of a candidate does
not establish optimality.
}
\details{
Integer residuals must be within tolerance before the rounded
variables are accepted. The rounded solution must satisfy bounds and rows,
reconstruct the same pair relations as its grades, and meet the grade cap,
any exact count and error-budget constraints. Raw-primal residuals are
retained as diagnostics and can produce warnings even if the rounded action
passes. Thus \code{valid} refers to the checked action within the tolerances.

For minimax, a shortfall of the continuous auxiliary variable within the
objective tolerance is raised to the action's maximum criterion risk before
checking the rounded constraints. Larger shortfalls are not repaired.
This function checks neither a solver lower bound nor optimality, posterior
calibration or the scientific accuracy of the supplied probabilities.
}
\examples{
problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = .2, G_max = 3L)
absent <- validate_postrank_solution(problem, NULL)
absent$valid
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank_solve(problem, backend = "highs",
    control = postrank_control(time_limit = 10))
  checked <- validate_postrank_solution(problem, fit$raw_solution)
  checked$valid
}
}
\seealso{
\code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}
}
\concept{decision}
