% Please edit documentation in R/problem-class.R
\name{postrank_problem}
\alias{postrank_problem}
\title{Build a Problem for Choosing Common Grades}
\usage{
postrank_problem(
  pairwise,
  weights = NULL,
  tau = NULL,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
}
\arguments{
\item{pairwise}{Pairwise directional-error probabilities: a
\code{postrank_pairwise} object from \code{\link[=postrank_pairwise]{postrank_pairwise()}}, a
\code{postrank_coefficients} object (\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}},
\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}), or a \code{\link[=postrank_probabilities]{postrank_probabilities()}}
object. Normal/mixture posteriors and supplied probabilities support only
the weighted objective without \code{q}, \code{exact_G} or \code{minimax_criteria}.}

\item{weights}{Nonnegative finite weights summing to one within \code{1e-12},
uniquely named by criterion (covering every criterion once, including
weight \code{1} for one criterion). Omit when passing \code{settings}; never
rescaled automatically.}

\item{tau}{Cost of leaving a pair unordered (\verb{0 < tau <= 0.5}). Omit when
passing \code{settings}.}

\item{G_max}{Largest number of occupied grades, a positive integer at most
the number of entities when passed directly. Fewer grades are allowed
unless \code{exact_G} is given. Omit when passing \code{settings}.}

\item{objective}{\code{"weighted"} (the default) minimizes the weighted sum of
criterion losses; \code{"minimax"} minimizes the largest loss among the
selected criteria.}

\item{q}{Optional vector of per-criterion expected-error budgets in \verb{[0, 1]},
uniquely named by known criteria. Each requires \code{E_k <= q_k * N} (even if
criterion \code{k} has weight 0 in \code{weights}); at \code{N = 0} this holds (\code{0 <= 0})
while \code{E_k / N} is \code{NA}.}

\item{exact_G}{Optional positive integer requiring an exact number of
occupied grades, at most \code{G_max} and never reduced automatically.}

\item{minimax_criteria}{Optional character vector of criterion IDs included
in the minimax objective (\code{NULL} includes all criteria). Allowed only when
\code{objective = "minimax"}.}

\item{minimax_refine}{How to refine a minimax solution when
\code{objective = "minimax"}: \code{"weighted"} (the default) or \code{"none"}; see
\code{\link[=postrank_solve]{postrank_solve()}}. Ignored when \code{objective = "weighted"}.}

\item{settings}{Optional \code{\link[=postrank_settings]{postrank_settings()}} object used instead of
\code{weights}, \code{tau}, \code{G_max}, \code{objective}, \code{q}, \code{exact_G}, \code{minimax_criteria}
and \code{minimax_refine}. Supplying both stops with \code{settings_conflict}.
Unlike a direct \code{G_max} argument, \code{settings} reduces an oversized \code{G_max}
to the number of entities.}
}
\value{
A \code{postrank_problem} object, a list containing \code{pairwise},
\code{settings}, the sparse linear/integer \code{model}, variable \code{index},
\code{pair_map}, unordered pair count \code{M}, \code{objective_units} (scale and offset
converting raw objective values to normalized loss), \code{input_identity},
\code{problem_identity}, \code{schema_version} and \code{builder_version}. When
\code{objective = "minimax"}, \code{minimax_diagnostics$degenerate_criteria} lists
any selected criteria whose directional-error probabilities are all at
least \code{tau} (whose criterion loss cannot fall below \code{tau}).
}
\description{
\code{postrank_problem()} builds the optimization problem for \code{\link[=postrank_solve]{postrank_solve()}}
from pairwise comparison probabilities and loss settings, without calling a
solver or fitting a model. Grade 1 is the highest priority, and entities in
the same grade are left unordered.
}
\details{
Losses and \code{q} error budgets are posterior expectations conditional on the
supplied probabilities; \code{q} constrains expected wrong-order counts rather
than realized error rates. The minimax objective minimizes
\verb{max_k E[loss_k]}, not \verb{E[max_k loss_k]}. To compute the loss of an existing
grading without building an optimization model, use \code{\link[=postrank_evaluate]{postrank_evaluate()}}.
}
\examples{
one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
  tau = 0.2, G_max = 3L)
one$objective_units

pw <- postrank_pairwise(postrank_toy)
protected <- postrank_problem(pw, weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25, G_max = 3L, q = c(need_B = 0.3), exact_G = 2L)
protected$settings[c("G_max", "exact_G", "q")]
}
\seealso{
\code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}}
}
\concept{decision}
