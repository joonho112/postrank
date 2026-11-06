% Please edit documentation in R/tie-solve.R
\name{postrank_tie_solve}
\alias{postrank_tie_solve}
\title{Choose Grades Under Equality-Neutral Loss}
\usage{
postrank_tie_solve(
  problem,
  backend = NULL,
  control = list(),
  strategy = "label_mip"
)
}
\arguments{
\item{problem}{A validated object from \code{\link[=postrank_tie_problem]{postrank_tie_problem()}}.}

\item{backend}{\code{NULL}, \code{"highs"} or \code{"gurobi"}. The explicit argument takes
precedence over \code{getOption("postrank.backend")}, then the default Gurobi.
Choose \code{"highs"} explicitly to use HiGHS. There is no backend fallback.}

\item{control}{Named time, thread, seed, gap and tolerance controls, or a
\code{postrank_control} with \code{strategy = "label_mip"}. Nonempty staged-engine
controls are unsupported in this mode.}

\item{strategy}{\code{"label_mip"} only. When omitted, an explicit strategy in
\code{control} is used and checked; otherwise the label model is used.}
}
\value{
A \code{postrank_tie_fit} with the problem, settings, backend, raw solver
result, status, validation, objective records and numerical warnings.
\code{incumbent_validated} indicates whether \code{grade} and \code{evaluation} are
available. Only a candidate passing independent rounded-primal,
active-profile and direct-loss checks receives grades.

The objective record includes validated action risk as an upper bound,
any usable whole-problem lower bound, the absolute risk gap, and raw
units/scale/offset. Bounds convert as \code{R0 + raw_bound/M}, where
\code{R0 = tau * T/M} is the all-withheld baseline. Unavailable action or bound
quantities are \code{NA}.
}
\description{
A prepared tie-aware problem is solved by mixed-integer optimization, and
its candidate is checked independently before grades are returned. The
objective minimizes weighted expected strict errors and distinct-comparison
withholding costs, subject to the grade cap and active-profile equality
guard. A validated candidate may remain available when optimization
terminates early.
}
\details{
A shared grade withholds a comparison; it does not assert latent
equality. A valid single-grade action has risk R0 and undefined
conditional error ratios. A solve without validated grades instead has
\code{grade = NULL}; it is not reported as an all-withheld action.

Inspect \code{incumbent_validated}, \code{status}, \code{objective$risk_lower_bound} and
\code{objective$risk_absolute_gap} together. A validated candidate establishes
feasibility within tolerance, not optimality. A rejected solver bound can
coexist with a retained grade. A raw optimal status becomes
\code{"feasible_not_certified"} when a usable whole-problem lower bound is
missing or the risk gap exceeds the requested threshold, allowing only
comparison roundoff. The threshold is the larger of \code{absolute_risk_gap}
and \code{relative_gap * abs(U - R0)}, where \code{U} is the validated action risk.
The valid grade, raw status, and any valid loose lower bound are retained.
Other termination statuses are not promoted. An optimal result remains
subject to floating-point tolerances, including the existing tolerance-scale
bound-inversion clamp, and does not constitute a numerical certificate;
the gap concerns the supplied optimization problem, not posterior or
Monte Carlo uncertainty. Multiple optima may have different grade counts
and imply different funding mappings.

This route supports weighted at-most-G decisions only. It does not run
the staged engine, minimax refinement, q protection or exact-G decisions.
Ordinary baselines, accessors, HTML reports, plots and Monte Carlo
guarantees do not accept tie-aware objects. Read \code{fit$grade} and
\code{fit$evaluation}, or use the tie-aware print, format and summary methods.
The optimizer does not verify the scientific declarations in the input.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE) &&
    requireNamespace("highs", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, c(S = .6, C = .4), tau = .25, G_max = 3L)
  fit <- postrank_tie_solve(problem, backend = "highs",
    control = postrank_control(strategy = "label_mip", time_limit = 10))
  fit
  fit$grade
  fit$objective[c("primary_action_risk", "risk_lower_bound", "risk_absolute_gap")]
}
}
\seealso{
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}},
\code{\link[=validate_postrank_tie_solution]{validate_postrank_tie_solution()}}, \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}
}
\concept{tie-aware}
