% Please edit documentation in R/tie-problem.R
\name{postrank_tie_problem}
\alias{postrank_tie_problem}
\title{Build a Grading Problem Under Equality-Neutral Loss}
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
\item{pairwise}{A validated \code{postrank_tie_pairwise} object from
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}

\item{weights}{Non-negative finite numeric vector named by every criterion in
\code{pairwise} and summing to \code{1} (for a single criterion, supply a named
weight of \code{1}; weights are not normalized automatically).}

\item{tau}{Cost of withholding a distinct comparison, a finite scalar with
\verb{0 < tau <= 0.5}.}

\item{G_max}{Positive integer cap on the number of occupied grades
(\verb{1 <= G_max <= n}).}

\item{objective}{Must be \code{"weighted"} (\code{"minimax"} is not supported in
tie-aware mode).}

\item{q}{Must be \code{NULL} (criterion error budgets are not supported in
tie-aware mode).}

\item{exact_G}{Must be \code{NULL} (requiring an exact grade count is not
supported in tie-aware mode).}
}
\value{
A \code{postrank_tie_problem} list (separate from \code{postrank_problem})
containing \code{pairwise}, \code{settings}, \code{guard} (the active-profile equality
constraint), sparse label-MIP \code{model}, \code{index}, \code{pair_map},
\code{M = choose(n, 2)}, \code{objective_units}, and \code{problem_identity}. Its raw
objective \code{Z} equals weighted expected strict errors minus \code{tau} times
weighted expected disclosed-distinct pairs, so weighted risk is
\code{R0 + Z / M}, where \code{objective_units$offset} is the all-withheld risk
\code{R0 = tau * T / M} (smaller than \code{tau} whenever positive equality
probability is present on an active criterion).
}
\description{
\code{postrank_tie_problem()} builds a weighted mixed-integer grading problem for
tie-aware mode under equality-neutral loss (where true target equality has
zero loss whether the pair is ordered or placed in the same grade). It
chooses one common grading across criteria with at most \code{G_max} occupied
grades while constraining entities in the same active-profile equality class
to receive the same grade. Pass the returned problem to
\code{\link[=postrank_tie_solve]{postrank_tie_solve()}}.
}
\details{
Grade \code{1} is the highest priority, and placing two entities in the same grade
leaves them unordered without claiming equal targets. On criterion \code{k},
ordering \code{i} above \code{j} has expected loss \verb{b[i, j, k] = Pr(theta_\{i,k\} < theta_\{j,k\})}, leaving them in the same grade has expected loss
\verb{tau * d[i, j, k] = tau * Pr(theta_\{i,k\} != theta_\{j,k\})}, and exact equality
(\verb{theta_\{i,k\} = theta_\{j,k\}}) contributes zero loss under either decision.
With \code{T} denoting the criterion-weighted sum of expected distinct pairs,
placing all entities in one shared grade has risk \code{R0 = tau * T / M}, where
\code{M = choose(n, 2)} counts all original unordered entity pairs.

\code{postrank_tie_problem()} intersects the criterion equality partitions across
positive-weight (\code{weights > 0}) criteria to form \emph{active-profile equality
classes} (\code{guard$classes} and \code{guard$groups}, labeled \code{"profile_1"}, ...) and
adds linear equality rows forcing every member of a class to receive the same
grade while keeping all \code{n} entities and original pair multiplicities. For
weighted at-most-\code{G_max} problems without extra constraints, there always
exists a global risk minimizer obeying this constraint (moving all members of
a class to the lowest-cost grade among their currently occupied grades cannot
increase risk or add occupied grades), although unconstrained problems can
also admit other minimizers that split a class.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
problem <- postrank_tie_problem(
  pw,
  weights = c(S = 0.6, C = 0.4),
  tau = 0.25,
  G_max = 3L
)
problem$guard$groups
problem$objective_units
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_tie_solve]{postrank_tie_solve()}}, \code{\link[=postrank_tie_evaluate]{postrank_tie_evaluate()}},
\code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}
}
\concept{tie-aware}
