% Please edit documentation in R/postrank-solve.R
\name{postrank_solve}
\alias{postrank_solve}
\title{Find Grades and Report Their Optimization Bounds}
\usage{
postrank_solve(problem, backend = NULL, control = list(), strategy = NULL)
}
\arguments{
\item{problem}{A \code{postrank_problem} object created by \code{\link[=postrank_problem]{postrank_problem()}}.}

\item{backend}{Solver to use, \code{"gurobi"} or \code{"highs"}. If \code{NULL} (the
default), \code{getOption("postrank.backend")} is used, or \code{"gurobi"} if unset.
The chosen solver and how it was selected (\code{"explicit"}, \code{"option"} or
\code{"default"}) are recorded in \code{fit$backend}. If the chosen solver is not
installed, cannot be loaded, or throws an uncaught R execution error (such
as a missing Gurobi license under \code{strategy = "label_mip"} or LP setup),
the call stops with an error.}

\item{control}{Solver controls from \code{\link[=postrank_control]{postrank_control()}} or a named list of
options (\code{time_limit}, \code{threads}, \code{seed}, \code{absolute_risk_gap},
\code{relative_gap}, \code{strategy}, \code{engine}, \code{verbose}, \code{output}, \code{tolerances}).}

\item{strategy}{Search method, \code{"staged"} or \code{"label_mip"}. If \code{NULL} (the
default), \code{control$strategy} is used, or \code{"staged"} when \code{control} is a
list without \code{strategy}. A non-\code{NULL} \code{strategy} overrides
\code{control$strategy}.}
}
\value{
A \code{postrank_fit} object, a list containing:
\itemize{
\item \code{has_incumbent} and \code{incumbent_validated}: whether the solver returned a
candidate grading ("incumbent"), and whether it passed
\code{\link[=validate_postrank_solution]{validate_postrank_solution()}};
\item \code{grade}, \code{evaluation} and \code{relations}: the checked integer grade vector,
its loss summary from \code{\link[=postrank_evaluate]{postrank_evaluate()}} and its pairwise relation
matrix, each \code{NULL} when \code{incumbent_validated} is \code{FALSE};
\item \code{solution_validation}: the \code{\link[=validate_postrank_solution]{validate_postrank_solution()}} record;
\item \code{status}: list with \code{raw_code}, \code{raw_message}, \code{normalized}
(\code{"optimal"}, \code{"feasible_not_certified"}, \code{"time_limit"},
\code{"infeasible"}, \code{"unbounded"}, \code{"numerical_error"} or \code{"unknown"}) and
\code{termination_reason};
\item \code{objective}: list with \code{primary_action_risk} (upper bound \code{U}),
\code{risk_upper_bound}, \code{risk_lower_bound} (\code{L}, a loss no feasible grading
can beat up to solver and floating-point tolerances), \code{risk_absolute_gap}
(\code{U - L}), raw objective values and \code{bound_source};
\item \code{problem}, \code{settings}, \code{backend}, \code{engine}, \code{runtime}, \code{raw_solution},
\code{raw_backend_result}, \code{warnings}, \code{numerical_issues}, \code{input_identity},
\code{problem_identity}, \code{solution_identity} and \code{schema_version};
\item \code{minimax_refine}: refinement record when
\code{problem$settings$objective == "minimax"} (stage-by-stage results when
\code{minimax_refine = "weighted"}, or \code{list(mode = "none", applied = FALSE)}
when \code{minimax_refine = "none"}).
}
}
\description{
\code{postrank_solve()} solves an optimization problem built by
\code{\link[=postrank_problem]{postrank_problem()}}, checks any candidate grading independently with
\code{\link[=validate_postrank_solution]{validate_postrank_solution()}}, and returns the checked grades, recomputed
posterior expected loss, lower bound and solver status.
}
\details{
Solving requires an optimization solver. HiGHS is free: install the \code{highs}
package (\code{install.packages("highs")}) and pass \code{backend = "highs"} or set
\code{options(postrank.backend = "highs")}. Gurobi (the default when no solver is
specified) is commercial software requiring a license. \code{postrank} never
switches solvers on its own.
}
\section{Optimization status and bounds}{

The solver's \code{status}, \code{risk_lower_bound} and \code{risk_absolute_gap} describe
optimization over the supplied pairwise probabilities up to solver and
floating-point tolerances (they are not exact numerical certificates,
posterior uncertainty intervals, Monte Carlo error bounds, or proof that
the optimal grading is unique). For weighted problems, raw solver
objectives \code{Z} convert to normalized loss via \code{R = tau + Z / M}, so a raw
\code{relative_gap} on centered \code{Z} differs from a relative gap in \code{R}; for
minimax problems, \code{U} is the grade's recomputed largest selected criterion
loss rather than a possibly slack auxiliary variable. In returned fields
and printed output, \code{"risk"} means posterior expected loss, \code{"disclosed"}
means ordered pairs, and \code{"withheld"} means unordered pairs.

For a solver-reported \code{"optimal"} result, a checked grading and a usable
lower bound must meet the gap tolerances. A valid grading with a missing
bound or a gap above tolerance gives \code{"feasible_not_certified"} when the
numerical checks otherwise pass. A missing or invalid grading, or a serious
numerical inconsistency, gives \code{"numerical_error"}. Check \code{incumbent_validated}
before interpreting the grades. Invalid \code{problem}, \code{control} or
\code{backend} arguments, an unavailable solver, and uncaught solver execution
errors (such as \code{"label_mip"} or LP setup failing without an active Gurobi
license) stop the call. Read \code{fit$status} for the overall outcome, including
infeasibility, a time limit, or numerical termination. In staged search,
caught LP round errors appear in \code{fit$engine$stages$lp$status} and its
\code{trace}. A caught final MIP error appears in \code{fit$engine$stages$mip$error}
and \code{fit$warnings}. When
a time limit ends without a checked grading, \code{grade} and \code{evaluation} are
\code{NULL} (\code{risk_absolute_gap = NA}), which is distinct from a valid
one-grade report leaving all pairs unordered (loss \code{tau}). Small bound
inversions (\code{L > U}) within the objective tolerance are clamped to \code{U}
with a warning; larger inversions exclude the bound (\code{risk_lower_bound = NA}).
}

\section{Search strategies}{

\code{"staged"} (the default) first builds candidate gradings from contiguous
cuts along priority orders and local search, then solves a linear
programming (LP) relaxation with separated triangle inequalities
(transitivity constraints on pairwise orderings) and grade-count bounds
(limits on how many pairs \code{G_max} or \code{exact_G} can order) to obtain a
whole-problem lower bound \code{L}, and finally runs a strengthened
mixed-integer program (MIP) if a gap remains and \code{engine$mip} allows it
(passing the best candidate to Gurobi as an initial starting grading).
\code{"label_mip"} sends the integer-label MIP directly to the solver. Model
construction, validation and refinement add overhead, so \code{time_limit} is
not a strict wall-clock cap on the whole R call.

Defaults in \code{control$engine} are \code{local_search_passes = 20L},
\code{local_search_starts = 5L}, \code{max_cut_rounds = 60L}, \code{cuts_per_round = NULL}
(\code{max(200, 10 * n)}), \code{lp_time_share = 0.5}, \code{mip = "auto"} (\code{"auto"},
\code{"always"} or \code{"never"}) and \code{mip_max_n = 200L} (\code{"auto"} runs the MIP
stage when \code{n <= mip_max_n}). When the MIP stage may run, the LP gets
\code{lp_time_share} of the remaining time; otherwise it gets the remaining
time minus a reserve (\code{max(1, 0.01 * time_limit, 2 * elapsed_candidate_stage)}
seconds), never less than \code{lp_time_share} of the remaining time.
\code{fit$engine$stages} records each stage that ran.
}

\section{Minimax refinement}{

When \code{objective = "minimax"} and \code{minimax_refine = "weighted"}, stage 1
(given \code{3/4} of \code{time_limit}) minimizes the largest selected criterion
loss. Stage 2 minimizes the weighted loss subject to keeping the stage-1
minimax cap; if any criterion has weight \code{0}, stage 3 minimizes the
uniform average criterion loss while keeping both caps (splitting the
remaining time, at least 1 second total after stage 1). Weights are never
perturbed, and any candidate that violates earlier caps beyond rounding is
discarded. Top-level \code{fit$status$normalized} and
\code{fit$objective$risk_lower_bound} come from stage 1; skipped or uncertified
later stages record a warning in \code{fit$warnings}. In \code{fit$minimax_refine},
\code{lexicographic_certified} indicates that both stage-1 minimax loss and
stage-2 weighted loss met optimality tolerances, and \code{pareto_certified}
requires stage-3 zero-weight refinement as well when applicable (both
subject to solver gaps and floating-point tolerances).
}

\examples{
# Inspect the fit inside a stored example without running a solver:
stored_fit <- postrank_example("tutorial_one")$fit
stored_fit$status$normalized
get_risk(stored_fit)
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Solve a problem directly with the optional highs package:
problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = 0.2, G_max = 3L)
fit <- postrank_solve(problem, backend = "highs",
  control = postrank_control(time_limit = 10))
fit$status$normalized
get_risk(fit)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_control]{postrank_control()}},
\code{\link[=validate_postrank_solution]{validate_postrank_solution()}}, \code{\link[=get_risk]{get_risk()}}
}
\concept{decision}
