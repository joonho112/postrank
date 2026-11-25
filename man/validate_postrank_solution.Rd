% Please edit documentation in R/validate-solution.R
\name{validate_postrank_solution}
\alias{validate_postrank_solution}
\title{Check a Solver Candidate for the Grading Problem}
\usage{
validate_postrank_solution(problem, solution, tolerances = list())
}
\arguments{
\item{problem}{A validated \code{postrank_problem} object from
\code{\link[=postrank_problem]{postrank_problem()}}.}

\item{solution}{Numeric primal vector in the column order of
\code{problem$model} (such as \code{fit$raw_solution}), or \code{NULL} when no candidate
was returned. To evaluate a named grade vector directly without primal
model variables, use \code{\link[=postrank_evaluate]{postrank_evaluate()}}.}

\item{tolerances}{Named list of nonnegative finite tolerances overriding
the defaults \code{feasibility = 1e-7}, \code{integrality = 1e-6} and
\code{objective = 1e-7}.}
}
\value{
A \code{postrank_solution_validation} list containing:
\itemize{
\item \code{valid}: \code{TRUE} when the rounded integer solution passes all variable,
constraint, grade-relation and objective checks;
\item \code{issues} and \code{warnings}: list of failure records and character vector of
raw-primal residual notes;
\item \code{grade}, \code{evaluation} and \code{recomputed_raw_objective}: the checked grade
vector and its \code{\link[=postrank_evaluate]{postrank_evaluate()}} summary (\code{NULL} / \code{NA} when \code{valid}
is \code{FALSE});
\item \code{raw_residuals}, \code{rounded_residuals}, \code{integrality_residual},
\code{rounded_solution}, \code{raw_labels}, \code{raw_pairs}, \code{epigraph_shortfall},
\code{epigraph_repaired}, \code{validity_basis} (\code{"rounded_integer_solution"})
and \code{tolerances}.
}
}
\description{
\code{validate_postrank_solution()} checks whether a raw primal vector returned
by an optimization solver defines a feasible grading for \code{problem}, and
recomputes its pairwise relations and posterior expected loss.
\code{\link[=postrank_solve]{postrank_solve()}} runs this check automatically on every candidate.
}
\details{
Integer and binary variables must lie within \code{tolerances$integrality} of an
integer before rounding. The rounded solution must satisfy variable bounds
and linear constraints within \code{tolerances$feasibility}, match the pair
orderings implied by its grades, satisfy \code{G_max}, any \code{exact_G} and any \code{q}
error budgets, and match the recomputed objective within
\code{tolerances$objective}. Raw (unrounded) primal residuals exceeding
\code{tolerances$feasibility} are recorded in \code{warnings}. For minimax problems,
an auxiliary \code{t} variable falling below the maximum selected criterion loss
by at most \code{tolerances$objective} is raised to that value before checking
rounded constraints.

Passing \code{validate_postrank_solution()} confirms feasibility of the candidate
grading, not solver optimality, lower-bound validity or model adequacy.
}
\examples{
one <- postrank_example("tutorial_one")
checked <- validate_postrank_solution(one$problem, one$fit$raw_solution)
checked$valid

absent <- validate_postrank_solution(one$problem, NULL)
absent$valid
absent$issues[[1]]$code
}
\seealso{
\code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}, \code{\link[=postrank_control]{postrank_control()}}
}
\concept{decision}
