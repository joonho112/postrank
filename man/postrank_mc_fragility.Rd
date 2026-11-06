% Please edit documentation in R/mc-diagnostics.R
\name{postrank_mc_fragility}
\alias{postrank_mc_fragility}
\title{Find Pairwise Decisions Close to the Monte Carlo Noise Scale}
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
\item{draws}{Joint equal-weight ordinary posterior draws. Whole states must
retain the dependence among entities and criteria. Exact finite laws,
criterion-wise blocks, Gaussian/mixture coefficients, supplied probabilities,
and equality-neutral inputs are not supported by this Monte Carlo diagnostic.}

\item{fit, settings}{Supply exactly one, as in \code{\link[=postrank_crossfit]{postrank_crossfit()}}. Only
\code{weights} and \code{tau} are needed in a settings list. A supplied fit's grade
is used to label its relation for each traced pair; its optimization status
is not improved by this diagnostic.}

\item{z}{Positive MCSE multiplier, default 2. This sets a descriptive scale,
not a simultaneous confidence level.}

\item{screen_margin}{Positive threshold: only pairs with margin strictly below
it are traced. For IID samples with \code{S > 1}, the default is
\code{z * 0.5 / sqrt(S - 1)}, using the maximum sample SD of a bounded indicator
to avoid screening out a pair that this rule could flag. The MCMC default
\code{0.1} is a heuristic screening threshold, not a bound on omitted pairs.}
}
\value{
A \code{postrank_mc_fragility} list with a \code{pairs} table of better
directions, weighted error, margin, MCSE, margin/MCSE ratio, and \code{fragile}
flag; a supplied grade adds its reported relation. \code{summary} counts all
pairs, traced pairs, flagged pairs, and unavailable MCSEs. Screening choices,
sampling regime, and diagnostic warnings are retained.
}
\description{
The diagnostic identifies pairs for which the estimated loss from disclosure
in the better direction is close to the withholding cost. Since
grades are selected jointly, a flagged pair need not imply a change in the
selected grading. Indicator traces are calculated without optimization.
}
\details{
Let \eqn{\bar e_{ij}=\sum_k w_k e_{ij,k}} and
\eqn{d=\min(\bar e_{ij},\bar e_{ji})}. Considering this pair alone,
disclosure in the better direction has lower estimated loss than
withholding when \eqn{d<\tau}. The function flags
\eqn{|d-\tau|<z\,\widehat{\mathrm{MCSE}}} using the weighted indicator
trace for the empirically better direction. It does not diagnose global
action stability, enforce grade counts or protections, or provide
post-selection coverage for that chosen direction.

IID MCSE is sample SD divided by the square root of the actual draw count.
MCMC MCSE uses \code{posterior::mcse_mean} with the original equal-length chains.
Unequal chains are not truncated or padded; missing optional software or
unavailable MCSE leaves the corresponding flags unavailable. In particular,
a constant empirical trace is not proof of certainty or adequate chain
exploration. MCMC ESS cannot replace an IID sample count in a concentration
bound. These pairwise flags are descriptive, not finite-sample guarantees.
}
\examples{
fragility <- postrank_mc_fragility(postrank_toy,
  settings = list(weights = c(need_A = .6, need_B = .4), tau = .25))
fragility$summary
fragility$pairs
}
\seealso{
\code{\link[=postrank_diagnose]{postrank_diagnose()}}, \code{\link[=postrank_crossfit]{postrank_crossfit()}}, \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
