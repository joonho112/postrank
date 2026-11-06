% Please edit documentation in R/baselines.R
\name{postrank_cuts}
\alias{postrank_cuts}
\title{Optimal or Quantile Cuts of a Declared Score Order}
\usage{
postrank_cuts(
  scores,
  pairwise,
  settings,
  direction = c("ascending", "descending"),
  rule = c("optimal", "quantile"),
  G_b = NULL,
  method = NULL
)
}
\arguments{
\item{scores}{A named score vector (one per entity), for example from
\code{\link[=postrank_expected_rank]{postrank_expected_rank()}} or \code{\link[=postrank_composite]{postrank_composite()}}.}

\item{pairwise}{The \code{postrank_pairwise}, \code{postrank_coefficients}, or
\code{postrank_probabilities} object whose directional errors define the loss.}

\item{settings}{A \code{\link[=postrank_settings]{postrank_settings()}} object (weights, tau, grade rule).}

\item{direction}{\code{"ascending"} (smaller score = higher priority, as for
expected rank) or \code{"descending"} (larger = higher, as for composites).}

\item{rule}{\code{"optimal"} or \code{"quantile"}.}

\item{G_b}{For \code{rule = "quantile"}, the requested number of grades
(default: the settings' \code{exact_G}, else \code{G_max}, capped at \code{n}).}

\item{method}{Optional label; defaults to the score's \code{score_method}
attribute, else \code{"user_scores"}.}
}
\value{
A \code{postrank_baseline} list. \code{scores}, \code{direction}, \code{order} and
\code{score_blocks} record the declared order and its indivisible exact-score
blocks. \code{cut_rule}, \code{cuts} (block positions) and the entity-named \code{grade}
record the action. \code{evaluation} contains the fixed-action metrics;
\code{risk} is the weighted loss and \code{objective} its raw optimization value.
\code{optimality_scope} distinguishes optimal partitions of this score order
from quantile cuts; neither provides a full-family solver bound.
\code{method}, \code{tie_policy}, bound \code{settings}, \code{input_identity},
\code{schema_version}, \code{provenance} and \code{warnings} retain the construction
record. When the requested grade count is impossible, the function raises
an error rather than returning an all-withheld report.
}
\description{
A declared score order is partitioned into ordered grades, with exactly tied
scores retained in the same grade. Optimal cuts minimize weighted loss over
partitions of that order, whereas quantile cuts use fixed positions. The
search therefore remains conditional on the declared order.
}
\details{
\code{rule = "optimal"} uses a contiguous-partition dynamic program
(subject to ordinary floating-point arithmetic) under the settings' grade
cap \code{G_max}, or the exact grade count \code{exact_G}; its optimality is
restricted to contiguous partitions of this score order. \code{rule = "quantile"}
uses the fixed positional labels \eqn{1 + \lfloor (p - 1) G_b / n \rfloor}
and performs no optimization. Exactly equal stored scores are never split;
a quantile boundary inside an exact-score block merges the grades it
straddles, so the realized number of grades can be below \code{G_b}. The realized
grade count must still satisfy \code{G_max} and \code{exact_G}; violations raise
\code{baseline_grade_limit_violation} or \code{baseline_exact_grade_violation}.

The dynamic program optimizes the weighted objective only: settings with
error budgets \code{q} or the minimax objective are refused
(\code{unsupported_baseline_settings}); an \code{exact_G} larger than the number of
exact-score blocks is refused (\code{exact_G_exceeds_blocks}). Typed Gaussian
and mixture coefficients permit exact-count cuts within this fixed order,
although their native joint problem constructor does not support exact-G.
Direct \code{\link[=postrank_probabilities]{postrank_probabilities()}} inputs are restricted to weighted
at-most-G cuts, as well as weighted at-most-G native problems.
}
\examples{
pw <- postrank_pairwise(postrank_toy)
s <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s, direction = "ascending")
get_grades(er)
}
\seealso{
\code{\link[=postrank_expected_rank]{postrank_expected_rank()}}, \code{\link[=postrank_composite]{postrank_composite()}}, \code{\link[=postrank_compare]{postrank_compare()}}
}
\concept{baselines}
