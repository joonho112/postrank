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
\item{scores}{Finite numeric vector named by \code{pairwise$entity_ids}, for
example from \code{\link[=postrank_expected_rank]{postrank_expected_rank()}} or \code{\link[=postrank_composite]{postrank_composite()}}.}

\item{pairwise}{A \code{postrank_pairwise}, \code{postrank_coefficients} or
\code{\link[=postrank_probabilities]{postrank_probabilities()}} object supplying directional-error
probabilities.}

\item{settings}{A \code{\link[=postrank_settings]{postrank_settings()}} object specifying weighted \code{weights},
\code{tau}, \code{G_max} and optional \code{exact_G}.}

\item{direction}{Score direction: \code{"ascending"} (smaller score = higher
priority, the default, matching \code{\link[=postrank_expected_rank]{postrank_expected_rank()}}) or
\code{"descending"} (larger score = higher priority, matching
\code{\link[=postrank_composite]{postrank_composite()}}).}

\item{rule}{Cut rule: \code{"optimal"} (the default, dynamic programming over
contiguous cuts) or \code{"quantile"} (fixed positional cuts).}

\item{G_b}{Positive integer requested grade count when \code{rule = "quantile"}
(defaults to \code{settings$exact_G}, or \code{settings$G_max}, capped at \code{n}; must
be \code{NULL} when \code{rule = "optimal"}).}

\item{method}{Optional non-empty label for this baseline; defaults to
\code{attr(scores, "score_method")}, or \code{"user_scores"} if unset.}
}
\value{
A \code{postrank_baseline} list containing \code{method}, \code{scores},
\code{direction}, \code{order}, \code{score_blocks}, \code{cut_rule}, \code{cuts}, \code{grade},
\code{evaluation}, \code{objective}, \code{risk}, \code{optimality_scope}, \code{tie_policy}, bound
\code{settings}, \code{input_identity}, \code{schema_version}, \code{provenance} and
\code{warnings}.
}
\description{
\code{postrank_cuts()} partitions an entity score order into contiguous integer
grades (grade 1 = highest priority), keeping entities with equal scores in
the same grade. No external optimization solver is required.
}
\details{
\code{rule = "optimal"} uses dynamic programming (in ordinary floating-point
arithmetic) to minimize weighted expected loss over contiguous partitions of
the given score order under \code{G_max} or \code{exact_G} (breaking exact objective
ties toward fewer occupied grades and then earlier block cuts). Optimality
holds only within contiguous partitions of this score order, not across all
allowed gradings. \code{rule = "quantile"} assigns raw positional grades
\eqn{1 + \lfloor (p - 1) G_b / n \rfloor} without optimization, merging any
grades straddled by equal scores (which can leave fewer than \code{G_b} occupied
grades, recorded in \code{warnings}).

Settings with \code{q} error budgets or \code{objective = "minimax"} stop with
\code{unsupported_baseline_settings}, and \code{exact_G} exceeding the number of
distinct score blocks stops with \code{exact_G_exceeds_blocks} (or
\code{baseline_exact_grade_violation} when quantile merging leaves fewer grades).
\code{\link[=postrank_probabilities]{postrank_probabilities()}} inputs support at-most-\code{G_max} cuts without
\code{exact_G}, whereas \code{postrank_pairwise} and \code{postrank_coefficients} also allow
\code{exact_G}.
}
\examples{
pw <- postrank_pairwise(postrank_toy)
s <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s,
  direction = "ascending")
get_grades(er)
}
\seealso{
\code{\link[=postrank_expected_rank]{postrank_expected_rank()}}, \code{\link[=postrank_composite]{postrank_composite()}},
\code{\link[=postrank_compare]{postrank_compare()}}
}
\concept{baselines}
