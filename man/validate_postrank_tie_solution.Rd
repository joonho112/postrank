% Please edit documentation in R/tie-solution.R
\name{validate_postrank_tie_solution}
\alias{validate_postrank_tie_solution}
\title{Check a Candidate Solution to a Tie-Aware Problem}
\usage{
validate_postrank_tie_solution(problem, solution, tolerances = list())
}
\arguments{
\item{problem}{A validated object from \code{\link[=postrank_tie_problem]{postrank_tie_problem()}}.}

\item{solution}{Numeric primal vector in sparse-model column order, such
as a tie-aware fit's \code{raw_solution}. \code{NULL} means no candidate was supplied.}

\item{tolerances}{Named list with optional \code{feasibility}, \code{integrality}
and \code{objective} tolerances; omitted values use package defaults.}
}
\value{
A \code{postrank_tie_solution_validation} list recording \code{valid},
\code{issues}, \code{warnings}, raw and rounded residuals, integrality residual,
rounded solution, raw labels/pairs, tolerances and recomputed objective.
Only a valid candidate has a \code{grade} and \code{evaluation}; otherwise both are
\code{NULL}. An absent candidate records \code{no_incumbent} and is distinct from
a valid all-withheld grade.
}
\description{
A numerical candidate is checked for feasible grades under the requested
tie-aware problem and for agreement between its objective and the directly
evaluated loss. A passing result establishes feasibility of the rounded
action within the specified tolerances. Optimality, uniqueness and the
scientific validity of declared equality classes are outside the scope of
this check.
}
\details{
Validation checks rounded variable bounds, sparse constraints,
grade counts, pair relations and the full active-profile guard. It checks
class membership independently of the model's equality rows. The
evaluator then sums strict reversal and distinct-withholding losses
directly, independently of the sparse objective coefficients, and checks
the reconstruction \code{R0 + Z/M}.

Raw residuals are retained even when the rounded action passes. A solver
result may therefore contain a usable grade with numerical warnings or
an unusable bound. Read its status, lower bound and risk gap separately;
this function checks the candidate, not the solver's optimality claim.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, c(S = .6, C = .4), tau = .25, G_max = 3L)
  absent <- validate_postrank_tie_solution(problem, NULL)
  absent$valid
  if (requireNamespace("highs", quietly = TRUE)) {
    fit <- postrank_tie_solve(problem, backend = "highs",
      control = postrank_control(strategy = "label_mip", time_limit = 10))
    checked <- validate_postrank_tie_solution(problem, fit$raw_solution)
    checked$valid
    checked$grade
  }
}
}
\seealso{
\code{\link[=postrank_tie_solve]{postrank_tie_solve()}}, \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}}
}
\concept{tie-aware}
