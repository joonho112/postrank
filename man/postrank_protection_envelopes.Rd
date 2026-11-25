% Please edit documentation in R/protection-envelopes.R
\name{postrank_protection_envelopes}
\alias{postrank_protection_envelopes}
\title{Build Inner and Outer Problems for Error Budgets}
\usage{
postrank_protection_envelopes(problem, bounds)
}
\arguments{
\item{problem}{Original public weighted \code{postrank_problem} from
\code{\link[=postrank_problem]{postrank_problem()}} with non-empty \code{q} budgets (\code{objective = "weighted"}
and no existing \code{protection_envelope}). \code{objective = "minimax"} is not
supported.}

\item{bounds}{A \code{postrank_iid_bounds} object from \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
built on the exact same posterior input, retaining every declared criterion
in \code{problem} (including zero-weight criteria) in the same order.}
}
\value{
A \code{postrank_protection_envelopes} list containing \code{public_problem},
\code{public_q}, \code{bounds}, \code{inner_problem}, \code{outer_problem}, signed
\code{thresholds = list(inner = ..., outer = ...)}, \code{envelope_identity}, and
status fields (\code{status = "diagnostic_only"}, \code{bound_computed = FALSE}, and
\code{guarantee_issued = FALSE}). This object does not issue a statistical or
numerical certificate.
}
\description{
\code{postrank_protection_envelopes()} builds two empirical grading problems from
a weighted problem that carries criterion error budgets \code{q_k}. Here a
\emph{protection envelope} is the pair of tightened (\code{inner}, using
\code{q_k - epsilon_k}) and relaxed (\code{outer}, using \code{q_k + epsilon_k}) problems
formed with simultaneous IID probability radii \code{epsilon_k} from
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}} so that, on the simultaneous \code{1 - alpha} event, their
feasible sets bracket the unknown true budget-constrained set. Building the
envelopes runs no solver.
}
\details{
For each protected criterion \code{k}, the empirical linear inequality is
\eqn{\widehat E_k \le (q_k - \varepsilon_k) N} in \code{inner_problem} and
\eqn{\widehat E_k \le (q_k + \varepsilon_k) N} in \code{outer_problem}, where \code{N}
is the number of disclosed (ordered) pairs and \eqn{\widehat E_k} is the
empirical sum of wrong-direction probabilities on criterion \code{k}. The signed
thresholds \code{q_k - epsilon_k} and \code{q_k + epsilon_k} are internal linear
constraint coefficients and are not clipped to \verb{(0, 1)} (nor accepted by the
public \code{q} argument of \code{\link[=postrank_settings]{postrank_settings()}}).

On the simultaneous \code{1 - alpha} coefficient event (and subject to valid
numerical feasibility checks), every grading feasible for \code{inner_problem}
satisfies the true posterior \code{q} budgets, and every grading satisfying the
true posterior \code{q} budgets is feasible for \code{outer_problem}. When
\code{q_k - epsilon_k < 0}, no grading with \code{N > 0} can satisfy that inner row,
whereas the single-grade all-withheld grading has \code{N = 0} and remains
feasible whenever \code{G = 1} is allowed (\code{exact_G >= 2} excludes \code{G = 1}).
Therefore an infeasible \code{inner_problem} does not prove that the true
budget-constrained problem is infeasible. Setting a criterion's objective
\code{weight} to \code{0} keeps any explicit \code{q_k} budget and its \code{epsilon_k} radius
active.

Pass the returned object to \code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}} to solve both
problems and compare an inner grading against an outer whole-problem lower
bound.
}
\examples{
bounds <- postrank_iid_bounds(
  postrank_toy,
  alpha = 0.05,
  alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
  design = list(
    sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE,
    adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"
  )
)
problem <- postrank_problem(
  postrank_pairwise(postrank_toy),
  weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25,
  G_max = 3L,
  q = c(need_A = 0.2)
)
envelopes <- postrank_protection_envelopes(problem, bounds)
envelopes$thresholds
identical(envelopes$public_problem, problem)
}
\seealso{
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}, \code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}},
\code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}
}
\concept{reference}
