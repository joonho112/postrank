% Please edit documentation in R/tie-solve.R
\name{postrank_tie_solve}
\alias{postrank_tie_solve}
\title{Solve a Grading Problem Under Equality-Neutral Loss}
\usage{
postrank_tie_solve(
  problem,
  backend = NULL,
  control = list(),
  strategy = "label_mip"
)
}
\arguments{
\item{problem}{A validated \code{postrank_tie_problem} object from
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}.}

\item{backend}{Solver to use, \code{"gurobi"} or \code{"highs"}. If \code{NULL} (the
default), \code{getOption("postrank.backend")} is used, or \code{"gurobi"} (which
requires a license) when unset; install the \code{highs} package and pass
\code{backend = "highs"} to use HiGHS. \code{postrank} never switches solvers
automatically. Missing or unloadable solver packages and runtime R errors
thrown by the solver (such as Gurobi without an active license) stop the
call with a \code{postrank_backend_unavailable} error, whereas solver
termination outcomes (\code{"optimal"}, \code{"time_limit"},
\code{"feasible_not_certified"}, \code{"infeasible"}, \code{"numerical_error"}, ...) are
returned in \code{status$normalized}.}

\item{control}{Named list of solver controls (\code{time_limit}, \code{threads},
\code{seed}, \code{relative_gap}, \code{absolute_risk_gap}, \code{tolerances}, \code{output},
\code{strategy}, and \code{verbose}, although \code{postrank_tie_solve()} itself prints no
progress messages when \code{verbose = TRUE}) or a \code{\link[=postrank_control]{postrank_control()}} object.
Because \code{\link[=postrank_control]{postrank_control()}} defaults to \code{strategy = "staged"}, pass
\code{postrank_control(strategy = "label_mip", ...)} (or pass
\code{strategy = "label_mip"} explicitly). Staged \code{engine} options are not
supported: in a plain \code{list}, omit \code{engine} or pass \code{engine = list()}; in
\code{\link[=postrank_control]{postrank_control()}}, leave \code{engine} at its defaults.}

\item{strategy}{Must be \code{"label_mip"} (\code{"staged"} search is not supported in
tie-aware mode). When \code{strategy} is omitted in the call and
\code{control$strategy} is present, \code{control$strategy} is used and checked.}
}
\value{
A \code{postrank_tie_fit} list containing \code{schema_version}, \code{loss},
\code{problem_identity}, \code{input_identity}, \code{problem}, \code{settings}, \code{backend},
\code{engine}, \code{control}, \code{capabilities}, \code{status} (\code{raw_code}, \code{raw_message},
\code{normalized}, \code{termination_reason}), \code{has_incumbent},
\code{incumbent_validated}, \code{raw_solution}, \code{solution_validation}, \code{grade},
\code{evaluation}, \code{relations} (\verb{n x n} integer pairwise relation matrix), and
\code{solution_identity} (the last four are \code{NULL} unless \code{incumbent_validated}
is \code{TRUE}), \code{objective}, \code{runtime}, \code{raw_backend_result},
\code{numerical_issues}, and \code{warnings}. \code{incumbent_validated} is \code{TRUE} only
when the rounded candidate passes integer constraint, active-profile
equality, and direct \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}} loss checks, establishing
feasibility within tolerances (not optimality).

In \code{objective}, \code{primary_action_risk} and \code{risk_upper_bound} give the
verified grading's directly evaluated equality-neutral risk \code{U} (\code{NA} when
\code{incumbent_validated} is \code{FALSE}), \code{risk_lower_bound} gives any usable
whole-problem lower bound \code{L = R0 + raw_lower_bound / M} (a loss no
feasible grading can beat according to the solver, or \code{NA} when
unavailable), \code{risk_absolute_gap} gives \code{U - L} (\code{NA} when either bound is
\code{NA}), and \code{offset} gives the all-withheld risk \code{R0 = tau * T / M}, where
\code{M = choose(n, 2)} counts all unordered pairs and \code{T} is the
criterion-weighted expected number of distinct-target pairs.
}
\description{
\code{postrank_tie_solve()} solves a tie-aware grading problem from
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}} by mixed-integer programming (\code{strategy = "label_mip"}) and independently checks any candidate grading before returning
it. It minimizes posterior expected equality-neutral loss (where true target
equality has zero loss whether the pair is ordered or placed in the same
grade), subject to at most \code{G_max} occupied grades and the active-profile
equality constraint (requiring entities declared structurally equal on every
positive-weight criterion to share a grade).
}
\details{
Placing two entities in the same grade leaves them unordered without claiming
equal targets. A valid single-grade (\code{G = 1}) solution has \code{grade} equal to
all \code{1}s, risk \code{R0}, and \code{NA} conditional error ratios (\code{E_over_N}, expected
strict errors per ordered pair, and \code{E_over_D}, expected strict errors per
ordered distinct pair); by contrast, a run without a verified grading (for
example, a time limit reached before finding any feasible integer solution)
has \code{incumbent_validated = FALSE} and \code{grade = NULL}.

Read \code{incumbent_validated}, \code{status$normalized}, \code{objective$risk_lower_bound},
and \code{objective$risk_absolute_gap} together:
\itemize{
\item A raw \code{"optimal"} status becomes \code{"feasible_not_certified"} (keeping
the verified \code{grade} and any valid loose \code{risk_lower_bound}) when a
usable whole-problem lower bound is missing or \code{risk_absolute_gap}
exceeds \code{max(absolute_risk_gap, relative_gap * abs(U - R0))} beyond
floating-point comparison roundoff.
\item If a solver's lower bound exceeds \code{U} by at most the objective
tolerance (scaled to the raw objective magnitude), it is clamped to \code{U}
(\code{risk_absolute_gap = 0}, \code{bound_inversion_within_tolerance = TRUE}) with
a warning. Larger bound inversions, unrounded solver constraint
violations larger than integer-rounding tolerances can explain, or other
backend consistency/numerical issues (such as objective mismatch or
numerical termination) set \code{status$normalized = "numerical_error"} and
exclude \code{risk_lower_bound} while keeping a valid rounded \code{grade};
non-eligible statuses such as \code{"unknown"} also exclude
\code{risk_lower_bound}.
\item Solver statuses and gaps describe optimization of the supplied
problem within floating-point tolerances; they do not provide a formal
numerical certificate or measure posterior or Monte Carlo uncertainty.
Multiple optimal gradings may exist with different occupied grade counts
\code{G} and different downstream policy or funding mappings.
}

Tie-aware solving supports weighted at-most-\code{G_max} problems only (\code{minimax},
\code{q} error budgets, and \code{exact_G} are not supported) and does not verify
scientific equality or sampling declarations in the input. Tie-aware fits
provide \code{print()}, \code{format()}, and \code{summary()} methods, and expose grades and
losses via \code{fit$grade}, \code{fit$evaluation}, and \code{fit$relations}. Ordinary
zero-equality functions (\code{get_grades()}, \code{postrank_compare()},
\code{postrank_report()}, \verb{postrank_plot_*()}, Monte Carlo diagnostics, and IID
bounds) do not accept \verb{postrank_tie_*} objects; see
\code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
if (requireNamespace("highs", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
  fit <- postrank_tie_solve(
    problem,
    backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10)
  )
  print(fit)
  fit$grade
  fit$objective[c("primary_action_risk", "risk_lower_bound", "risk_absolute_gap")]
}
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}},
\code{\link[=validate_postrank_tie_solution]{validate_postrank_tie_solution()}}, \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}
}
\concept{tie-aware}
