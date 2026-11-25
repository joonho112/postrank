% Please edit documentation in R/mc-diagnostics.R
\name{postrank_mc_fragility}
\alias{postrank_mc_fragility}
\title{Find Pairwise Decisions Near the Monte Carlo Noise Scale}
\usage{
postrank_mc_fragility(
  draws,
  fit = NULL,
  settings = NULL,
  z = 2,
  screen_margin = NULL
)
}
\arguments{
\item{draws}{Joint equal-weight posterior draws from \code{\link[=postrank_draws]{postrank_draws()}} or
\code{\link[=as_postrank_draws]{as_postrank_draws()}} (\code{dependence_mode = "joint_model"}). Criterion-wise
blocks, exact finite laws, Gaussian or mixture coefficients, pre-computed
probabilities, and tie-mode inputs are not accepted.}

\item{fit, settings}{Supply \code{fit} (\code{postrank_fit} or \code{postrank_analysis} on
\code{draws}) or \code{settings} (\code{\link[=postrank_settings]{postrank_settings()}} or named list with \code{weights}
and \code{tau}), not both. When \code{fit} has a checked grading, each traced pair is
also labeled by its relation in \code{fit$grade}.}

\item{z}{Positive numeric MCSE multiplier (\code{2} by default) setting the
descriptive flagging threshold \verb{|d - tau| < z * mcse}.}

\item{screen_margin}{Positive numeric pre-screen threshold: only pairs with
\verb{|d - tau| < screen_margin} have per-draw indicator traces built. When
\code{NULL} (the default), IID inputs with \code{S > 1} use
\code{z * 0.5 / sqrt(S - 1)} (the maximum sample SD of a \verb{[0, 1]} indicator, so
no pair that could be flagged is skipped), and MCMC inputs use \code{0.1} (a
working screen accompanied by a warning, not an upper bound).}
}
\value{
A \code{postrank_mc_fragility} list with \code{pairs} (data frame of traced
pairs containing \code{entity_i}, \code{entity_j}, \code{better_direction},
\code{weighted_error}, \code{margin}, \code{disclose_preferred}, \code{mcse}, \code{ratio}, and
\code{fragile}, plus \code{relation_in_grade} when \code{fit} has grades), \code{summary}
(\code{pairs}, \code{traced}, \code{fragile}, \code{fragile_share}, \code{mcse_unavailable}, plus
\code{fragile_disclosed} and \code{fragile_tied} when \code{fit} has grades), \code{regime},
\code{draws}, \code{z}, \code{screen_margin}, \code{mcse_method}, and \code{warnings}.
}
\description{
\code{postrank_mc_fragility()} identifies unordered entity pairs whose estimated
wrong-direction error in the better ordering direction lies close to the
withholding cost \code{tau} relative to its Monte Carlo standard error (MCSE),
without running a solver. Because grades are chosen jointly across all pairs,
a flagged pair need not change the selected grading.
}
\details{
For each unordered pair \verb{(i, j)}, let
\eqn{\bar e_{ij} = \sum_k w_k e_{ij,k}} be the criterion-weighted
directional-error probability and \eqn{d = \min(\bar e_{ij}, \bar e_{ji})}.
Taken in isolation, ordering the pair in its better direction beats
withholding when \eqn{d < \tau}. For pairs passing \code{screen_margin},
\code{postrank_mc_fragility()} builds the per-draw weighted indicator trace for
that empirically better direction and flags \verb{|d - tau| < z * mcse}.

IID MCSE is \code{sd(trace) / sqrt(S)}. MCMC MCSE uses \code{posterior::mcse_mean()} on
equal-length chains; unequal chain lengths or an uninstalled \code{posterior}
package leave \code{mcse} and \code{fragile} as \code{NA} with a warning rather than
truncating chains or substituting zero. Pairwise fragility flags are
descriptive summaries and do not assess global grade stability, account for
\code{G_max} or error budgets \code{q}, or provide simultaneous confidence levels or a
finite-sample guarantee.
}
\examples{
fragility <- postrank_mc_fragility(
  postrank_toy,
  settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
)
fragility$summary
fragility$pairs
}
\seealso{
\code{\link[=postrank_diagnose]{postrank_diagnose()}}, \code{\link[=postrank_crossfit]{postrank_crossfit()}},
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
