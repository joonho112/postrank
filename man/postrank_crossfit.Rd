% Please edit documentation in R/mc-diagnostics.R
\name{postrank_crossfit}
\alias{postrank_crossfit}
\title{Select and Evaluate Gradings on Two Draw Folds}
\usage{
postrank_crossfit(
  draws,
  fit = NULL,
  settings = NULL,
  backend = NULL,
  control = list(),
  strategy = NULL
)
}
\arguments{
\item{draws}{Joint equal-weight posterior draws from \code{\link[=postrank_draws]{postrank_draws()}} or
\code{\link[=as_postrank_draws]{as_postrank_draws()}} (\code{dependence_mode = "joint_model"}), so each draw
contains a joint state across all entities and criteria. Criterion-wise
blocks, exact finite laws, Gaussian or mixture coefficients, pre-computed
probabilities, and tie-mode inputs are not accepted.}

\item{fit}{Optional \code{postrank_fit} or \code{postrank_analysis} solved on \code{draws}
(for an original public problem, without protection envelopes or
second-stage risk caps). Supplies the problem settings and, when a checked
grading is present, also evaluates that full-draw grading on each fold.
Supply \code{fit} or \code{settings}, not both.}

\item{settings}{A \code{\link[=postrank_settings]{postrank_settings()}} object or named list with \code{weights},
\code{tau}, \code{G_max}, and optional \code{objective}, \code{q}, \code{exact_G},
\code{minimax_criteria}, and \code{minimax_refine}. Supply \code{fit} or \code{settings}, not
both.}

\item{backend, control, strategy}{Solver choice, \code{\link[=postrank_control]{postrank_control()}} options,
and search strategy passed to \code{\link[=postrank_solve]{postrank_solve()}} on each fold. \code{backend = NULL} (the default) uses \code{getOption("postrank.backend")} or Gurobi (which
requires a license); install \code{highs} and pass \code{backend = "highs"} to use
HiGHS. \code{postrank} never switches solvers automatically.}
}
\value{
A \code{postrank_crossfit} list containing \code{split} metadata, per-fold
records in \code{folds} (\code{draws}, \code{status}, \code{incumbent_validated},
\code{risk_absolute_gap}, and when a checked grading exists, \code{grade}, \code{G},
\code{in_fold_risk}, \code{out_of_fold_risk}, \code{optimism = out_of_fold_risk - in_fold_risk}, plus \code{out_of_fold_protection} when \code{q} is set and
\code{full_grade_risk_on_fold} when \code{fit} has grades), \code{agreement}
(\code{between_folds}, plus \code{full_vs_A} and \code{full_vs_B} when \code{fit} has grades),
\code{folds_with_incumbent}, \code{mean_optimism}, \code{mean_abs_optimism}, and
\code{warnings}.
}
\description{
\code{postrank_crossfit()} splits posterior draws into two folds (\code{A} and \code{B}),
solves the grading problem on each fold, and evaluates each fold's grading on
the held-out fold. It measures sensitivity of the chosen grading and its risk
to finite posterior simulation without refitting your statistical model to
held-out observations. Running \code{postrank_crossfit()} executes two solver
runs.
}
\details{
For IID draws (\code{S >= 4}), fold \code{A} is the first \code{floor(S / 2)} draws and fold
\code{B} is the remainder. For MCMC draws with at least two chains, fold \code{A} holds
the first \code{ceiling(C / 2)} whole chains and fold \code{B} holds the remaining
chains; single-chain MCMC (\code{S >= 4}) splits iterations into first and second
halves with an autocorrelation warning.

When \code{A} and \code{B} are independent IID folds from the same posterior and
\code{objective = "weighted"} with loss settings fixed beforehand, out-of-fold
weighted risk is conditionally unbiased for that fold grading's true
posterior risk (computed from roughly \code{S / 2} draws rather than all \code{S}
draws). When both folds select the exact same grading, their two signed
\code{optimism} values have opposite signs and cancel in \code{mean_optimism}; check
\code{mean_abs_optimism} for the noise scale. Under \code{objective = "minimax"} (a
maximum of empirical criterion risks) or MCMC folds, out-of-fold risk is not
unbiased. When \code{q} budgets are present, \code{out_of_fold_protection} reports
held-out \code{E_k / N} descriptively.

Cross-fitting is a descriptive summary of Monte Carlo sensitivity and does
not adjust the full-sample risk or provide a finite-sample guarantee.
}
\examples{
cf <- postrank_example("toy_crossfit")
cf[c("folds_with_incumbent", "mean_optimism", "mean_abs_optimism")]
cf$agreement
}
\seealso{
\code{\link[=postrank_diagnose]{postrank_diagnose()}}, \code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}},
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
