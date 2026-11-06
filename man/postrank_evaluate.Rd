% Please edit documentation in R/evaluate-grade.R
\name{postrank_evaluate}
\alias{postrank_evaluate}
\title{Evaluate the Posterior Loss of Supplied Grades}
\usage{
postrank_evaluate(
  grade,
  pairwise,
  weights = NULL,
  tau = NULL,
  objective = c("weighted", "minimax"),
  minimax_criteria = NULL,
  settings = NULL
)
}
\arguments{
\item{grade}{Numeric vector of positive integer grades, named in exactly
the input's entity order. Occupied labels are renumbered consecutively.}

\item{pairwise}{A \code{postrank_pairwise}, \code{postrank_coefficients}, or
\code{\link[=postrank_probabilities]{postrank_probabilities()}} object. Gaussian/mixture coefficients and
supplied probabilities currently support weighted expected risk only.}

\item{weights}{Nonnegative finite criterion-named weights summing to one.
Supply every criterion exactly once, including weight 1 for a single
criterion, unless using \code{settings}. Weights are not normalized automatically.}

\item{tau}{Cost of a withheld comparison, with \verb{0 < tau <= 0.5}.}

\item{objective}{\code{"weighted"} or \code{"minimax"}. The latter uses the largest
expected criterion risk, not an expectation of statewise maximum loss.}

\item{minimax_criteria}{Optional nonempty criterion subset for minimax;
\code{NULL} uses all criteria. Only allowed with \code{objective = "minimax"}.}

\item{settings}{Optional \code{\link[=postrank_settings]{postrank_settings()}} supplying weights, tau,
objective and minimax criteria instead of the separate arguments.
Explicitly supplying both is a \code{settings_conflict} error.}
}
\value{
An unclassed list with the canonical \code{grade}, occupied count \code{G},
total unordered pairs \code{M}, disclosed pairs \code{N}, and directed disclosure
matrix \code{x}. \code{disclosure_rate = N/M} and \code{abstention_rate = (M-N)/M}.
Criterion-named \code{E}, \code{E_over_M}, \code{E_over_N} and \code{criterion_risk} give
expected error counts, their two normalizations and loss including
withholding. \code{weighted_risk}, \code{minimax_risk} and \code{primary_risk} distinguish
the weighted, largest selected-criterion and requested objectives.
\code{weighted_raw_objective = sum(weights * E) - tau * N} is in centered raw
units. \code{objective}, \code{minimax_criteria}, \code{settings}, \code{schema_version} and
input/pairwise identities record what was evaluated.
}
\description{
Disclosed comparisons, expected directional errors and loss are calculated
for an existing grade vector without optimization. Smaller grades indicate
higher priority. Equal grades withhold a direction without asserting
equality of the latent targets. The resulting quantities are conditional on
the supplied posterior probabilities and chosen loss.
}
\details{
For criterion k, risk is \code{(E_k + tau * (M - N)) / M}.
When all comparisons are withheld, N=0, conditional error ratios
\code{E_over_N} are \code{NA}, and risk is tau. This is a valid action, distinct
from a solve with no validated grade.

Evaluation does not check membership in a grade-cap, exact-grade or
error-budget family, even when those restrictions appear in \code{settings}.
Use \code{\link[=postrank_problem]{postrank_problem()}} to specify that family; \code{\link[=postrank_compare]{postrank_compare()}}
records membership separately when comparing actions.
}
\examples{
grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
ev <- postrank_evaluate(grade, pr_tutorial$one,
  weights = c(score_A = 1), tau = .2)
ev[c("N", "M", "E_over_N", "primary_risk")]
held <- postrank_evaluate(setNames(rep(1L, 6), names(grade)),
  pr_tutorial$one, weights = c(score_A = 1), tau = .2)
held[c("N", "E_over_N", "primary_risk")]
}
\seealso{
\code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=get_profile]{get_profile()}}
}
\concept{decision}
