% Please edit documentation in R/probabilities.R
\name{postrank_probabilities}
\alias{postrank_probabilities}
\title{Use Previously Calculated Comparison Probabilities}
\usage{
postrank_probabilities(
  probabilities,
  event,
  zero_ties,
  margin,
  source,
  targets,
  criterion = NULL,
  correction = "none",
  tolerance = NULL,
  summaries = NULL
)
}
\arguments{
\item{probabilities}{A named \verb{n x n} numeric matrix for one criterion, or a
named \verb{n x n x K} numeric array (\code{n >= 2}). Row and column entity names
must match in the same order. Diagonal entries must be \code{NA} (unused
self-comparisons, not \code{0} or \code{NaN}), and off-diagonal entries must be
finite numbers in \verb{[0, 1]}.}

\item{event}{Which pairwise event \code{probabilities[i, j, ]} represents
(required): \code{"higher_priority"} for \code{P(theta[i, k] > theta[j, k])}, or
\code{"directional_error"} for \code{P(theta[i, k] <= theta[j, k])}, where larger
\code{theta} means higher priority. The returned \verb{$e} array always stores
\code{"directional_error"} (the expected error if entity \code{i} is graded above
entity \code{j}).}

\item{zero_ties}{Must be \code{TRUE} (required): distinct entities have zero
probability of exact equality on each criterion. For posteriors with
positive or unknown tie probability, use \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}

\item{margin}{Must be \code{0} (required). Nonzero comparison margins are not
supported.}

\item{source}{Plain named list with strings \code{kind}, \code{description} and
\code{conditioning} (required). \code{kind} must be one of \code{"analytic_reference"},
\code{"numerical_integration"}, \code{"iid_summary"}, \code{"mcmc_summary"} or
\code{"published_reference"}. State how the probabilities were computed and
what was conditioned on (including any fixed empirical Bayes prior).}

\item{targets}{Character vector named by criterion (in the same order as
\code{probabilities}) describing each higher-priority target and its units
(required).}

\item{criterion}{Single criterion name when \code{probabilities} is a 2D matrix;
leave \code{NULL} when \code{probabilities} is a 3D array (whose 3rd axis supplies
the names).}

\item{correction}{How small discrepancies in \code{P(i, j) + P(j, i) = 1} are
handled: \code{"none"} (the default) or \code{"symmetric"}.}

\item{tolerance}{Maximum allowed complement discrepancy
\verb{max |P(i, j) + P(j, i) - 1|} when \code{correction = "symmetric"}, a finite
number in \verb{[0, 1e-3]} (this cap is a safeguard, not a recommended
integration tolerance). Must be \code{NULL} when \code{correction = "none"}, which
requires complement sums to be within \code{1e-12} of \code{1}.}

\item{summaries}{Optional plain named list of marginal target summaries for
the same oriented targets and units: \code{means} (\verb{n x K} matrix with matching
row and column names), \code{same_targets = TRUE}, and \code{description}. To enable
report cards, also supply \code{lower}, \code{upper} (\verb{n x K} matrices with
\code{lower <= upper}) and \code{level} (\verb{0 < level < 1}) together; intervals at any
other \code{level} cannot be computed from these summaries.}
}
\value{
A \code{postrank_probabilities} object (inheriting from
\code{postrank_pairwise}) containing directional error probabilities \code{e},
\code{raw_probabilities}, \code{corrected_probabilities}, \code{correction} diagnostics,
\code{source}, \code{targets}, \code{summaries} and \code{capabilities}. Accepted by
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}},
\code{\link[=postrank_expected_rank]{postrank_expected_rank()}} and \code{\link[=postrank_cuts]{postrank_cuts()}}.
}
\description{
\code{postrank_probabilities()} builds a pairwise-probability input from
comparison probabilities computed outside \code{postrank} (for example by
analytic formulas, numerical integration or another posterior summary),
without requiring posterior draws. Pass a square matrix for one criterion or
a 3D array for several criteria.
}
\details{
\strong{Supported settings and summaries.} Supplied probabilities support the
weighted expected-loss objective with \code{G_max}. Minimax objectives, \code{q} error
budgets and \code{exact_G} are not available in \code{\link[=postrank]{postrank()}} or
\code{\link[=postrank_problem]{postrank_problem()}}. Because no posterior draws are present, Monte Carlo
fragility, cross-fitting, draw diagnostics and IID bounds are unavailable;
a report card is available in \code{\link[=postrank]{postrank()}} and \code{\link[=postrank_report_card]{postrank_report_card()}} only
when \code{summaries} includes \code{lower}, \code{upper} and \code{level}, and only at that
\code{level}.

\strong{Symmetric correction.} When \code{correction = "symmetric"}, each upper-triangle
entry is replaced by \code{(a[i, j] + 1 - a[j, i]) / 2} and the lower-triangle
entry is set to \code{1 - a[i, j]}. For any fixed grading with \code{N} ordered pairs
out of \code{M} total pairs, this changes the weighted loss by at most \code{N / M}
times the weighted sum of \code{correction$maximum_absolute_change}. That bound
measures only the adjustment to the supplied array, not numerical
integration, Monte Carlo or model error.

\strong{Scope of checks.} Checking range and complement sums does not verify that
the probabilities come from a coherent joint posterior or an adequate model.
}
\examples{
x <- postrank_probabilities(pr_tutorial$one$e,
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal-CDF comparisons for pr_tutorial score A",
    conditioning = "The specified means, variances and independent-site law are fixed"),
  targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
postrank_evaluate(grade, x, c(score_A = 1), tau = 0.25)$weighted_risk
validate_postrank_probabilities(x)
}
\seealso{
\code{\link[=validate_postrank_probabilities]{validate_postrank_probabilities()}}, \code{\link[=postrank_pairwise]{postrank_pairwise()}},
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}
}
\concept{input}
