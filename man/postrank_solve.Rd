% Please edit documentation in R/postrank-solve.R
\name{postrank_solve}
\alias{postrank_solve}
\title{Find Grades and Report Their Optimization Bounds}
\usage{
postrank_solve(problem, backend = NULL, control = list(), strategy = NULL)
}
\arguments{
\item{problem}{A \code{postrank_problem} specifying the supplied probabilities,
loss, grade limit and any supported error-budget or exact-count constraints.}

\item{backend}{\code{NULL} (default), \code{"gurobi"} or \code{"highs"}. An explicit choice
takes precedence; otherwise \code{getOption("postrank.backend")} is used, then Gurobi if unset.
The chosen name and source (\code{"explicit"}, \code{"option"} or \code{"default"}) are
recorded in \code{fit$backend}. HiGHS must be chosen explicitly or through the
option. A missing, failed or timed-out backend is never replaced automatically.}

\item{control}{A \code{\link[=postrank_control]{postrank_control()}} object or named list of time, thread,
seed, gap and tolerance controls. \code{engine} contains staged-search options.
Package progress messages and native solver logs have separate switches.}

\item{strategy}{\code{NULL} uses \code{control$strategy}, or \code{"staged"} if absent.
An explicit \code{"staged"} or \code{"label_mip"} overrides the control object's choice.}
}
\value{
A \code{postrank_fit}. \code{incumbent_validated} identifies whether \code{grade}
and \code{evaluation} are available; \code{solution_validation} retains the independent
check. \code{status} contains \code{raw_code}, \code{raw_message}, \code{normalized} and
\code{termination_reason}. \code{objective} contains \code{primary_action_risk},
\code{risk_upper_bound}, \code{risk_lower_bound}, \code{risk_absolute_gap}, raw objective
values and their conversion, and the \code{bound_source}.
\code{problem}, \code{settings}, \code{backend}, \code{engine}, warnings and numerical issues
preserve the calculation's context. Minimax refinement adds \code{minimax_refine}.
}
\description{
A grading is sought within the family specified by \code{\link[=postrank_problem]{postrank_problem()}}.
Returned grades must satisfy an independent feasibility check. The fit
retains the candidate, its directly recomputed posterior risk, the reported
lower bound and the termination status. These records distinguish the
available action from the numerical conclusions about optimality.
}
\section{Candidate feasibility and optimization bounds}{

A validated candidate's recomputed primary risk is the upper bound U.
A usable lower bound L concerns the whole declared problem; the absolute
risk gap is U-L. For minimax, U is the grade's largest included criterion
risk, not a possibly slack auxiliary variable. A weighted raw gap must be
converted using \code{R = tau + Z/M}; a raw relative gap is not the same as a
relative gap in risk.

\code{optimal} is a numerical conclusion subject to recorded gap controls and
tolerances. A backend's optimal label becomes \code{feasible_not_certified}
if a valid candidate lacks a usable bound or has an excessive gap.
A \code{time_limit} result may
or may not contain a validated grade. With no validated grade, action risk
and gap are unavailable, even if a useful lower bound remains. This is
different from a valid one-grade report withholding all comparisons.

Inconsistent bounds can be rejected while independently validated grades
remain available. Small bound inversions within the recorded objective
tolerance may instead be clamped with a warning. Inspect \code{bound_source},
numerical issues and warnings; these are not exact numerical certificates,
posterior uncertainty intervals, or proof of a unique optimal grade.
}

\section{Search strategies}{

\code{"label_mip"} sends the integer-label model to the selected backend.
\code{"staged"} first constructs candidates using contiguous cuts of several
priority orders and local search. It then solves a linear relaxation with
comparison constraints, including separated triangle inequalities and
disclosure-count bounds implied by the grade limits. This can bound the
full problem even though the initial candidate searches use fixed orders.
If a gap remains and the size/settings permit, it runs a strengthened
label MIP. Gurobi can use the candidate as a MIP start.

Staged-search defaults in \code{control$engine} are \code{local_search_passes = 20},
\code{local_search_starts = 5}, \code{max_cut_rounds = 60}, \code{cuts_per_round = NULL}
(meaning \code{max(200, 10 * n)}), \code{lp_time_share = .5}, \code{mip = "auto"} and
\code{mip_max_n = 200}. \code{mip} may also be \code{"always"} or \code{"never"}; \code{"auto"}
runs the MIP only up to \code{mip_max_n}. With a possible MIP stage, the LP gets
\code{lp_time_share} of the remaining budget. Otherwise it can use the remainder
less a reserve for candidate construction and validation: the largest of
one second, 1\% of the time limit and twice the initial candidate-stage time.
It receives at least the usual LP share. \code{fit$engine$stages} records what
ran, including the LP \code{time_budget} and \code{time_budget_rule}.
}

\section{Interpretation of minimax refinement}{

With \code{minimax_refine = "weighted"}, the first stage minimizes the largest
selected criterion risk. A second stage minimizes the original weighted
risk while retaining the first-stage criterion caps. If any weight is zero,
a third stage minimizes uniform criterion risk while also retaining a cap
on the original weighted objective. No weight perturbation is used.
Centered/scaled internal calculations retain the original public risk units.

Stage 1 receives three quarters of the time budget. Refinement shares
the remainder, with at least one second in total after stage 1; with zero
weights, stage 2 initially receives half and stage 3 the time left.
Heuristic fallbacks share their stage's deadline. Construction and
validation add overhead, so \code{time_limit} is not a strict wall-clock bound.
The final primary status and lower bound come from stage 1 and are checked
against the released action. A candidate that breaches primary caps or
worsens the original weighted objective beyond machine rounding is excluded.

\code{fit$minimax_refine} records stage results, budgets and the released action.
\code{lexicographic_certified} requires primary and original-weighted
certification for that action; \code{pareto_certified} also requires the
zero-weight third stage when applicable. These flags remain subject to
solver gaps and floating-point tolerances. Skipped or uncertified refinement
is reported with a warning when a first-stage action is available.
\code{minimax_refine = "none"} keeps the first-stage action.
\code{fit$backend$options} retains the first-stage options.
}

\examples{
problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = .2, G_max = 3L)
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank_solve(problem, backend = "highs",
    control = postrank_control(time_limit = 10))
  fit$status$normalized
  fit$objective[c("risk_lower_bound", "risk_upper_bound", "risk_absolute_gap")]
}
}
\seealso{
\code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_control]{postrank_control()}},
\code{\link[=validate_postrank_solution]{validate_postrank_solution()}}, \code{\link[=get_risk]{get_risk()}}
}
\concept{decision}
