% Please edit documentation in R/problem-class.R
\name{postrank_problem}
\alias{postrank_problem}
\title{Build a Problem for Choosing Common Grades}
\usage{
postrank_problem(
  pairwise,
  weights = NULL,
  tau = NULL,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
}
\arguments{
\item{pairwise}{A validated \code{postrank_pairwise}, \code{postrank_coefficients},
or \code{\link[=postrank_probabilities]{postrank_probabilities()}} object. Problem construction from Gaussian/
mixture coefficients or supplied probabilities currently supports weighted
at-most-G problems only, without q, exact-G or minimax modes.}

\item{weights}{Nonnegative finite criterion-named weights summing to one.
Include every criterion exactly once, including weight 1 for a single
criterion, unless using \code{settings}. No automatic normalization is performed.}

\item{tau}{Cost of withholding a comparison, \verb{0 < tau <= 0.5}.}

\item{G_max}{Positive integer upper bound on occupied grades, no larger than
the number of entities. Fewer grades are permitted unless \code{exact_G} is set.}

\item{objective}{\code{"weighted"} or \code{"minimax"}: minimize the weighted average
or largest selected criterion's expected risk.}

\item{q}{Optional uniquely criterion-named error budgets in \verb{[0, 1]}.
Each requires \code{E_k <= q_k * N}, including a protected criterion with zero
objective weight. At N=0 this count constraint holds but \code{E_k/N} is undefined.}

\item{exact_G}{Optional exact number of nonempty grades, at most \code{G_max}.}

\item{minimax_criteria}{Optional nonempty set of criterion IDs for minimax;
\code{NULL} includes all criteria. Only allowed for the minimax objective.}

\item{minimax_refine}{\code{"weighted"} (default) or \code{"none"}. For minimax,
weighted refinement minimizes the original weighted risk within the
primary cap. If any weight is zero, a further stage minimizes uniform
criterion risk while also retaining a cap on that original weighted risk.
Weights are never perturbed. See \code{\link[=postrank_solve]{postrank_solve()}} for the qualifications
of the recorded refinement conclusions. Ignored for weighted problems.}

\item{settings}{Optional \code{\link[=postrank_settings]{postrank_settings()}} instead of separate policy
arguments; explicitly supplying both is a \code{settings_conflict} error.
Unlike the separate \code{G_max} argument, this route caps an oversized grade
limit at the number of entities. An exact count is never relaxed.}
}
\value{
A \code{postrank_problem} list containing \code{pairwise}, \code{settings}, the
sparse \code{model}, variable \code{index}, \code{pair_map}, total pair count \code{M}, and
\code{objective_units} for converting raw objectives to risk. Input/problem
identities and builder/schema versions support subsequent validation.
Minimax problems also contain \code{minimax_diagnostics$degenerate_criteria}:
selected criteria whose directional errors are all at least tau. Their
risk cannot be below tau, so the minimax value is at least tau and equals
tau when all withholding is allowed.
}
\description{
The constructor defines the posterior loss and admissible grade reports for
\code{\link[=postrank_solve]{postrank_solve()}}. Smaller grades indicate higher priority and shared
grades withhold comparisons. Construction of the optimization problem does
not run a solver or estimate the posterior.
}
\details{
Expected risk is conditional on the supplied posterior and chosen
targets. Error budgets limit posterior expected wrong fractions when N>0;
they do not ensure that every realized report has that error rate.
Minimax uses the maximum of expected criterion risks, not the expectation
of their statewise maximum. Use \code{\link[=postrank_evaluate]{postrank_evaluate()}} to score a supplied
action without solving; evaluation alone does not check this action family.
}
\examples{
one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = .2, G_max = 3L)
one$objective_units
pw <- postrank_pairwise(postrank_toy)
protected <- postrank_problem(pw, weights = c(need_A = .6, need_B = .4),
  tau = .25, G_max = 3L, q = c(need_B = .3), exact_G = 2L)
protected$settings[c("G_max", "exact_G", "q")]
}
\seealso{
\code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}
}
\concept{decision}
