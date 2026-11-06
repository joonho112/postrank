% Please edit documentation in R/tie-problem.R
\name{postrank_tie_problem}
\alias{postrank_tie_problem}
\title{Build a Grading Problem with Equality-Neutral Loss}
\usage{
postrank_tie_problem(
  pairwise,
  weights,
  tau,
  G_max,
  objective = "weighted",
  q = NULL,
  exact_G = NULL
)
}
\arguments{
\item{pairwise}{A validated object from \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}, with
strict-error, equality and distinctness probabilities and verified
criterion equality partitions.}

\item{weights}{Nonnegative finite weights named for every criterion exactly
once and summing to one. No automatic normalization is used. A single
criterion requires its named weight of 1.}

\item{tau}{Cost of withholding a distinct comparison, with \verb{0 < tau <= 0.5}.}

\item{G_max}{Positive integer upper bound on occupied grades, no larger than
the original entity count. This is a cap, not a required grade count.}

\item{objective}{Only \code{"weighted"} is supported in this mode.}

\item{q}{Must be \code{NULL}; tie-aware error-budget protection is unsupported.}

\item{exact_G}{Must be \code{NULL}; requiring an exact grade count is unsupported.}
}
\value{
A \code{postrank_tie_problem} with a sparse label mixed-integer model,
\code{guard}, \code{M}, \code{objective_units}, settings and input/loss identities. Its raw
objective Z is weighted expected strict errors minus \code{tau} times weighted
disclosed-distinct opportunities. Risk is \code{R0 + Z/M}; the offset
\code{objective_units$offset} is the all-withheld risk R0, not generally \code{tau}.
}
\description{
A weighted problem is constructed for targets that may be exactly equal. One
common grading is selected for all criteria, subject to at most \code{G_max}
occupied grades and a constraint retaining verified identical active
profiles in the same grade. The resulting problem is passed to
\code{\link[=postrank_tie_solve]{postrank_tie_solve()}} for optimization. This explicitly selected loss
leaves ordinary postrank problems unchanged.
}
\details{
Grade 1 has highest priority; a shared grade withholds a direction.
Disclosing i above j has criterion loss \code{P(theta_i < theta_j)};
withholding has loss \code{tau * P(theta_i != theta_j)}. Genuine equality
costs zero under either action. With T the weighted expected number of
distinct pairs, \code{R0 = tau * T/M}. M still counts the original unordered
entity pairs, including pairs with equality mass.

The mandatory guard intersects verified equality partitions over the
positive-weight criteria. Entities in the same resulting active-profile
class receive the same grade. The sparse model enforces label equality
within each class; it retains all entities and original pair
multiplicities. Equal sample values or posterior means alone cannot
establish an almost-sure equality class.

For weighted at-most-G decisions without extra constraints, there exists
a global minimizer obeying the guard: moving an equality class to its
least costly currently occupied class grade cannot increase risk or the
number of occupied grades. This is an existence result, not a claim that
every unconstrained optimum obeys the guard. It does not extend here to
quotas, q budgets, minimax or exact-G decisions, or guarantee that a
funding schedule is preserved when the grade count changes.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  problem <- postrank_tie_problem(pw, weights = c(S = .6, C = .4),
    tau = .25, G_max = 3L)
  problem$guard$groups
  problem$objective_units
}
}
\seealso{
\code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}}, \code{\link[=postrank_tie_solve]{postrank_tie_solve()}},
\code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}
}
\concept{tie-aware}
