% Please edit documentation in R/postrank-diagnose.R
\name{postrank_diagnose}
\alias{postrank_diagnose}
\title{Inspect Monte Carlo Precision for Reports or Pairs}
\usage{
postrank_diagnose(
  draws,
  fit = NULL,
  grade = NULL,
  settings = NULL,
  pairs = NULL,
  stability = NULL
)
}
\arguments{
\item{draws}{Ordinary input from \code{\link[=postrank_draws]{postrank_draws()}} or \code{\link[=as_postrank_draws]{as_postrank_draws()}},
including a specified finite law, or Gaussian/mixture coefficients. The
latter delegate to \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} and have no latent
target-draw traces. Supplied probability arrays and equality-neutral inputs
do not provide this diagnostic route.}

\item{fit}{Optional \code{postrank_fit} from exactly the same input. Its settings
and validated grade are used; results are marked descriptive after selection
on those draws. A fit without a validated incumbent supplies no fixed grade.}

\item{grade}{Optional named fixed grade vector, with smaller grades indicating
higher priority. It must agree with \code{fit} when both are supplied. The
software cannot verify that a manually supplied grade was chosen independently
of these draws.}

\item{settings}{Explicit \code{weights} and \code{tau} for a grade without a fit, plus
optional problem settings. \code{G_max} is required for stability solves.}

\item{pairs}{Explicit list of records or a data.frame with \code{entity_i},
\code{entity_j}, and \code{criterion_id}, naming up to 500 distinct directed comparisons.
Each trace is the indicator that the row entity's target is less than or
equal to the column entity's. \code{NULL} requests no pair traces.}

\item{stability}{Optional request for additional optimization runs, with
explicit \code{backend} and \code{control} (\code{threads = 1}). \code{prefixes}, \code{include_full},
\code{chain_subsets}, and \code{settings_grid} select at most \code{max_solves} attempts
(default and hard maximum 12); the settings grid has at most six overrides.
Joint equal-weight draws are required. IID inputs allow full-input settings
grids only; chain subsets and per-chain prefixes require original MCMC history.}
}
\value{
For draw input, a \code{postrank_diagnostics} list containing \code{traces},
their \code{summaries}, \code{posterior_profiles}, \code{total_loss} availability, and any
\code{stability} results, along with grade, settings, sampling regimes, selection
context, and warnings. Metric records retain \code{value}, \code{available},
\code{unavailable_reason}, and \code{method}; unavailable is not zero.
Gaussian/mixture input instead returns \code{postrank_coefficient_diagnostics};
see \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}.
}
\description{
The diagnostics summarize target draws, requested pair-error traces and the
loss of a supplied grading. Posterior target intervals describe uncertainty
under the model, whereas Monte Carlo standard errors describe the numerical
precision with which features of that law are estimated.
}
\details{
IID trace MCSE is sample SD divided by the square root of the actual
retained count. Eligible MCMC traces use the optional \code{posterior} package
for MCSE, R-hat, and ESS. Original chain/iteration history is retained;
unequal chains are not truncated or padded to obtain cross-chain metrics.
Missing, nonfinite, or inapplicable metrics keep their reasons. A complete
finite law uses its stated masses and has no Monte Carlo error to diagnose.

Joint inputs combine criterion losses within the same state, preserving
covariance in the total-loss trace. Criterion-wise blocks can provide
individual traces without a joint total-loss MCSE. Under minimax, a weighted
total-loss trace is auxiliary; it is not MCSE for the maximum of expected
criterion risks. Without a fixed grade, no total-loss trace is produced.

Pointwise MCSE for a grading selected on the same draws is a descriptive
measure and does not automatically provide post-selection coverage or regret
bounds. An all-withheld report has constant ordinary loss \code{tau}, which
provides no information about exploration of the targets. Similarly, a
constant observed pair trace does not establish a posterior probability of
zero or one. Stability across overlapping subsets is insufficient to
establish convergence. Changes in grades after changes in policy settings
may reflect the decision problem rather than simulation error.

Gaussian/mixture inputs reject pair traces and stability solves. This
wrapper supplies no original hyperparameter chain history; use
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} with explicit \code{chain_history} for eligible
conditional expected-risk metrics. No route here verifies convergence,
numerical accuracy, or external repeated-data calibration.
}
\examples{
# Begin with one explicitly named directional comparison.
pair <- data.frame(entity_i = "001", entity_j = "site-B",
  criterion_id = "need_A")
d <- postrank_diagnose(postrank_toy, pairs = pair)
d$summaries$pair_1$diagnostics$mcse_mean

# A declared report, evaluated without optimizing its grades.
grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
d <- postrank_diagnose(postrank_toy, grade = grade,
  settings = list(weights = c(need_A = .6, need_B = .4), tau = .25))
d$summaries$weighted_total_loss$mean
d$post_selection_descriptive
}
\seealso{
\code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}}, \code{\link[=postrank_crossfit]{postrank_crossfit()}},
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
