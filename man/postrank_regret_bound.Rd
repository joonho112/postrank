% Please edit documentation in R/risk-regret-bounds.R
\name{postrank_regret_bound}
\alias{postrank_regret_bound}
\title{Bound Weighted Risk Regret Under Fixed-Sample IID Draws}
\usage{
postrank_regret_bound(fit, bounds)
}
\arguments{
\item{fit}{A \code{postrank_fit} (for example \code{analysis$fit}) solved on the exact
same input as \code{bounds} with \code{objective = "weighted"} and no criterion error
budgets (\code{q = NULL}). Both \code{at-most-G_max} and \code{exact_G} families are
supported when fixed beforehand; \code{objective = "minimax"} and empirical \code{q}
constraints stop with an error.}

\item{bounds}{A matching \code{postrank_iid_bounds} object from
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}.}
}
\value{
A \code{postrank_regret_bound} list containing \code{weights}, \code{epsilon},
weighted probability error \code{delta_w}, whole-problem solver gap \code{eta},
\code{regret_upper_bound} (\code{2 * delta_w + eta} when established, otherwise
\code{NA_real_}), \code{eta_source}, \code{unavailable_reason}, \code{action_space}, and status
flags. When \code{eta} is usable, \code{guarantee_status} is \code{"conditional_bound"}
(\code{guarantee_issued} and \code{numerically_verified} remain \code{FALSE}); when \code{eta}
is missing or inconsistent, \code{regret_upper_bound} is \code{NA_real_} with
\code{guarantee_status = "not_established"} and \code{unavailable_reason} stating
why. Invalid or mismatched inputs stop with an error.
}
\description{
\code{postrank_regret_bound()} combines simultaneous IID probability radii from
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}} with a solver's whole-problem risk gap to compute an
analytic upper bound on posterior weighted-risk regret over a fixed grading
family. The bound applies to posterior expected loss rather than differences
between grade vectors.
}
\details{
Let \eqn{\delta_w = \sum_k w_k \varepsilon_k}. On the simultaneous
\eqn{1 - \alpha} coefficient event of \code{bounds}, and given a valid absolute
risk gap \eqn{\eta = U - L} for the complete empirical problem, the chosen
grading's true posterior weighted risk exceeds the minimum true posterior
weighted risk over the same fixed grading family by at most
\eqn{2 \delta_w + \eta}. Both the selected grading and the comparator must
belong to the same non-empty grading family fixed prior to sampling;
\code{postrank} records that assumption without verifying prior fixation.

\code{postrank_regret_bound()} re-runs \code{\link[=validate_postrank_solution]{validate_postrank_solution()}} on
\code{fit$raw_solution} and checks that \code{fit} has a verified grading, no numerical
issues, and a whole-problem lower bound consistent with \code{fit}'s risk units
(including lower bounds clamped within one objective tolerance when
\code{bound_inversion_within_tolerance} is \code{TRUE}). An unfinished solve (such as
\code{"time_limit"}) is usable when it retains a valid whole-problem lower bound;
a raw objective gap, relative gap, restricted candidate-set bound, or solver
status label alone is never substituted.

Empirical error budgets \code{q} depend on estimated probabilities and can change
which gradings are feasible, so use \code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}} and
\code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}} when \code{q} is set. Because the formula is
evaluated in ordinary floating-point arithmetic from solver-reported bounds,
it does not provide a formal numerical certificate or imply a unique optimal
grading.
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
toy <- postrank_example("toy_analysis")
ref <- postrank_regret_bound(toy$fit, bounds)
ref[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
}
\seealso{
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}, \code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}},
\code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}
}
\concept{reference}
