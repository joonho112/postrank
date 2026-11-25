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
\item{grade}{Positive integer vector named in the exact \code{entity_ids} order
of \code{pairwise}. Occupied grade numbers are renumbered to \verb{1, ..., G} by
\code{\link[=canonical_postrank_grade]{canonical_postrank_grade()}}.}

\item{pairwise}{Pairwise directional-error probabilities: a
\code{postrank_pairwise}, \code{postrank_coefficients} or \code{\link[=postrank_probabilities]{postrank_probabilities()}}
object. Normal/mixture posteriors and supplied probabilities support only
\code{objective = "weighted"} without \code{minimax_criteria}.}

\item{weights}{Nonnegative finite weights summing to one within \code{1e-12},
uniquely named by criterion (covering every criterion once, including
weight \code{1} for one criterion). Omit when passing \code{settings}; never
rescaled automatically.}

\item{tau}{Cost of leaving a pair unordered (\verb{0 < tau <= 0.5}). Omit when
passing \code{settings}.}

\item{objective}{\code{"weighted"} (the default) or \code{"minimax"}. Minimax uses the
largest posterior expected criterion loss among the selected criteria, not
the expected statewise maximum.}

\item{minimax_criteria}{Optional character vector of criterion IDs included
when \code{objective = "minimax"} (\code{NULL} uses all criteria). Must be \code{NULL}
when \code{objective = "weighted"}.}

\item{settings}{Optional \code{\link[=postrank_settings]{postrank_settings()}} object supplying \code{weights},
\code{tau}, \code{objective} and \code{minimax_criteria} instead of separate arguments;
supplying both stops with \code{settings_conflict}.}
}
\value{
An unclassed named list containing:
\itemize{
\item \code{grade} and \code{G}: the renumbered integer grades (\verb{1, ..., G}) and number
of occupied grades;
\item \code{M}, \code{N}, \code{x}, \code{disclosure_rate} (\code{N / M}) and \code{abstention_rate}
(\code{(M - N) / M}): total unordered pairs, ordered (\code{disclosed}) pairs,
the \verb{n x n} logical ordering matrix (\code{x[i, j]} is \code{TRUE} when
\code{grade[i] < grade[j]}), and pair fractions;
\item \code{E}, \code{E_over_M}, \code{E_over_N} and \code{criterion_risk}: criterion-named
expected wrong-order pair counts, counts divided by \code{M} and by \code{N}
(\code{NA} when \code{N = 0}), and per-criterion loss \code{(E_k + tau * (M - N)) / M};
\item \code{weighted_risk}, \code{minimax_risk}, \code{primary_risk} and
\code{weighted_raw_objective} (\code{sum(weights * E) - tau * N});
\item \code{objective}, \code{minimax_criteria}, \code{settings}, \code{schema_version},
\code{input_identity} and \code{pairwise_identity}.
}
}
\description{
\code{postrank_evaluate()} computes the ordered pair count, posterior expected
wrong-order errors and posterior expected loss for a supplied integer grade
vector, without running an optimization solver. Grade 1 is the highest
priority; entities given the same grade are left unordered without claiming
they are equal.
}
\details{
When every entity is given the same grade (\code{G = 1}), \code{N = 0}, \code{E_over_N} is
\code{NA}, and every criterion's loss equals \code{tau}. \code{postrank_evaluate()} scores
any valid grade vector; it does not check whether \code{grade} satisfies \code{G_max},
\code{exact_G} or \code{q} constraints in \code{settings} (see \code{\link[=postrank_problem]{postrank_problem()}} and
\code{\link[=postrank_compare]{postrank_compare()}}).
}
\examples{
grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
ev <- postrank_evaluate(grade, pr_tutorial$one,
  weights = c(score_A = 1), tau = 0.2)
ev[c("N", "M", "E_over_N", "primary_risk")]

held <- postrank_evaluate(setNames(rep(1L, 6), names(grade)),
  pr_tutorial$one, weights = c(score_A = 1), tau = 0.2)
held[c("N", "E_over_N", "primary_risk")]
}
\seealso{
\code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=get_profile]{get_profile()}},
\code{\link[=canonical_postrank_grade]{canonical_postrank_grade()}}
}
\concept{decision}
