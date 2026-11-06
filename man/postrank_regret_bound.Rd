% Please edit documentation in R/risk-regret-bounds.R
\name{postrank_regret_bound}
\alias{postrank_regret_bound}
\title{Bound Weighted Risk with IID and Optimization Errors}
\usage{
postrank_regret_bound(fit, bounds)
}
\arguments{
\item{fit}{A normalized \code{postrank_fit} for the weighted problem on exactly
the input used for \code{bounds}. At-most-G and exact-G families are supported
when held fixed. Empirical \code{q} protections and minimax are unsupported here.}

\item{bounds}{A matching object from \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}.}
}
\value{
A \code{postrank_regret_bound} object containing \code{delta_w}, the usable
absolute risk gap \code{eta}, and \code{regret_upper_bound} when established.
Missing or unusable gap information produces \code{NA} with
\code{guarantee_status = "not_established"} and an explicit reason. Invalid or
mismatched inputs raise an error. A computed result remains an uncertified
conditional floating-point reference.
}
\description{
A conditional regret reference is calculated for a weighted report selected
from the same fixed action family as its comparator. Probability
approximation error is combined with an absolute optimization gap for the
complete empirical problem. The resulting bound concerns risk rather than
differences between grade vectors.
}
\details{
Write \eqn{\delta_w=\sum_k w_k\varepsilon_k}. On the simultaneous
coefficient event, true supplied-law regret is at most
\eqn{2\delta_w+\eta}, assuming a valid empirical whole-problem gap
\eqn{\eta=U-L}. Both the chosen action and the true-risk comparator must
belong to the same nonempty fixed family. The function records that
assumption; it cannot verify that the analyst fixed the family in advance.

The fit's incumbent is independently revalidated. The gap must be the
normalized absolute gap in risk units from the same complete problem.
A raw objective gap, relative gap, restricted candidate-set lower bound,
or status label alone is insufficient. A numerically validated but
unfinished solve can be usable when it retains the required whole-problem
bound. Numerical issues or inconsistent bounds prevent the calculation.

Empirical protection constraints can change the feasible family when
coefficients change, so the common-family argument does not apply to them.
Use \code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}} and \code{\link[=postrank_protection_analysis]{postrank_protection_analysis()}}
for that separate construction. The reference certifies neither arithmetic
nor backend bounds, posterior calibration, or a unique selected grade.
}
\examples{
bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025),
  design = list(sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"))
problem <- postrank_problem(postrank_pairwise(postrank_toy),
  weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
\dontrun{
# Optional native solve; requires an installed HiGHS backend.
fit <- postrank_solve(problem, backend = "highs",
  control = postrank_control(time_limit = 10, threads = 1))
reference <- postrank_regret_bound(fit, bounds)
reference[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
}
}
\seealso{
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}, \code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}
}
\concept{reference}
