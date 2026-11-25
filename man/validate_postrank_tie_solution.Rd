% Please edit documentation in R/tie-solution.R
\name{validate_postrank_tie_solution}
\alias{validate_postrank_tie_solution}
\title{Validate a Candidate Solution to a Tie-Aware Problem}
\usage{
validate_postrank_tie_solution(problem, solution, tolerances = list())
}
\arguments{
\item{problem}{A validated \code{postrank_tie_problem} object from
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}.}

\item{solution}{Numeric primal vector in \code{problem$model} column order (such
as \code{fit$raw_solution}), or \code{NULL} when no candidate solution was returned
(which records issue \code{"no_incumbent"}).}

\item{tolerances}{Optional named list with \code{feasibility}, \code{integrality}, and
\code{objective} tolerances; omitted entries use package defaults.}
}
\value{
A \code{postrank_tie_solution_validation} list containing \code{valid},
\code{issues}, \code{warnings}, \code{raw_residuals}, \code{rounded_residuals},
\code{integrality_residual}, \code{rounded_solution}, \code{raw_labels}, \code{raw_pairs},
\code{grade} and \code{evaluation} (both \code{NULL} unless \code{valid} is \code{TRUE}),
\code{recomputed_raw_objective}, \code{validity_basis}, and \code{tolerances}. An absent
candidate (\code{solution = NULL}) has \code{valid = FALSE} and is distinct from a
valid single-grade all-withheld grading.
}
\description{
\code{validate_postrank_tie_solution()} checks whether a raw primal solution
vector rounds to a feasible grading for a \code{postrank_tie_problem} and matches
the equality-neutral loss computed directly by \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}}. A
passing result confirms feasibility within numerical tolerances; it does not
test optimality, uniqueness, or scientific equality declarations.
}
\details{
\code{validate_postrank_tie_solution()} rounds integer and binary variables,
checks \code{integrality_residual}, variable bounds, sparse linear constraints,
positive integer labels, consistency between pair variables and canonical
grade order \code{g[i] < g[j]}, \code{G <= G_max}, and the active-profile equality
constraint (\code{problem$guard$groups}, checked directly on \code{g} independently of
the sparse equality rows). It then evaluates \code{g} with
\code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}} and checks that both the raw objective \code{Z} and
reconstructed risk \code{R0 + Z / M} agree within the scale-aware objective
tolerance.

If the unrounded primal exceeds \code{feasibility} while the rounded integer
solution passes all checks, \code{valid} is \code{TRUE} and \code{warnings} records the raw
residual; \code{\link[=postrank_tie_solve]{postrank_tie_solve()}} additionally checks whether raw residuals
exceed integrality-rounding limits when deciding whether to keep a solver's
lower bound.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
absent <- validate_postrank_tie_solution(problem, NULL)
absent$valid
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank_tie_solve(
    problem,
    backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10)
  )
  checked <- validate_postrank_tie_solution(problem, fit$raw_solution)
  checked$valid
  checked$grade
}
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_tie_solve]{postrank_tie_solve()}}, \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}},
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}
}
\concept{tie-aware}
