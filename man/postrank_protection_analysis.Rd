% Please edit documentation in R/protection-envelopes.R
\name{postrank_protection_analysis}
\alias{postrank_protection_analysis}
\title{Solve Protection Envelopes and Bound Regret}
\usage{
postrank_protection_analysis(envelopes, backend = NULL, control = list())
}
\arguments{
\item{envelopes}{A \code{postrank_protection_envelopes} object from
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}}.}

\item{backend}{Solver to use, \code{"gurobi"} or \code{"highs"}. If \code{NULL} (the
default), \code{getOption("postrank.backend")} is used, or \code{"gurobi"} (which
requires a license) when unset; install the \code{highs} package and pass
\code{backend = "highs"} to use HiGHS. If the chosen solver package is not
installed or cannot be loaded, \code{postrank_protection_analysis()} stops with
an error before attempting either solve. \code{postrank} never switches solvers
automatically. Uncaught runtime errors escaping \code{\link[=postrank_solve]{postrank_solve()}} (for
example under \code{strategy = "label_mip"} or LP setup) leave \code{inner_fit} or
\code{outer_fit} as \code{NULL}, populate that solve's \verb{attempts$*$error}, and record
\code{"inner_solve_error"} or \code{"outer_solve_error"} in \code{reasons}; under the
default \code{strategy = "staged"}, runtime errors caught during LP cut rounds
or Stage-C MIP return a \code{postrank_fit} with warnings and record
\code{"outer_whole_problem_lower_unavailable"} in \code{reasons}.}

\item{control}{A \code{\link[=postrank_control]{postrank_control()}} object or named control list passed to
each of the two \code{\link[=postrank_solve]{postrank_solve()}} calls (\code{time_limit} applies separately
to the inner solve and the outer solve).}
}
\value{
A \code{postrank_protection_analysis} list containing \code{inner_fit} and
\code{outer_fit} (\code{NULL} when an uncaught solve error occurred), per-solve
metadata in \code{attempts} (\code{inner} and \code{outer}), \code{backend}, \code{control},
\code{solve_count}, \code{public_q}, \code{thresholds}, \code{inner_risk_upper},
\code{outer_whole_problem_risk_lower},
\code{empirical_inner_upper_minus_outer_lower}, \code{delta_w}, \code{computed_value},
\code{formula}, \code{status}, \code{reasons}, \code{interpretation}, \code{assumptions}, identity
hashes (\code{analysis_identity}, \code{envelope_identity}, \code{input_identity},
\code{public_problem_identity}, \code{coefficient_bound_identity}), \code{schema_version},
and status flags. When usable bounds are available, \code{status} and
\code{guarantee_status} are \code{"diagnostic_only"} and \code{bound_computed} is \code{TRUE}
(\code{guarantee_issued}, \code{numerically_verified}, \code{numerical_certification}, and
\code{finite_sample_certificate} remain \code{FALSE}); otherwise \code{computed_value} is
\code{NA_real_}, \code{status} and \code{guarantee_status} are \code{"not_established"}, and
\code{reasons} lists every missing or failed check.
}
\description{
\code{postrank_protection_analysis()} solves the tightened (\code{inner}) and relaxed
(\code{outer}) problems in a protection envelope from
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}} (a pair of empirical problems that shift
criterion error budgets \code{q_k} by \code{-epsilon_k} and \code{+epsilon_k}) to compute
an analytic upper bound on weighted-risk regret relative to the true
budget-constrained family. The two solves run sequentially, and both attempt
records are kept even if the inner solve fails or is infeasible.
}
\details{
Let \eqn{U_{\mathrm{inner}}} be the evaluated empirical risk of the verified
inner grading (\code{analysis$inner_fit$grade}, or
\code{get_grades(analysis$inner_fit)}), \eqn{L_{\mathrm{outer}}} be a
whole-problem empirical risk lower bound from \code{outer_problem}, and
\eqn{\delta_w = \sum_k w_k \varepsilon_k}. When both endpoints are valid and
\eqn{U_{\mathrm{inner}} \ge L_{\mathrm{outer}}}, \code{computed_value} is
\deqn{(U_{\mathrm{inner}} - L_{\mathrm{outer}}) + 2 \delta_w.}
On the simultaneous \code{1 - alpha} IID coefficient event of \code{envelopes$bounds}
(assuming valid numerical feasibility of the inner grading), the inner
grading \code{analysis$inner_fit$grade} satisfies the true posterior \code{q} budgets.
Under the same event and a valid solver-reported whole-outer lower bound, its
true posterior weighted risk exceeds the minimum true posterior weighted risk
over the true \code{q}-protected family by at most \code{computed_value}.

Computing \code{computed_value} requires a checked inner grading without numerical
issues and a usable whole-problem outer lower bound (\code{outer_fit$status$normalized}
in \code{"optimal"}, \code{"feasible_not_certified"}, or \code{"time_limit"}, a recognized
whole-problem \code{outer_fit$objective$bound_source}, and no numerical issues; a
solver \code{"optimal"} status label alone is insufficient). Neither the inner
problem's lower bound nor an outer grading's risk is ever substituted for
\eqn{L_{\mathrm{outer}}}; if \eqn{U_{\mathrm{inner}} < L_{\mathrm{outer}}},
\code{computed_value} is \code{NA_real_} with reason
\code{"outer_lower_above_inner_upper"}. An infeasible inner problem records
\code{"inner_infeasible"} and does not prove that the true protected family is
empty.

See \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}} and \code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}} for the
fixed-sample IID design requirements and signed (unclipped)
\verb{q_k -/+ epsilon_k} threshold construction. Because feasibility tolerances
and solver bounds use ordinary floating-point arithmetic without interval
arithmetic to bound floating-point rounding, this function does not provide a
formal numerical certificate, a posterior probability of constraint
satisfaction, or calibration on new data.
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
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
analysis <- postrank_protection_analysis(
  envelopes,
  backend = "highs",
  control = postrank_control(time_limit = 10, threads = 1)
)
analysis[c("status", "computed_value", "reasons", "guarantee_issued")]
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_protection_envelopes]{postrank_protection_envelopes()}}, \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}},
\code{\link[=postrank_regret_bound]{postrank_regret_bound()}}, \code{\link[=postrank_guarantee_capabilities]{postrank_guarantee_capabilities()}}
}
\concept{reference}
