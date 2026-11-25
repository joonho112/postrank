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
\item{draws}{Posterior draws from \code{\link[=postrank_draws]{postrank_draws()}} or \code{\link[=as_postrank_draws]{as_postrank_draws()}}
(equal-weight IID or MCMC draws, or an exact finite law), or a
\code{postrank_coefficients} object (Gaussian or mixture, which delegates to
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}). Pre-computed \code{\link[=postrank_probabilities]{postrank_probabilities()}}
and tie-mode inputs (\verb{postrank_tie_*}) are not accepted.}

\item{fit}{Optional \code{postrank_fit} (for example \code{analysis$fit}) solved on
\code{draws}. Supplies problem settings and, when a checked grading is present,
its grade vector; results are marked \code{post_selection_descriptive = TRUE}.}

\item{grade}{Optional named integer vector of fixed grades (\code{1} = highest
priority). Must match \code{fit$grade} when both are supplied; requires
\code{settings} when \code{fit} is \code{NULL}. \code{postrank} cannot verify whether a
manually supplied \code{grade} was chosen independently of \code{draws}.}

\item{settings}{Named list (or \code{postrank_settings} fields) with \code{weights} and
\code{tau} when \code{grade} is supplied without \code{fit}, plus optional \code{G_max},
\code{objective}, \code{q}, \code{exact_G}, \code{minimax_criteria}, and \code{minimax_refine}.
\code{G_max} is required when \code{stability} is requested.}

\item{pairs}{Optional list of records or data frame with columns \code{entity_i},
\code{entity_j}, and \code{criterion_id} naming up to 500 distinct directed pairs.
Each pair trace records the per-draw indicator \code{I(theta_i <= theta_j)}.
\code{NULL} (the default) requests no pair traces.}

\item{stability}{Optional named list requesting up to \code{max_solves} (default
and maximum \code{12L}) re-solves on joint equal-weight draws. Requires explicit
\code{backend} (\code{"gurobi"} or \code{"highs"}) and \code{control} with \code{threads = 1L}, plus
optional \code{prefixes}, \code{include_full}, \code{chain_subsets}, and \code{settings_grid}
(at most 6 overrides). Chain subsets and per-chain prefixes require MCMC
chain history; IID inputs support full-draw \code{settings_grid} runs only.}
}
\value{
For draw inputs, a \code{postrank_diagnostics} list containing \code{traces},
\code{summaries}, \code{posterior_profiles}, \code{total_loss}, \code{stability}, \code{grade},
\code{settings}, \code{regimes}, \code{post_selection_descriptive}, and \code{warnings}. Each
diagnostic metric record stores \code{value}, \code{available}, \code{unavailable_reason},
and \code{method} (unavailable metrics remain \code{NA}, never zero). For
\code{postrank_coefficients} inputs, returns \code{postrank_coefficient_diagnostics};
see \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}.
}
\description{
\code{postrank_diagnose()} summarizes posterior target distributions, requested
directed-pair error traces, and per-draw loss traces for a supplied grading,
with optional subset or settings-grid stability re-solves. Posterior target
intervals describe uncertainty under your statistical model, whereas Monte
Carlo standard errors (MCSEs) describe simulation precision when estimating
summaries of that posterior from finite draws.
}
\details{
For IID draws, trace MCSE is \code{sd(z) / sqrt(S)} using the retained draw count
\code{S}. For MCMC draws with equal-length chains and the optional \code{posterior}
package installed, \code{postrank_diagnose()} computes \code{mcse_mean}, \code{rhat},
\code{ess_bulk}, and \code{ess_tail} from the original chain-by-iteration layout;
unequal chains are never truncated or padded to force cross-chain metrics. An
exact finite law uses its rational state masses (\code{gmp} quantiles at \code{1/40},
\code{1/2}, and \code{39/40}) and has zero Monte Carlo error.

Joint draws (\code{dependence_mode = "joint_model"}) combine criterion losses
within each draw to form \code{weighted_total_loss}, preserving cross-criterion
covariance; criterion-wise draw blocks provide per-criterion traces without a
joint total-loss MCSE. Under \code{objective = "minimax"}, \code{weighted_total_loss}
is marked \code{"weighted_auxiliary"} because minimax optimizes the maximum of
expected criterion risks rather than an expectation of per-draw maxima.
Without a fixed grade, no loss trace is computed.

An all-withheld single-grade report has constant per-draw loss \code{tau} (zero
variance), and an all-zero or all-one pair indicator trace does not establish
an exact posterior probability of \code{0} or \code{1}. Gaussian and mixture
coefficient inputs reject \code{pairs} and \code{stability}; call
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} directly when supplying hyperparameter
\code{chain_history}. These diagnostics are descriptive summaries and do not
provide post-selection coverage, convergence proof, or a finite-sample
guarantee.
}
\examples{
pair <- data.frame(
  entity_i = "001",
  entity_j = "site-B",
  criterion_id = "need_A"
)
d <- postrank_diagnose(postrank_toy, pairs = pair)
d$summaries$pair_1$diagnostics$mcse_mean

grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
d_grade <- postrank_diagnose(
  postrank_toy,
  grade = grade,
  settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
)
d_grade$summaries$weighted_total_loss$mean
d_grade$post_selection_descriptive
}
\seealso{
\code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}}, \code{\link[=postrank_crossfit]{postrank_crossfit()}},
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}, \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
