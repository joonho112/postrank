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
\item{probabilities}{A named square matrix for one criterion, or a named
entity-by-entity-by-criterion numeric array. Both entity axes must contain
the same IDs in the same order. Diagonals must be \code{NA}: they are unused
self-comparisons, not zero-probability events.}

\item{event}{Explicitly \code{"higher_priority"} for
\code{P(theta[i,k] > theta[j,k])}, or \code{"directional_error"} for
\code{P(theta[i,k] <= theta[j,k])}. Larger target values mean higher priority.
The output \code{e} always stores the latter event, the error for reporting
row entity i above column entity j.}

\item{zero_ties}{Explicitly \code{TRUE}: each pair of distinct targets has equality
probability zero. Continuous marginals are not required; a finite law with
no pairwise equality is also admissible. Positive or unknown equality
probability cannot be imported by this route.}

\item{margin}{Explicitly \code{0}. Nonzero comparison margins are unsupported.}

\item{source}{A list with \code{kind}, \code{description}, and \code{conditioning}.
\code{kind} is \code{"analytic_reference"}, \code{"numerical_integration"},
\code{"iid_summary"}, \code{"mcmc_summary"}, or \code{"published_reference"}.
Describe how the probabilities were obtained and what was held fixed,
including an estimated prior in an empirical Bayes analysis. The label
records the producer's account; it does not verify calculation accuracy.}

\item{targets}{A criterion-named character vector describing the oriented
targets and units, in the same order as the probability array.}

\item{criterion}{One criterion name, required for matrix input. Omit it for
an array, whose third dimension provides the names.}

\item{correction}{\code{"none"} (default) or an explicit \code{"symmetric"}
correction of small reverse-complement discrepancies.}

\item{tolerance}{With symmetric correction, an explicit nonnegative
tolerance no larger than \code{1e-3}. This upper limit is a safeguard, not a
recommended integration tolerance. Without correction, reverse sums must
be within \code{1e-12} of one and this argument must be omitted.}

\item{summaries}{Optional list with named entity-by-criterion \code{means},
\code{same_targets = TRUE}, and a \code{description}. To supply fixed central
equal-tail intervals, also include \code{lower}, \code{upper}, and \code{level}.
These must describe the same oriented targets and units. Intervals at
another level cannot be recovered from these summaries.}
}
\value{
A \code{postrank_probabilities} object containing directional errors \code{e},
raw and corrected probabilities, source records, correction magnitudes,
and optional supplied summaries. It can be used by \code{\link[=postrank]{postrank()}},
\code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}, \code{\link[=postrank_expected_rank]{postrank_expected_rank()}},
and \code{\link[=postrank_cuts]{postrank_cuts()}} within their documented scope. No draw count,
Monte Carlo diagnostic, or numerical certificate is inferred.
}
\description{
The constructor imports comparison probabilities from an external posterior
analysis, numerical integration or a specified law. A matrix represents one
criterion and an array represents several criteria. The event direction,
target definition, source and any requested numerical correction are
recorded. Neither posterior draws nor a fitted model are produced by this
operation.
}
\details{
Native joint search and fixed-order cuts support weighted expected
loss with an upper grade-count limit for this input. Minimax, \code{q}
protections, and an exact grade count are unsupported in those routes.
A fixed report can be scored with \code{\link[=postrank_evaluate]{postrank_evaluate()}}; this does not test
whether it belongs to a particular constrained action family.

Range and reverse-complement checks do not establish that the supplied
probabilities come from a coherent joint posterior or a suitable model.
Cross-criterion dependence is unnecessary for additive expected loss, but
these coefficients do not determine composite ordering or simultaneous
correctness probabilities. A summary of Monte Carlo comparisons likewise
does not retain the original draws or chain histories.

Symmetric correction replaces a forward probability by the average of
itself and one minus its reverse, then complements the reverse value.
The maximum change is retained separately for each criterion. For a fixed
report, the resulting risk change is at most \code{N/M} times the weighted
sum of these maxima, where \code{N} counts disclosed pairs and \code{M} counts all
unordered pairs. This describes a change from the supplied array; it does
not bound quadrature, model, or Monte Carlo error. Nothing is corrected
silently when \code{correction = "none"}.
}
\examples{
# The same analytic one-criterion law as the tutorial Gaussian input.
x <- postrank_probabilities(pr_tutorial$one$e,
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal-CDF comparisons for pr_tutorial score A",
    conditioning = "The specified means, variances, and independent-site law are fixed"),
  targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
postrank_evaluate(grade, x, c(score_A = 1), tau = .25)$weighted_risk
validate_postrank_probabilities(x)
}
\seealso{
\code{\link[=validate_postrank_probabilities]{validate_postrank_probabilities()}}, \code{\link[=postrank_pairwise]{postrank_pairwise()}},
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}} for the separate equality-neutral loss.
}
\concept{input}
