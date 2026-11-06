% Please edit documentation in R/tie-evaluate.R
\name{postrank_tie_evaluate}
\alias{postrank_tie_evaluate}
\title{Score Fixed Grades When True Equality Has Zero Loss}
\usage{
postrank_tie_evaluate(grade, pairwise, weights, tau)
}
\arguments{
\item{grade}{Positive integer numeric vector named in declared entity order.
Labels are canonicalized without changing pairwise relations.}

\item{pairwise}{A validated object from \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}

\item{weights}{Nonnegative finite weights, named for every criterion exactly
once and summing to one. They are not automatically normalized. For one
criterion, supply its named weight of 1.}

\item{tau}{Cost of withholding a distinct comparison, in \verb{(0, 0.5]}.}
}
\value{
A \code{postrank_tie_evaluation} list with the grade, counts, losses,
settings, input identities and \code{guard_satisfied}/\code{guard_classes}.
Criterion-specific \code{E} (also \code{Eb}), \code{D_k}, \code{T_k} and \code{H_k} are expected
wrong, disclosed-distinct, total-distinct and withheld-distinct counts.
\code{D} and \code{T} are the weighted distinct counts. \code{N} is the raw number of
disclosed unordered pairs; \code{M} counts all unordered pairs.

\code{disclosure_rate = N/M} and \code{D_over_T} (also
\code{distinct_disclosure_rate}) use raw pairs and distinct opportunities,
respectively. \code{D_k_over_T_k}, \code{E_over_D} and \code{E_over_N} keep the
criterion-specific distinct and raw denominators separate. Ratios with
zero denominators are \code{NA}.

\code{criterion_risk} and \code{criterion_baseline} contain criterion losses and
all-withheld baselines. \code{weighted_risk} and \code{primary_risk} are the
weighted loss. \code{all_withhold_risk} (also \code{R0}) is its all-withheld
baseline. \code{weighted_raw_objective} (also \code{raw_Z}) is
\code{sum(weights * E) - tau * D}.
}
\description{
A proposed grading is evaluated under the equality-neutral loss. A disclosed
direction incurs an error only when the targets are strictly reversed, and
withholding costs \code{tau} only when the targets are distinct. True equality
therefore has zero loss under either action. Shared grades remain decisions
to withhold comparisons and do not establish target equality. The supplied
grades are evaluated without selection or optimization.
}
\details{
Criterion risk is \code{(E + tau * H_k) / M}. The all-withheld baseline
is \code{R0 = tau * T / M}, which is generally smaller than \code{tau} when some
equality mass is present. Risk also equals \code{R0 + raw_Z / M}, but the
evaluator directly sums the action's losses independently of the solver
objective. For an all-withheld action, N and every D_k are zero, risk is
R0, and E/N and E/D_k are undefined. Zero expected strict errors do not
establish a strictly superior direction when equality is possible.

Ratios are ratios of posterior expected counts, not expectations of
realized draw-specific ratios. They describe the supplied law and loss,
not external prediction accuracy or policy benefit. Ordinary
\code{\link[=postrank_evaluate]{postrank_evaluate()}} retains its separate weak-error loss and does not
silently change when this function is used.

Entities equal with probability one on every positive-weight criterion
form an active-profile class. Tie-aware optimization keeps each such
class in one grade. This evaluator reports whether a fixed grade obeys
that rule, but also scores violations for comparison. It does not check
a \code{G_max} family or establish feasibility or optimality. Use
\code{\link[=validate_postrank_tie_solution]{validate_postrank_tie_solution()}} to check a problem's numerical solution.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  # A complete two-state law, not two Monte Carlo draws.
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
  weights <- c(S = .6, C = .4)
  ev <- postrank_tie_evaluate(c(A = 3L, B = 3L, C = 2L, D = 1L),
    pw, weights, tau = .25)
  ev[c("primary_risk", "R0", "N", "D", "T", "guard_satisfied")]
  held <- postrank_tie_evaluate(c(A = 1L, B = 1L, C = 1L, D = 1L),
    pw, weights, tau = .25)
  held[c("primary_risk", "E_over_N", "E_over_D")]
}
}
\seealso{
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}},
\code{vignette("m4-ties-and-withholding", package = "postrank")}
}
\concept{tie-aware}
