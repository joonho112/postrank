% Please edit documentation in R/mc-diagnostics.R
\name{postrank_crossfit}
\alias{postrank_crossfit}
\title{Select and Evaluate Reports on Two Draw Folds}
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
\item{draws}{Joint equal-weight ordinary posterior draws, validated or a
supported canonical payload. Whole states must preserve all entities and
criteria. Separate criterion blocks, exact finite laws, Gaussian/mixture
coefficients, supplied probabilities, and equality-neutral inputs are not
supported by this draw-splitting diagnostic.}

\item{fit}{Optional \code{postrank_fit} or \code{postrank_analysis} on the same input.
Its problem settings are used, and its grade, when available, is also
evaluated on both folds. Supply exactly one of \code{fit} or \code{settings}.}

\item{settings}{Alternatively, a \code{\link[=postrank_settings]{postrank_settings()}} object or a list with
\code{weights}, \code{tau}, \code{G_max}, and optional \code{objective}, \code{q}, \code{exact_G},
\code{minimax_criteria}, and \code{minimax_refine}. The conditional unbiasedness
interpretation requires loss settings fixed independently of evaluation draws.}

\item{backend, control, strategy}{Backend, numerical controls, and strategy as
in \code{\link[=postrank_solve]{postrank_solve()}}, applied separately to each fold. \code{backend = NULL}
uses the \code{postrank.backend} option, then Gurobi; there is no fallback.}
}
\value{
A \code{postrank_crossfit} list with split receipts and per-fold status,
incumbent availability, absolute risk gap, selected grade, in-fold and
out-of-fold risk, and \code{optimism} (out-of-fold minus in-fold). It also reports
pair-relation agreement, \code{folds_with_incumbent}, \code{mean_optimism}, and
\code{mean_abs_optimism}. With \code{q}, out-of-fold protection ratios are descriptive;
they do not assert that the report remains protected under the target law.
}
\description{
Posterior draws are divided into two folds. A grading is selected on each
fold and evaluated on the other, giving a diagnostic of sensitivity to
finite posterior simulation. The supplied model is retained throughout; it
is not refitted to held-out observations. The calculation requires two
optimizations.
}
\details{
IID input uses the first and second halves of stored draws. MCMC
input with at least two chains uses groups of whole original chains; one
chain is split into halves. A half split requires at least four draws.
The input's ordinary zero-equality condition is retained.

For independent IID training and evaluation folds from the same target law,
out-of-fold linear weighted risk is conditionally unbiased for the selected
training-fold report's true risk. Its difference from in-fold risk therefore
concerns that fold report's optimism, not the full-data report's optimism.
The same linearity applies to each criterion risk. It does not apply to
minimax risk: a maximum of empirical risks is generally biased upward.

No exact unbiasedness is claimed for MCMC folds. Single-chain halves can
be dependent, and grouping whole chains alone establishes neither
independence nor target stationarity and does not remove initialization
bias. Sampling declarations are not independently verified.

Cross-fit values describe simulation sensitivity and do not correct the
full-data risk. When both folds select the same report, the signed
differences cancel, although their absolute magnitudes can remain
informative about simulation sensitivity. A fold without a validated
incumbent retains its reason for unavailability, and aggregates use only
available folds. Interpretation therefore depends on the fold count and
statuses. These diagnostics provide neither a finite-sample bound nor
evidence of calibration on new observations.
}
\examples{
settings <- list(weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
\dontrun{
# Optional: two small native solves; no model is refitted.
cf <- postrank_crossfit(postrank_toy, settings = settings,
  backend = "highs", control = postrank_control(time_limit = 10, threads = 1))
cf[c("folds_with_incumbent", "mean_optimism", "mean_abs_optimism")]
cf$folds
}
}
\seealso{
\code{\link[=postrank_diagnose]{postrank_diagnose()}}, \code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}},
\code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}}
}
\concept{diagnostics}
